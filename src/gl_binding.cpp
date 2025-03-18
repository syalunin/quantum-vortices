#include <iso_fortran_binding.h>
#include <OpenGL/gl3.h> // enables GL3.0+ features
#include <GLFW/glfw3.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <math.h>

GLuint uloc_pos;

static const char* vertexSource = R"(
#version 410 core
out vec2 uv;
uniform vec4 pos;
vec2 vpos[6] = vec2[6](
vec2(pos[0],pos[1]), vec2(pos[0],pos[3]), vec2(pos[2],pos[1]),
vec2(pos[2],pos[1]), vec2(pos[2],pos[3]), vec2(pos[0],pos[3]));
const vec2 textureCoord[6] = vec2[6](
vec2(0.0,0.0), vec2(1.0,0.0), vec2(0.0,1.0),
vec2(0.0,1.0), vec2(1.0,1.0), vec2(1.0,0.0));
void main() {
   gl_Position = vec4(vpos[gl_VertexID], 0.0, 1.0);
   uv = textureCoord[gl_VertexID];
})";

static const char* fragmentSource = R"(
#version 410 core
in vec2 uv;
out vec4 fragmentColor;
uniform sampler2D data1;
uniform sampler2D data2;
uniform sampler1D colormap;
vec3 rgb2hsv(vec3 rgb) {
   float cmax = max(rgb.r, max(rgb.g, rgb.b));
   float cmin = min(rgb.r, min(rgb.g, rgb.b));
   float delta = cmax - cmin;
   float h = 0.0;
   if (delta > 0.0) {
      if      (cmax == rgb.r) h = (rgb.g - rgb.b) / delta;
      else if (cmax == rgb.g) h = (rgb.b - rgb.r) / delta + 2.0;
      else h = (rgb.r - rgb.g) / delta + 4.0;
      h = mod(h / 6.0, 1.0);
   }
   float s = (cmax == 0.0) ? 0.0 : delta / cmax;
   float v = cmax;
   return vec3(h, s, v);
}
vec3 hsv2rgb(vec3 hsv) {
   float h = hsv.x * 6.0;
   float s = hsv.y;
   float v = hsv.z;
   float c = v * s;
   float x = c * (1.0 - abs(mod(h, 2.0) - 1.0));
   float m = v - c;
   vec3 rgb = vec3(0.0);
   if      (h < 1.0) rgb = vec3(c, x, 0.0);
   else if (h < 2.0) rgb = vec3(x, c, 0.0);
   else if (h < 3.0) rgb = vec3(0.0, c, x);
   else if (h < 4.0) rgb = vec3(0.0, x, c);
   else if (h < 5.0) rgb = vec3(x, 0.0, c);
   else rgb = vec3(c, 0.0, x);
   return rgb + vec3(m, m, m);
}
void main() {
   float data = texture(data1, uv).r;
   vec3 hsv = rgb2hsv(texture(colormap, data).rgb);
   hsv.z = hsv.z * texture(data2, uv).r;
   fragmentColor.rgb = hsv2rgb(hsv);
})";

// Compile a shader program
GLuint gl_create_program(const char *vertexSource, const char *fragmentSource) {
   const GLsizei length = 512;
   GLchar infoLog[length];
   GLuint vertexShader;
   GLuint fragmentShader;
   GLuint shaderProgram;
   GLint success;

   vertexShader = glCreateShader(GL_VERTEX_SHADER);
   glShaderSource(vertexShader, 1, &vertexSource, nullptr);
   glCompileShader(vertexShader);
   glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
   if (!success) {
      glGetShaderInfoLog(vertexShader, length, nullptr, infoLog);
      std::cerr << "Failed to compile vertex shader" << std::endl;
      std::cerr << infoLog << std::endl;
      std::exit(EXIT_FAILURE);
   }

   fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
   glShaderSource(fragmentShader, 1, &fragmentSource, nullptr);
   glCompileShader(fragmentShader);
   glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
   if (!success) {
      glGetShaderInfoLog(fragmentShader, length, nullptr, infoLog);
      std::cerr << "Failed to compile fragment shader" << std::endl;
      std::cerr << infoLog << std::endl;
      std::exit(EXIT_FAILURE);
   }

   shaderProgram = glCreateProgram();
   glAttachShader(shaderProgram, vertexShader);
   glAttachShader(shaderProgram, fragmentShader);
   glLinkProgram(shaderProgram);
   glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
   if (!success) {
      glGetProgramInfoLog(shaderProgram, length, nullptr, infoLog);
      std::cerr << "Failed to link shaders" << std::endl;
      std::cerr << infoLog << std::endl;
      std::exit(EXIT_FAILURE);
   }
   glDeleteShader(vertexShader);
   glDeleteShader(fragmentShader);
   return shaderProgram;
}

