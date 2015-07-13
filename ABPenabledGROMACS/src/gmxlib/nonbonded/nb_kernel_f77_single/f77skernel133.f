C
C                This source code is part of
C
C                 G   R   O   M   A   C   S
C
C Copyright (c) 1991-2000, University of Groningen, The Netherlands.
C Copyright (c) 2001-2009, The GROMACS Development Team
C
C Gromacs is a library for molecular simulation and trajectory analysis,
C written by Erik Lindahl, David van der Spoel, Berk Hess, and others - for
C a full list of developers and information, check out http://www.gromacs.org
C
C This program is free software; you can redistribute it and/or modify it under 
C the terms of the GNU Lesser General Public License as published by the Free 
C Software Foundation; either version 2 of the License, or (at your option) any 
C later version.
C As a special exception, you may use this file as part of a free software
C library without restriction.  Specifically, if other files instantiate
C templates or use macros or inline functions from this file, or you compile
C this file and link it with other files to produce an executable, this
C file does not by itself cause the resulting executable to be covered by
C the GNU Lesser General Public License.  
C
C In plain-speak: do not worry about classes/macros/templates either - only
C changes to the library have to be LGPL, not an application linking with it.
C
C To help fund GROMACS development, we humbly ask that you cite
C the papers people have written on it - you can find them on the website!
C

C
C Gromacs nonbonded kernel f77skernel133
C Coulomb interaction:     Normal Coulomb
C VdW interaction:         Tabulated
C water optimization:      TIP4P - other atoms
C Calculate forces:        yes
C
      subroutine f77skernel133(
     &                          nri,
     &                          iinr,
     &                          jindex,
     &                          jjnr,
     &                          shift,
     &                          shiftvec,
     &                          fshift,
     &                          gid,
     &                          pos,
     &                          faction,
     &                          charge,
     &                          facel,
     &                          krf,
     &                          crf,
     &                          Vc,
     &                          type,
     &                          ntype,
     &                          vdwparam,
     &                          Vvdw,
     &                          tabscale,
     &                          VFtab,
     &                          invsqrta,
     &                          dvda,
     &                          gbtabscale,
     &                          GBtab,
     &                          nthreads,
     &                          count,
     &                          mtx,
     &                          outeriter,
     &                          inneriter,
     &                          work)
      implicit      none
      integer*4     nri,iinr(*),jindex(*),jjnr(*),shift(*)
      real*4        shiftvec(*),fshift(*),pos(*),faction(*)
      integer*4     gid(*),type(*),ntype
      real*4        charge(*),facel,krf,crf,Vc(*),vdwparam(*)
      real*4        Vvdw(*),tabscale,VFtab(*)
      real*4        invsqrta(*),dvda(*),gbtabscale,GBtab(*)
      integer*4     nthreads,count,mtx,outeriter,inneriter
      real*4        work(*)

      integer*4     n,ii,is3,ii3,k,nj0,nj1,jnr,j3,ggid
      integer*4     nn0,nn1,nouter,ninner
      real*4        shX,shY,shZ
      real*4        fscal,tx,ty,tz
      real*4        rinvsq
      real*4        jq
      real*4        qq,vcoul,vctot
      integer*4     nti
      integer*4     tj
      real*4        Vvdw6,Vvdwtot
      real*4        Vvdw12
      real*4        r,rt,eps,eps2
      integer*4     n0,nnn
      real*4        Y,F,Geps,Heps2,Fp,VV
      real*4        FF
      real*4        fijD,fijR
      real*4        ix1,iy1,iz1,fix1,fiy1,fiz1
      real*4        ix2,iy2,iz2,fix2,fiy2,fiz2
      real*4        ix3,iy3,iz3,fix3,fiy3,fiz3
      real*4        ix4,iy4,iz4,fix4,fiy4,fiz4
      real*4        jx1,jy1,jz1,fjx1,fjy1,fjz1
      real*4        dx11,dy11,dz11,rsq11,rinv11
      real*4        dx21,dy21,dz21,rsq21,rinv21
      real*4        dx31,dy31,dz31,rsq31,rinv31
      real*4        dx41,dy41,dz41,rsq41,rinv41
      real*4        qH,qM
      real*4        c6,c12


C    Initialize water data
      ii               = iinr(1)+1       
      qH               = facel*charge(ii+1)
      qM               = facel*charge(ii+3)
      nti              = 2*ntype*type(ii)


