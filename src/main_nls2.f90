program main_magn
   use iso_c_binding
   use gl_module
   implicit none
   type(c_ptr)    :: window
   !
   integer, parameter :: nx = 200
   integer, parameter :: ny = nx + 1
   integer, parameter :: n = nx * ny
   integer, parameter :: nev = 4
   integer, parameter :: ncv = 2 * nev + 40
   real(8), parameter :: pi = 4 * atan(1.0d0)
   real(8), parameter :: rad = 3.2d0
   real(8), parameter :: dx = 2 * rad / nx
   real(8), parameter :: dy = dx
   real(8), parameter :: tol = 1.0d-18
   !
   integer    :: i, j, k, loc
   integer    :: ido, ierr, iparam(11), ipntr(14)
   complex(8) :: sigma = (0.0d0, 0.0d0)
   logical    :: select(ncv)
   !
   complex(8),    allocatable, dimension(:)   :: u, workev, workd, workl
   complex(8),    allocatable, dimension(:)   :: eval, resid
   complex(8),    allocatable, dimension(:,:) :: evec
   real(c_float), allocatable, dimension(:,:) :: color
   real(c_float), allocatable, dimension(:,:) :: brightness
   real(8),       allocatable, dimension(:)   :: rwork
   real(8),       allocatable, dimension(:)   :: x, y, r, pot, phase
   !
   allocate( x(n), y(n), r(n), pot(n), u(n) )
   allocate( workev(2*ncv), workl(ncv*(3*ncv+5)) )
   allocate( workd(3*n), rwork(ncv), resid(n) )
   allocate( eval(nev), evec(n,ncv) )
   allocate( color(ny,nx), brightness(ny,nx) )
   !
   ido = 0
   ierr = 0
   iparam(1) = 1
   iparam(3) = 300
   iparam(7) = 1
   !
   do i = 1,nx
      do j = 1,ny
         k = j + (i-1) * ny
         x(k) = (i-dble(nx+1)/2) * dx
         y(k) = (j-dble(ny+1)/2) * dy
      enddo
   enddo
   r = sqrt(x*x + y*y)
   pot = merge(r*r/2, 10*rad*rad/2, r < (rad-2*dx))
   !
   do
      call znaupd(ido, 'I', n, 'SM', nev, tol, resid, ncv, &
         evec, n, iparam, ipntr, workd, workl, size(workl), rwork, ierr)
      if (abs(ido)==1) then
         call matvec(nx, ny, dx, dy, x, y, pot, workd(ipntr(1)), workd(ipntr(2)))
      else
         exit
      endif
   end do
   !
   call zneupd(.true., 'All', select, eval, evec, n, sigma, workev, &
      'I', n, 'SM', nev, tol, resid, ncv, evec, n, iparam, ipntr, &
      workd, workl, size(workl), rwork, ierr)
   !
   window = gl_create_window(2*nx, 2*ny, "Simulation")
   call gl_set_window_pos(window, 400, 0)
   call gl_set_colormap("colormap/rainbow1024.txt")
   !
   do k = 1,nev
      loc = maxloc(abs(evec(:,k)), dim=1)
      evec(:,k) = evec(:,k) / evec(loc,k)
   enddo
   !
   k = 1
   phase = atan2(aimag(evec(:,k)), real(evec(:,k)))
   color = reshape(real((phase+pi)/(2*pi), kind=c_float), [ny,nx])
   brightness = reshape(real(abs(evec(:,k)), kind=c_float), [ny,nx])
   !brightness = 1.0_c_float
   !
   do while (.not.gl_window_should_close(window))
      call gl_draw_image(window, ny, nx, color, brightness)
      call gl_swap_buffers(window)
      call gl_poll_events()
      call sleep(1)
   enddo
   call gl_destroy_window(window)
   !
end program


subroutine matvec(nx, ny, dx, dy, x, y, pot, u, v)
   integer, intent(in)  :: nx, ny
   real(8), intent(in)  :: dx, dy
   real(8), intent(in)  :: x(nx * ny), y(nx * ny), pot(nx * ny)
   complex(8), intent(in)  :: u (nx * ny)
   complex(8), intent(out) :: v (nx * ny)
   complex(8) :: ux(nx * ny), uxx(nx * ny)
   complex(8) :: uy(nx * ny), uyy(nx * ny)
   complex(8) :: B = (0.0d0, 10.0d0)
   integer    :: i, j, k
   !
   ux = (0.0d0, 0.0d0)
   uy = (0.0d0, 0.0d0)
   uxx = -2 * u / (dx * dx)
   uyy = -2 * u / (dy * dy)
   do i = 1,nx
      do j = 1,ny
         k = j + (i-1) * ny
         if (i>1)  then
            uxx(k) = uxx(k) + u(k-ny) / (dx*dx)
            ux (k) = ux (k) - u(k-ny) / (2*dx)
         else
            !uxx(k) = uxx(k) + u(k+(nx-1)*ny) / (dx*dx)
            !ux (k) = ux (k) - u(k+(nx-1)*ny) / (2*dx)
         endif
         if (i<nx) then
            uxx(k) = uxx(k) + u(k+ny) / (dx*dx)
            ux (k) = ux (k) + u(k+ny) / (2*dx)
         else
            !uxx(k) = uxx(k) + u(k-(nx-1)*ny) / (dx*dx)
            !ux (k) = ux (k) + u(k-(nx-1)*ny) / (2*dx)
         endif
         if (j>1)  then
            uyy(k) = uyy(k) + u(k-1) / (dy*dy)
            uy (k) = uy (k) - u(k-1) / (2*dy)
         else
            !uyy(k) = uyy(k) + u(k+(ny-1)) / (dy*dy)
            !uy (k) = uy (k) - u(k+(ny-1)) / (2*dy)
         endif
         if (j<ny) then
            uyy(k) = uyy(k) + u(k+1) / (dy*dy)
            uy (k) = uy (k) + u(k+1) / (2*dy)
         else
            !uyy(k) = uyy(k) + u(k-(ny-1)) / (dy*dy)
            !uy (k) = uy (k) + u(k-(ny-1)) / (2*dy)
         endif
      enddo
   enddo
   v = -(uxx + uyy)/2 - B/2 * (ux*y - uy*x) + &
         abs(B*B)/8 * (x*x + y*y) * u + 0*pot * u + &
         (40 + 40*abs(u)**2 / norm2(abs(u))**2 / (dx*dy)) * u
end subroutine
