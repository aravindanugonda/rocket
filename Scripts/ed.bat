@echo off
setlocal enabledelayedexpansion

echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====
echo Calling environment setup...

REM --- Attempt to clear COBDIR first to ensure a clean test ---
set COBDIR=

REM --- Use the full path via environment variable for better reliability ---
set SETUP_SCRIPT="%ProgramFiles(x86)%\Micro Focus\Enterprise Developer\SetupEnv.bat"
REM --- Optional: Add a check if the script exists ---
if not exist %SETUP_SCRIPT% (
  echo ERROR: Setup script not found at %SETUP_SCRIPT%
  exit /b 9009
)

call %SETUP_SCRIPT% 32
set RETCODE=!ERRORLEVEL!

echo Setup script call completed with return code: !RETCODE!

REM --- **** Check the return code FIRST **** ---
if !RETCODE! NEQ 0 (
  echo ERROR: Environment setup script failed with code !RETCODE!.
  REM --- Optionally check COBDIR even on failure for diagnostics ---
  if defined COBDIR (
    echo DIAGNOSTIC: COBDIR was set to !COBDIR! despite setup failure.
  ) else (
    echo DIAGNOSTIC: COBDIR was not set.
  )
  exit /b !RETCODE!
)

REM --- If RETCODE is 0, *now* check COBDIR as a secondary validation ---
if not defined COBDIR (
  echo ERROR: Setup script succeeded (RETCODE=0) but COBDIR is NOT set.
  exit /b 1
)

REM --- Optional: Cleanup COBDIR (quotes/semicolons) ---
set "COBDIR=!COBDIR:"=!"
if "!COBDIR:~-1!"==";" (
  set "COBDIR=!COBDIR:~0,-1!"
)

echo COBDIR is set to: !COBDIR!
echo Environment setup successful.

exit /b 0
