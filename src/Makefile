# -std=c++11 enables the use of R"( )"
# -lstdc++ enables to use C++ I/O streams, etc.

FFLAGS = -O3 -xCORE-AVX2 -lstdc++ -qopenmp
CFLAGS = -O3 -xCORE-AVX2 -std=c++11

MKLROOT  = $(ONEAPI_ROOT)/mkl/latest
GLFWROOT = $(HOME)/install/glfw/3.4

LDFLAGS = -L$(GLFWROOT)/lib-x86_64
LDLIBS  = -lglfw3 -framework Cocoa -framework OpenGL -framework IOKit \
          -L/usr/local/lib -larpack -llapack -lblas

MODS = $(MKLROOT)/lib/libmkl_intel_lp64.a \
       $(MKLROOT)/lib/libmkl_intel_thread.a \
       $(MKLROOT)/lib/libmkl_core.a
MODFLAGS = -liomp5 -lpthread -lm -ldl

OBJ    = gl_module.o mkl_dfti.o gl_binding.o
TARGET = main_harm.x main_nls.x

all: fresh $(OBJ) $(TARGET) clean

fresh:
	@rm -f *.x *.o *.mod ../*.x ../images/*.png

%.o: %.f90
	ifort -c $< $(FFLAGS)

%.o: %.cpp
	icc -c $< $(CFLAGS) -I$(GLFWROOT)/include

%.x: %.o
	ifort -o $@ $< $(OBJ) $(FFLAGS) $(MODS) $(MODFLAGS) $(LDFLAGS) $(LDLIBS)
	@cp $@ ../

clean:
	@rm -f *.x *.o *.mod

