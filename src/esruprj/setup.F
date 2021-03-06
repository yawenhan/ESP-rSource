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

C file setup.F includes facilities for display of dates, time
C and viewpoints. MODSIT is set to true if default wireframe
C viewpoint is changed.

      SUBROUTINE SETUP(MODSIT,ITRC,IER)
#include "building.h"
#include "model.h"

C geometry.h provides commons G0 and G2.
#include "geometry.h"
#include "prj3dv.h"
#include "espriou.h"
      
      integer lnblnk  ! function definition

      common/OUTIN/IUOUT,IUIN
      common/FILEP/IFIL
      common/SET1/IYEAR,IBDOY,IEDOY,IFDAY,IFTIME
      common/texted/tedlbl,teditor
      common/user/browse

C Initial view.
      common/initv/initvt,EYEMI(3),VIEWMI(3),ANGI

      logical OK,DOK,MODSIT,browse,defview,unixok
      logical closea,closeb,closec,closed,concat
      dimension ITEMS1(14)
      character LFIL*96,longtfile*144,llitem*144,longtfiledos*144
      character ITEMS1*47,doit*248,tedlbl*20,teditor*20
      character tmode*8,hold32*32
      character ureturn*8  ! info back from silentread
      integer NITMS,INO1 ! max items and current menu item

C For help messages
      character helpinsub*24 ! subroutine name
      character helptopic*24 ! string (unique) for topic
      integer nbhelp     ! number of help lines found

      helpinsub='SETUP'  ! set for subroutine
      
C Set initial states to false and clear text buffers.
      MODSIT=.false.
      LFIL=' '
      longtfile=' '
      doit=' '
      hold32=' '

C Check if Unix-based or DOS based.
      call isunix(unixok)

C Check default view point.
  33  defview=.false.
      CALL ECLOSE(EYEM(1),-100.0,1.0,closea)
      CALL ECLOSE(EYEM(2),-100.0,1.0,closeb)
      CALL ECLOSE(EYEM(3),100.0,1.0,closec)
      CALL ECLOSE(ANG,40.0,1.0,closed)
      if(closea.and.closeb.and.closec.and.closed)then
        defview=.true.
      endif

      INO1=-4
      if(defview)then
        ITEMS1(1)='a wireframe view: default                     '
      else
        ITEMS1(1)='a wireframe view: user defined                '
      endif
      IF(IFDAY.EQ.0)THEN
        ITEMS1(2)='b display format for date>> DOY 10            '
      ELSEIF(IFDAY.EQ.1)THEN
        ITEMS1(2)='b display format for date>> 10 Jan            '
      ELSEIF(IFDAY.EQ.2)THEN
        ITEMS1(2)='b display format for date>> Fri 10 Jan        '
      ENDIF

C Display of time of day.
      IF(IFTIME.EQ.0)THEN
        ITEMS1(3)='c display format for time>> 10h30             '
      ELSEIF(IFTIME.EQ.1)THEN
        ITEMS1(3)='c display format for time>> 10.50             '
      ELSEIF(IFTIME.EQ.2)THEN
        ITEMS1(3)='c display format for time>> 0.4166 (day frac.)'
      ENDIF

      ITEMS1(4)  ='e look at ASCII file                          '
      ITEMS1(5)  ='f edit an ASCII file                          '
      ITEMS1(6)  ='g edit ESP-r defaults for files               '
      ITEMS1(7)  ='h edit ESP-r 3rd party applications           '
      ITEMS1(8)  ='i edit ESP-r climatelist entries              '
      ITEMS1(9)  ='j edit ESP-r exemplars entries                '
      IF(ITRC.EQ.0)THEN
        ITEMS1(10)='k feedback >> silent                          '
      ELSEIF(ITRC.EQ.1)THEN
        ITEMS1(10)='k feedback >> summary                         '
      ELSEIF(ITRC.EQ.2)THEN
        ITEMS1(10)='k feedback >> detailed                        '
      ENDIF
      if(igupgrade.eq.0)then
        ITEMS1(11)='l upgrade files >> no change                  '
      elseif(igupgrade.eq.1)then
        ITEMS1(11)='l upgrade files >> save current format        '
      endif
      ITEMS1(12)  ='* test button (esp-r meta file scan)          '
      ITEMS1(13) ='? help                                        '
      ITEMS1(14) ='- exit this menu                              '