C    Reset outer and inner iteration counters
      nouter           = 0               
      ninner           = 0               

C    Loop over thread workunits
   10 call f77kernelsync(mtx,count,nri,nthreads,nn0,nn1)
        if(nn1.gt.nri) nn1=nri

C      Start outer loop over neighborlists
        
        do n=nn0+1,nn1

C        Load shift vector for this list
          is3              = 3*shift(n)+1    
          shX              = shiftvec(is3)   
          shY              = shiftvec(is3+1) 
          shZ              = shiftvec(is3+2) 

C        Load limits for loop over neighbors
          nj0              = jindex(n)+1     
          nj1              = jindex(n+1)     

C        Get outer coordinate index
          ii               = iinr(n)+1       
          ii3              = 3*ii-2          

C        Load i atom data, add shift vector
          ix1              = shX + pos(ii3+0)
          iy1              = shY + pos(ii3+1)
          iz1              = shZ + pos(ii3+2)
          ix2              = shX + pos(ii3+3)
          iy2              = shY + pos(ii3+4)
          iz2              = shZ + pos(ii3+5)
          ix3              = shX + pos(ii3+6)
          iy3              = shY + pos(ii3+7)
          iz3              = shZ + pos(ii3+8)
          ix4              = shX + pos(ii3+9)
          iy4              = shY + pos(ii3+10)
          iz4              = shZ + pos(ii3+11)

C        Zero the potential energy for this list
          vctot            = 0               
          Vvdwtot          = 0               

C        Clear i atom forces
          fix1             = 0               
          fiy1             = 0               
          fiz1             = 0               
          fix2             = 0               
          fiy2             = 0               
          fiz2             = 0               
          fix3             = 0               
          fiy3             = 0               
          fiz3             = 0               
          fix4             = 0               
          fiy4             = 0               
          fiz4             = 0               
          
          do k=nj0,nj1

C          Get j neighbor index, and coordinate index
            jnr              = jjnr(k)+1       
            j3               = 3*jnr-2         

C          load j atom coordinates
            jx1              = pos(j3+0)       
            jy1              = pos(j3+1)       
            jz1              = pos(j3+2)       

C          Calculate distance
            dx11             = ix1 - jx1       
            dy11             = iy1 - jy1       
            dz11             = iz1 - jz1       
            rsq11            = dx11*dx11+dy11*dy11+dz11*dz11
            dx21             = ix2 - jx1       
            dy21             = iy2 - jy1       
            dz21             = iz2 - jz1       
            rsq21            = dx21*dx21+dy21*dy21+dz21*dz21
            dx31             = ix3 - jx1       
            dy31             = iy3 - jy1       
            dz31             = iz3 - jz1       
            rsq31            = dx31*dx31+dy31*dy31+dz31*dz31
            dx41             = ix4 - jx1       
            dy41             = iy4 - jy1       
            dz41             = iz4 - jz1       
            rsq41            = dx41*dx41+dy41*dy41+dz41*dz41

C          Calculate 1/r and 1/r2
            rinv11           = 1.0/sqrt(rsq11) 
            rinv21           = 1.0/sqrt(rsq21) 
            rinv31           = 1.0/sqrt(rsq31) 
            rinv41           = 1.0/sqrt(rsq41) 

C          Load parameters for j atom
            tj               = nti+2*type(jnr)+1
            c6               = vdwparam(tj)    
            c12              = vdwparam(tj+1)  

C          Calculate table index
            r                = rsq11*rinv11    

C          Calculate table index
            rt               = r*tabscale      
            n0               = rt              
            eps              = rt-n0           
            eps2             = eps*eps         
            nnn              = 8*n0+1          

C          Tabulated VdW interaction - dispersion
            Y                = VFtab(nnn)      
            F                = VFtab(nnn+1)    
            Geps             = eps*VFtab(nnn+2)
            Heps2            = eps2*VFtab(nnn+3)
            Fp               = F+Geps+Heps2    
            VV               = Y+eps*Fp        
            FF               = Fp+Geps+2.0*Heps2
            Vvdw6            = c6*VV           
            fijD             = c6*FF           

