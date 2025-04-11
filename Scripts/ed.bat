@echo off
setlocal enabledelayedexpansion  REM <--- Enable Delayed Expansion

echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====
echo Calling environment setup...

rem Use the short (8.3) path for SetupEnv.bat to avoid issues.
call "C:\PROGRA~2\Micro Focus\Enterprise Developer\SetupEnv.bat" 32
set RETCODE=!ERRORLEVEL!  REM <--- Use !ERRORLEVEL!

rem Check COBDIR immediately after call, using delayed expansion
if defined COBDIR (
  REM Use !COBDIR! for potentially problematic variable content
  set "COBDIR=!COBDIR:"=!"
  if "!COBDIR:~-1!"==";" (
    set "COBDIR=!COBDIR:~0,-1!"
  )
)

echo Setup completed with return code: !RETCODE! REM <--- Use !RETCODE!

rem Use !COBDIR! for the check and echo
if "!COBDIR!"=="" (
  echo ERROR: Environment setup failed - COBDIR not set.
  exit /b 1
) else (
  echo COBDIR is set to: !COBDIR! REM <--- Use !COBDIR!
  echo Environment setup successful.
)

exit /b !RETCODE! REM <--- Use !RETCODE!
