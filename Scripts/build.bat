@echo off
setlocal enabledelayedexpansion

REM =====================================================================
REM === CONSOLIDATED COBOL AND BMS COMPILATION SCRIPT                 ===
REM === Assumes Micro Focus Env (COBDIR, PATH, LIB etc) is PRE-SET    ===
REM =====================================================================

REM ... (SECTION 1: PARAMETERS) ...
:PARAMETERS
set base=C:\Build\Rehost
set build_base=C:\Build\Rehost
set source_base=C:\Build\Rehost
set loadlib=%build_base%\loadlib
set listing=%build_base%\listing
set logdir=C:\Temp\logs
set cpy_dir=%source_base%
set bms_cpy=%source_base%
set cbl_dir=%source_base%
set bms_dir=%source_base%
set modtype=%1
set modname=%2
if "%3"=="" ( set target_env=CICSTSTQ ) else ( set target_env=%3 )
set execpath=C:\ES\%target_env%\LOADLIB
set BYPASSCBL="XXXXXXXX"

REM ... (SECTION 2: INITIALIZATION) ...
:INIT
REM Normalize parameters
for /f "tokens=*" %%V in ('powershell -command "$ENV:modtype.toUpper()"') do set modtype=%%V
for /f "tokens=*" %%V in ('powershell -command "$ENV:modname.toUpper()"') do set modname=%%V
for /f "tokens=*" %%V in ('powershell -command "$ENV:target_env.toUpper()"') do set target_env=%%V

set mydate=%date:/=-%
set mydate=%mydate: =%
set mytime=%time::=.%
set mytime=%mytime: =%

echo DEBUG build.bat: Verifying pre-set environment...
if not defined COBDIR (
  echo ERROR in build.bat: COBDIR is not defined! Environment setup failed earlier.
  exit /b 98
) else (
  echo DEBUG build.bat: COBDIR is !COBDIR!
)
REM *** ADD PATH CHECK ***
echo DEBUG build.bat: Checking PATH...
echo PATH=!PATH!
REM Check if path contains cobdir\bin 
set "MFBIN_PATH=!COBDIR!bin"
echo "!PATH!" | findstr /i /c:"!MFBIN_PATH!" > nul
if errorlevel 1 (
  echo WARNING in build.bat: PATH does not seem to contain !MFBIN_PATH!
  echo WARNING in build.bat: COBOL command may fail to find cobol.exe
) else (
  echo DEBUG build.bat: Found !MFBIN_PATH! in PATH.
)
REM *** END PATH CHECK ***


set logfile=%logdir%\Compile_%mydate%_%mytime%.log

rem Create directories needed by this script 
if not exist "!loadlib!" mkdir "!loadlib!"
if not exist "!listing!" mkdir "!listing!"
if not exist "!logdir!" mkdir "!logdir!"
if not exist "!execpath!" mkdir "!execpath!"

REM =====================================================================
REM === SECTION 3: COMPILATION LOGIC                                  ===
REM =====================================================================
:COMPILE
echo =================================================================== >> "!logfile!"
echo === COMPILING !modtype! MODULE: !modname! for !target_env! environment >> "!logfile!"
echo =================================================================== >> "!logfile!"
echo === COMPILING !modtype! MODULE: !modname! for !target_env! environment

if /i "!modtype!"=="BMS" (
  call :COMPILE_BMS
) else if /i "!modtype!"=="CBL" (
  call :COMPILE_COBOL
) else (
  echo ERROR: Invalid module type specified: !modtype! >> "!logfile!"
  echo ERROR: Invalid module type specified: !modtype!
  echo Valid types are BMS or CBL
  exit /b 12
)

rem --- Capture the actual return code from the called subroutine ---
set "_rc=!errorlevel!"  # <-- *** FIX: Capture errorlevel here ***
goto :EXIT

REM =====================================================================
REM === SECTION 4: BMS COMPILATION                                    ===
REM =====================================================================
:COMPILE_BMS
echo Compiling BMS map: !modname! >> "!logfile!"
echo Compiling BMS map: !modname!

set "source_file=!bms_dir!\!modname!.bms"
if not exist "!source_file!" (
  echo ERROR: BMS source file not found: !source_file! >> "!logfile!"
  echo ERROR: BMS source file not found: !source_file!
  exit /b 8
)

echo MFBMSCL "!source_file!" /BINARY="!loadlib!\" /COBOL="!bms_cpy!\" /VERBOSE /SDF /HLL /IGNORE /SYSPARM=MAP /SYSPARM=DSECT /MAP=!modname! /DSECT=!modname! >> "!logfile!"
MFBMSCL "!source_file!" /BINARY="!loadlib!\" /COBOL="!bms_cpy!\" /VERBOSE /SDF /HLL /IGNORE /SYSPARM=MAP /SYSPARM=DSECT /MAP=!modname! /DSECT=!modname! >> "!logfile!" 2>&1

