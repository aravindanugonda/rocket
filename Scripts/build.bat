@echo off
setlocal enabledelayedexpansion

REM =====================================================================
REM === CONSOLIDATED COBOL AND BMS COMPILATION SCRIPT                 ===
REM === v2025-04-11e - CLEANED VERSION: Removed ALL trailing # comments ===
REM === Retains GOTO workarounds, explicit errorlevel capture,        ===
REM === enhanced logging, robust mkdir.                               ===
REM === Assumes Micro Focus Env (COBDIR, PATH, LIB etc) is PRE-SET  ===
REM =====================================================================

REM =====================================================================
REM === SECTION 1: CONFIGURABLE PARAMETERS                          ===
REM =====================================================================

:PARAMETERS
REM Base directories
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

REM Input Parameters
set modtype=%1
set modname=%2
if "%3"=="" ( set target_env=SHARED ) else ( set target_env=%3 )
set execpath=C:\ES\%target_env%\LOADLIB
set BYPASSCBL="XXXXXXXX"

REM =====================================================================
REM === SECTION 2: INITIALIZATION                                   ===
REM =====================================================================

:INIT
REM Ensure C:\Temp exists early on, as log dir is under it
if not exist "C:\Temp" mkdir "C:\Temp" 2>nul

REM Normalize parameters using PowerShell for case-insensitivity
for /f "tokens=*" %%V in ('powershell -command "$ENV:modtype.toUpper()"') do set modtype=%%V
for /f "tokens=*" %%V in ('powershell -command "$ENV:modname.toUpper()"') do set modname=%%V
for /f "tokens=*" %%V in ('powershell -command "$ENV:target_env.toUpper()"') do set target_env=%%V

REM Generate Date/Time stamp for log file
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

echo DEBUG build.bat: Checking PATH...
echo PATH=!PATH!
set "MFBIN_PATH=!COBDIR!bin"
REM Use findstr to check if the path fragment exists (case insensitive)
echo "!PATH!" | findstr /i /c:"!MFBIN_PATH!" > nul
if errorlevel 1 (
  echo WARNING in build.bat: PATH does not seem to contain !MFBIN_PATH! Compile may fail.
) else (
  echo DEBUG build.bat: Found !MFBIN_PATH! in PATH.
)

rem Define log file path
set logfile=%logdir%\Compile_!mydate!_!mytime!.log
echo DEBUG: Logfile path set to: "!logfile!"

rem Create ALL potentially needed directories robustly, ignoring errors if they exist
echo DEBUG: Ensuring base directories exist (errors ignored)...
if not exist "C:\Build" mkdir "C:\Build" 2>nul
if not exist "!build_base!" mkdir "!build_base!" 2>nul
if not exist "C:\Temp" mkdir "C:\Temp" 2>nul
if not exist "!loadlib!" mkdir "!loadlib!" 2>nul
if not exist "!listing!" mkdir "!listing!" 2>nul
if not exist "!logdir!" mkdir "!logdir!" 2>nul
if not exist "C:\ES" mkdir "C:\ES" 2>nul
if not exist "C:\ES\SHARED" mkdir "C:\ES\SHARED" 2>nul
if not exist "C:\ES\SHARED\DIRECTIVES" mkdir "C:\ES\SHARED\DIRECTIVES" 2>nul
if not exist "C:\ES\!target_env!" mkdir "C:\ES\!target_env!" 2>nul
if not exist "!execpath!" mkdir "!execpath!" 2>nul
echo DEBUG: Finished ensuring directories (errors ignored).

REM =====================================================================
REM === SECTION 3: COMPILATION LOGIC (Using GOTO for dispatch)      ===
REM =====================================================================
:COMPILE
rem --- Ensure log directory exists RIGHT before first write ---
echo DEBUG: Final check for log directory: "!logdir!"
if not exist "!logdir!" mkdir "!logdir!" 2>nul
rem Final check - Abort if log dir is unusable
if not exist "!logdir!" (
  echo ERROR: Failed to create or find log directory: !logdir! Cannot proceed.
  exit /b 96
) else (
  echo DEBUG: Log directory confirmed. Proceeding to log header.
)

rem --- Start Logging ---
echo =================================================================== >> "!logfile!"
echo === COMPILING !modtype! MODULE: !modname! for !target_env! environment >> "!logfile!"
echo =================================================================== >> "!logfile!"
echo === COMPILING !modtype! MODULE: !modname! for !target_env! environment