C Help text for menu.
      helptopic='setup_date_format'
      call gethelptext(helpinsub,helptopic,nbhelp)
      NITMS=14
      CALL EMENU('Tool preferences',ITEMS1,NITMS,INO1)
      IF(INO1.EQ.1)THEN

C Wire frame view point.
        if(browse)goto 33
        CALL EASKABCD(' Initial view position options',' :',
     &      'default','accept current','edit','continue',IW,nbhelp)
        if(IW.EQ.1)then

C Set eye point at standard place and viewed point at cog.
          EYEMI(1)=-100.
          EYEMI(2)=-100.
          EYEMI(3)=100.
          call bndobj(0,ier)
          VIEWMI(1)=VIEWM(1)
          VIEWMI(2)=VIEWM(2)
          VIEWMI(3)=VIEWM(3)
          ANGI=40.
          initvt=0
          MODSIT=.true.
        elseif(IW.EQ.2)then
          EYEMI(1)=EYEM(1)
          EYEMI(2)=EYEM(2)
          EYEMI(3)=EYEM(3)
          VIEWMI(1)=VIEWM(1)
          VIEWMI(2)=VIEWM(2)
          VIEWMI(3)=VIEWM(3)
          ANGI=ANG
          initvt=1
          MODSIT=.true.
        elseif(IW.EQ.3)then
 143      WRITE(HOLD32,'(1x,3f8.2)')EYEM(1),EYEM(2),EYEM(3)
          CALL EASKS(HOLD32,' Eye point  X  Y  Z (in metres): ',
     &     '  ',32,' -100.0 -100.0 100.0 ','eye point coord',IER,nbhelp)
          K=0
          CALL EGETWR(HOLD32,K,EYEMI(1),-999.,999.,'W','Xcord',IER)
          CALL EGETWR(HOLD32,K,EYEMI(2),-999.,999.,'W','Ycord',IER)
          CALL EGETWR(HOLD32,K,EYEMI(3),0.,999.,'W','eye Zcord',IER)
          if(ier.ne.0)goto 143
 141      WRITE(HOLD32,'(1x,3f8.2)')VIEWM(1),VIEWM(2),VIEWM(3)
          CALL EASKS(HOLD32,' Viewpoint  X  Y  Z (in metres): ',
     &     '  ',32,' 2.0 2.0 1.0 ','viewpoint coord',IER,nbhelp)
          K=0
          CALL EGETWR(HOLD32,K,VIEWMI(1),-999.,999.,'W','Xcord',IER)
          CALL EGETWR(HOLD32,K,VIEWMI(2),-999.,999.,'W','Ycord',IER)
          CALL EGETWR(HOLD32,K,VIEWMI(3),0.,999.,'W','v Zcord',IER)
          if(ier.ne.0)goto 141
          ANGI=ANG
          CALL EASKR(ANGI,' ',' New angle of view ? ',
     &             1.0,'W',120.0,'W',40.,'angle ofview',IER,2)
          initvt=1
          MODSIT=.true.
        endif
      ELSEIF(INO1.EQ.2)THEN

C Allow user to toggle between 'Fri 10 Jan'/'10 Jan'/'DOY 124' format.
        IFDAY=IFDAY+1
        IF(IFDAY.GT.2)IFDAY=0
      ELSEIF(INO1.EQ.3)THEN

C Allow user to toggle between '10h00'/'10.00'/'0.41666' format. Only
C allow decimal day representation if day format is DOY
        IFTIME=IFTIME+1
        IF(IFDAY.EQ.0.AND.IFTIME.GT.2)IFTIME=0
        IF(IFDAY.GE.1.AND.IFTIME.GT.1)IFTIME=0
      ELSEIF(INO1.EQ.4)THEN

C List out an ASCII file. Use file browser if in GTK mode.
        longtfile=' '    ! reset return string
  6     CALL EASKXORGTKF(LFIL,'ASCII file name?',' ',
     &    'xxx.rep',longtfile,'ASCII file',IER,nbhelp)

C If user request jump back and re-display the menu.
        if(ier.eq.-3)then
          goto 33  ! redisplay menu.
        endif
        IUNIT=IFIL+1
        CALL LISTAS(IUNIT,longtfile,IER)
        IF(IER.LT.0)THEN
          dok=.false.
          helptopic='setup_list_ascii_error'
          call gethelptext(helpinsub,helptopic,nbhelp)
          CALL ASKOK(' Problem detected while trying to open',
     &               ' ASCII file. Try again?',OK,dok,nbhelp)
          IF(OK)GOTO 6
        ENDIF
      ELSEIF(INO1.EQ.5)THEN

