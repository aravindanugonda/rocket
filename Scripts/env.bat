@echo off  
setlocal  

rem Use the short path version to avoid spaces and parentheses issues  
set "setupPath=C:\PROGRA~2\Micro Focus\Enterprise Developer\SetupEnv.bat"  

echo Calling SetupEnv.bat using: %setupPath% 32  
call "%setupPath%" 32