rem --- Use GOTO for dispatch to avoid potential IF/ELSE IF/ELSE syntax issues ---
echo DEBUG: Dispatching based on modtype '!modtype!'...
if /i "!modtype!"=="BMS" goto CallCompileBMS
if /i "!modtype!"=="CBL" goto CallCompileCBL

rem --- Handle Invalid Type ---
echo ERROR: Invalid module type specified: !modtype! >> "!logfile!"
echo ERROR: Invalid module type specified: !modtype!
echo Valid types are BMS or CBL
exit /b 12

:CallCompileBMS
echo DEBUG: Jumping to :COMPILE_BMS...
call :COMPILE_BMS
set "_rc=!errorlevel!"
goto :EXIT

:CallCompileCBL
echo DEBUG: Jumping to :COMPILE_COBOL...
call :COMPILE_COBOL
set "_rc=!errorlevel!"
goto :EXIT

REM =====================================================================
REM === SECTION 4: BMS COMPILATION (Using !var! and !_sub_rc!)      ===
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

set "BMS_CMD_LINE=MFBMSCL "!source_file!" /BINARY="!loadlib!\" /COBOL="!bms_cpy!\" /VERBOSE /SDF /HLL /IGNORE /SYSPARM=MAP /SYSPARM=DSECT /MAP=!modname! /DSECT=!modname!"
echo INFO: Preparing to execute BMS compile command. >> "!logfile!"
echo CMD: %BMS_CMD_LINE% >> "!logfile!"
echo INFO: Executing BMS command...

(call )
%BMS_CMD_LINE% >> "!logfile!" 2>&1
set "_sub_rc=!errorlevel!"

echo INFO: BMS Compile command finished. Captured Return Code: !_sub_rc! >> "!logfile!"
echo INFO: BMS Compile command finished. Captured Return Code: !_sub_rc!

REM Copy .cpy file if generated
if exist "!modname!.cpy" (
  move /Y "!modname!.cpy" "!bms_cpy!\!modname!.cpy" >> "!logfile!" 2>&1
  echo Moved copybook to !bms_cpy!\!modname!.cpy >> "!logfile!"
  echo Moved copybook to !bms_cpy!\!modname!.cpy
)

REM Copy compiled module to target execution directory
if !_sub_rc! leq 8 (
  echo INFO: BMS Compile RC= !_sub_rc! (Success/Warning), copying output file... >> "!logfile!"
  copy /Y "!loadlib!\!modname!.MOD" "!execpath!\!modname!.MOD" >> "!logfile!" 2>&1
  echo Copied compiled module to !execpath!\!modname!.MOD >> "!logfile!"
  echo Copied compiled module to !execpath!\!modname!.MOD
) else (
  echo ERROR: BMS Compile RC= !_sub_rc! (Failure), skipping copy. >> "!logfile!"
  echo ERROR: BMS Compile RC= !_sub_rc! (Failure), skipping copy.
)

exit /b !_sub_rc!

REM =====================================================================
REM === SECTION 5: COBOL COMPILATION (Using GOTO, !var!, logging)   ===
REM =====================================================================
:COMPILE_COBOL
echo Compiling COBOL program: !modname! >> "!logfile!"
echo Compiling COBOL program: !modname!

rem Check bypass
for %%G in (%BYPASSCBL%) do ( if /i "%%~G"=="!modname!" ( echo Bypassing !modname! >> "!logfile!" & echo Bypassing !modname! & exit /b 1 ) )

set "source_file=!cbl_dir!\!modname!.cbl"
if not exist "!source_file!" ( echo ERROR: COBOL source file not found: !source_file! >> "!logfile!" & echo ERROR: COBOL source file not found: !source_file! & exit /b 8 )

rem --- Get directives file using GOTO logic ---
set "directives=C:\ES\SHARED\DIRECTIVES\!modname!.dir"
set "directives_mod=!directives!"
echo DEBUG: Checking for module-specific directives: "!directives_mod!" >> "!logfile!"
dir "!directives_mod!" > nul 2> nul
if !errorlevel! EQU 0 goto ModuleDirectiveFound_CBL_Final

echo DEBUG: Module-specific directives NOT found. Checking default. >> "!logfile!"
set "directives=C:\ES\SHARED\DIRECTIVES\CBL.dir"
echo DEBUG: Checking for default directives: "!directives!" >> "!logfile!"
dir "!directives!" > nul 2> nul
if !errorlevel! EQU 0 goto DefaultDirectiveFound_CBL_Final

