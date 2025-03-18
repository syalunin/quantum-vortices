module gl_module
use iso_c_binding
implicit none
interface

! Create a window
function gl_create_window(width, height, title) bind(C, name="gl_create_window")
   import c_ptr, c_int
   type(c_ptr) :: gl_create_window
   integer(c_int), intent(in), value :: width, height
   character(*), intent(in) :: title
end function gl_create_window

! Set the position of the upper-left corner
subroutine gl_set_window_pos(window, xpos, ypos) bind(C, name="glfwSetWindowPos")
   import c_ptr, c_int
   type(c_ptr), intent(in), value :: window
   integer(c_int), intent(in), value :: xpos, ypos
end subroutine gl_set_window_pos

! Checks the close flag of the specified window
function gl_window_should_close(window) bind(C, name="glfwWindowShouldClose")
   import c_ptr, c_int
   integer(c_int) :: gl_window_should_close
   type(c_ptr), intent(in), value :: window
end function gl_window_should_close

! Swap the front and back buffers
subroutine gl_swap_buffers(window) bind(C, name="glfwSwapBuffers")
   import c_ptr
   type(c_ptr), intent(in), value :: window
end subroutine gl_swap_buffers

! Process events in the event queue
subroutine gl_poll_events() bind(C, name="glfwPollEvents")
end subroutine gl_poll_events

! Draw an image
subroutine gl_draw_image(pos, shape, data1, data2) bind(C, name="gl_draw_image")
   import c_ptr, c_int, c_float
   integer(c_int), intent(in) :: shape(2)
   real(c_float), intent(in) :: pos(*), data1(*), data2(*)
end subroutine gl_draw_image

! Set a colormap using unit 0
subroutine gl_set_colormap(filename) bind(C, name="gl_set_colormap")
   character(*), intent(in) :: filename
end subroutine gl_set_colormap

! Clear the background
subroutine gl_clear_buffer(red, green, blue) bind(C, name="gl_clear_buffer")
   import c_float
   real(c_float), intent(in), value :: red, green, blue
end subroutine gl_clear_buffer

! Make the context if the window current on the calling thread
subroutine gl_make_context_current(window) bind(C, name="glfwMakeContextCurrent")
   import c_ptr
   type(c_ptr), intent(in), value :: window
end subroutine gl_make_context_current

! Destroy the window and terminate GLFW
subroutine gl_destroy_window(window) bind(C, name="gl_destroy_window")
   import c_ptr
   type(c_ptr), intent(in), value :: window
end subroutine gl_destroy_window

! Get mouse button state
function gl_get_mouse_button(window, button) bind(C, name="glfwGetMouseButton")
   import c_ptr, c_int
   integer(c_int) :: gl_get_mouse_button
   type(c_ptr), intent(in), value :: window
   integer(c_int), intent(in), value :: button
end function gl_get_mouse_button

end interface
end module gl_module
