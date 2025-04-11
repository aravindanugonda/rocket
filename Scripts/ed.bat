@echo off  
setlocal enabledelayedexpansion  

echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====  
echo Input parameter: %1  
set ARCH=32  
if "%1"=="64" set ARCH=64  

echo Setting up Enterprise Developer %ARCH%-bit environment...  

set MF_ROOT=%ProgramFiles(x86)%\Micro Focus\Enterprise Developer  
echo MF_ROOT: !MF_ROOT!  

echo Calling SetupEnv.bat...  
call "!MF_ROOT!\SetupEnv.bat" %ARCH%  
set SETUP_RESULT=%ERRORLEVEL%  

echo SetupEnv.bat completed with return code: %SETUP_RESULT%  

if defined COBDIR (  
  echo COBDIR is set to: %COBDIR%  
  echo Enterprise Developer setup successful  
) else (  
  echo ERROR: COBDIR not set - environment setup failed  
  exit /b 1  
)  

echo PATH: %PATH%  
echo.  
echo Environment setup complete.  
exit /b 0