echo DEBUG: Default directives NOT found. Creating default file... >> "!logfile!"
echo Creating default directive file: !directives! >> "!logfile!"
echo Creating default directive file: !directives!
rem Directory should exist from :INIT, but check again just in case
if not exist "C:\ES\SHARED\DIRECTIVES" mkdir "C:\ES\SHARED\DIRECTIVES" 2>nul
( echo sourcetabs & echo cicsecm(int) & echo charset(ascii) & echo dialect(mf) & echo anim ) > "!directives!"
dir "!directives!" > nul 2> nul
if errorlevel 1 ( echo ERROR: Failed to create default directives file !directives! >> "!logfile!" & echo ERROR: Failed to create default directives file !directives! & exit /b 97 )
echo DEBUG: Default directives file created successfully. >> "!logfile!"
goto SetCobcpy_CBL_Final

:ModuleDirectiveFound_CBL_Final
echo DEBUG: Found existing module-specific directives file: !directives_mod! >> "!logfile!"
set "directives=!directives_mod!"
goto SetCobcpy_CBL_Final

:DefaultDirectiveFound_CBL_Final
echo DEBUG: Found existing default directives file: !directives! >> "!logfile!"
goto SetCobcpy_CBL_Final

:SetCobcpy_CBL_Final
echo DEBUG: Using directives file: !directives! >> "!logfile!"
echo DEBUG: Using directives file: !directives!

rem Setup COBCPY environment
set "COBCPY=!bms_cpy!;!cpy_dir!;%COBCPY%"
echo Using COBCPY=!COBCPY!>> "!logfile!"

rem --- Enhanced Logging Around Compilation ---
set "COBOL_CMD_LINE=cobol "!source_file!",nul,"!listing!\!modname!.lst",nul, ANIM GNT("!loadlib!\!modname!.gnt") COBIDY("!loadlib!") USE("!directives!") NOQUERY ;"
echo INFO: Preparing to execute COBOL compile command. >> "!logfile!"
echo CMD: %COBOL_CMD_LINE% >> "!logfile!"

rem --- Execute the Compilation ---
echo INFO: Executing COBOL command...
(call )
%COBOL_CMD_LINE% >> "!logfile!" 2>&1
set "_sub_rc=!errorlevel!"

rem Log the result
echo INFO: COBOL Compile command finished. Captured Return Code: !_sub_rc! >> "!logfile!"
echo INFO: COBOL Compile command finished. Captured Return Code: !_sub_rc!

rem --- Decide whether to copy files based on captured RC using GOTO ---
if !_sub_rc! GTR 8 goto SkipFileCopyOnError_CBL

rem --- This section runs only if _sub_rc is LEQ 8 (Success or Warning) ---
echo INFO: Compile RC= !_sub_rc! (Success or Warning), copying output files... >> "!logfile!"
echo INFO: Compile RC= !_sub_rc! (Success or Warning), copying output files...
copy /Y "!loadlib!\!modname!.gnt" "!execpath!\!modname!.gnt" >> "!logfile!" 2>&1
copy /Y "!loadlib!\!modname!.idy" "!execpath!\!modname!.idy" >> "!logfile!" 2>&1
rem Check for .bnd file existence before copying - use GOTO here too for safety
if not exist "!loadlib!\!modname!.bnd" goto SkipBndCopy_Final_CBL
copy /Y "!loadlib!\!modname!.bnd" "!execpath!\!modname!.bnd" >> "!logfile!" 2>&1
:SkipBndCopy_Final_CBL
echo Copied compiled files to execution directory: !execpath! >> "!logfile!"
echo Copied compiled files to execution directory: !execpath!
goto EndCobolSubroutine_CBL

:SkipFileCopyOnError_CBL
rem --- This section runs only if _sub_rc is GTR 8 (Failure) ---
echo ERROR: Compile RC= !_sub_rc! (Failure), skipping copy of output files. >> "!logfile!"
echo ERROR: Compile RC= !_sub_rc! (Failure), skipping copy of output files.

:EndCobolSubroutine_CBL
exit /b !_sub_rc!

REM =====================================================================
REM === SECTION 6: EXIT                                             ===
REM =====================================================================
:EXIT
rem _rc was set right after the CALL in the :COMPILE section
echo Compilation complete with final overall return code %_rc% >> "!logfile!"
echo Compilation complete with final overall return code %_rc%
exit /b %_rc%
