! This code solves the eigenvalue problem for a harmonic oscillator
! using the Lanczos method, the ARPACK and MKL libraries.
!
! Author: Sergey Yalunin
! Date: 2024-08-26

program main_harm
   use iso_c_binding
   use MKL_DFTI
   use gl_module
   implicit none
   type(c_ptr)  :: window
   !
   integer, parameter :: nx = 160
   integer, parameter :: ny = nx + 1
   integer, parameter :: n = nx * ny
   integer, parameter :: m = 4
   integer, parameter :: mnx = m * nx
   integer, parameter :: mny = m * ny
   integer, parameter :: nev = m * m
   integer, parameter :: ncv = 2 * nev + 10
   real(8), parameter :: pi = 4 * atan(1.0d0)
   real(8), parameter :: rad = 3.8d0
   real(8), parameter :: dx = 2 * rad / nx
   real(8), parameter :: dy = dx
   real(8), parameter :: dkx = 2 * pi / (nx * dx)
   real(8), parameter :: dky = 2 * pi / (ny * dy)
   real(8), parameter :: tol = 1.0d-8
   complex(8),    allocatable, dimension(:)   :: uk
   real(8),       allocatable, dimension(:)   :: x, y, kx, ky, r, pot, u, phase
   real(8),       allocatable, dimension(:)   :: workd, workl
   real(8),       allocatable, dimension(:)   :: eval, resid
   real(8),       allocatable, dimension(:,:) :: evec
   real(c_float), allocatable, dimension(:,:) :: color, brightness
   type(DFTI_DESCRIPTOR), pointer :: hand  => null()
   real(c_float), parameter :: pos(4) = [-1.0,-1.0, 1.0, 1.0]
   !
   logical  :: select(ncv)
   integer  :: i, j, k, ii, jj, loc, status
   integer  :: ido, info, iparam(11), ipntr(14)
   !
   allocate( x(n), y(n), r(n), u(n), pot(n) )
   allocate( kx(n), ky(n), uk(n) )
   allocate( eval(nev), evec(n,ncv), resid(n) )
   allocate( workd(3*n), workl(ncv*(ncv+8)) )
   allocate( brightness(mny,mnx) )
   allocate( color(mny,mnx) )
   !
   status = DftiCreateDescriptor(hand, DFTI_DOUBLE , DFTI_REAL, 2, [ny,nx])
   status = DftiSetValue(hand, DFTI_PLACEMENT, DFTI_NOT_INPLACE)
   status = DftiSetValue(hand, DFTI_CONJUGATE_EVEN_STORAGE, DFTI_COMPLEX_COMPLEX)
   status = DftiSetValue(hand, DFTI_FORWARD_SCALE, 1.0d0);
   status = DftiSetValue(hand, DFTI_BACKWARD_SCALE, 1.0d0/(nx*ny));
   status = DftiCommitDescriptor(hand)
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
   r = sqrt(x*x + y*y)
   pot = merge(r*r/2, 10*rad*rad/2, r < (rad-2*dx))
   !
   ido = 0
   info = 0
   iparam(1) = 1
   iparam(3) = 300
   iparam(7) = 1
   !
   do
      call dsaupd(ido, 'I', n, 'SM', nev, tol, resid, ncv, &
         evec, n, iparam, ipntr, workd, workl, size(workl), info)
      if (abs(ido)==1) then
         u = workd(ipntr(1):ipntr(1) + n-1)
         status = DftiComputeForward(hand, u, uk)
         uk = (kx*kx + ky*ky)/2 * uk
         status = DftiComputeBackward(hand, uk, u)
         workd(ipntr(2):ipntr(2) + n-1) = u + &
            pot * workd(ipntr(1):ipntr(1) + n-1)
      else
         exit
      endif
   enddo
   !
   call dseupd(.true., 'All', select, eval, evec, n, 0.0d0, &
      'I', n, 'SM', nev, tol, resid, ncv, evec, n, iparam, ipntr, &
      workd, workl, size(workl), info)
   do i = 1,nev
      write( *,"(3X,A,I2,A,F10.7)" ) "E(",i,") =", eval(i)
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
         phase = (atan2(0*evec(:,k), evec(:,k))+pi)/(2*pi)
         color(ii+1:ii+ny, jj+1:jj+nx) = reshape(real(phase, kind=c_float), [ny,nx])
         brightness(ii+1:ii+ny, jj+1:jj+nx) = &
            reshape(real(abs(evec(:,k)), kind=c_float), [ny,nx])
      enddo
   enddo
   color = color(mny:1:-1,:)
   brightness = brightness(mny:1:-1,:)
   !
   do while (.not.gl_window_should_close(window))
      call gl_draw_image(pos, shape(color), color, brightness)
      call gl_swap_buffers(window)
      call gl_poll_events()
      call sleep(1)
   enddo
   call gl_destroy_window(window)
   !
end program