// Convert a Fortran string to C++ string
std::string fstr2c(CFI_cdesc_t* data) {
   char* fstr = (char*) data->base_addr;
   int length = (int) data->elem_len;
   std::string cstr(fstr, length);
   return cstr;
}

// Set a colormap using unit 0
extern "C" void gl_set_colormap(CFI_cdesc_t* filename_) {
   std::string filename = fstr2c(filename_);
   std::ifstream fin(filename, std::ifstream::in);
   if (!fin) {
      std::cerr << "Failed to open " << filename << std::endl;
      std::exit(EXIT_FAILURE);
   }
   GLsizei length;
   fin >> length;
   GLfloat* colormap = new GLfloat[3*length];
   for (int i = 0; i<3*length; i++) fin >> colormap[i];
   fin.close();

   GLuint texture;
   glGenTextures(1, &texture);
   glActiveTexture(GL_TEXTURE0);
   glBindTexture(GL_TEXTURE_1D, texture);
   glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAX_LEVEL, 0);
   glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
   glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
   glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
   glTexImage1D(GL_TEXTURE_1D, 0, GL_RGB32F, length, 0, GL_RGB, GL_FLOAT, colormap);
   delete[] colormap;
}

// Create a window
extern "C" GLFWwindow* gl_create_window(int width, int height, CFI_cdesc_t* title_) {
   if (!glfwInit()) {
      std::cerr << "Failed to initialize GLFW" << std::endl;
      std::exit(EXIT_FAILURE);
   }
   glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
   glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
   glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
   glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
   std::string title = fstr2c(title_);
   GLFWwindow* window = glfwCreateWindow(width, height, title.c_str(), nullptr, nullptr);
   if (!window) {
      glfwTerminate();
      std::cerr << "Failed to create window" << std::endl;
      std::exit(EXIT_FAILURE);
   }
   glfwSetWindowPos(window, 0, 0);
   glfwMakeContextCurrent(window);
   std::cout << "Window successfully created" << std::endl;
   std::cout << "GL version  : " << glGetString(GL_VERSION) << std::endl;
   std::cout << "GL renderer : " << glGetString(GL_RENDERER) << std::endl;
   
   GLuint program = gl_create_program(vertexSource, fragmentSource);
   GLint uloc_colormap = glGetUniformLocation(program, "colormap");
   GLint uloc_data1 = glGetUniformLocation(program, "data1");
   GLint uloc_data2 = glGetUniformLocation(program, "data2");
   uloc_pos = glGetUniformLocation(program, "pos");
   glUseProgram(program);
   glUniform1i(uloc_colormap, 0);
   glUniform1i(uloc_data1, 1);
   glUniform1i(uloc_data2, 2);

   GLuint vao;
   glGenVertexArrays(1, &vao);
   glBindVertexArray(vao);
   return window;
}

// Clear the background
extern "C" void gl_clear_buffer(GLfloat red, GLfloat green, GLfloat blue) {
   glClearColor(red, green, blue, 1.0f);
   glClear(GL_COLOR_BUFFER_BIT);
}

// Draw an image
extern "C" void gl_draw_image(GLfloat* pos, GLsizei* shape, GLfloat* data1, GLfloat* data2) {
   glUniform4f(uloc_pos, pos[0], pos[1], pos[2], pos[3]);
   GLsizei N1 = shape[0];
   GLsizei N2 = shape[1];

   GLuint texture1;
   glGenTextures(1, &texture1);
   glActiveTexture(GL_TEXTURE1);
   glBindTexture(GL_TEXTURE_2D, texture1);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_R32F, N1, N2, 0, GL_RED, GL_FLOAT, data1);

   GLuint texture2;
   glGenTextures(1, &texture2);
   glActiveTexture(GL_TEXTURE2);
   glBindTexture(GL_TEXTURE_2D, texture2);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_R32F, N1, N2, 0, GL_RED, GL_FLOAT, data2);

   glDrawArrays(GL_TRIANGLES, 0, 6);
   glDeleteTextures(1, &texture1);
   glDeleteTextures(1, &texture2);
}

// Destroy a window and terminate GLFW
extern "C" void gl_destroy_window(GLFWwindow* window) {
   glfwDestroyWindow(window);
   glfwTerminate();
}
