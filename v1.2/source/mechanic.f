c
c     Sorbonne University
c     Washington University in Saint Louis
c     University of Texas at Austin
c
c     ###############################################################
c     ##                                                           ##
c     ##  subroutine mechanic  --  initialize molecular mechanics  ##
c     ##                                                           ##
c     ###############################################################
c
c
c     "mechanic" sets up needed parameters for the potential energy
c     calculation and reads in many of the user selectable options
c
c
      subroutine mechanic
      use domdec
      use inform
      use iounit
      use potent
      use vdwpot
      use mpi
      implicit none
c
c     set the bonded connectivity lists and active atoms
c
      call kewald
      call attach
      call active
c
c     find bonds, angles, torsions, bitorsions and small rings
c
      call bonds(.true.)
      call angles(.true.)
      call torsions(.true.)
      call bitors(.true.)
c     call rings(.true.)
      call rings
c
c     get the base force field from parameter file and keyfile
c
      call field
c
c      call polymer
c
c     assign atom types, classes and other atomic information
c
      call katom
c
c     assign atoms to molecules and set the atom groups
c
      call molecule(.true.)
      call cluster
c
c     find any pisystem atoms, bonds and torsional angles
c
c      call orbital
c
c     assign bond, angle and cross term potential parameters
c
      if (use_bond .or. use_strbnd .or. use_strtor
     $    .or. (use_vdw .and. vdwtyp.eq.'MM3-HBOND'))
     $    call kbond
      if (use_angle .or. use_strbnd .or. use_angang) call kangle
      if (use_strbnd)  call kstrbnd(.true.)
      if (use_urey)  call kurey(.true.)
      if (use_angang)  call kangang(.true.)
c
c     assign out-of-plane deformation potential parameters
c
      if (use_angle .or. use_opbend)  call kopbend(.true.)
      if (use_angle .or. use_opdist)  call kopdist(.true.)
      if (use_improp)  call kimprop(.true.)
      if (use_imptor)  call kimptor(.true.)
c
c     assign torsion and torsion cross term potential parameters
c
      if (use_tors .or. use_strtor .or. use_tortor)  call ktors
      if (use_pitors)  call kpitors(.true.)
      if (use_strtor)  call kstrtor(.true.)
      if (use_angtor)  call kangtor(.true.)
      if (use_tortor)  call ktortor(.true.)
c
c     assign van der Waals and electrostatic potential parameters
c
      if (use_charge) call kcharge(.true.,0)
      if (use_vdw)  call kvdw(.true.,0)
      if (use_mpole .or. use_polar .or.
     &    use_solv)  call kmpole(.true.,0)
      if (use_polar .or. use_mpole)  call kpolar(.true.,0)
c
      call initmpipme
c
c     assign restraint parameters
c
      if (use_geom)  call kgeom(.true.)
c
c     set hybrid parameter values for free energy perturbation
c
      call mutate
c
c     set holonomic constrains
c
      call shakeup(.true.)
c
c     SMD parametrization
c
      call ksmd(.true.)
c
c     quit if essential parameter information is missing
c
      if (abort) then
         if (rank.eq.0) write (iout,10)
   10    format (/,' MECHANIC  --  Some Required Potential Energy',
     &              ' Parameters are Undefined')
         call fatal
      end if
      return
      end
c
c     subroutine mechanicstep : fill the array parameters between two time steps
c
      subroutine mechanicstep(istep)
      use potent
      implicit none
      integer istep
c
c      call molecule(.false.)

      call bonds(.false.)
      call angles(.false.)
      call torsions(.false.)
      call bitors(.false.)

      if (use_charge) call kcharge(.false.,istep)
      if (use_mpole) call kmpole(.false.,istep)
      if (use_polar) call kpolar(.false.,istep)
      if (use_vdw) call kvdw(.false.,istep)
      if (use_strbnd) call kstrbnd(.false.)
      if (use_urey) call kurey(.false.)
      if (use_angang) call kangang(.false.)
      if (use_angle .or. use_opbend)  call kopbend(.false.)
      if (use_angle .or. use_opdist)  call kopdist(.false.)
      if (use_improp)  call kimprop(.false.)
      if (use_imptor)  call kimptor(.false.)
      if (use_pitors)  call kpitors(.false.)
      if (use_strtor)  call kstrtor(.false.)
      if (use_angtor)  call kangtor(.false.)
      if (use_tortor)  call ktortor(.false.)
      if (use_geom)  call kgeom(.false.)
      if (use_smd_velconst .or. use_smd_forconst) call ksmd(.false.)


      call initmpipme

