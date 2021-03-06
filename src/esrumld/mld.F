C This file is part of the ESP-r system.
C Copyright Energy Systems Research Unit, University of
C Strathclyde, Glasgow Scotland, 2001.

C ESP-r is free software.  You can redistribute it and/or
C modify it under the terms of the GNU General Public
C License as published by the Free Software Foundation 
C (version 2 orlater).

C ESP-r is distributed in the hope that it will be useful
C but WITHOUT ANY WARRANTY; without even the implied
C warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
C PURPOSE. See the GNU General Public License for more
C details.

C You should have received a copy of the GNU General Public
C License along with ESP-r. If not, write to the Free
C Software Foundation, Inc., 59 Temple Place, Suite 330,
C Boston, MA 02111-1307 USA.

      program mld
      USE START_UP
#include "building.h"
#include "model.h"
#include "mould.h"
#include "esprdbfile.h"
#include "espriou.h"

      common/minfo/mno(MOULD),species(MOULD)
      common/meqn/a0(MOULD),a1(MOULD),a2(MOULD),a3(MOULD)
      common/mglook/GROT(MLOOK,MOULD),GRORH(MLOOK,MOULD)
      common/mglook2/GROW(MLOOK,MOULD)
      common/moupk/ispp(mould),a(4,mould),mldnam(mould)
      common/mstats/imstat,ifloat(mould),ifloatp(mould),imdur1(mould)
     &,imdur0(mould),i1max(mould),i0max(mould),imup(mould),
     &imdn(mould)
      common/iopnmld/iopmld
      common/mdbase/mdbnam
      character mdbnam*72

      common/OUTIN/IUOUT,IUIN
      common/SHOUT/ICOUT
      common/FILEP/IFIL
      common/SPAD/MMOD,LIMIT,LIMTTY
      common/appw/iappw,iappx,iappy
      integer menuchw,igl,igr,igt,igb,igw,igwh
      common/VIEWPX/menuchw,igl,igr,igt,igb,igw,igwh
      integer ifs,itfs,imfs
      common/GFONT/IFS,ITFS,IMFS
      common/funit/iucfg, iupdb
      common/appcols/mdispl,nifgrey,ncset,ngset,nzonec

C Path to problem and command line file (if any).
      common/rpath/path
      common/rcmd/LCMDFL

C Defaults.
      character*96 DFCFG,DFCTL,DEFRLB,DAPROB,DAFRES,DPNF
      common/DEFLT2/DFCFG,DFCTL,DEFRLB,DAFRES,DAPROB,DPNF

C Name of current application
      common/APPNAME/cAppName
      
      character cAppName*12

      character*29 ITEM(10)
      character LCMDFL*144,inf*144,mldnam*48
      character path*72
      character species*64, grow*1, head*29,fs*1

      character cVnum*16      ! returned from ESPrVersionNum
      character pagestitle*42 ! for banner title via epages call

      logical unixok

#ifdef OSI
      integer iigl,iigr,iigt,iigb,iigw,iigwh
      integer iiw1,iiw2,iiw3,iiw4,iimenu
#else
      integer*8 iigl,iigr,iigt,iigb,iigw,iigwh
      integer*8 iiw1,iiw2,iiw3,iiw4,iimenu
#endif

      integer iglib   ! if 1 then X11, if 2 then GTK, if 3 then text only.
      integer nitem,ino ! max items and current menu item

C Initialize global common data.
      call ezero
      call curmodule('mld ')
      cAppName = 'mld'
      helpinapp='mld'  ! set once for the application
      IUOUT=6
      IUIN=5
      IFIL=10
      IFS=1
      ITFS=1
      IMFS=1
      iopmld=0
      call parpsf(MODL,iappw,iappx,iappy,inf)

C Set folder separator (fs) to \ or / as required.
      call isunix(unixok)
      if(unixok)then
        fs = char(47)
      else
        fs = char(92)
      endif
      write(path,'(a1,a1)')'.',fs

C Set unit numbers for configuration file and plant data
C base files respectively.
      iucfg = 7
      iupdb = 8

C Determine terminal type and set write unit to stderr for rule scripts.
      MODL=8
      MMOD=MODL
      if(iappw.eq.0.and.iappx.eq.0.and.iappy.eq.0)then
        iappw=520
        iappx=100
        iappy=150
      else
        if(iappx.le.0)iappx=100
        if(iappy.le.0)iappy=150
        if(iappw.le.200)then
          iappwi=int(520*iappw*0.01)
          iappw=iappwi
        elseif(iappw.gt.200)then
          continue
        endif
      endif

C Set pixels high to iappw and pixels wide to factor in monitor size.
      iapphi=iappw
      iappwi=int(real(iappw)*(1024.0/780.0))

      if(iappw.gt.0.and.iappw.lt.100)then
        menuchw = MAX0(int(32*iappw*0.01),24)
        LIMTTY=10
        LIMIT =10
      else
        menuchw = 32
        LIMTTY=10
        LIMIT =10
      endif
      IF(MMOD.EQ.8)THEN

C Set initial font sizes (IMFS is for graphs, IFS is for dialog & text feedback).
        IMFS=1
        IFS=1
        ITFS=1
        call userfonts(IFS,ITFS,IMFS)
      ELSE
        LIMTTY=16
        LIMIT =16
      ENDIF

C Find the current ESP-r version number and add it to application title.
      call ESPrVersionNum(cVnum)
      write(pagestitle,'(2a)') 'ESP-r Mould Analysis ',
     &  cVnum(1:lnblnk(cVnum))

      CALL EPAGES(MMOD,IUIN,IUOUT,iappwi,iapphi,iappx,iappy,menuchw,
     &  pagestitle)

