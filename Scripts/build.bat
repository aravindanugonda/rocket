@echo off
setlocal enabledelayedexpansion

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

REM ... (SECTION 2: INITIALIZATION ) ...
:INIT
REM Normalize parameters ... (OK) ...
for /f "tokens=*" %%V in ('powershell -command "$ENV:modtype.toUpper()"') do set modtype=%%V
for /f "tokens=*" %%V in ('powershell -command "$ENV:modname.toUpper()"') do set modname=%%V
for /f "tokens=*" %%V in ('powershell -command "$ENV:target_env.toUpper()"') do set target_env=%%V

set mydate=%date:/=-%
set mydate=%mydate: =%
set mytime=%time::=.%
set mytime=%mytime: =%

echo DEBUG build.bat: Verifying pre-set environment...
if not defined COBDIR ( /* ... exit ... */ ) else ( echo DEBUG build.bat: COBDIR is !COBDIR! )
echo DEBUG build.bat: Checking PATH...
echo PATH=!PATH!
set "MFBIN_PATH=!COBDIR!bin"
echo "!PATH!" | findstr /i /c:"!MFBIN_PATH!" > nul
if errorlevel 1 ( /* ... warning ... */ ) else ( echo DEBUG build.bat: Found !MFBIN_PATH! in PATH. )

set logfile=%logdir%\Compile_%mydate%_%mytime%.log

rem Create directories - Add check for C:\Temp
if not exist "C:\Temp" mkdir "C:\Temp"
if not exist "!loadlib!" mkdir "!loadlib!"
if not exist "!listing!" mkdir "!listing!"
if not exist "!logdir!" mkdir "!logdir!"
if not exist "!execpath!" mkdir "!execpath!"
REM Check errorlevel after mkdir? Maybe later if needed. For now, assume they work or fail silently if path issue resolved.

REM =====================================================================
REM === SECTION 3: COMPILATION LOGIC                                ===
REM =====================================================================
:COMPILE
echo =================================================================== >> "!logfile!"
echo === COMPILING !modtype! MODULE: !modname! for !target_env! environment >> "!logfile!"
echo =================================================================== >> "!logfile!"
echo === COMPILING !modtype! MODULE: !modname! for !target_env! environment

if /i "!modtype!"=="BMS" (
  call :COMPILE_BMS
) else if /i "!modtype!"=="CBL" 
  call :COMPILE_COBOL
) else (                        
  echo ERROR: Invalid module type specified: !modtype! >> "!logfile!"
  echo ERROR: Invalid module type specified: !modtype!
  echo Valid types are BMS or CBL
  exit /b 12
)

set "_rc=!errorlevel!"
goto :EXIT

REM =====================================================================
REM === SECTION 5: COBOL COMPILATION                                ===
REM =====================================================================
:COMPILE_COBOL
echo Compiling COBOL program: !modname! >> "!logfile!"
echo Compiling COBOL program: !modname!

REM Check bypass ... (OK) ...
for %%G in (%BYPASSCBL%) do ( if /i "%%~G"=="!modname!" ( exit /b 1 ) )

set "source_file=!cbl_dir!\!modname!.cbl"
if not exist "!source_file!" ( /* ... error exit ... */ )

REM --- Debugging Directives Logic ---
set "directives=C:\ES\SHARED\DIRECTIVES\!modname!.dir" # Initial attempt path
set "directives_mod=!directives!" # Save it

echo DEBUG: Checking for module-specific directives: "!directives_mod!" # Line 98 printed OK

echo DEBUG: About to run DIR command on "!directives_mod!"
dir "!directives_mod!" # Temporarily remove redirection > nul 2> nul
set DIR_RC=!errorlevel!
echo DEBUG: DIR command finished with errorlevel: !DIR_RC!

if !DIR_RC! EQU 0 goto ModuleDirectiveFound # Use EQU for clarity, check for 0 explicitly

echo DEBUG: Module-specific directives NOT found or inaccessible (DIR RC: !DIR_RC!).
set "directives=C:\ES\SHARED\DIRECTIVES\CBL.dir" # Set path to default
echo DEBUG: Checking for default directives: "!directives!"

echo DEBUG: About to run DIR command on "!directives!"
dir "!directives!" # Temporarily remove redirection > nul 2> nul
set DIR_RC_DEFAULT=!errorlevel!
echo DEBUG: DIR command finished with errorlevel: !DIR_RC_DEFAULT!

if !DIR_RC_DEFAULT! EQU 0 goto DefaultDirectiveFound

rem --- Default not found either, create it ---
echo DEBUG: Default directives NOT found or inaccessible (DIR RC: !DIR_RC_DEFAULT!). Creating default file...
echo Creating default directive file: !directives! >> "!logfile!"
echo Creating default directive file: !directives!
if not exist "C:\ES\SHARED\DIRECTIVES" (
    echo DEBUG: Creating directory C:\ES\SHARED\DIRECTIVES
    mkdir "C:\ES\SHARED\DIRECTIVES"
)
(
    echo sourcetabs
    echo cicsecm(int)
    echo charset(ascii)
    echo dialect(mf)
    echo anim
) > "!directives!"
rem Check if creation worked
dir "!directives!" > nul 2> nul
if errorlevel 1 (
    echo ERROR: Failed to create or access default directives file !directives! after attempting creation. >> "!logfile!"
    echo ERROR: Failed to create or access default directives file !directives! after attempting creation.
    exit /b 97
) else (
    echo DEBUG: Default directives file created successfully.
)
goto SetCobcpy # Jump past the "found" messages

:ModuleDirectiveFound
echo DEBUG: Found existing module-specific directives file: !directives_mod!
set "directives=!directives_mod!" # Ensure 'directives' holds the found module-specific path
goto SetCobcpy

:DefaultDirectiveFound
echo DEBUG: Found existing default directives file: !directives!
# 'directives' variable already holds the correct default path
goto SetCobcpy

:SetCobcpy
echo DEBUG: Using directives file: !directives!

REM Setup COBCPY environment ... (OK) ...
set "COBCPY=!bms_cpy!;!cpy_dir!;%COBCPY%"
echo Using COBCPY=!COBCPY!>> "!logfile!"

REM Run the compilation ... (OK) ...
echo cobol "!source_file!",nul,"!listing!\!modname!.lst",nul, ANIM GNT("!loadlib!\!modname!.gnt") COBIDY("!loadlib!") USE("!directives!") NOQUERY ;>> "!logfile!"
cobol "!source_file!",nul,"!listing!\!modname!.lst",nul, ANIM GNT("!loadlib!\!modname!.gnt") COBIDY("!loadlib!") USE("!directives!") NOQUERY ;>> "!logfile!" 2>&1

set "_sub_rc=!errorlevel!"

REM Copy compiled files ... (OK) ...
if !_sub_rc! leq 8 ( /* ... copy ... */ ) else ( /* ... echo skip ... */ )

exit /b !_sub_rc!

REM ... ( :EXIT section - OK) ...
:EXIT
echo Compilation complete with return code %_rc% >> "!logfile!"
echo Compilation complete with return code %_rc%
exit /b %_rc%