C          Tabulated VdW interaction - repulsion
            nnn              = nnn+4           
            Y                = VFtab(nnn)      
            F                = VFtab(nnn+1)    
            Geps             = eps*VFtab(nnn+2)
            Heps2            = eps2*VFtab(nnn+3)
            Fp               = F+Geps+Heps2    
            VV               = Y+eps*Fp        
            FF               = Fp+Geps+2.0*Heps2
            Vvdw12           = c12*VV          
            fijR             = c12*FF          
            Vvdwtot          = Vvdwtot+ Vvdw6 + Vvdw12
            fscal            = -((fijD+fijR)*tabscale)*rinv11

C          Calculate temporary vectorial force
            tx               = fscal*dx11      
            ty               = fscal*dy11      
            tz               = fscal*dz11      

C          Increment i atom force
            fix1             = fix1 + tx       
            fiy1             = fiy1 + ty       
            fiz1             = fiz1 + tz       

C          Decrement j atom force
            fjx1             = faction(j3+0) - tx
            fjy1             = faction(j3+1) - ty
            fjz1             = faction(j3+2) - tz

C          Load parameters for j atom
            jq               = charge(jnr+0)   
            qq               = qH*jq           
            rinvsq           = rinv21*rinv21   

C          Coulomb interaction
            vcoul            = qq*rinv21       
            vctot            = vctot+vcoul     
            fscal            = (vcoul)*rinvsq  

C          Calculate temporary vectorial force
            tx               = fscal*dx21      
            ty               = fscal*dy21      
            tz               = fscal*dz21      

C          Increment i atom force
            fix2             = fix2 + tx       
            fiy2             = fiy2 + ty       
            fiz2             = fiz2 + tz       

C          Decrement j atom force
            fjx1             = fjx1 - tx       
            fjy1             = fjy1 - ty       
            fjz1             = fjz1 - tz       

C          Load parameters for j atom
            rinvsq           = rinv31*rinv31   

C          Coulomb interaction
            vcoul            = qq*rinv31       
            vctot            = vctot+vcoul     
            fscal            = (vcoul)*rinvsq  

C          Calculate temporary vectorial force
            tx               = fscal*dx31      
            ty               = fscal*dy31      
            tz               = fscal*dz31      

C          Increment i atom force
            fix3             = fix3 + tx       
            fiy3             = fiy3 + ty       
            fiz3             = fiz3 + tz       

C          Decrement j atom force
            fjx1             = fjx1 - tx       
            fjy1             = fjy1 - ty       
            fjz1             = fjz1 - tz       

C          Load parameters for j atom
            qq               = qM*jq           
            rinvsq           = rinv41*rinv41   

C          Coulomb interaction
            vcoul            = qq*rinv41       
            vctot            = vctot+vcoul     
            fscal            = (vcoul)*rinvsq  

C          Calculate temporary vectorial force
            tx               = fscal*dx41      
            ty               = fscal*dy41      
            tz               = fscal*dz41      

C          Increment i atom force
            fix4             = fix4 + tx       
            fiy4             = fiy4 + ty       
            fiz4             = fiz4 + tz       

C          Decrement j atom force
            faction(j3+0)    = fjx1 - tx       
            faction(j3+1)    = fjy1 - ty       
            faction(j3+2)    = fjz1 - tz       

C          Inner loop uses 134 flops/iteration
          end do
          

C        Add i forces to mem and shifted force list
          faction(ii3+0)   = faction(ii3+0) + fix1
          faction(ii3+1)   = faction(ii3+1) + fiy1
          faction(ii3+2)   = faction(ii3+2) + fiz1
          faction(ii3+3)   = faction(ii3+3) + fix2
          faction(ii3+4)   = faction(ii3+4) + fiy2
          faction(ii3+5)   = faction(ii3+5) + fiz2
          faction(ii3+6)   = faction(ii3+6) + fix3
          faction(ii3+7)   = faction(ii3+7) + fiy3
          faction(ii3+8)   = faction(ii3+8) + fiz3
          faction(ii3+9)   = faction(ii3+9) + fix4
          faction(ii3+10)  = faction(ii3+10) + fiy4
          faction(ii3+11)  = faction(ii3+11) + fiz4
          fshift(is3)      = fshift(is3)+fix1+fix2+fix3+fix4
          fshift(is3+1)    = fshift(is3+1)+fiy1+fiy2+fiy3+fiy4
          fshift(is3+2)    = fshift(is3+2)+fiz1+fiz2+fiz3+fiz4

