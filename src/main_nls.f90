! This code solves the time-dependent Gross–Pitaevskii equation
! using the split-step propagation method and Intel MKL library.
!
! Author: Sergey Yalunin
! Date: 2024-08-26

program main_nls
   use iso_c_binding
   use MKL_DFTI
   use gl_module
   implicit none
   type(c_ptr)    :: window
   !
   integer, parameter :: nx = 400
   integer, parameter :: ny = 400
   integer, parameter :: n = nx * ny
   real(8), parameter :: tpi = 8 * atan(1.0d0)
   real(8), parameter :: rad = 4.4d0
   real(8), parameter :: dx = 2 * rad / nx
   real(8), parameter :: dy = 2 * rad / ny
   real(8), parameter :: dkx = tpi / (nx * dx)
   real(8), parameter :: dky = tpi / (ny * dy)
   real(8), parameter :: B = -10.0d0
   complex(8), parameter :: dt = (0.001d0, 0.006d0)
   !
   integer        :: i, j, k, iter, status
   real(c_float)  :: pos(4)
   real(8)        :: umax
   !
   complex(8),    allocatable, dimension(:)   :: u
   real(8),       allocatable, dimension(:)   :: x, y, r, kx, ky, pot, phase
   real(c_float), allocatable, dimension(:,:) :: color1, brightness1
   real(c_float), allocatable, dimension(:,:) :: color2, brightness2
   type(DFTI_DESCRIPTOR), pointer :: hand => null()
   type(DFTI_DESCRIPTOR), pointer :: hand1 => null()
   type(DFTI_DESCRIPTOR), pointer :: hand2 => null()
   !
   allocate( x(n), y(n), r(n), kx(n), ky(n), u(n), pot(n), phase(n) )
   allocate( color1(ny,3*nx), brightness1(ny,3*nx) )
   allocate( color2(ny,3*nx), brightness2(ny,3*nx) )
   !
   ! FFT in both dimensions
   status = DftiCreateDescriptor(hand, DFTI_DOUBLE , DFTI_COMPLEX, 2, [ny,nx])
   status = DftiSetValue(hand, DFTI_FORWARD_SCALE, 1.0d0);
   status = DftiSetValue(hand, DFTI_BACKWARD_SCALE, 1.0d0/n);
   status = DftiCommitDescriptor(hand)
   !
   ! FFT along 1st dimension
   status = DftiCreateDescriptor(hand1, DFTI_DOUBLE, DFTI_COMPLEX, 1, ny)
   status = DftiSetValue(hand1, DFTI_NUMBER_OF_TRANSFORMS, nx)
   status = DftiSetValue(hand1, DFTI_INPUT_DISTANCE, ny)
   status = DftiSetValue(hand1, DFTI_BACKWARD_SCALE, 1.0d0/ny)
   status = DftiCommitDescriptor(hand1)
   !
   ! FFT along 2st dimension
   status = DftiCreateDescriptor(hand2, DFTI_DOUBLE, DFTI_COMPLEX, 1, nx)
   status = DftiSetValue(hand2, DFTI_NUMBER_OF_TRANSFORMS, ny)
   status = DftiSetValue(hand2, DFTI_INPUT_DISTANCE, 1)
   status = DftiSetValue(hand2, DFTI_INPUT_STRIDES, [0,ny])
   status = DftiSetValue(hand2, DFTI_BACKWARD_SCALE, 1.0d0/nx)
   status = DftiCommitDescriptor(hand2)
   !
   window = gl_create_window(3*nx, 2*ny, "Quantum vortices")
   call gl_set_window_pos(window, 400, 0)
   call gl_clear_buffer(0.0, 0.0, 0.0)
   !
   do i = 1,nx
      do j = 1,ny
         k = j + (i-1) * ny
         x(k) = (i-dble(nx+1)/2) * dx
         y(k) = (j-dble(ny+1)/2) * dy
         !
         kx(k) = (i-1) * dkx
         ky(k) = (j-1) * dky
         if (i-1 > nx/2) kx(k) = kx(k) - nx * dkx
         if (j-1 > ny/2) ky(k) = ky(k) - ny * dky
      enddo
   enddo
   !
   call random_number(u%re)
   phase = atan2(y, x)
   r = sqrt(x*x + y*y)
   u = r * exp(-r/2 + (0.0d0, 1.0d0)*phase)
   !
   iter = 0
   brightness1 = 1.0_c_float
   brightness2 = 1.0_c_float
   do while (.not.gl_window_should_close(window))
      if (.not.gl_get_mouse_button(window,0)) then
         ! compare with J. Phys. Soc. Jpn. 89, 054006 (2020)
         status = DftiComputeForward(hand1, u)
         u = exp(-dt * (ky*ky - B*ky*x)) * u
         status = DftiComputeBackward(hand1, u)
         status = DftiComputeForward(hand2, u)
         u = exp(-dt * (kx*kx + B*kx*y)) * u
         status = DftiComputeBackward(hand2, u)
         pot = (2 + B*B/4) * (x*x + y*y) + 40 * abs(u)**2 - 40
         u = exp(-dt * pot) * u
         iter = iter + 1
      endif
      !
      umax = maxval(abs(u))
      do i = 1,3
         if ((iter==10 .and. i==1) .or. (iter==1120 .and. i==2) .or. (i==3)) then
            phase = atan2(aimag(u), real(u))+tpi/2
            color1(:,(i-1)*nx+1:i*nx) = reshape(real(phase/tpi, kind=c_float), [ny,nx])
            color2(:,(i-1)*nx+1:i*nx) = reshape(real(abs(u)/umax, kind=c_float), [ny,nx])
            brightness1(:,(i-1)*nx+1:i*nx) = color2(:,(i-1)*nx+1:i*nx)**0.8_c_float
            brightness2(:,(i-1)*nx+1:i*nx) = 1.0_c_float
         endif
      enddo
      !
      pos = [-1.0, 0.0, 1.0, 1.0]
      call gl_set_colormap("colormaps/rainbow1024.txt")
      call gl_draw_image(pos, shape(color2), color2, brightness2)
      !
      pos = [-1.0,-1.0, 1.0, 0.0]
      call gl_set_colormap("colormaps/binary_r1024.txt")
      call gl_draw_image(pos, shape(color1), color1, brightness1)
      call gl_swap_buffers(window)
      !
      call gl_poll_events()
      print *, " iter =", iter
      !
   enddo
   !
   status = DftiFreeDescriptor(hand)
   status = DftiFreeDescriptor(hand1)
   status = DftiFreeDescriptor(hand2)
   !
   call gl_destroy_window(window)
   !
end program main_nls