C Allow user to edit a file.  Use file browser if in GTK mode.
C If vi then spawn a new window to do the editing in.
        helptopic='setup_edit_ascii'
        call gethelptext(helpinsub,helptopic,nbhelp)
        llitem=' '    ! reset return string
        CALL EASKXORGTKF(LFIL,'ASCII file name?',' ',
     &    'xxx.rep',llitem,'ASCII file',IER,nbhelp)

C If user request jump back and re-display the menu.
        if(ier.eq.-3)then
          goto 33  ! redisplay menu.
        endif

C Depending on whether Unix or DOS based setup paths. If DOS
C then check for spaces in name and change / to \.
        call isunix(unixok)
        if(unixok)then
          call addpath(llitem,longtfile,concat)
        else
          call addpath(llitem,longtfile,concat)
          call cmdfiledos(longtfile,longtfiledos,ier)
          longtfile=' '
          longtfile=longtfiledos
        endif
        tmode='graph'
        if(teditor(1:2).eq.'vi')tmode='text'
        write(doit,'(a,2x,a,a)') teditor(1:lnblnk(teditor)),
     &    longtfile(1:lnblnk(longtfile)),' &'
        call runit(doit,tmode)
      ELSEIF(INO1.EQ.6)THEN

C Edit the installed file `defaults'.
        call isunix(unixok)
        helptopic='setup_edit_defaults'
        call gethelptext(helpinsub,helptopic,nbhelp)
        llitem=' '    ! reset return string
        CALL EASKXORGTKF(defdbfl,'ESP-r default files?',' ',
     &    'default',llitem,'defaults file',IER,nbhelp)

C If user request jump back and re-display the menu.
        if(ier.eq.-3)then
          goto 33  ! redisplay menu.
        endif

C Depending on whether Unix or DOS based setup paths. If DOS
C then check for spaces in name and change / to \.
        if(unixok)then
          call addpath(llitem,longtfile,concat)
        else
          call addpath(llitem,longtfile,concat)
          call cmdfiledos(longtfile,longtfiledos,ier)
          longtfile=' '
          longtfile=longtfiledos
        endif
        tmode='graph'
        if(teditor(1:2).eq.'vi')tmode='text'
        write(doit,'(a,2x,a,a)') teditor(1:lnblnk(teditor)),
     &    longtfile(1:lnblnk(longtfile)),' &'
        call runit(doit,tmode)

      ELSEIF(INO1.EQ.7)THEN

C Edit the installed file `esprc'.
        call isunix(unixok)
        helptopic='setup_edit_esprc'
        call gethelptext(helpinsub,helptopic,nbhelp)
        llitem=' '    ! reset return string
        CALL EASKXORGTKF(esprc,'ESP-r esprc file?','(see help)',
     &    'esprc',llitem,'esprc file',IER,nbhelp)

C If user request jump back and re-display the menu.
        if(ier.eq.-3)then
          goto 33  ! redisplay menu.
        endif

C Depending on whether Unix or DOS based setup paths. If DOS
C then check for spaces in name and change / to \.
        if(unixok)then
          call addpath(llitem,longtfile,concat)
        else
          call addpath(llitem,longtfile,concat)
          call cmdfiledos(longtfile,longtfiledos,ier)
          longtfile=' '
          longtfile=longtfiledos
        endif
        tmode='graph'
        if(teditor(1:2).eq.'vi')tmode='text'
        write(doit,'(a,2x,a,a)') teditor(1:lnblnk(teditor)),
     &    longtfile(1:lnblnk(longtfile)),' &'
        call runit(doit,tmode)

      ELSEIF(INO1.EQ.8)THEN

