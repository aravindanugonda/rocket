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

rem --- Check the return code FIRST using goto ---
rem If RETCODE is 0, jump to the SetupSuccess label
if !RETCODE! EQU 0 goto SetupSuccess

rem --- This code only runs if RETCODE is NOT 0 ---
echo ERROR: Environment setup script failed with code !RETCODE!.
exit /b !RETCODE!


:SetupSuccess
rem --- Label indicating the setup script call was successful (RETCODE=0) ---
echo DEBUG: RETCODE was 0, proceeding...

rem --- Check COBDIR definition (secondary validation) ---
rem This IF statement is further down and should be okay
if not defined COBDIR (
  echo ERROR: Setup script succeeded (RETCODE=0) but COBDIR is NOT set.
  exit /b 1
)

rem --- Cleanup COBDIR (remove quotes, trailing semicolon) ---
set "COBDIR_CLEAN=!COBDIR:"=!"
if "!COBDIR_CLEAN:~-1!"==";" (
  set "COBDIR_CLEAN=!COBDIR_CLEAN:~0,-1!"
)
echo DEBUG: Original COBDIR was: !COBDIR!
echo DEBUG: Cleaned COBDIR is: !COBDIR_CLEAN!

rem --- Export variable to GitHub Actions environment ---
if defined GITHUB_ENV (
  echo COBDIR=!COBDIR_CLEAN!>>"%GITHUB_ENV%"
  echo DEBUG: Exported COBDIR=!COBDIR_CLEAN! to GITHUB_ENV file.
) else (
  echo WARNING: GITHUB_ENV variable not found. Cannot export COBDIR to workflow environment.
)

echo Environment setup successful.

exit /b 0
