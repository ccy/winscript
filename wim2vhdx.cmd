@echo off
setlocal

rem *** default values
set _vhdx_size=20480
set _label="New Volume"

rem *** make sure current session has administrator permission
:checkPermission
  net session >nul 2>&1
  if %errorLevel% NEQ 0 echo require administrator privilege && goto error

rem *** check command line parameters
:checkParams
  if [%1] equ [] goto main
  set _param=%1
  if %_param:~0,1% equ - goto getParam
  goto help

:h
:help
  echo.
  echo usage: %~n0 ^<-f vhdx file name^> ^<-s vhdx size in mega bytes^> ^<-l partition label^> ^<-w wim file^> ^<-i wim file index^>
  echo Create a GPT partitioned windows virtual hard disk file
  echo.
  echo  -f   VHDX file name
  echo  -h   Show helps
  echo  -i   WimBoot file Index
  echo  -l   Volume name
  echo  -s   VHDX size in megabytes.  Default: 20GB
  echo  -w   WimBoot file
  echo.
  goto end

:nextParam
  shift /1
  goto checkParams

:getParam
  set arg=%1
  for %%A IN (f,h,i,l,s,w) do (if [%arg:~1,1%] equ [%%A] goto %%A)
  echo invalid parameters %arg% && goto help

:f
  shift /1
  set _vhdx=%1
  goto nextParam

:i
  shift /1
  set _index=%1
  goto nextParam

:s
  shift /1
  set _vhdx_size=%1
  goto nextParam

:l
  shift /1
  set _label=%1
  goto nextParam

:w
  shift /1
  set _wimfile=%1
  goto nextParam

rem *** Create a VHDX with GPT. Create EFI, MSR and NTFS partition ***
rem %1: vhdx file
rem %2: vhdx file size
rem %3: NTFS partition label
:vhdx
if [%1] == [] echo please specify a vhdx file name && goto error
if exist %1 echo vhdx file %1 already exist && goto error
rem if [%2] == [] set _vhdx_size=20480
rem if [%3] == [] set _label="New Volume"

(echo create vdisk file=%1 type=expandable maximum=%2
echo attach vdisk
echo convert gpt
echo select part 1
echo delete part override
echo create part efi size=100
echo format quick fs=fat32 label="EFI"
echo assign
echo create part msr size=16
echo create part primary
echo format quick fs=ntfs label=%3
echo assign) | diskpart
exit /b

rem *** Apply WIM image file ***
rem %1: vhdx file
rem %2: wim file name
rem %3: wIM file index
:dism
if [%1] == [] echo wimfile not found: %1 && goto error
if [%2] == [] echo wimfile index not found: %2 && goto error

call :getLetter %1 1
set bootLetter=%_result%

call :getLetter %1 3
set srcLetter=%_result%

dism /Apply-Image /ImageFile:"%2" /Index:%3 /ApplyDir:%srcLetter%:\
bcdboot %srcLetter%:\windows /s %bootLetter%: /f uefi

exit /b

rem *** getLetter ***
rem %1: vhdx file name
rem %2: index of partition
:getLetter
setlocal enableDelayedExpansion

set script=( ^
  echo select vdisk file=%1 ^
& echo attach disk ^
& echo select part %2 ^
& echo list volume ^
) ^
| diskpart ^
| findstr /c:"* Volume"

for /f "tokens=4 usebackq" %%i in (`!script!`) do (
  set letter=%%i
)

endlocal & set _result=%letter%
exit /b

:main
call :vhdx %_vhdx% %_vhdx_size% %_label%
call :dism %_vhdx% %_wimfile% %_index%
goto end

:error
endlocal
if %errorLevel% NEQ 0 set errorlevel=1
exit /b %errorlevel%

:end
endlocal
exit /b 0