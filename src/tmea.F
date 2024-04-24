      MODULE tmea_module

!-----------------------------------------------------------------------------
!  Ivan Basic 16.03.23. added this to src folder
!  tmea_module, Jan Weinkaemmerer, 2019/20
!   
!  For on-the-fly time averaging between two outputs. See tmeafrq in namelist
!  to set the summation frequency.
!  The quantities defined in the setup_tmea subroutine appear automatically in
!  the output. The averaging itself is done in calc_tmea. Both subroutines are
!  called in CM1.F (main code).
!  Every quantity is interpolated to the scalar grid. Averaging along y axis
!  may be done offline or online as well (after collecting the data from every
!  processor). Check out writeout.F how it is done currently.
!
!-----------------------------------------------------------------------------

      implicit none

      private
      public :: setup_tmea, calc_tmea, calc_tke_sg

      CONTAINS

      subroutine setup_tmea(name_tmea,desc_tmea,unit_tmea)

        use input
        
        implicit none

        character(len=40), dimension(maxvars), intent(inout) :: name_tmea, unit_tmea
        character(len=60), dimension(maxvars), intent(inout) :: desc_tmea

        ntmea2d = 0

        ntmea2d = ntmea2d + 1
        name_tmea(ntmea2d) = 'hpbl_TM '
        desc_tmea(ntmea2d) = 'TM PBL height'
        unit_tmea(ntmea2d) = 'm'

        if (imoist.eq.1) then
          ntmea2d = ntmea2d + 1
          name_tmea(ntmea2d) = 'cape_TM '
          desc_tmea(ntmea2d) = 'TM convective available potential energy'
          unit_tmea(ntmea2d) = 'J/kg'

          ntmea2d = ntmea2d + 1
          name_tmea(ntmea2d) = 'cin_TM  '
          desc_tmea(ntmea2d) = 'TM convective inhibition'
          unit_tmea(ntmea2d) = 'J/kg'

          ntmea2d = ntmea2d + 1
          name_tmea(ntmea2d) = 'lcl_TM  '
          desc_tmea(ntmea2d) = 'TM lifted condensation level'
          unit_tmea(ntmea2d) = 'm'

          ntmea2d = ntmea2d + 1
          name_tmea(ntmea2d) = 'lfc_TM  '
          desc_tmea(ntmea2d) = 'TM level of free convection'
          unit_tmea(ntmea2d) = 'm'
        endif

        ntmea = 0

        ntmea = ntmea + 1
        name_tmea(ntmea+ntmea2d) = 'th_TM   '
        desc_tmea(ntmea+ntmea2d) = 'TM potential temperature plus background'
        unit_tmea(ntmea+ntmea2d) = 'K'

        ntmea = ntmea + 1
        name_tmea(ntmea+ntmea2d) = 'tha_TM  '
        desc_tmea(ntmea+ntmea2d) = 'TM potential temperature'
        unit_tmea(ntmea+ntmea2d) = 'K'

        ntmea = ntmea + 1
        name_tmea(ntmea+ntmea2d) = 'prs_TM  '
        desc_tmea(ntmea+ntmea2d) = 'TM pressure'
        unit_tmea(ntmea+ntmea2d) = 'Pa'
        
        ntmea = ntmea + 1
        name_tmea(ntmea+ntmea2d) = 'rho_TM  '
        desc_tmea(ntmea+ntmea2d) = 'TM dry-air density'
        unit_tmea(ntmea+ntmea2d) = 'kg/m^3'


        if (imoist.eq.1) then
          ntmea = ntmea + 1
          name_tmea(ntmea+ntmea2d) = 'qv_TM  '
          desc_tmea(ntmea+ntmea2d) = 'TM water vapor mixing ratio'
          unit_tmea(ntmea+ntmea2d) = 'kg/kg'
        endif

        ntmea = ntmea + 1
        name_tmea(ntmea+ntmea2d) = 'u_TM    '
        desc_tmea(ntmea+ntmea2d) = 'TM u interp'
        unit_tmea(ntmea+ntmea2d) = 'm/s'

        ntmea = ntmea + 1
        name_tmea(ntmea+ntmea2d) = 'v_TM    '
        desc_tmea(ntmea+ntmea2d) = 'TM v interp'
        unit_tmea(ntmea+ntmea2d) = 'm/s'

        ntmea = ntmea + 1
        name_tmea(ntmea+ntmea2d) = 'w_TM    '
        desc_tmea(ntmea+ntmea2d) = 'TM w interp'
        unit_tmea(ntmea+ntmea2d) = 'm/s'

        if (cm1setup.eq.1) then
          ntmea = ntmea + 1
          name_tmea(ntmea+ntmea2d) = 'tke_sg  '
          desc_tmea(ntmea+ntmea2d) = 'TM subgrid turbulence kinetic energy interp'
          unit_tmea(ntmea+ntmea2d) = 'm^2/s^2'
        endif
        
        if (iptra.eq.1) then

          ntmea = ntmea + 1
          name_tmea(ntmea+ntmea2d) = 'pt1_TM'
          desc_tmea(ntmea+ntmea2d) = 'passive tracer time-averaged (CO2)'
          unit_tmea(ntmea+ntmea2d) = 'kg/kg' ! Ivan Basic 04.08.2023.
          
          ntmea = ntmea + 1
          name_tmea(ntmea+ntmea2d) = 'pt2_TM'
          desc_tmea(ntmea+ntmea2d) = 'passive tracer time-averaged (CH4)'
          unit_tmea(ntmea+ntmea2d) = 'kg/kg' ! Ivan Basic 21.09.2023.
          
        endif

        ntmea = ntmea + 1
        name_tmea(ntmea+ntmea2d) = 'u_u     '
        desc_tmea(ntmea+ntmea2d) = 'for calculating covariances'
        unit_tmea(ntmea+ntmea2d) = 'm^2/s^2'

        ntmea = ntmea + 1
        name_tmea(ntmea+ntmea2d) = 'v_v     '
        desc_tmea(ntmea+ntmea2d) = 'for calculating covariances'
        unit_tmea(ntmea+ntmea2d) = 'm^2/s^2'

        ntmea = ntmea + 1
        name_tmea(ntmea+ntmea2d) = 'w_w     '
        desc_tmea(ntmea+ntmea2d) = 'for calculating covariances'
        unit_tmea(ntmea+ntmea2d) = 'm^2/s^2'

      end subroutine setup_tmea

      subroutine calc_tmea(ncalctm,mtime,dbldt,name_tmea,rf, &
                           mf,tmea,tke_sg,hpbl,th0,tha,prs,rho, &
                           qa,ua,va,wa,tkea,khh,khv,thflux,qvflux,t13,lenscl, &
                           sigma,sigmaf,rds,rdsf,gz,gzu,gzv,gxu,gyv,rgz,uf,vf, &
                           udiag,vdiag,wdiag,tdiag,qdiag,pi0,ppi, &
                           pta,rmh,zh)

        use input
        use getcape_module
        use domaindiag_module!, only: getavg3d, getmax
        
        implicit none

        integer, intent(in) :: ncalctm
        double precision, intent(in) :: mtime,dbldt
        !double precision, intent(inout) :: mtimelast
        character(len=40), dimension(maxvars), intent(in) :: name_tmea
        real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: rf,lenscl
        real, dimension(ib:ie,jb:je,kb:ke+1), intent(in) :: mf
        real, dimension(ib:ie,jb:je,kb:ke,ntmea), intent(inout) :: tmea
        real, dimension(ib:ie,jb:je,kb:ke+1,5), intent(in) :: tke_sg
        real, dimension(ibl:iel,jbl:jel), intent(in) :: hpbl
        real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: th0,tha,prs,rho,t13
        !real, dimension(ib:ie,jb:je,kb:ke), intent(inout) :: thlast        
        real, dimension(ibm:iem,jbm:jem,kbm:kem,numq), intent(in) :: qa
        real, dimension(ib:ie+1,jb:je,kb:ke), intent(in) :: ua
        real, dimension(ib:ie,jb:je+1,kb:ke), intent(in) :: va
        real, dimension(ib:ie,jb:je,kb:ke+1), intent(in) :: wa
        real, dimension(ibt:iet,jbt:jet,kbt:ket), intent(in) :: tkea
        real, dimension(ibc:iec,jbc:jec,kbc:kec), intent(in) :: khh,khv
        real, dimension(ib:ie,jb:je), intent(in) :: thflux,qvflux
        real, dimension(kb:ke), intent(in) :: sigma,rds
        real, dimension(kb:ke+1), intent(in) :: sigmaf,rdsf
        real, dimension(itb:ite,jtb:jte), intent(in) :: gz,gzu,gzv,rgz
        real, dimension(itb:ite,jtb:jte,ktb:kte), intent(in) :: gxu,gyv
        real, dimension(ib:ie+1), intent(in) :: uf
        real, dimension(jb:je+1), intent(in) :: vf
        real, intent(in), dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nudiag) :: udiag
        real, intent(in), dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nvdiag) :: vdiag
        real, intent(in), dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nwdiag) :: wdiag
        real, intent(in), dimension(ibdt:iedt,jbdt:jedt,kbdt:kedt,ntdiag) :: tdiag
        real, intent(in), dimension(ibdq:iedq,jbdq:jedq,kbdq:kedq,nqdiag) :: qdiag
        
        integer :: n,i,j,k,k2,imyi,i2
        real :: tmp1,tmp2,tmp3,tmp4,r1,r2
        real, dimension(ib:ie,jb:je,kb:ke) :: th,thw,thten,dthdx,dthdy,dthdz,dthdzs,sgs,dpdz,dqvdz

        real, dimension(:), allocatable :: pfoo,tfoo,qfoo
        real :: zel , psource , tsource , qvsource
        real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: pi0,ppi
        real, dimension(ib:ie,jb:je,kb:ke) :: dum1,dum2

        real, dimension(ibp:iep,jbp:jep,kbp:kep,npt), intent(in) :: pta
        real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: rmh
        real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: zh
        double precision, dimension(nk+1) :: savg
        real :: stdev_min,csm,z_b,z_t,zmin
        integer :: n_ymea,n_stdymea,n_dry,n_cs,n_alphay,n_wu,n_we,n_thu,n_the,n_qvu,n_qve

        real, dimension(jb:je,kb:ke) :: dumyz
		!print *,'  Done with declarations.'
        csm = 1.0

        do j=0,nj+1
          do k=1,nk
          do i=0,ni+1
            th(i,j,k)=th0(i,j,k)+tha(i,j,k)
          enddo
          enddo

          do i=0,ni+1
            thw(i,j,1) = cgs1*th(i,j,1)+cgs2*th(i,j,2)+cgs3*th(i,j,3)
          enddo

          do i=0,ni+1
            thw(i,j,nk+1) = cgt1*th(i,j,nk)+cgt2*th(i,j,nk-1)+cgt3*th(i,j,nk-2)
          enddo

          do k=2,nk
          r2 = (sigmaf(k)-sigma(k-1))*rds(k)
          r1 = 1.0-r2
          do i=0,ni+1
            thw(i,j,k) = r1*th(i,j,k-1)+r2*th(i,j,k)
          enddo
          enddo
        enddo
        !print *,'  Done with th'

        ! do k=1,nk
        ! do j=1,nj
        ! do i=1,ni
        !   thten(i,j,k) = (th(i,j,k) - thlast(i,j,k))/(mtime + dbldt - mtimelast) 
        !   thlast(i,j,k) = th(i,j,k)
        ! enddo
        ! enddo
        ! enddo
        ! mtimelast = mtime + dbldt

        if (terrain_flag) then

          do k=1,nk
          do j=1,nj
          do i=1,ni+1
            dthdx(i,j,k) = gzu(i,j)*(th(i,j,k)*rgz(i,j)-th(i-1,j,k)*rgz(i-1,j))*rdx*uf(i)  &
                    +0.5*( gxu(i,j,k+1)*(thw(i,j,k+1)+thw(i-1,j,k+1))                      &
                          -gxu(i,j,k  )*(thw(i,j,k  )+thw(i-1,j,k  )) )*rdsf(k)
          enddo
          enddo
          enddo
			!print *,'  done with dthdx'
          do k=1,nk
          do j=1,nj+1
          do i=1,ni
            dthdy(i,j,k) = gzv(i,j)*(th(i,j,k)*rgz(i,j)-th(i,j-1,k)*rgz(i,j-1))*rdy*vf(i)  &
                    +0.5*( gyv(i,j,k+1)*(thw(i,j,k+1)+thw(i,j-1,k+1))                      &
                          -gyv(i,j,k  )*(thw(i,j,k  )+thw(i,j-1,k  )) )*rdsf(k)
          enddo
          enddo
          enddo
			!print *,'  done with dthdy'
          do k=1,nk
          do j=1,nj
          do i=1,ni
            dthdzs(i,j,k) = gz(i,j)*(thw(i,j,k+1) - thw(i,j,k))*rdsf(k)
          enddo
          enddo
          enddo
			!print *,'  done with dthdzs'
        else

          dthdx = 0.0
          dthdy = 0.0
          dthdzs = 0.0

        endif

        do k=2,nk
        do j=1,nj
        do i=1,ni
          dthdz(i,j,k) = (th(i,j,k) - th(i,j,k-1))*rdz*mf(i,j,k)
        enddo
        enddo
        enddo
        !print *,'  done with dthdz'

        ! do i=1,ni
        ! do j=1,nj
        ! dpdz(i,j,1) = (prs(i,j,2) - prs(i,j,1))*rdz*mf(i,j,1)
        ! do k=2,nk-1
        !   dpdz(i,j,k) = (prs(i,j,k+1) - prs(i,j,k-1)) * 1.0/(1.0/(rdz*mf(i,j,k+1)) + 1.0/(rdz*mf(i,j,k)))
        ! enddo
        ! dpdz(i,j,nk) = (prs(i,j,nk) - prs(i,j,nk-1))*rdz*mf(i,j,nk)
        ! enddo
        ! enddo

        do k=2,nk
        do j=1,nj
        do i=1,ni
          dqvdz(i,j,k) = (qa(i,j,k,nqv) - qa(i,j,k-1,nqv))*rdz*mf(i,j,k)
        enddo
        enddo
        enddo
        !print *,'  done with dqvdz'
        
		!print *,'THE BIG LOOP BEGINS'
        DO n = 1, ntmea+ntmea2d
		  !print *,'  n = ',n
          if (trim(name_tmea(n)).eq.'hpbl_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j)
            do j=1,nj
            do i=1,ni
              tmea(i,j,1,n) = tmea(i,j,1,n) + ( hpbl(i,j) - tmea(i,j,1,n) )/dble(ncalctm)
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'cape_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k,pfoo,tfoo,qfoo,zel,psource,tsource,qvsource)
            DO j=1,nj
            DO i=1,ni
              allocate( pfoo(nk+1) )
              allocate( tfoo(nk+1) )
              allocate( qfoo(nk+1) )
  
              do k=1,nk
                pfoo(k+1) = 0.01*prs(i,j,k)
                tfoo(k+1) = (th0(i,j,k)+tha(i,j,k))*(pi0(i,j,k)+ppi(i,j,k)) - 273.15
                qfoo(k+1) = qa(i,j,k,nqv)
              enddo
  
              pfoo(1) = cgs1*pfoo(2)+cgs2*pfoo(3)+cgs3*pfoo(4)
              tfoo(1) = cgs1*tfoo(2)+cgs2*tfoo(3)+cgs3*tfoo(4)
              qfoo(1) = cgs1*qfoo(2)+cgs2*qfoo(3)+cgs3*qfoo(4)
  
              call getcape( 3 , nk+1 , pfoo , tfoo , qfoo , dum1(i,j,1) , dum1(i,j,2) ,   &
                            dum2(i,j,1), dum2(i,j,2), zel , psource , tsource , qvsource )
  
              deallocate( pfoo )
              deallocate( tfoo )
              deallocate( qfoo )
            ENDDO
            ENDDO

            !$omp parallel do default(shared)  &
            !$omp private(i,j)
            do j=1,nj
            do i=1,ni
              tmea(i,j,1,n) = tmea(i,j,1,n) + ( dum1(i,j,1) - tmea(i,j,1,n) )/dble(ncalctm)
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'cin_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j)
            do j=1,nj
            do i=1,ni
              tmea(i,j,1,n) = tmea(i,j,1,n) + ( dum1(i,j,2) - tmea(i,j,1,n) )/dble(ncalctm)
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'lcl_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j)
            do j=1,nj
            do i=1,ni
              tmea(i,j,1,n) = tmea(i,j,1,n) + ( dum2(i,j,1) - tmea(i,j,1,n) )/dble(ncalctm)
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'lfc_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j)
            do j=1,nj
            do i=1,ni
              tmea(i,j,1,n) = tmea(i,j,1,n) + ( dum2(i,j,2) - tmea(i,j,1,n) )/dble(ncalctm)
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'th_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( th0(i,j,k)+tha(i,j,k) - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'tha_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tha(i,j,k) - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo
            

          ! elseif (trim(name_tmea(n)).eq.'thten_TM') then
          !   !$omp parallel do default(shared)  &
          !   !$omp private(i,j,k)
          !   do k=1,maxk
          !   do j=1,nj
          !   do i=1,ni
          !     tmea(i,j,k,n) = tmea(i,j,k,n) + ( thten(i,j,k) - tmea(i,j,k,n) )/dble(ncalctm)
          !   enddo
          !   enddo
          !   enddo

          ! elseif (trim(name_tmea(n)).eq.'dthdx_TM') then
          !   !$omp parallel do default(shared)  &
          !   !$omp private(i,j,k)
          !   do k=1,maxk
          !   do j=1,nj
          !   do i=1,ni
          !     tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*(dthdx(i,j,k)+dthdx(i+1,j,k)) - tmea(i,j,k,n) )/dble(ncalctm)
          !   enddo
          !   enddo
          !   enddo

          ! elseif (trim(name_tmea(n)).eq.'dthdy_TM') then
          !   !$omp parallel do default(shared)  &
          !   !$omp private(i,j,k)
          !   do k=1,maxk
          !   do j=1,nj
          !   do i=1,ni
          !     tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*(dthdy(i,j,k)+dthdy(i,j+1,k)) - tmea(i,j,k,n) )/dble(ncalctm)
          !   enddo
          !   enddo
          !   enddo

          ! elseif (trim(name_tmea(n)).eq.'dthdz_TM') then
          !   !$omp parallel do default(shared)  &
          !   !$omp private(i,j,k)
          !   do k=1,maxk
          !   do j=1,nj
          !   do i=1,ni
          !     tmea(i,j,k,n) = tmea(i,j,k,n) + ( dthdzs(i,j,k) - tmea(i,j,k,n) )/dble(ncalctm)
          !   enddo
          !   enddo
          !   enddo

          elseif (trim(name_tmea(n)).eq.'prs_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( prs(i,j,k) - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          ! elseif (trim(name_tmea(n)).eq.'dpdz_TM') then
          !   !$omp parallel do default(shared)  &
          !   !$omp private(i,j,k)
          !   do k=1,maxk
          !   do j=1,nj
          !   do i=1,ni
          !     tmea(i,j,k,n) = tmea(i,j,k,n) + ( dpdz(i,j,k) - tmea(i,j,k,n) )/dble(ncalctm)
          !   enddo
          !   enddo
          !   enddo

          elseif (trim(name_tmea(n)).eq.'rho_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( rho(i,j,k) - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'qv_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( qa(i,j,k,nqv) - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'qc_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( qa(i,j,k,nqc) - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'qr_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( qa(i,j,k,nqr) - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'u_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*(ua(i,j,k)+ua(i+1,j,k)) - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'v_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*(va(i,j,k)+va(i,j+1,k)) - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*(wa(i,j,k)+wa(i,j,k+1)) - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'tke_sg') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*(tkea(i,j,k)+tkea(i,j,k+1)) - tmea(i,j,k,n) )/dble(ncalctm) ! subgrid
            enddo
            enddo
            enddo
            
          elseif (trim(name_tmea(n)).eq.'pt1_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*(pta(i,j,k,1)+pta(i,j,k+1,1)) - tmea(i,j,k,n) )/dble(ncalctm) ! Ivan Basic 04.08.2023.
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'pt2_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*(pta(i,j,k,2)+pta(i,j,k+1,2)) - tmea(i,j,k,n) )/dble(ncalctm) ! Ivan Basic 04.08.2023., 21.09.2023.
            enddo
            enddo
            enddo

          ! === for calculating covariances === !
          ! elseif (trim(name_tmea(n)).eq.'u_dthdx') then
          !   !$omp parallel do default(shared)  &
          !   !$omp private(i,j,k)
          !   do k=1,maxk
          !   do j=1,nj
          !   do i=1,ni
          !     tmp1 = ua(i,j,k)*dthdx(i,j,k)
          !     tmp2 = ua(i+1,j,k)*dthdx(i+1,j,k)
          !     tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*(tmp1+tmp2) - tmea(i,j,k,n) )/dble(ncalctm)
          !   enddo
          !   enddo
          !   enddo

          ! elseif (trim(name_tmea(n)).eq.'v_dthdy') then
          !   !$omp parallel do default(shared)  &
          !   !$omp private(i,j,k)
          !   do k=1,maxk
          !   do j=1,nj
          !   do i=1,ni
          !     tmp1 = va(i,j,k)*dthdy(i,j,k)
          !     tmp2 = va(i,j+1,k)*dthdy(i,j+1,k)
          !     tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*(tmp1+tmp2) - tmea(i,j,k,n) )/dble(ncalctm)
          !   enddo
          !   enddo
          !   enddo

          ! elseif (trim(name_tmea(n)).eq.'w_dthdz') then
          !   !$omp parallel do default(shared)  &
          !   !$omp private(i,j,k)
          !   do k=1,maxk
          !   do j=1,nj
          !   do i=1,ni
          !     tmp1 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
          !     tmp2 = dthdzs(i,j,k)
          !     tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
          !   enddo
          !   enddo
          !   enddo

          elseif (trim(name_tmea(n)).eq.'th_th') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = tha(i,j,k)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1**2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'th_th_SG') then
	          sgs = 0.0
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=2,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = (th0(i,j,k)+tha(i,j,k)) - (th0(i,j,k-1)+tha(i,j,k-1))
              if ( tkea(i,j,k).ge.1.0e-6 ) then
                sgs(i,j,k) = 2.0*lenscl(i,j,k)*khv(i,j,k)     &
                                *( (tmp1*rdz*mf(i,j,k))**2 )  &
                                /(2.02*sqrt(max(1.0e-6,tkea(i,j,k)))) ! from domaindiag.F
              endif
            enddo
            enddo
            enddo
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(sgs(i,j,k) + sgs(i,j,k+1))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'u_u') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(ua(i,j,k)+ua(i+1,j,k))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1**2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'v_v') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(va(i,j,k)+va(i,j+1,k))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1**2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_w') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1**2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'u_w') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(ua(i,j,k)+ua(i+1,j,k))
              tmp2 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'u_w_SG') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = -t13(i,j,k)/(0.5*(rf(i,j,k)+rf(i-1,j,k)))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'v_w') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(va(i,j,k)+va(i,j+1,k))
              tmp2 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'u_th') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(ua(i,j,k)+ua(i+1,j,k))
              tmp2 = tha(i,j,k)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'u_th_SG') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni+1
              tmp1 = 0.25*(khh(i,j,k)+khh(i,j,k+1)+khh(i-1,j,k)+khh(i-1,j,k+1))
              sgs(i,j,k) = -tmp1*dthdx(i,j,k)
            enddo
            enddo
            enddo
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(sgs(i,j,k)+sgs(i+1,j,k))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'v_th_SG') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj+1
            do i=1,ni
              tmp1 = 0.25*(khh(i,j,k)+khh(i,j,k+1)+khh(i,j-1,k)+khh(i,j-1,k+1))
              sgs(i,j,k) = -tmp1*dthdy(i,j,k)
            enddo
            enddo
            enddo
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(sgs(i,j,k)+sgs(i,j+1,k))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_th') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
              tmp2 = tha(i,j,k)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_th_SG') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do i=1,ni
            do j=1,nj
            sgs(i,j,1) = thflux(i,j)
            do k=2,maxk
              sgs(i,j,k) = -khv(i,j,k)*dthdz(i,j,k)
            enddo
            enddo
            enddo
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(sgs(i,j,k) + sgs(i,j,k+1))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'u_u_w') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(ua(i,j,k)+ua(i+1,j,k))
              tmp2 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1*tmp1*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'v_v_w') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(va(i,j,k)+va(i,j+1,k))
              tmp2 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1*tmp1*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_w_w') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1**3 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          ! elseif (trim(name_tmea(n)).eq.'w_p') then
          !   !$omp parallel do default(shared)  &
          !   !$omp private(i,j,k)
          !   do k=1,maxk
          !   do j=1,nj
          !   do i=1,ni
          !     tmp1 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
          !     tmp2 = prs(i,j,k)
          !     tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
          !   enddo
          !   enddo
          !   enddo

          elseif (trim(name_tmea(n)).eq.'w_w_th') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
              tmp2 = tha(i,j,k)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1*tmp1*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          ! elseif (trim(name_tmea(n)).eq.'th_dpdz') then
          !   !$omp parallel do default(shared)  &
          !   !$omp private(i,j,k)
          !   do k=1,maxk
          !   do j=1,nj
          !   do i=1,ni
          !     tmp1 = tha(i,j,k)
          !     tmp2 = dpdz(i,j,k)
          !     tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
          !   enddo
          !   enddo
          !   enddo

          elseif (trim(name_tmea(n)).eq.'qv_qv') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = qa(i,j,k,nqv)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1**2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_qv') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
              tmp2 = qa(i,j,k,nqv)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_qv_SG') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do i=1,ni
            do j=1,nj
            sgs(i,j,1) = qvflux(i,j)
            do k=2,maxk
              sgs(i,j,k) = -khv(i,j,k)*dqvdz(i,j,k)
            enddo
            enddo
            enddo
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(sgs(i,j,k) + sgs(i,j,k+1))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_w_qv') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
              tmp2 = qa(i,j,k,nqv)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1*tmp1*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          ! === resolved TKE budget === !

          elseif (trim(name_tmea(n)).eq.'tke_buoy_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp3 = 0.25*(wa(i,j,k)+wa(i,j,k+1))*(wdiag(i,j,k,wd_buoy)+wdiag(i,j,k+1,wd_buoy))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp3 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'tke_prs_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.25*(ua(i,j,k)+ua(i+1,j,k))*(udiag(i,j,k,ud_pgrad)+udiag(i+1,j,k,ud_pgrad))
              tmp2 = 0.25*(va(i,j,k)+va(i,j+1,k))*(vdiag(i,j,k,vd_pgrad)+vdiag(i,j+1,k,vd_pgrad))
              tmp3 = 0.25*(wa(i,j,k)+wa(i,j,k+1))*(wdiag(i,j,k,wd_pgrad)+wdiag(i,j,k+1,wd_pgrad))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1+tmp2+tmp3 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'tke_adv_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.25*(ua(i,j,k)+ua(i+1,j,k)) &
                     *(udiag(i,j,k,ud_hadv)+udiag(i,j,k,ud_vadv)+udiag(i+1,j,k,ud_hadv)+udiag(i+1,j,k,ud_vadv))
              tmp2 = 0.25*(va(i,j,k)+va(i,j+1,k)) &
                     *(vdiag(i,j,k,vd_hadv)+vdiag(i,j,k,vd_vadv)+vdiag(i,j+1,k,vd_hadv)+vdiag(i,j+1,k,vd_vadv))
              tmp3 = 0.25*(wa(i,j,k)+wa(i,j,k+1)) &
                     *(wdiag(i,j,k,wd_hadv)+wdiag(i,j,k,wd_vadv)+wdiag(i,j,k+1,wd_hadv)+wdiag(i,j,k+1,wd_vadv))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1+tmp2+tmp3 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'tke_turb_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.25*(ua(i,j,k)+ua(i+1,j,k)) &
                     *(udiag(i,j,k,ud_hturb)+udiag(i,j,k,ud_vturb)+udiag(i+1,j,k,ud_hturb)+udiag(i+1,j,k,ud_vturb))
              tmp2 = 0.25*(va(i,j,k)+va(i,j+1,k)) &
                     *(vdiag(i,j,k,vd_hturb)+vdiag(i,j,k,vd_vturb)+vdiag(i,j+1,k,vd_hturb)+vdiag(i,j+1,k,vd_vturb))
              tmp3 = 0.25*(wa(i,j,k)+wa(i,j,k+1)) &
                     *(wdiag(i,j,k,wd_hturb)+wdiag(i,j,k,wd_vturb)+wdiag(i,j,k+1,wd_hturb)+wdiag(i,j,k+1,wd_vturb))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1+tmp2+tmp3 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'tke_diff_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.25*(ua(i,j,k)+ua(i+1,j,k)) &
                     *(udiag(i,j,k,ud_hidiff)+udiag(i,j,k,ud_vidiff)+udiag(i+1,j,k,ud_hidiff)+udiag(i+1,j,k,ud_vidiff))
              tmp2 = 0.25*(va(i,j,k)+va(i,j+1,k)) &
                     *(vdiag(i,j,k,vd_hidiff)+vdiag(i,j,k,vd_vidiff)+vdiag(i,j+1,k,vd_hidiff)+vdiag(i,j+1,k,vd_vidiff))
              tmp3 = 0.25*(wa(i,j,k)+wa(i,j,k+1)) &
                     *(wdiag(i,j,k,wd_hidiff)+wdiag(i,j,k,wd_vidiff)+wdiag(i,j,k+1,wd_hidiff)+wdiag(i,j,k+1,wd_vidiff))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1+tmp2+tmp3 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          ! === resolved TKE budget === !
          ! = ensemble means = !

          elseif (trim(name_tmea(n)).eq.'w_buoy') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp3 = wdiag(i,j,k,wd_buoy) + wdiag(i,j,k+1,wd_buoy)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*tmp3 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'u_prs') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = udiag(i,j,k,ud_pgrad) + udiag(i+1,j,k,ud_pgrad)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'v_prs') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp2 = vdiag(i,j,k,vd_pgrad) + vdiag(i,j+1,k,vd_pgrad)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_prs') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp3 = wdiag(i,j,k,wd_pgrad) + wdiag(i,j,k+1,wd_pgrad)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*tmp3 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'u_adv') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = (udiag(i,j,k,ud_hadv)+udiag(i,j,k,ud_vadv)) &
                   + (udiag(i+1,j,k,ud_hadv)+udiag(i+1,j,k,ud_vadv))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'v_adv') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp2 = (vdiag(i,j,k,vd_hadv)+vdiag(i,j,k,vd_vadv)) &
                   + (vdiag(i,j+1,k,vd_hadv)+vdiag(i,j+1,k,vd_vadv))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_adv') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp3 = (wdiag(i,j,k,wd_hadv)+wdiag(i,j,k,wd_vadv)) &
                   + (wdiag(i,j,k+1,wd_hadv)+wdiag(i,j,k+1,wd_vadv))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*tmp3 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'u_turb') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = (udiag(i,j,k,ud_hturb)+udiag(i,j,k,ud_vturb)) &
                   + (udiag(i+1,j,k,ud_hturb)+udiag(i+1,j,k,ud_vturb))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'v_turb') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp2 = (vdiag(i,j,k,vd_hturb)+vdiag(i,j,k,vd_vturb)) &
                   + (vdiag(i,j+1,k,vd_hturb)+vdiag(i,j+1,k,vd_vturb))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_turb') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp3 = (wdiag(i,j,k,wd_hturb)+wdiag(i,j,k,wd_vturb)) &
                   + (wdiag(i,j,k+1,wd_hturb)+wdiag(i,j,k+1,wd_vturb))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*tmp3 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'u_diff') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = (udiag(i,j,k,ud_hidiff)+udiag(i,j,k,ud_vidiff)) &
                   + (udiag(i+1,j,k,ud_hidiff)+udiag(i+1,j,k,ud_vidiff))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'v_diff') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp2 = (vdiag(i,j,k,vd_hidiff)+vdiag(i,j,k,vd_vidiff)) &
                   + (vdiag(i,j+1,k,vd_hidiff)+vdiag(i,j+1,k,vd_vidiff))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_diff') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp3 = (wdiag(i,j,k,wd_hidiff)+wdiag(i,j,k,wd_vidiff)) &
                   + (wdiag(i,j,k+1,wd_hidiff)+wdiag(i,j,k+1,wd_vidiff))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( 0.5*tmp3 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          ! === subgrid TKE budget === !

          elseif (trim(name_tmea(n)).eq.'tke_shear_sg') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(tke_sg(i,j,k,1)+tke_sg(i,j,k+1,1))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'tke_buoy_sg') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(tke_sg(i,j,k,2)+tke_sg(i,j,k+1,2))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo
          
          elseif (trim(name_tmea(n)).eq.'tke_diss_sg') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(tke_sg(i,j,k,3)+tke_sg(i,j,k+1,3))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'tke_adv_sg') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(tke_sg(i,j,k,4)+tke_sg(i,j,k+1,4))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'tke_diff_sg') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*(tke_sg(i,j,k,5)+tke_sg(i,j,k+1,5))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          ! === resolved wth budget === !

          elseif (trim(name_tmea(n)).eq.'wth_buoy_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*tha(i,j,k)*(wdiag(i,j,k,wd_buoy)+wdiag(i,j,k+1,wd_buoy))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wth_prs_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*tha(i,j,k)*(wdiag(i,j,k,wd_pgrad)+wdiag(i,j,k+1,wd_pgrad))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wth_adv_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*tha(i,j,k) &
                     *(wdiag(i,j,k,wd_hadv)+wdiag(i,j,k,wd_vadv)+wdiag(i,j,k+1,wd_hadv)+wdiag(i,j,k+1,wd_vadv))
              tmp2 = 0.5*(wa(i,j,k)+wa(i,j,k+1)) &
                     *(tdiag(i,j,k,td_hadv)+tdiag(i,j,k,td_vadv))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1+tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wth_turb_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*tha(i,j,k) &
                     *(wdiag(i,j,k,wd_hturb)+wdiag(i,j,k,wd_vturb)+wdiag(i,j,k+1,wd_hturb)+wdiag(i,j,k+1,wd_vturb))
              tmp2 = 0.5*(wa(i,j,k)+wa(i,j,k+1)) &
                     *(tdiag(i,j,k,td_hturb)+tdiag(i,j,k,td_vturb))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1+tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wth_diff_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*tha(i,j,k) &
                     *(wdiag(i,j,k,wd_hidiff)+wdiag(i,j,k,wd_vidiff)+wdiag(i,j,k+1,wd_hidiff)+wdiag(i,j,k+1,wd_vidiff))
              tmp2 = 0.5*(wa(i,j,k)+wa(i,j,k+1)) &
                     *(tdiag(i,j,k,td_hidiff)+tdiag(i,j,k,td_vidiff))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1+tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wth_mp_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp2 = 0.5*(wa(i,j,k)+wa(i,j,k+1))*tdiag(i,j,k,td_mp)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wth_div_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp2 = 0.5*(wa(i,j,k)+wa(i,j,k+1))*tdiag(i,j,k,td_div)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          ! === resolved wth budget === !
          ! = ensemble means = !

          elseif (trim(name_tmea(n)).eq.'th_adv') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = tdiag(i,j,k,td_hadv)+tdiag(i,j,k,td_vadv)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'th_turb') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = tdiag(i,j,k,td_hturb)+tdiag(i,j,k,td_vturb)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'th_diff') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = tdiag(i,j,k,td_hidiff)+tdiag(i,j,k,td_vidiff)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'th_mp') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = tdiag(i,j,k,td_mp)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'th_div') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = tdiag(i,j,k,td_div)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'th_rad') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = tdiag(i,j,k,td_rad)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'th_pbl') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = tdiag(i,j,k,td_pbl)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          ! === resolved wqv budget === !

          elseif (trim(name_tmea(n)).eq.'wqv_buoy_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*qa(i,j,k,nqv)*(wdiag(i,j,k,wd_buoy)+wdiag(i,j,k+1,wd_buoy))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wqv_prs_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*qa(i,j,k,nqv)*(wdiag(i,j,k,wd_pgrad)+wdiag(i,j,k+1,wd_pgrad))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wqv_adv_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*qa(i,j,k,nqv) &
                     *(wdiag(i,j,k,wd_hadv)+wdiag(i,j,k,wd_vadv)+wdiag(i,j,k+1,wd_hadv)+wdiag(i,j,k+1,wd_vadv))
              tmp2 = 0.5*(wa(i,j,k)+wa(i,j,k+1)) &
                     *(qdiag(i,j,k,qd_hadv)+qdiag(i,j,k,qd_vadv))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1+tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wqv_turb_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*qa(i,j,k,nqv) &
                     *(wdiag(i,j,k,wd_hturb)+wdiag(i,j,k,wd_vturb)+wdiag(i,j,k+1,wd_hturb)+wdiag(i,j,k+1,wd_vturb))
              tmp2 = 0.5*(wa(i,j,k)+wa(i,j,k+1)) &
                     *(qdiag(i,j,k,qd_hturb)+qdiag(i,j,k,qd_vturb))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1+tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wqv_diff_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = 0.5*qa(i,j,k,nqv) &
                     *(wdiag(i,j,k,wd_hidiff)+wdiag(i,j,k,wd_vidiff)+wdiag(i,j,k+1,wd_hidiff)+wdiag(i,j,k+1,wd_vidiff))
              tmp2 = 0.5*(wa(i,j,k)+wa(i,j,k+1)) &
                     *(qdiag(i,j,k,qd_hidiff)+qdiag(i,j,k,qd_vidiff))
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1+tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wqv_mp_res') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp2 = 0.5*(wa(i,j,k)+wa(i,j,k+1))*qdiag(i,j,k,qd_mp)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp2 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          ! === resolved wqv budget === !
          ! = ensemble means = !

          elseif (trim(name_tmea(n)).eq.'qv_adv') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = qdiag(i,j,k,qd_hadv)+qdiag(i,j,k,qd_vadv)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'qv_turb') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = qdiag(i,j,k,qd_hturb)+qdiag(i,j,k,qd_vturb)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'qv_diff') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = qdiag(i,j,k,qd_hidiff)+qdiag(i,j,k,qd_vidiff)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'qv_mp') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = qdiag(i,j,k,qd_mp)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'qv_pbl') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = qdiag(i,j,k,qd_pbl)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          ! === qc budget === !

          elseif (trim(name_tmea(n)).eq.'qc_adv') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = qdiag(i,j,k,qcd_hadv)+qdiag(i,j,k,qcd_vadv)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'qc_turb') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = qdiag(i,j,k,qcd_hturb)+qdiag(i,j,k,qcd_vturb)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'qc_diff') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = qdiag(i,j,k,qcd_hidiff)+qdiag(i,j,k,qcd_vidiff)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'qc_mp') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = qdiag(i,j,k,qcd_mp)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'qc_pbl') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = qdiag(i,j,k,qcd_pbl)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          ! === conditional sampling === !

          elseif (trim(name_tmea(n)).eq.'pt1_tm_ym') then
            n_ymea = n
            do imyi=1,nodex
              do i=1,ni
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = pta(i,j,k,1)
                  enddo
                  enddo
                else
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = 0.0
                  enddo
                  enddo
                endif
                call getavgy(dumyz,savg)
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    tmea(i,j,k,n) = savg(k)
                  enddo
                  enddo
                endif
              enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'std_tm_ym') then
            n_stdymea = n
            do imyi=1,nodex
              do i=1,ni
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = ( pta(i,j,k,1) - tmea(i,j,k,n_ymea) )**2
                  enddo
                  enddo
                else
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = 0.0
                  enddo
                  enddo
                endif
                call getavgy(dumyz,savg)
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    tmea(i,j,k,n) = sqrt( savg(k) )
                  enddo
                  enddo
                endif
              enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'cs_dry') then
            n_dry = n
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              stdev_min = 0.0
              do k2=1,k
                stdev_min = stdev_min + tmea(i,j,k2,n_stdymea)*dz*rmh(i,j,k2)
              enddo
              stdev_min = 0.05*stdev_min/zh(i,j,k)
              if ( pta(i,j,k,1)-tmea(i,j,k,n_ymea) .gt. csm*max(tmea(i,j,k,n_stdymea), stdev_min) &
                   .and. 0.5*(wa(i,j,k)+wa(i,j,k+1)) .gt. 0.0 ) then
                tmea(i,j,k,n) = 1.0
              else
                tmea(i,j,k,n) = 0.0
              endif
            enddo 
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'cs') then
            n_cs = n
            do i=1,ni
            do j=1,nj
              z_b = zh(i,j,maxk)
              z_t = zh(i,j,maxk)
              do k=1,maxk-1
                if ( z_b.eq.zh(i,j,maxk) .and. qa(i,j,k,nqc).gt.0.0001 ) then
                  z_b = zh(i,j,k)
                  z_t = z_b
                elseif ( qa(i,j,k,nqc).gt.0.0001 .and. qa(i,j,k+1,nqc).le.0.0001 ) then
                  z_t = zh(i,j,k)
                endif
              enddo
              if ( qa(i,j,maxk,nqc).gt.0.0001 ) then !Ivan Basic 28.03.23.
                z_t = zh(i,j,maxk)
                zmin = z_b + (z_t-z_b)/4.0
              endif

              do k=1,nk
                if ( zh(i,j,k).ge.zmin ) then
                  if ( tmea(i,j,k,n_dry).eq.1.0 .and. qa(i,j,k,nqc).gt.0.0001 ) then
                    tmea(i,j,k,n) = 1.0
                  else
                    tmea(i,j,k,n) = 0.0
                  endif
                else
                  tmea(i,j,k,n) = tmea(i,j,k,n_dry)
                endif
              enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'alpha_y') then
            n_alphay = n
            do imyi=1,nodex
              do i=1,ni
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = tmea(i,j,k,n_cs)
                  enddo
                  enddo
                else
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = 0.0
                  enddo
                  enddo
                endif
                call getavgy(dumyz,savg)
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    tmea(i,j,k,n) = savg(k)
                  enddo
                  enddo
                endif
              enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'alpha_y_TM') then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              tmp1 = tmea(i,j,k,n_alphay)
              tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
            enddo
            enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_u') then
            n_wu = n
            do imyi=1,nodex
              do i=1,ni
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = tmea(i,j,k,n_cs)*0.5*(wa(i,j,k)+wa(i,j,k+1))
                  enddo
                  enddo
                else
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = 0.0
                  enddo
                  enddo
                endif
                call getavgy(dumyz,savg)
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    if ( tmea(i,j,k,n_alphay).ne.0.0 ) then
                      tmp1 = savg(k)/tmea(i,j,k,n_alphay)
                    else
                      tmp1 = 0.0
                    endif
                    tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
                  enddo
                  enddo
                endif
              enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'w_e') then
            n_we = n
            do imyi=1,nodex
              do i=1,ni
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = (1.-tmea(i,j,k,n_cs))*0.5*(wa(i,j,k)+wa(i,j,k+1))
                  enddo
                  enddo
                else
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = 0.0
                  enddo
                  enddo
                endif
                call getavgy(dumyz,savg)
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    if ( tmea(i,j,k,n_alphay).ne.1.0 ) then
                      tmp1 = savg(k)/(1.-tmea(i,j,k,n_alphay))
                    else
                      tmp1 = 0.0
                    endif
                    tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
                  enddo
                  enddo
                endif
              enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'th_u') then
            n_thu = n
            do imyi=1,nodex
              do i=1,ni
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = tmea(i,j,k,n_cs)*tha(i,j,k)
                  enddo
                  enddo
                else
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = 0.0
                  enddo
                  enddo
                endif
                call getavgy(dumyz,savg)
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    if ( tmea(i,j,k,n_alphay).ne.0.0 ) then
                      tmp1 = savg(k)/tmea(i,j,k,n_alphay)
                    else
                      tmp1 = 0.0
                    endif
                    tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
                  enddo
                  enddo
                endif
              enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'th_e') then
            n_the = n
            do imyi=1,nodex
              do i=1,ni
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = (1.-tmea(i,j,k,n_cs))*tha(i,j,k)
                  enddo
                  enddo
                else
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = 0.0
                  enddo
                  enddo
                endif
                call getavgy(dumyz,savg)
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    if ( tmea(i,j,k,n_alphay).ne.1.0 ) then
                      tmp1 = savg(k)/(1.-tmea(i,j,k,n_alphay))
                    else
                      tmp1 = 0.0
                    endif
                    tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
                  enddo
                  enddo
                endif
              enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'qv_u') then
            n_qvu = n
            do imyi=1,nodex
              do i=1,ni
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = tmea(i,j,k,n_cs)*qa(i,j,k,nqv)
                  enddo
                  enddo
                else
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = 0.0
                  enddo
                  enddo
                endif
                call getavgy(dumyz,savg)
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    if ( tmea(i,j,k,n_alphay).ne.0.0 ) then
                      tmp1 = savg(k)/tmea(i,j,k,n_alphay)
                    else
                      tmp1 = 0.0
                    endif
                    tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
                  enddo
                  enddo
                endif
              enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'qv_e') then
            n_qve = n
            do imyi=1,nodex
              do i=1,ni
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = (1.-tmea(i,j,k,n_cs))*qa(i,j,k,nqv)
                  enddo
                  enddo
                else
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = 0.0
                  enddo
                  enddo
                endif
                call getavgy(dumyz,savg)
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    if ( tmea(i,j,k,n_alphay).ne.1.0 ) then
                      tmp1 = savg(k)/(1.-tmea(i,j,k,n_alphay))
                    else
                      tmp1 = 0.0
                    endif
                    tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
                  enddo
                  enddo
                endif
              enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wth_u') then
            do imyi=1,nodex
              do i=1,ni
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    tmp1 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
                    tmp2 = tha(i,j,k)
                    dumyz(j,k) = tmea(i,j,k,n_cs)*tmp1*tmp2
                  enddo
                  enddo
                else
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = 0.0
                  enddo
                  enddo
                endif
                call getavgy(dumyz,savg)
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    if ( tmea(i,j,k,n_alphay).ne.0.0 ) then
                      tmp1 = savg(k)/tmea(i,j,k,n_alphay)
                    else
                      tmp1 = 0.0
                    endif
                    tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
                  enddo
                  enddo
                endif
              enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wth_e') then
            do imyi=1,nodex
              do i=1,ni
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    tmp1 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
                    tmp2 = tha(i,j,k)
                    dumyz(j,k) = (1.-tmea(i,j,k,n_cs))*tmp1*tmp2
                  enddo
                  enddo
                else
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = 0.0
                  enddo
                  enddo
                endif
                call getavgy(dumyz,savg)
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    if ( tmea(i,j,k,n_alphay).ne.1.0 ) then
                      tmp1 = savg(k)/(1.-tmea(i,j,k,n_alphay))
                    else
                      tmp1 = 0.0
                    endif
                    tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
                  enddo
                  enddo
                endif
              enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wqv_u') then
            do imyi=1,nodex
              do i=1,ni
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    tmp1 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
                    tmp2 = qa(i,j,k,nqv)
                    dumyz(j,k) = tmea(i,j,k,n_cs)*tmp1*tmp2
                  enddo
                  enddo
                else
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = 0.0
                  enddo
                  enddo
                endif
                call getavgy(dumyz,savg)
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    if ( tmea(i,j,k,n_alphay).ne.0.0 ) then
                      tmp1 = savg(k)/tmea(i,j,k,n_alphay)
                    else
                      tmp1 = 0.0
                    endif
                    tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
                  enddo
                  enddo
                endif
              enddo
            enddo

          elseif (trim(name_tmea(n)).eq.'wqv_e') then
            do imyi=1,nodex
              do i=1,ni
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    tmp1 = 0.5*(wa(i,j,k)+wa(i,j,k+1))
                    tmp2 = qa(i,j,k,nqv)
                    dumyz(j,k) = (1.-tmea(i,j,k,n_cs))*tmp1*tmp2
                  enddo
                  enddo
                else
                  do k=1,nk
                  do j=1,nj
                    dumyz(j,k) = 0.0
                  enddo
                  enddo
                endif
                call getavgy(dumyz,savg)
                if (imyi.eq.myi) then
                  do k=1,nk
                  do j=1,nj
                    if ( tmea(i,j,k,n_alphay).ne.1.0 ) then
                      tmp1 = savg(k)/(1.-tmea(i,j,k,n_alphay))
                    else
                      tmp1 = 0.0
                    endif
                    tmea(i,j,k,n) = tmea(i,j,k,n) + ( tmp1 - tmea(i,j,k,n) )/dble(ncalctm)
                  enddo
                  enddo
                endif
              enddo
            enddo

          else
            if(myid.eq.0) print *
            if(myid.eq.0) print *,'  unrecognized tmea variable '
            if(myid.eq.0) print *,'  n,name_tmea = ',n,trim(name_tmea(n))
            !if(myid.eq.0) print *
            !if(myid.eq.0) print *,'      87542 '
            call stopcm1

          endif
		!print *,'THE BIG LOOP ENDS'
        ENDDO

      end subroutine calc_tmea

      subroutine calc_tke_sg(tke_sg,ust,znt,kmv,defv,defh,thflux,rth0s,qvflux,khv,nm,dissten,kdiag)

        use input
        use constants
        
        implicit none

        real, intent(in), dimension(ib:ie,jb:je) :: znt,ust,thflux,qvflux
        real, intent(in), dimension(ibc:iec,jbc:jec,kbc:kec) :: kmv,khv
        real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: nm,defv,defh,dissten
        real, intent(in), dimension(ib:ie,jb:je) :: rth0s
        real, intent(in), dimension(ibdk:iedk,jbdk:jedk,kbdk:kedk,nkdiag) :: kdiag
        real, dimension(ib:ie,jb:je,kb:ke+1,5), intent(inout) :: tke_sg

        integer :: i,j,k

        if (sgsmodel.eq.1) then

          ! shear (#1):
          do j=1,nj
          do i=1,ni
            tke_sg(i,j,1,1) = ust(i,j)*ust(i,j)*ust(i,j)/(karman*znt(i,j))
          enddo
          enddo

          do k=2,nk
          do j=1,nj
          do i=1,ni
            tke_sg(i,j,k,1) = kmv(i,j,k)*max(0.0,(defv(i,j,k)+defh(i,j,k)))
          enddo
          enddo
          enddo

          ! buoyancy (#2):
          do j=1,nj
          do i=1,ni
            tke_sg(i,j,1,2) = g*( thflux(i,j)*rth0s(i,j) + repsm1*qvflux(i,j) )
          enddo
          enddo

          do k=2,nk
          do j=1,nj
          do i=1,ni
            tke_sg(i,j,k,2) = -khv(i,j,k)*nm(i,j,k)
          enddo
          enddo
          enddo

          ! dissipation (#3):
          do j=1,nj
          do i=1,ni
  !!!            dum1(i,j,1) = -ust(i,j)*ust(i,j)*ust(i,j)/(karman*znt(i,j))  &
  !!!                          -g*( thflux(i,j)*rth0s(i,j) + repsm1*qvflux(i,j) )
            tke_sg(i,j,1,3) = 0.0
            tke_sg(i,j,nk+1,3) = 0.0
          enddo
          enddo

          do k=2,nk
          do j=1,nj
          do i=1,ni
            tke_sg(i,j,k,3) = -dissten(i,j,k)
          enddo
          enddo
          enddo

          ! advection (#4):
          do k=1,nk
          do j=1,nj
          do i=1,ni
            tke_sg(i,j,k,4) = kdiag(i,j,k,kd_adv)
          enddo
          enddo
          enddo

          ! diffusion (#5):
          do k=1,nk
          do j=1,nj
          do i=1,ni
            tke_sg(i,j,k,5) = kdiag(i,j,k,kd_turb)
          enddo
          enddo
          enddo

        endif
		!print *,'  calc_tke routine done. '
      end subroutine calc_tke_sg

      subroutine getavgy(s,savg,nkm)

        use input
#ifdef MPI
        use mpi
#endif
        implicit none
    
        real, intent(in), dimension(jb:je,kb:ke) :: s
        double precision, dimension(nk+1) :: savg
        integer, intent(in), optional :: nkm
    
        integer :: j,k,k2
        double precision :: temd
    
        savg = 0.0
    
        k2 = nk
    
        IF( present(nkm) )THEN
          k2 = min(nkm,nk+1)
        ENDIF
    
        do k=1,k2
        do j=1,nj
          savg(k) = savg(k)+s(j,k)
        enddo
        enddo
    
#ifdef MPI
        call MPI_ALLREDUCE(MPI_IN_PLACE,savg(1),k2,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
#endif
    
        temd = 1.0d0/dble(ny)
        do k=1,k2
          savg(k) = savg(k)*temd
        enddo
       
      end subroutine getavgy

      END MODULE tmea_module

