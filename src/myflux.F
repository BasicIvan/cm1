! Ivan Basic 2024-10-14 add spatially and temporally varying tracer fluxes
! Reads flux data from a pre-generated myflux.nc file.

MODULE myflux_module
    IMPLICIT NONE
    
    PUBLIC :: load_myflux, myflux, ptnt, ptnx, ptny, ptnpt, myflux_loaded

    REAL, ALLOCATABLE :: myflux(:,:,:,:)
    INTEGER :: ptnt, ptnx, ptny, ptnpt
    LOGICAL :: myflux_loaded = .false.
CONTAINS

    SUBROUTINE load_myflux(model_npt,model_nx,model_ny)

#ifdef NETCDF
      USE netcdf
#endif
#ifdef MPI
      use mpi
#endif
      IMPLICIT NONE

      INTEGER, INTENT(IN) :: model_npt,model_nx,model_ny
      LOGICAL :: fluxfile_exists
      INTEGER :: ncid,varid,dimid,status,myid,ierr

      ! Ivan Basic 2026-07-27 validate optional myflux input
      myflux_loaded = .false.
      fluxfile_exists = .false.
      myid = 0
      ierr = 0

#ifdef MPI
      CALL MPI_COMM_RANK(MPI_COMM_WORLD,myid,ierr)
      IF( ierr.ne.MPI_SUCCESS )THEN
        print *,'ERROR: could not determine MPI rank while loading myflux.nc.'
        call stopcm1
      ENDIF
#endif

#ifndef NETCDF
      IF( myid.eq.0 )THEN
        print *,'myflux.nc cannot be read without NetCDF support; ',  &
                'using constant passive-tracer surface fluxes.'
      ENDIF
      return
#else

      IF( myid.eq.0 ) inquire(file='myflux.nc',exist=fluxfile_exists)

#ifdef MPI
      call MPI_BCAST(fluxfile_exists,1,MPI_LOGICAL,0,MPI_COMM_WORLD,ierr)
      IF( ierr.ne.MPI_SUCCESS )THEN
        print *,'ERROR: could not broadcast myflux.nc file status.'
        call stopcm1
      ENDIF
#endif

      IF( .not.fluxfile_exists )THEN
        IF( myid.eq.0 )THEN
          print *,'myflux.nc not found; using constant passive-tracer ',  &
                  'surface fluxes.'
        ENDIF
        return
      ENDIF

      IF( myid.eq.0 )THEN
        print *,'reading passive tracer flux data from myflux.nc...'

        status = nf90_open('myflux.nc',mode=nf90_nowrite,ncid=ncid)
        call check_myflux_netcdf(status,'open myflux.nc')

        status = nf90_inq_dimid(ncid,'nt',dimid)
        call check_myflux_netcdf(status,'find dimension nt')
        status = nf90_inquire_dimension(ncid,dimid,len=ptnt)
        call check_myflux_netcdf(status,'read dimension nt')

        status = nf90_inq_dimid(ncid,'nx',dimid)
        call check_myflux_netcdf(status,'find dimension nx')
        status = nf90_inquire_dimension(ncid,dimid,len=ptnx)
        call check_myflux_netcdf(status,'read dimension nx')

        status = nf90_inq_dimid(ncid,'ny',dimid)
        call check_myflux_netcdf(status,'find dimension ny')
        status = nf90_inquire_dimension(ncid,dimid,len=ptny)
        call check_myflux_netcdf(status,'read dimension ny')

        status = nf90_inq_dimid(ncid,'npt',dimid)
        call check_myflux_netcdf(status,'find dimension npt')
        status = nf90_inquire_dimension(ncid,dimid,len=ptnpt)
        call check_myflux_netcdf(status,'read dimension npt')

        status = nf90_inq_varid(ncid,'flux',varid)
        call check_myflux_netcdf(status,'find variable flux')

        IF( ptnx.ne.model_nx .or. ptny.ne.model_ny )THEN
          print *,'ERROR: myflux.nc horizontal dimensions do not match CM1.'
          print *,'  file nx, ny  = ',ptnx,ptny
          print *,'  model nx, ny = ',model_nx,model_ny
          call stopcm1
        ENDIF

        IF( ptnt.lt.2 )THEN
          print *,'ERROR: myflux.nc must contain at least two time levels.'
          print *,'  file nt = ',ptnt
          call stopcm1
        ENDIF

        IF( model_npt.gt.ptnpt )THEN
          print *,'ERROR: CM1 requests more passive tracers than myflux.nc contains.'
          print *,'  model npt = ',model_npt
          print *,'  file npt  = ',ptnpt
          call stopcm1
        ENDIF

        IF( model_npt.lt.ptnpt )THEN
          print *,'myflux.nc contains ',ptnpt,' tracers; using the first ',  &
                  model_npt,'.'
        ENDIF
      ENDIF

#ifdef MPI
      call MPI_BCAST(ptnx,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
      IF( ierr.ne.MPI_SUCCESS ) call stopcm1
      call MPI_BCAST(ptny,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
      IF( ierr.ne.MPI_SUCCESS ) call stopcm1
      call MPI_BCAST(ptnt,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
      IF( ierr.ne.MPI_SUCCESS ) call stopcm1
      call MPI_BCAST(ptnpt,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
      IF( ierr.ne.MPI_SUCCESS ) call stopcm1
#endif

      allocate(myflux(ptnpt,ptnt,ptnx,ptny))

      IF( myid.eq.0 )THEN
        status = nf90_get_var(ncid,varid,myflux)
        call check_myflux_netcdf(status,'read variable flux')
        status = nf90_close(ncid)
        call check_myflux_netcdf(status,'close myflux.nc')
        print *,'finished reading myflux.nc'
      ENDIF

#ifdef MPI
      call MPI_BCAST(myflux,ptnpt*ptnt*ptnx*ptny,MPI_REAL,0,  &
                     MPI_COMM_WORLD,ierr)
      IF( ierr.ne.MPI_SUCCESS )THEN
        print *,'ERROR: could not broadcast myflux.nc data.'
        call stopcm1
      ENDIF
#endif

      myflux_loaded = .true.
#endif
    END SUBROUTINE load_myflux

#ifdef NETCDF
    SUBROUTINE check_myflux_netcdf(status,operation)
      USE netcdf
      IMPLICIT NONE

      INTEGER, INTENT(IN) :: status
      CHARACTER(LEN=*), INTENT(IN) :: operation

      IF( status.ne.nf90_noerr )THEN
        print *,'ERROR: failed to ',trim(operation),'.'
        print *,'  NetCDF: ',trim(nf90_strerror(status))
        call stopcm1
      ENDIF
    END SUBROUTINE check_myflux_netcdf
#endif

END MODULE myflux_module
