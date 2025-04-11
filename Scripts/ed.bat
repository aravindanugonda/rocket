@echo off  
echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====  
echo Calling environment setup...  

rem Use the short (8.3) path for SetupEnv.bat to avoid issues.  
call "C:\PROGRA~2\Micro Focus\Enterprise Developer\SetupEnv.bat" 32  
set RETCODE=%ERRORLEVEL%  

echo Setup completed with return code: %RETCODE%  

rem Use quotes when testing or echoing the variable   
if "%COBDIR%"=="" (  
  echo ERROR: Environment setup failed - COBDIR not set.  
  exit /b 1  
) else (  
  echo COBDIR is set to: "%COBDIR%"  
  echo Environment setup successful.  
)  

exit /b %RETCODE%  
