@echo off  
setlocal enabledelayedexpansion  

echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====  
echo Input parameter: %1  
set ARCH=32  
if "%1"=="64" set ARCH=64  

echo Setting up Enterprise Developer %ARCH%-bit environment...  

rem Use short path format to avoid parentheses problems  
for /f "delims=" %%i in ('dir /x /b "%ProgramFiles(x86)%\Micro Focus\Enterprise Developer\SetupEnv.bat"') do set SETUP_PATH=%ProgramFiles(x86)%\MICROS~1\ENTERP~1\%%i  

echo Using setup path: !SETUP_PATH!  

rem Call SetupEnv using the short path  
call !SETUP_PATH! %ARCH%  
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
