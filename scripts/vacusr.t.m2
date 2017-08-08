  !##############################################################################
  ! module vacusr - uniform spiral ! setvac -d=22 -g=204,204 -p=hdadiab -u=sim1
  
  
  INCLUDE:vacusr.gravity.t
  INCLUDE:vacusr.viscosity.t

  !=============================================================================
  SUBROUTINE specialini(ix^L,w)

    INCLUDE 'vacdef.f'

    INTEGER:: ix^L
    DOUBLE PRECISION:: w(ixG^T,1:nw)

    RETURN
  END SUBROUTINE specialini


  !=============================================================================
  SUBROUTINE specialsource(qdt,ixI^L,ixO^L,iws,qtC,wCT,qt,w)

    INCLUDE 'vacdef.f'

    INTEGER:: ixI^L,ixO^L,iws(niw_)
    DOUBLE PRECISION:: qdt,qtC,qt,wCT(ixG^T,nw),w(ixG^T,nw) !Intent(IN)

    INTEGER:: iw
    INTEGER:: ix_1,ix_2,ix_3

    DOUBLE PRECISION:: s_period, xc1, xc2, xc3, xxmax, yymax, zzmax
    DOUBLE PRECISION:: xc1Mm, xc2Mm, xc3Mm, r0
    DOUBLE PRECISION:: xx, yy, zz, rr
    DOUBLE PRECISION:: vvx(ixG^T), vvy(ixG^T), vvz(ixG^T)
    DOUBLE PRECISION:: AA, B, ux, uy, phi, theta, u_th, u_r, v_A, B_sq
    DOUBLE PRECISION:: delta_z, delta_x, delta_y, exp_x, exp_y, exp_z, exp_xyz, tdep

    INTEGER, PARAMETER :: l=2

!-----------------------------------------------------------------------------

    eqpar(eta_)=0.d0
    eqpar(nu_)=1.0d0
    
    CALL addsource_grav(qdt,ixI^L,ixO^L,iws,qtC,wCT,qt,w)
    
    IF(ABS(eqpar(nu_))>smalldouble)&
         CALL addsource_visc(qdt,ixI^L,ixO^L,iws,qtC,wCT,qt,w)

    vvx(ixG^T) = 0.d0
    vvy(ixG^T) = 0.d0
    vvz(ixG^T) = 0.d0

    xc1Mm=0.1   !Mm        z axis
    xc2Mm=0.0 !0.99d0  !Mm        x axis
    xc3Mm=0.0 !0.99d0  !Mm        y axis


    xc1=xc1Mm*1.0d6  !m        z axis
    xc2=xc2Mm*1.0d6  !m        x axis
    xc3=xc3Mm*1.0d6  !m        y axis

    xxmax=1.d6
    yymax=1.d6
    zzmax=1.6d6

    !### DELTA_Z ###   
 delta_z = 0.05d6
    !### DELTA_X ###
 delta_x = 0.5d6
    !### DELTA_Y ###
 delta_y = 0.5d6

    !### AMPLITUDE ###
  AA = 0.d0
    !### EXP_FAC ###
  B = 0.05
    !### PERIOD ###
  s_period = 330.0

    r0 = 0.1d6

    IF (qt .LT. s_period/2.0) THEN
      tdep=SIN(qt*2.d0*pi/s_period)
    ELSE
      tdep=0.d0
    END IF
    {^IFMPI IF (ipe.EQ.0)} PRINT*, "tdep==",tdep

    DO ix_1=ixImin1,ixImax1
       DO ix_2=ixImin2,ixImax2
          DO ix_3=ixImin3,ixImax3

             xx=x(ix_1,ix_2,ix_3,2)-xc2
             yy=x(ix_1,ix_2,ix_3,3)-xc3
             zz=x(ix_1,ix_2,ix_3,1)-xc1  

             rr = SQRT(xx**2 + yy**2) / r0
             theta = ATAN2(yy,xx)

             exp_z = EXP(-(zz**2.d0)/(delta_z**2.d0))

             u_th = AA * rr * (1 - rr**2) * EXP(-(rr**2)) * COS(l * theta) * tdep * exp_z
             u_r = AA * l * (rr / 2.0) * EXP(-(rr**2)) * SIN(l * theta) * tdep * exp_z

             ux = (u_r * COS(theta)) - (u_th * SIN(theta))
             uy = (u_r * SIN(theta)) + (u_th * COS(theta))
             
             vvx(ix_1,ix_2,ix_3) = ux
             vvy(ix_1,ix_2,ix_3) = uy

          ENDDO
       ENDDO
    ENDDO

    DO ix_1=ixImin1,ixImax1
       DO ix_2=ixImin2,ixImax2
          DO ix_3=ixImin3,ixImax3
             
            !w(ix_1,ix_2,ix_3,m1_)=w(ix_1,ix_2,ix_3,m1_)+(w(ix_1,ix_2,ix_3,rho_)+w(ix_1,ix_2,ix_3,rhob_))*vvz(ix_1,ix_2,ix_3)*qdt
             
             w(ix_1,ix_2,ix_3,m2_)=w(ix_1,ix_2,ix_3,m2_)+(w(ix_1,ix_2,ix_3,rho_)+w(ix_1,ix_2,ix_3,rhob_))*vvx(ix_1,ix_2,ix_3)*qdt
             
             w(ix_1,ix_2,ix_3,m3_)= w(ix_1,ix_2,ix_3,m3_)+(w(ix_1,ix_2,ix_3,rho_)+w(ix_1,ix_2,ix_3,rhob_))*vvy(ix_1,ix_2,ix_3)*qdt

             
             w(ix_1,ix_2,ix_3,e_)=w(ix_1,ix_2,ix_3,e_)+(w(ix_1,ix_2,ix_3,rho_)+w(ix_1,ix_2,ix_3,rhob_))*(vvx(ix_1,ix_2,ix_3)**2.d0 + vvy(ix_1,ix_2,ix_3)**2.d0 + vvz(ix_1,ix_2,ix_3)**2.d0)*qdt/2.d0


          ENDDO
       ENDDO
    ENDDO


    {^IFMPI IF (ipe.EQ.0)} WRITE(*,*) '***time=',qt

  END SUBROUTINE specialsource