set "_sub_rc=!errorlevel!"

REM Copy .cpy file if generated (use !modname!)
if exist "!modname!.cpy" (
  move /Y "!modname!.cpy" "!bms_cpy!\!modname!.cpy" >> "!logfile!" 2>&1
  echo Moved copybook to !bms_cpy!\!modname!.cpy >> "!logfile!"
  echo Moved copybook to !bms_cpy!\!modname!.cpy
)

REM Copy compiled module to target execution directory (use !modname!)
if !_sub_rc! leq 8 (
  copy /Y "!loadlib!\!modname!.MOD" "!execpath!\!modname!.MOD" >> "!logfile!" 2>&1
  echo Copied compiled module to !execpath!\!modname!.MOD >> "!logfile!"
  echo Copied compiled module to !execpath!\!modname!.MOD
)

exit /b !_sub_rc!

REM =====================================================================
REM === SECTION 5: COBOL COMPILATION                                  ===
REM =====================================================================
:COMPILE_COBOL
echo Compiling COBOL program: !modname! >> "!logfile!"
echo Compiling COBOL program: !modname!

REM Check if in bypass list (Use standard expansion for FOR variable)
for %%G in (%BYPASSCBL%) do (
  if /i "%%~G"=="!modname!" (
    echo Bypassing !modname! - Marked as Do Not Compile >> "!logfile!"
    echo Bypassing !modname! - Marked as Do Not Compile
    exit /b 1 # Exit cleanly for bypass
  )
)

set "source_file=!cbl_dir!\!modname!.cbl"
if not exist "!source_file!" (
  echo ERROR: COBOL source file not found: !source_file! >> "!logfile!"
  echo ERROR: COBOL source file not found: !source_file!
  exit /b 8
)

REM Get directives file
set "directives=C:\ES\SHARED\DIRECTIVES\!modname!.dir"
if not exist "!directives!" (
  set "directives=C:\ES\SHARED\DIRECTIVES\CBL.dir"
  if not exist "!directives!" (
    echo Creating default directive file: !directives! >> "!logfile!"
    echo Creating default directive file: !directives!
    if not exist "C:\ES\SHARED\DIRECTIVES" mkdir "C:\ES\SHARED\DIRECTIVES"
    (
        echo sourcetabs
        echo cicsecm(int)
        echo charset(ascii)
        echo dialect(mf)
        echo anim
    ) > "!directives!"
  )
)

REM Setup COBCPY environment - Append BMS/CPY dirs to existing COBCPY
set "COBCPY=!bms_cpy!;!cpy_dir!;%COBCPY%" # Use !...! for local dirs, %...% for inherited COBCPY
echo Using COBCPY=!COBCPY!>> "!logfile!"

REM Run the compilation - Use !...! for variables, quote paths
echo cobol "!source_file!",nul,"!listing!\!modname!.lst",nul, ANIM GNT("!loadlib!\!modname!.gnt") COBIDY("!loadlib!") USE("!directives!") NOQUERY ;>> "!logfile!"
cobol "!source_file!",nul,"!listing!\!modname!.lst",nul, ANIM GNT("!loadlib!\!modname!.gnt") COBIDY("!loadlib!") USE("!directives!") NOQUERY ;>> "!logfile!" 2>&1

set "_sub_rc=!errorlevel!"

REM Copy compiled files to execution directory if successful
if !_sub_rc! leq 8 (
  echo DEBUG: Compile RC= !_sub_rc!, copying files... >> "!logfile!"
  copy /Y "!loadlib!\!modname!.gnt" "!execpath!\!modname!.gnt" >> "!logfile!" 2>&1
  copy /Y "!loadlib%\!modname%.idy" "!execpath%\!modname%.idy" >> "!logfile!" 2>&1 # Corrected path separator
  echo Copied compiled files to execution directory: !execpath! >> "!logfile!"
  echo Copied compiled files to execution directory: !execpath!
) else (
  echo DEBUG: Compile RC= !_sub_rc!, skipping copy. >> "!logfile!"
)

exit /b !_sub_rc!

REM =====================================================================
REM === SECTION 6: EXIT                                               ===
REM =====================================================================
:EXIT
echo Compilation complete with return code %_rc% >> "!logfile!" # Use standard % here is OK
echo Compilation complete with return code %_rc%
exit /b %_rc% # Use standard % here is OK
