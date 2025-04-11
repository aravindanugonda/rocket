@echo off
setlocal enabledelayedexpansion

echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====
echo Calling environment setup...

rem --- Attempt to clear COBDIR first ---
set COBDIR=

rem --- Use the full path ---
set SETUP_SCRIPT="%ProgramFiles(x86)%\Micro Focus\Enterprise Developer\SetupEnv.bat"
if not exist %SETUP_SCRIPT% (
  echo ERROR: Setup script not found at %SETUP_SCRIPT%
  exit /b 9009
)

call %SETUP_SCRIPT% 32
set RETCODE=!ERRORLEVEL!

echo Setup script call completed with return code: !RETCODE!

rem --- Debug Checkpoints ---
echo DEBUG: Checkpoint 1 (Before RETCODE check line).
echo DEBUG: Checkpoint 2 (Before simplified IF statement).

rem --- **** SIMPLIFIED IF STATEMENT (NO BLOCK) **** ---
rem Test if the comparison itself works without the parentheses block
if !RETCODE! NEQ 0 echo DEBUG: RETCODE was non-zero! This should NOT print if RETCODE is 0.

rem --- If the above line passes without error, the original issue was likely the (...) block ---
rem --- If the above line still fails, the issue is deeper with IF or !RETCODE! parsing ---

echo DEBUG: Checkpoint 3 (After simplified IF statement).

rem --- Temporarily comment out the rest of the script ---
REM if !RETCODE! NEQ 0 (
REM   echo ERROR: Environment setup script failed with code !RETCODE!.
REM   exit /b !RETCODE!
REM )

REM if not defined COBDIR (
REM   echo ERROR: Setup script succeeded (RETCODE=0) but COBDIR is NOT set.
REM   exit /b 1
REM )

REM set "COBDIR_CLEAN=!COBDIR:"=!"
REM if "!COBDIR_CLEAN:~-1!"==";" (
REM   set "COBDIR_CLEAN=!COBDIR_CLEAN:~0,-1!"
REM )
REM echo DEBUG: Original COBDIR was: !COBDIR!
REM echo DEBUG: Cleaned COBDIR is: !COBDIR_CLEAN!

REM if defined GITHUB_ENV (
REM   echo COBDIR=!COBDIR_CLEAN!>>"%GITHUB_ENV%"
REM   echo DEBUG: Exported COBDIR=!COBDIR_CLEAN! to GITHUB_ENV file.
REM ) else (
REM   echo WARNING: GITHUB_ENV variable not found. Cannot export COBDIR to workflow environment.
REM )

REM echo Environment setup successful.
REM exit /b 0
rem --- End of temporarily commented out section ---


echo DEBUG: Script reached end (temporarily). Testing IF statement only.
exit /b 99 # Use a distinct exit code for this test run