C Edit the installed file `climatelist'.
        call isunix(unixok)
        helptopic='setup_edit_climatelist'
        call gethelptext(helpinsub,helptopic,nbhelp)
        llitem=' '    ! reset return string
        CALL EASKXORGTKF(cdblfil,'ESP-r climatelist file?',
     &    '(see help)','climatelist',llitem,'climatelist file',IER,
     &    nbhelp)

C If user request jump back and re-display the menu.
        if(ier.eq.-3)then
          goto 33  ! redisplay menu.
        endif

C Depending on whether Unix or DOS based setup paths. If DOS
C then check for spaces in name and change / to \.
        if(unixok)then
          call addpath(llitem,longtfile,concat)
        else
          call addpath(llitem,longtfile,concat)
          call cmdfiledos(longtfile,longtfiledos,ier)
          longtfile=' '
          longtfile=longtfiledos
        endif
        tmode='graph'
        if(teditor(1:2).eq.'vi')tmode='text'
        write(doit,'(a,2x,a,a)') teditor(1:lnblnk(teditor)),
     &    longtfile(1:lnblnk(longtfile)),' &'
        call runit(doit,tmode)
      ELSEIF(INO1.EQ.9)THEN

C Edit the installed file `exemplars'.
        call isunix(unixok)
        helptopic='setup_edit_exemplars'
        call gethelptext(helpinsub,helptopic,nbhelp)
        llitem=' '    ! reset return string
        CALL EASKXORGTKF(exemfl,'ESP-r exemplars?','(see help)',
     &    'exemplars',llitem,'exemplars file',IER,nbhelp)

C If user request jump back and re-display the menu.
        if(ier.eq.-3)then
          goto 33  ! redisplay menu.
        endif

C Depending on whether Unix or DOS based setup paths. If DOS
C then check for spaces in name and change / to \.
        if(unixok)then
          call addpath(llitem,longtfile,concat)
        else
          call addpath(llitem,longtfile,concat)
          call cmdfiledos(longtfile,longtfiledos,ier)
          longtfile=' '
          longtfile=longtfiledos
        endif
        tmode='graph'
        if(teditor(1:2).eq.'vi')tmode='text'
        write(doit,'(a,2x,a,a)') teditor(1:lnblnk(teditor)),
     &    longtfile(1:lnblnk(longtfile)),' &'
        call runit(doit,tmode)

      ELSEIF(INO1.EQ.10)THEN

C Toggle trace/feedback level.
        ITRC=ITRC+1
        IF(ITRC.GT.2)ITRC=0
      ELSEIF(INO1.EQ.11)THEN

C Toggle file format upgrade opinion.
        igupgrade=igupgrade+1
        IF(igupgrade.GT.1)ITRC=0
        if(igupgrade.eq.1)then
          helptopic='setup_date_format'
          call gethelptext(helpinsub,helptopic,nbhelp)
          CALL EASKAB('Upgrade options',' :',
     &      'scan & update all zones','cancel',IUW,nbhelp)
          if(iuw.eq.1)then
            call mupdate(ier)
            igupgrade=0
          endif
        endif
      ELSEIF(INO1.EQ.12)THEN

C Test button for ESP-r meta file read testing.

C Add a choice point here - one to carry on with the current model,
C one to start a fresh model, one to just list the details of the
C silent file.
        helptopic='setup_date_format'
        call gethelptext(helpinsub,helptopic,nbhelp)
        CALL EASKABCD(' META file options',' :',
     &    'retrieve description','process META data','XX','continue',
     &    IW,nbhelp)

C Allow user to edit a file.  Use file browser if in GTK mode.
C If vi then spawn a new window to do the editing in.
        LFIL=' '
        longtfile=' '    ! reset return string
        CALL EASKXORGTKF(LFIL,'ESP-r meta file name?',' ',
     &    'xxx.txt',longtfile,'esp-r meta file',IER,nbhelp)
     
        IUNIT=IFIL+1
        if(IW.EQ.1)then
          call silentread(iunit,longtfile,'?',ureturn,ier)
          call edisp(iuout,ureturn)
          call edisp(iuout,modeltitle)
          call edisp248(iuout,modeldocblock,80)
        elseif(IW.eq.2)then
          call silentread(iunit,longtfile,'-',ureturn,ier)
          call edisp(iuout,ureturn)
          call edisp(iuout,modeltitle)
          call edisp248(iuout,modeldocblock,80)
          return
        elseif(IW.eq.3)then
          continue
        elseif(IW.eq.4)then
          continue
        endif
      ELSEIF(INO1.EQ.13)THEN

C User asked for help.
      helptopic='setup_date_format'
      call gethelptext(helpinsub,helptopic,nbhelp)
      CALL PHELPD('general preferences',nbhelp,'-',0,0,IER)
      ELSEIF(INO1.EQ.14)THEN
        RETURN
      else
        goto 33
      endif
      goto 33
     
      END
