@echo off  
setlocal enabledelayedexpansion  

echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====  
echo Input parameter: %1  
set ARCH=32  
if "%1"=="64" set ARCH=64  

echo Setting up Enterprise Developer %ARCH%-bit environment...  

rem Define the setup path with proper quoting  
set "MF_ROOT=%ProgramFiles(x86)%\Micro Focus\Enterprise Developer"  
set "SETUP_SCRIPT=%MF_ROOT%\SetupEnv.bat"  

echo Setup script: "!SETUP_SCRIPT!"  

rem Call SetupEnv with explicit quotes  
call "!SETUP_SCRIPT!" %ARCH%  
set SETUP_RESULT=%ERRORLEVEL%  

echo SetupEnv.bat completed with return code: %SETUP_RESULT%  

if defined COBDIR (  
  echo COBDIR is set to: %COBDIR%  
  echo Enterprise Developer setup successful  
) else (  
  echo ERROR: COBDIR not set - environment setup failed  
  exit /b 1  
)  

exit /b 0
