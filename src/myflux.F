! Ivan Basic 14.10.2024.: the code below is
! an implementation of time- and spatially varying surface tracer flux.
! It reads from a file myflux.nc, that needs to be created beforehand
! NetCDF file: /home/b/b381871/python.git/<some name of the file>.nc

MODULE myflux_module
    IMPLICIT NONE
    
    PUBLIC :: load_myflux, myflux, ptnt, ptnx, ptny, ptnpt, myflux_loaded   ! Make myflux accessible

    REAL, ALLOCATABLE :: myflux(:,:,:,:) ! Global myflux array
    INTEGER :: ptnt, ptnx, ptny, ptnpt          ! dimensions
    LOGICAL :: myflux_loaded = .false.
CONTAINS

    SUBROUTINE load_myflux()

#ifdef NETCDF
        USE netcdf
#endif
    
#ifdef MPI
      use mpi
#endif
        IMPLICIT NONE
        LOGICAL :: fluxfile_exists
        INTEGER :: ncid, varid, dimid, status
#ifdef MPI
        INTEGER :: myid, ierr  ! Declare these variables locally
        CALL MPI_COMM_RANK(MPI_COMM_WORLD, myid, ierr)
#endif
        inquire(file='myflux.nc', exist=fluxfile_exists)
        if (.not. fluxfile_exists) then
                if (myid == 0) then
                        write(*,*) 'myflux.nc file not provided.'
                endif
        !allocate(myflux(npt_in,nt_in,ny_in,nx_in))
        !myflux(:,:,:,:) = 0.0
        return
        endif
		IF(myid.eq.0) THEN
        ! Only processor 0 reads file:
        
          print *, 'reading passive tracer flux data from myflux.nc...'
          status = nf90_open('myflux.nc', mode=nf90_nowrite , ncid=ncid)

          
          status = nf90_inq_dimid(ncid, 'nt', dimid)
          status = nf90_inquire_dimension(ncid, dimid, len=ptnt)
          
          status = nf90_inq_dimid(ncid, 'nx', dimid)
          status = nf90_inquire_dimension(ncid, dimid, len=ptnx)
          
          status = nf90_inq_dimid(ncid, 'ny', dimid)
          status = nf90_inquire_dimension(ncid, dimid, len=ptny)
          
          status = nf90_inq_dimid(ncid, 'npt', dimid)
          status = nf90_inquire_dimension(ncid, dimid, len=ptnpt)
          
          print *, 'nx: ', ptnx
          print *, 'ny: ', ptny
          print *, 'nt: ', ptnt
          print *, 'npt: ', ptnpt
          
            
		ENDIF ! myid
		
#ifdef MPI
		! Broadcast the dimensions
          call MPI_BCAST(ptnx, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
          call MPI_BCAST(ptny, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
          call MPI_BCAST(ptnt, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
          call MPI_BCAST(ptnpt,1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
          
#endif
          ! Allocate myflux array to store ptflux data for the entire domain
          allocate(myflux(ptnpt,ptnt,ptnx,ptny))

		IF(myid.eq.0) THEN
          ! Retrieve variable ID and read the flux data
          status = nf90_inq_varid(ncid,'flux', varid)
          status = nf90_get_var(ncid, varid, myflux)
          if (status /= nf90_noerr) then
            !print *, 'error nf90_get_var'
            print *, 'error in nf90_get_var: ', trim(nf90_strerror(status))
            print *, 'status: ', status
            call stopcm1
          endif

          ! Close the NetCDF file
          status = nf90_close(ncid)
          print *, 'finished reading'
          !print *, 'min, max:', minval(myflux), maxval(myflux)
          print *, "Sizes of myflux: ", size(myflux, 1), size(myflux, 2), size(myflux, 3), size(myflux, 4)
    	ENDIF ! myid

#ifdef MPI
          ! Now broadcast the myflux array to all processes
          call MPI_BCAST(myflux, ptnpt*ptnt*ptnx*ptny, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
          if (ierr /= 0) then
              print *, 'Error in MPI_BCAST myflux: ', ierr
              call stopcm1
          endif
#endif
          myflux_loaded = .true.
    END SUBROUTINE load_myflux

END MODULE myflux_module