c     set holonomic constrains
c
      call shakeup(.false.)

      return
      end
c
c     subroutine mechanicsteprespa: fill the array parameters between two time steps
c
      subroutine mechanicsteprespa(istep,fast)
      use potent
      implicit none
      integer istep
      logical fast
c
c      call molecule(.false.)
      if (fast) then
        call bonds(.false.)
        call angles(.false.)
        call torsions(.false.)
        call bitors(.false.)
        if (use_strbnd) call kstrbnd(.false.)
        if (use_urey) call kurey(.false.)
        if (use_angang) call kangang(.false.)
        if (use_angle .or. use_opbend)  call kopbend(.false.)
        if (use_angle .or. use_opdist)  call kopdist(.false.)
        if (use_improp)  call kimprop(.false.)
        if (use_imptor)  call kimptor(.false.)
        if (use_pitors)  call kpitors(.false.)
        if (use_strtor)  call kstrtor(.false.)
        if (use_angtor)  call kangtor(.false.)
        if (use_tortor)  call ktortor(.false.)
        if (use_geom)  call kgeom(.false.)
        if (use_smd_velconst .or. use_smd_forconst) call ksmd(.false.)
      else
        if (use_charge) call kcharge(.false.,istep)
        if (use_mpole) call kmpole(.false.,istep)
        if (use_polar) call kpolar(.false.,istep)
        if (use_vdw) call kvdw(.false.,istep)
        if (istep.ne.-1) call initmpipme
c
c     set holonomic constrains
c
      call shakeup(.false.)
      end if
      return
      end
c
c     subroutine mechanicsteprespa1: fill the array parameters between two time steps
c
      subroutine mechanicsteprespa1(istep,rule)
      use domdec
      use iounit
      use potent
      implicit none
      integer istep,rule
 1000 format(' illegal rule in mechanicsteprespa1.')
c
c     rule = 0: fast part of the forces
c     rule = 1: intermediate part of the forces
c     rule = 2: slow part of the forces
c
c      call molecule(.false.)
      if (rule.eq.0) then
        call bonds(.false.)
        call angles(.false.)
        call torsions(.false.)
        call bitors(.false.)
        if (use_strbnd) call kstrbnd(.false.)
        if (use_urey) call kurey(.false.)
        if (use_angang) call kangang(.false.)
        if (use_angle .or. use_opbend)  call kopbend(.false.)
        if (use_angle .or. use_opdist)  call kopdist(.false.)
        if (use_improp)  call kimprop(.false.)
        if (use_imptor)  call kimptor(.false.)
        if (use_pitors)  call kpitors(.false.)
        if (use_strtor)  call kstrtor(.false.)
        if (use_angtor)  call kangtor(.false.)
        if (use_tortor)  call ktortor(.false.)
        if (use_geom)  call kgeom(.false.)
        if (use_smd_velconst .or. use_smd_forconst) call ksmd(.false.)
      else if (rule.eq.1) then
        if (use_charge) call kcharge(.false.,istep)
        if (use_mpole) call kmpole(.false.,istep)
        if (use_polar) call kpolar(.false.,istep)
        if (use_vdw) call kvdw(.false.,istep)
      else if (rule.eq.2) then
        if (use_charge) call kcharge(.false.,istep)
        if (use_mpole) call kmpole(.false.,istep)
        if (use_polar) call kpolar(.false.,istep)
        if (use_vdw) call kvdw(.false.,istep)
        if (istep.ne.-1) call initmpipme
        call initmpipme
c        call updategrid
c
c     set holonomic constrains
c
        call shakeup(.false.)
      else
         if (rank.eq.0) write(iout,1000) 
      end if
      return
      end
