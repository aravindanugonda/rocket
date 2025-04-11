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

rem --- **** DEBUGGING STEP: DUMP ALL ENV VARS **** ---
echo DEBUG: Displaying ALL environment variables using 'set':
set
echo DEBUG: End of ALL variable display.
rem --- **** END DEBUGGING STEP **** ---

rem --- Check the return code FIRST ---
if !RETCODE! NEQ 0 (
  echo ERROR: Environment setup script failed with code !RETCODE!.
  exit /b !RETCODE!
)

rem --- Check COBDIR definition (secondary validation) ---
rem --- **** TEMPORARILY COMMENTED OUT FOR DEBUGGING **** ---
rem if not defined COBDIR (
rem   echo ERROR: Setup script succeeded (RETCODE=0) but COBDIR is NOT set.
rem   exit /b 1
rem )
echo DEBUG: Skipping 'if not defined COBDIR' check.


rem --- Optional: Cleanup COBDIR (quotes/semicolons) ---
rem --- **** TEMPORARILY COMMENTED OUT FOR DEBUGGING **** ---
rem set "COBDIR=!COBDIR:"=!"
rem if "!COBDIR:~-1!"==";" (
rem   set "COBDIR=!COBDIR:~0,-1!"
rem )
echo DEBUG: Skipping COBDIR cleanup steps.


rem --- Use potentially safer echo method ---
echo COBDIR is set to (raw value):
rem Using 'set COBDIR' is safest for display if !COBDIR! contains poison chars
set COBDIR
rem echo.!COBDIR!
echo Environment setup successful.

exit /b 0
