@echo off  
setlocal  

echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====  
echo Input parameter: %1  

echo Calling environment setup...  
set "setupPath=C:\PROGRA~2\Micro Focus\Enterprise Developer\SetupEnv.bat"  

echo Calling SetupEnv.bat using: %setupPath% 32  
call "%setupPath%" 32

echo Setup completed with return code: %ERRORLEVEL%  

if defined COBDIR (  
  echo COBDIR is set to: %COBDIR%  
  echo Environment setup successful  
) else (  
  echo ERROR: Environment setup failed - COBDIR not set  
  exit /b 1  
)  

exit /b 0