C        Add potential energies to the group for this list
          ggid             = gid(n)+1        
          Vc(ggid)         = Vc(ggid) + vctot
          Vvdw(ggid)       = Vvdw(ggid) + Vvdwtot

C        Increment number of inner iterations
          ninner           = ninner + nj1 - nj0

C        Outer loop uses 38 flops/iteration
        end do
        

C      Increment number of outer iterations
        nouter           = nouter + nn1 - nn0
      if(nn1.lt.nri) goto 10

C    Write outer/inner iteration count to pointers
      outeriter        = nouter          
      inneriter        = ninner          
      return
      end






C
C Gromacs nonbonded kernel f77skernel133nf
C Coulomb interaction:     Normal Coulomb
C VdW interaction:         Tabulated
C water optimization:      TIP4P - other atoms
C Calculate forces:        no
C
      subroutine f77skernel133nf(
     &                          nri,
     &                          iinr,
     &                          jindex,
     &                          jjnr,
     &                          shift,
     &                          shiftvec,
     &                          fshift,
     &                          gid,
     &                          pos,
     &                          faction,
     &                          charge,
     &                          facel,
     &                          krf,
     &                          crf,
     &                          Vc,
     &                          type,
     &                          ntype,
     &                          vdwparam,
     &                          Vvdw,
     &                          tabscale,
     &                          VFtab,
     &                          invsqrta,
     &                          dvda,
     &                          gbtabscale,
     &                          GBtab,
     &                          nthreads,
     &                          count,
     &                          mtx,
     &                          outeriter,
     &                          inneriter,
     &                          work)
      implicit      none
      integer*4     nri,iinr(*),jindex(*),jjnr(*),shift(*)
      real*4        shiftvec(*),fshift(*),pos(*),faction(*)
      integer*4     gid(*),type(*),ntype
      real*4        charge(*),facel,krf,crf,Vc(*),vdwparam(*)
      real*4        Vvdw(*),tabscale,VFtab(*)
      real*4        invsqrta(*),dvda(*),gbtabscale,GBtab(*)
      integer*4     nthreads,count,mtx,outeriter,inneriter
      real*4        work(*)

      integer*4     n,ii,is3,ii3,k,nj0,nj1,jnr,j3,ggid
      integer*4     nn0,nn1,nouter,ninner
      real*4        shX,shY,shZ
      real*4        jq
      real*4        qq,vcoul,vctot
      integer*4     nti
      integer*4     tj
      real*4        Vvdw6,Vvdwtot
      real*4        Vvdw12
      real*4        r,rt,eps,eps2
      integer*4     n0,nnn
      real*4        Y,F,Geps,Heps2,Fp,VV
      real*4        ix1,iy1,iz1
      real*4        ix2,iy2,iz2
      real*4        ix3,iy3,iz3
      real*4        ix4,iy4,iz4
      real*4        jx1,jy1,jz1
      real*4        dx11,dy11,dz11,rsq11,rinv11
      real*4        dx21,dy21,dz21,rsq21,rinv21
      real*4        dx31,dy31,dz31,rsq31,rinv31
      real*4        dx41,dy41,dz41,rsq41,rinv41
      real*4        qH,qM
      real*4        c6,c12


C    Initialize water data
      ii               = iinr(1)+1       
      qH               = facel*charge(ii+1)
      qM               = facel*charge(ii+3)
      nti              = 2*ntype*type(ii)


C    Reset outer and inner iteration counters
      nouter           = 0               
      ninner           = 0               

C    Loop over thread workunits
   10 call f77kernelsync(mtx,count,nri,nthreads,nn0,nn1)
        if(nn1.gt.nri) nn1=nri

C      Start outer loop over neighborlists
        
        do n=nn0+1,nn1

C        Load shift vector for this list
          is3              = 3*shift(n)+1    
          shX              = shiftvec(is3)   
          shY              = shiftvec(is3+1) 
          shZ              = shiftvec(is3+2) 

C        Load limits for loop over neighbors
          nj0              = jindex(n)+1     
          nj1              = jindex(n+1)     

C        Get outer coordinate index
          ii               = iinr(n)+1       
          ii3              = 3*ii-2          

