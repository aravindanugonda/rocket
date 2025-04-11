@echo off  
rem =============================  
rem Merged Setup Script  
rem =============================  
rem We enable delayed expansion and use a temporary file trick so that any  
rem environment variables (like COBDIR) set by SetupEnv.bat (which uses a temporary  
rem file internally) are exported back to the main environment.  
setlocal EnableDelayedExpansion  

echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====  
echo Calling environment setup...  

rem Use the short (8.3) path to avoid issues with spaces and parentheses.  
call "C:\PROGRA~2\Micro Focus\Enterprise Developer\SetupEnv.bat" 32  
set RETCODE=%ERRORLEVEL%  

rem Now, export COBDIR (or any variable) to a temporary file  
if defined COBDIR (  
    echo set "COBDIR=%COBDIR%" > "%TEMP%\setenvvars.bat"  
) else (  
    echo set "COBDIR=" > "%TEMP%\setenvvars.bat"  
)  

rem End the local block while importing the temporary file that restores COBDIR.  
endlocal & call "%TEMP%\setenvvars.bat"  
del /q "%TEMP%\setenvvars.bat"  

echo Setup completed with return code: %RETCODE%  

if defined COBDIR (  
  echo COBDIR is set to: %COBDIR%  
  echo Environment setup successful.  
) else (  
  echo ERROR: Environment setup failed - COBDIR not set.  
  exit /b 1  
)  

exit /b %RETCODE%  
