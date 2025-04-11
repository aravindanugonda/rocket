@echo off  
setlocal  

echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====  

echo Calling environment setup...  
call Scripts\env.bat  
echo Setup completed with return code: %ERRORLEVEL%  

if defined COBDIR (  
  echo COBDIR is set to: %COBDIR%  
  echo Environment setup successful  
) else (  
  echo ERROR: Environment setup failed - COBDIR not set  
  exit /b 1  
)  

exit /b 0  
