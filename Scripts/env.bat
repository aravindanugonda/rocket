@echo off  
setlocal EnableDelayedExpansion  

rem Call SetupEnv.bat using the short path to avoid spacing issues:  
call "C:\PROGRA~2\Micro Focus\Enterprise Developer\SetupEnv.bat" 32  
set SETUP_RESULT=%ERRORLEVEL%  

rem At this point, SetupEnv.bat’s temporary file should have been called and its environment applied.  
rem To "export" variables like COBDIR beyond the setlocal block,  
rem write them to a temporary file and then import.  
if defined COBDIR (  
    echo set "COBDIR=%COBDIR%" > "%TEMP%\setenvvars.bat"  
) else (  
    rem If COBDIR wasn’t set, still write an empty value if needed:  
    echo set "COBDIR=" > "%TEMP%\setenvvars.bat"  
)  

rem End the local block and import the variable  
endlocal & call "%TEMP%\setenvvars.bat"  

exit /b %SETUP_RESULT%  