C        Load i atom data, add shift vector
          ix1              = shX + pos(ii3+0)
          iy1              = shY + pos(ii3+1)
          iz1              = shZ + pos(ii3+2)
          ix2              = shX + pos(ii3+3)
          iy2              = shY + pos(ii3+4)
          iz2              = shZ + pos(ii3+5)
          ix3              = shX + pos(ii3+6)
          iy3              = shY + pos(ii3+7)
          iz3              = shZ + pos(ii3+8)
          ix4              = shX + pos(ii3+9)
          iy4              = shY + pos(ii3+10)
          iz4              = shZ + pos(ii3+11)

C        Zero the potential energy for this list
          vctot            = 0               
          Vvdwtot          = 0               

C        Clear i atom forces
          
          do k=nj0,nj1

C          Get j neighbor index, and coordinate index
            jnr              = jjnr(k)+1       
            j3               = 3*jnr-2         

C          load j atom coordinates
            jx1              = pos(j3+0)       
            jy1              = pos(j3+1)       
            jz1              = pos(j3+2)       

C          Calculate distance
            dx11             = ix1 - jx1       
            dy11             = iy1 - jy1       
            dz11             = iz1 - jz1       
            rsq11            = dx11*dx11+dy11*dy11+dz11*dz11
            dx21             = ix2 - jx1       
            dy21             = iy2 - jy1       
            dz21             = iz2 - jz1       
            rsq21            = dx21*dx21+dy21*dy21+dz21*dz21
            dx31             = ix3 - jx1       
            dy31             = iy3 - jy1       
            dz31             = iz3 - jz1       
            rsq31            = dx31*dx31+dy31*dy31+dz31*dz31
            dx41             = ix4 - jx1       
            dy41             = iy4 - jy1       
            dz41             = iz4 - jz1       
            rsq41            = dx41*dx41+dy41*dy41+dz41*dz41

C          Calculate 1/r and 1/r2
            rinv11           = 1.0/sqrt(rsq11) 
            rinv21           = 1.0/sqrt(rsq21) 
            rinv31           = 1.0/sqrt(rsq31) 
            rinv41           = 1.0/sqrt(rsq41) 

C          Load parameters for j atom
            tj               = nti+2*type(jnr)+1
            c6               = vdwparam(tj)    
            c12              = vdwparam(tj+1)  

C          Calculate table index
            r                = rsq11*rinv11    

C          Calculate table index
            rt               = r*tabscale      
            n0               = rt              
            eps              = rt-n0           
            eps2             = eps*eps         
            nnn              = 8*n0+1          

C          Tabulated VdW interaction - dispersion
            Y                = VFtab(nnn)      
            F                = VFtab(nnn+1)    
            Geps             = eps*VFtab(nnn+2)
            Heps2            = eps2*VFtab(nnn+3)
            Fp               = F+Geps+Heps2    
            VV               = Y+eps*Fp        
            Vvdw6            = c6*VV           

C          Tabulated VdW interaction - repulsion
            nnn              = nnn+4           
            Y                = VFtab(nnn)      
            F                = VFtab(nnn+1)    
            Geps             = eps*VFtab(nnn+2)
            Heps2            = eps2*VFtab(nnn+3)
            Fp               = F+Geps+Heps2    
            VV               = Y+eps*Fp        
            Vvdw12           = c12*VV          
            Vvdwtot          = Vvdwtot+ Vvdw6 + Vvdw12

C          Load parameters for j atom
            jq               = charge(jnr+0)   
            qq               = qH*jq           

C          Coulomb interaction
            vcoul            = qq*rinv21       
            vctot            = vctot+vcoul     

C          Load parameters for j atom

C          Coulomb interaction
            vcoul            = qq*rinv31       
            vctot            = vctot+vcoul     

C          Load parameters for j atom
            qq               = qM*jq           

C          Coulomb interaction
            vcoul            = qq*rinv41       
            vctot            = vctot+vcoul     

C          Inner loop uses 80 flops/iteration
          end do
          

C        Add i forces to mem and shifted force list

C        Add potential energies to the group for this list
          ggid             = gid(n)+1        
          Vc(ggid)         = Vc(ggid) + vctot
          Vvdw(ggid)       = Vvdw(ggid) + Vvdwtot

C        Increment number of inner iterations
          ninner           = ninner + nj1 - nj0

C        Outer loop uses 14 flops/iteration
        end do
        

C      Increment number of outer iterations
        nouter           = nouter + nn1 - nn0
      if(nn1.lt.nri) goto 10

C    Write outer/inner iteration count to pointers
      outeriter        = nouter          
      inneriter        = ninner          
      return
      end



