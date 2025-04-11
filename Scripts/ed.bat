@echo off
setlocal enabledelayedexpansion

echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====
echo Calling environment setup...

rem --- Attempt to clear COBDIR first to ensure a clean test ---
set COBDIR=

rem --- Use the full path via environment variable for better reliability ---
set SETUP_SCRIPT="%ProgramFiles(x86)%\Micro Focus\Enterprise Developer\SetupEnv.bat"
rem --- Optional: Add a check if the script exists ---
if not exist %SETUP_SCRIPT% (
  echo ERROR: Setup script not found at %SETUP_SCRIPT%
  exit /b 9009
)

call %SETUP_SCRIPT% 32
set RETCODE=!ERRORLEVEL!

echo Setup script call completed with return code: !RETCODE!

rem --- **** SAFE ECHO FOR DEBUGGING **** ---
echo DEBUG: Displaying COBDIR value safely using 'set':
set COBDIR
echo DEBUG: End of COBDIR display.
rem --- **** END DEBUGGING ECHO **** ---

rem --- Check the return code FIRST ---
if !RETCODE! NEQ 0 (
  echo ERROR: Environment setup script failed with code !RETCODE!.
  rem --- Optionally check COBDIR even on failure for diagnostics ---
  if defined COBDIR (
    echo DIAGNOSTIC: COBDIR was set to !COBDIR! despite setup failure.
  ) else (
    echo DIAGNOSTIC: COBDIR was not set.
  )
  exit /b !RETCODE!
)

rem --- If RETCODE is 0, *now* check COBDIR as a secondary validation ---
if not defined COBDIR (
  echo ERROR: Setup script succeeded (RETCODE=0) but COBDIR is NOT set.
  exit /b 1
)

rem --- Optional: Cleanup COBDIR (quotes/semicolons) ---
rem --- **** TEMPORARILY COMMENTED OUT FOR DEBUGGING **** ---
rem set "COBDIR=!COBDIR:"=!"
rem if "!COBDIR:~-1!"==";" (
rem   set "COBDIR=!COBDIR:~0,-1!"
rem )
echo DEBUG: Skipping COBDIR cleanup steps.

rem --- Use potentially safer echo method ---
echo COBDIR is set to (raw value):
echo.!COBDIR!
echo Environment setup successful.

exit /b 0