C Open the text display box equal to LIMTTY if MMOD = 8.
      IF(MMOD.EQ.8)THEN

C Setup and pass in parameters to win3d.
        iiw1=12; iiw2=12; iiw3=4; iiw4=3; iimenu=menuchw
        iigl=igl; iigr=igr; iigt=igt; iigb=igb; iigw=igw; iigwh=igwh
        CALL win3d(iimenu,iiw1,iiw2,iiw3,iiw4,
     &    iigl,iigr,iigt,iigb,iigw,iigwh)
        igl=int(iigl); igr=int(iigr); igt=int(iigt); igb=int(iigb)
        igw=int(iigw); igwh=int(iigwh)
        iglib = igraphiclib()  ! find out if X11 or GTK or text support only.
        if(iglib.eq.1)then
          call opencpw
          call opensetup
        endif
        mdispl=0
        nifgrey=0
        ncset=0
        ngset=0
        nzonec=0
        call foundcolour(mdispl,nifgrey,ncset,ngset,nzonec)
        call startbuffer()
      ENDIF

C Take `c' command line file name, convert to fortran string LCMDFL.
      if(inf(1:2).ne.'  '.and.inf(1:4).ne.'UNKN')then
        LCMDFL=inf
        write(mdbnam,'(a)') inf(1:lnblnk(inf))
      else
        LCMDFL='UNKNOWN'
        mdbnam='UNKNOWN'
      endif

C Set additional output units to stdout. Then redirect warning
C messages to stderr in case of rule script program control.
      ICOUT=IUOUT
      IF(MMOD.EQ.-6) ICOUT=0

      CALL ESPrVersion("summary",cAppName,IUOUT)

C Initialise the ststistical results
      imstat=0

  2   head='mould growth main menu'
      ino=-1
      item(1)='a Select mould species '
      item(2)='  ---------------      '
      if(imstat.eq.0) then
        item(3)='c Statistics >> OFF  '
      else
         item(3)='c Statistics >> ON  '
      endif
      item(4)='d Graphs               '
      item(5)='                       '
      item(6)='---------------        '
      item(7)='? Help                 '
      item(8)='- Exit                 '
      nitem=8

C Use askabout to instanciate the initial help messages (2nd parameter is one).
      call askabout('mld ',1)

      call emenu(head,item,nitem,ino)

      if(ino.eq.1) then

C Recover mould names and display menu of moulds.
       call mycorecv(ino,1)

      elseif(ino.eq.3) then

C Set statistics reporting flag to ON or OFF  .
         if(imstat.eq.0) then
            imstat=1
            call mycostat(1,0.,0.)
         else
            imstat=0
         endif     
      elseif(ino.eq.4) then
        call mycograph
      elseif(ino.eq.7) then

C Help via the askabout facility in esru_ask.F The zero requests display
        call askabout('mld ',0)
        goto 2
      elseif(ino.eq.8) then
        CALL EPAGEND
        STOP
      else
         ino=-4
         goto 2
      endif
      goto 2
 
      end

C ***** Dummy display of images.
      subroutine cfgpk(act)
      character act*1

      return
      end

      subroutine imgdisp(iforce,focus,ier)
      character focus*4

      return
      end

C Dummy routines from common3dv.F needed to match implied
C calls in esru_lib.F
      SUBROUTINE ADJVIEW(IER)
      ier=0
      return
      end

      subroutine chgazi(icazi)
      return
      end

      subroutine chgelev(icelev)
      return
      end

      subroutine chgsun(isunhour)
      return
      end

      subroutine chgeye(EVX,EVY,EVZ,VX,VY,VZ,EAN,JITZNM,JITSNM,JITVNO,
     &   JITOBS,JITSNR,JITGRD,JITORG,DIS,JITBND,JITDSP,JITHLS,JITHLZ,
     &   JITPPSW)

C Passed paramters.
      real EVX,EVY,EVZ,VX,VY,VZ,EAN,DIS

C Depending on computer type set integer size of passed parameters.
#ifdef OSI
      integer JITZNM,JITSNM,JITVNO,JITOBS,JITSNR,JITGRD,JITORG
      integer JITBND,JITDSP,JITHLS,JITHLZ,JITPPSW
#else
      integer*8 JITZNM,JITSNM,JITVNO,JITOBS,JITSNR,JITGRD,JITORG
      integer*8 JITBND,JITDSP,JITHLS,JITHLZ,JITPPSW
#endif     
      return
      end

      subroutine chgzonpik(jizgfoc,jnzg)
#ifdef OSI
      integer jizgfoc,jnzg  ! for use with viewtext
#else
      integer*8 jizgfoc,jnzg  ! for use with viewtext
#endif
      return
      end

      subroutine chgzonpikarray(jnznog,jnznogv)
#ifdef OSI
      integer jnznog,jnznogv
#else
      integer*8 jnznog,jnznogv
#endif
      return
      end

      SUBROUTINE EMKVIEW(IUO,CFGOK,IER)
      logical cfgok
      ier=0
      return
      end

      SUBROUTINE EPKMLC(ISEL,PROMPT1,PROMPT2,IER)
      CHARACTER*(*) PROMPT1,PROMPT2
      ier=0
      return
      end

      SUBROUTINE INLNST(ITYP)
      return
      end

      SUBROUTINE PLELEV(direc)
      CHARACTER direc*1
      return
      end

