@echo off  
echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====  
echo Calling environment setup...  

rem Use the short (8.3) path for SetupEnv.bat to avoid issues with spaces and parentheses.  
call "C:\PROGRA~2\Micro Focus\Enterprise Developer\SetupEnv.bat" 32  
set RETCODE=%ERRORLEVEL%  

echo Setup completed with return code: %RETCODE%  

if defined COBDIR (  
  echo COBDIR is set to: %COBDIR%  
  echo Environment setup successful.  
) else (  
  echo ERROR: Environment setup failed - COBDIR not set.  
  exit /b 1  
)  

exit /b %RETCODE%  