!=============================================================================
SUBROUTINE specialbound(qt,ix^L,iw,iB,w)
  INCLUDE 'vacdef.f'

  INTEGER:: ix_1,ix_2

  INTEGER:: iw^LIM,idim^LIM
  DOUBLE PRECISION:: qt,w(ixG^T,1:nw)
  INTEGER:: ix,ix^D,ixe,ixf,ix^L,ixpair^L,idim,iw,iB

  CALL die('not defined')
  RETURN
END SUBROUTINE specialbound

!=============================================================================
SUBROUTINE getdt_special(w,ix^L)

  ! If the Coriolis force is made very strong it may require time step limiting,
  ! but this is not implemented here.

  INCLUDE 'vacdef.f'
  DOUBLE PRECISION:: w(ixG^T,nw)
  INTEGER:: ix^L
  !----------------------------------------------------------------------------

  !call getdt_diff(w,ix^L)

  IF(ABS(eqpar(nu_))>smalldouble)&
       CALL getdt_visc(w,ix^L)

  CALL getdt_grav(w,ix^L)

  RETURN
END SUBROUTINE getdt_special

!=============================================================================
SUBROUTINE specialeta(w,ix^L,idirmin)

  INCLUDE 'vacdef.f'

  DOUBLE PRECISION:: w(ixG^T,nw)
  INTEGER:: ix^L,idirmin
!------------------------------------------------------------------------------

  STOP 'specialeta is not defined'
END SUBROUTINE specialeta

!------------------------------------------------------------------------------
SUBROUTINE savefilelog_special(qunit,w,ix^L)
  
  ! This is a save log file routine to calculate and save out Vpar Vperp and Vaz
  ! It mimics savefileout_bin to mantain compatibility with usual readin routines
  
  INCLUDE 'vacdef.f'

  INTEGER:: qunit,ix^L
  DOUBLE PRECISION :: w(ixG^T,nw)

  CALL die("log save is not defined")

END SUBROUTINE savefilelog_special

