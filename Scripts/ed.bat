@echo off
setlocal enabledelayedexpansion

echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====
echo Calling environment setup...

set COBDIR=

set SETUP_SCRIPT="%ProgramFiles(x86)%\Micro Focus\Enterprise Developer\SetupEnv.bat"
if not exist %SETUP_SCRIPT% (
  echo ERROR: Setup script not found at %SETUP_SCRIPT%
  exit /b 9009
)

call %SETUP_SCRIPT% 32
set RETCODE=!ERRORLEVEL!

echo Setup script call completed with return code: !RETCODE!

rem --- Check the return code FIRST ---
if !RETCODE! NEQ 0 (
  echo ERROR: Environment setup script failed with code !RETCODE!.
  exit /b !RETCODE!
)

rem --- Check COBDIR definition (secondary validation) ---
if not defined COBDIR (
  echo ERROR: Setup script succeeded (RETCODE=0) but COBDIR is NOT set.
  exit /b 1
)

rem --- Restore Cleanup Logic ---
echo DEBUG: Cleaning up COBDIR variable...
set "COBDIR_CLEAN=!COBDIR:"=!"
if "!COBDIR_CLEAN:~-1!"==";" (
  set "COBDIR_CLEAN=!COBDIR_CLEAN:~0,-1!"
)
echo DEBUG: Cleaned COBDIR value: !COBDIR_CLEAN!

rem --- Persist variable for subsequent GitHub Actions steps ---
echo Persisting COBDIR for GitHub Actions environment...
echo COBDIR=!COBDIR_CLEAN!>> %GITHUB_ENV% 
if !ERRORLEVEL! NEQ 0 (
   echo ERROR: Failed to write COBDIR to GITHUB_ENV file: %GITHUB_ENV%
   exit /b 1
)

echo Environment setup successful. Script will exit 0.

exit /b 0
