! This code solves eigenvalue problem for a harmonic oscillator
! using the Lanczos method and the ARPACK library
!
! 26-08-2024 / Sergey Yalunin

program main_ho
   use iso_c_binding
   use gl_module
   implicit none
   type(c_ptr)  :: window
   !
   integer, parameter :: nx = 150
   integer, parameter :: ny = nx + 1
   integer, parameter :: n = nx * ny
   integer, parameter :: m = 5
   integer, parameter :: mnx = m * nx
   integer, parameter :: mny = m * ny
   integer, parameter :: nev = m * m
   integer, parameter :: ncv = 2 * nev + 1
   real(8), parameter :: pi = 4 * atan(1.0d0)
   real(8), parameter :: rad = 3.8d0
   real(8), parameter :: dx = 2 * rad / (nx+1)
   real(8), parameter :: dy = dx
   real(8), parameter :: tol = 1.0d-12
   real(8),       allocatable, dimension(:)   :: x, y, r, pot, phase
   real(8),       allocatable, dimension(:)   :: workd, workl
   real(8),       allocatable, dimension(:)   :: eval, resid
   real(8),       allocatable, dimension(:,:) :: evec
   real(c_float), allocatable, dimension(:,:) :: color, brightness
   logical  :: select(ncv)
   integer  :: i, j, k, ii, jj, loc
   integer  :: ido, ierr, iparam(11), ipntr(14)
   !
   allocate( x(n), y(n), r(n), pot(n), eval(nev), evec(n,ncv) )
   allocate( resid(n), workd(3*n), workl(ncv*(ncv+8)) )
   allocate( color(mny,mnx), brightness(mny,mnx) )
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
      call dsaupd(ido, 'I', n, 'SM', nev, tol, resid, ncv, &
         evec, n, iparam, ipntr, workd, workl, size(workl), ierr)
      if (abs(ido)==1) then
         call matvec(nx, ny, dx, dy, pot, workd(ipntr(1)), workd(ipntr(2)))
      else
         exit
      endif
   enddo
   !
   call dseupd(.true., 'All', select, eval, evec, n, 0.0d0, &
      'I', n, 'SM', nev, tol, resid, ncv, evec, n, iparam, ipntr, &
      workd, workl, size(workl), ierr)
   do i = 1,nev
      print *, eval(i)
   enddo
   !
   window = gl_create_window(mnx, mny, "Harmonic oscillator")
   call gl_set_window_pos(window, 400, 0)
   call gl_set_colormap("colormap/hsv_matlab1024.txt")
   !
   do i = 1,m
      do j = 1,m
         k = j + (i-1) * m
         ii = (i-1) * ny
         jj = (j-1) * nx
         loc = maxloc(abs(evec(:,k)), dim=1)
         evec(:,k) = evec(:,k) / evec(loc,k)
         phase = atan2(0 * evec(:,k), evec(:,k))
         color(ii+1:ii+ny, jj+1:jj+nx) = &
            reshape(real((phase+pi)/(2*pi), kind=c_float), [ny,nx])
         brightness(ii+1:ii+ny, jj+1:jj+nx) = &
            reshape(real(abs(evec(:,k)), kind=c_float), [ny,nx])
      enddo
   enddo
   color = color(mny:1:-1,:)
   brightness = brightness(mny:1:-1,:)
   !
   do while (.not.gl_window_should_close(window))
      call gl_draw_image(window, mny, mnx, color, brightness)
      call gl_swap_buffers(window)
      call gl_poll_events()
      call sleep(1)
   enddo
   call gl_destroy_window(window)
   !
end program


subroutine matvec(nx, ny, dx, dy, pot, u, v)
   integer, intent(in)  :: nx, ny
   real(8), intent(in)  :: dx, dy
   real(8), intent(in)  :: pot(nx * ny)
   real(8), intent(in)  :: u(nx * ny)
   real(8), intent(out) :: v(nx * ny)
   integer :: i, j, k
   !
   v = 0.0d0
   do i = 1,nx
      do j = 1,ny
         k = j + (i-1) * ny
         v(k) = v(k) - 2 * u(k) / (dx * dx) - 2 * u(k) / (dy * dy)
         if (i>1)  then
            v(k) = v(k) + u(k-ny) / (dx * dx)
         else
            !v(k) = v(k) + u(k-ny+nx*ny) / (dx * dx)
         endif
         if (i<nx) then
            v(k) = v(k) + u(k+ny) / (dx * dx)
         else
            !v(k) = v(k) + u(k+ny-nx*ny) / (dx * dx)
         endif
         if (j>1)  then
            v(k) = v(k) + u(k-1) / (dy * dy)
         else
            !v(k) = v(k) + u(k-1+ny) / (dx * dx)
         endif
         if (j<ny) then
            v(k) = v(k) + u(k+1) / (dy * dy)
         else
            !v(k) = v(k) + u(k+1-ny) / (dy * dy)
         endif
      enddo
   enddo
   v = -v/2 + pot * u
end subroutine

