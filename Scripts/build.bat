@echo off  
setlocal enabledelayedexpansion  

REM =====================================================================  
REM === CONSOLIDATED COBOL AND BMS COMPILATION SCRIPT                 ===  
REM =====================================================================  

REM =====================================================================  
REM === SECTION 1: CONFIGURABLE PARAMETERS                           ===  
REM =====================================================================  

:PARAMETERS  
REM Base directories - Modify these for your environment  
set base=C:\Build\Rehost
set build_base=C:\Build\Rehost
set source_base=C:\Build\Rehost
set loadlib=%build_base%\loadlib  
set listing=%build_base%\listing  
set logdir=C:\Temp\logs  

REM Copybook directories  
set cpy_dir=%source_base%
set bms_cpy=%source_base%

REM Default directories for types  
set cbl_dir=%source_base%
set bms_dir=%source_base%

REM Type of file to compile and name  
set modtype=%1  
set modname=%2  

REM Target execution path - will be set based on environment  
if "%3"=="" (  
  set target_env=CICSTSTQ  
) else (  
  set target_env=%3  
)  

REM Set the target execution path based on environment  
set execpath=C:\ES\%target_env%\LOADLIB

REM COBOL programs to bypass compilation  
set BYPASSCBL="XXXXXXXX"  

REM =====================================================================  
REM === SECTION 2: INITIALIZATION                                    ===  
REM =====================================================================  

:INIT  
REM Normalize parameters  
for /f "tokens=*" %%V in ('powershell -command "$ENV:modtype.toUpper()"') do set modtype=%%V  
for /f "tokens=*" %%V in ('powershell -command "$ENV:modname.toUpper()"') do set modname=%%V  
for /f "tokens=*" %%V in ('powershell -command "$ENV:target_env.toUpper()"') do set target_env=%%V  

REM Set date and time for logging  
set mydate=%date:/=-%  
set mydate=%mydate: =%  
set mytime=%time::=.%  
set mytime=%mytime: =%  

REM Setup Enterprise Developer environment if not already set  
if not defined COBDIR (  
  echo Setting up Enterprise Developer environment...  
  call "%ProgramFiles(x86)%\Micro Focus\Enterprise Developer\SetupEnv.bat" 32
  echo COBDIR set to: %COBDIR% 
)  

REM Set log file  
set logfile=%logdir%\Compile_%mydate%_%mytime%.log  

REM Create directories if they don't exist  
if not exist "%source_base%" mkdir "%source_base%"  
if not exist "%cpy_dir%" mkdir "%cpy_dir%"  
if not exist "%bms_cpy%" mkdir "%bms_cpy%"  
if not exist "%cbl_dir%" mkdir "%cbl_dir%"  
if not exist "%bms_dir%" mkdir "%bms_dir%"  
if not exist "%loadlib%" mkdir "%loadlib%"  
if not exist "%logdir%" mkdir "%logdir%"  
if not exist "%execpath%" mkdir "%execpath%"  

REM =====================================================================  
REM === SECTION 3: COMPILATION LOGIC                                 ===  
REM =====================================================================  

:COMPILE  
echo ===================================================================  
echo === COMPILING %modtype% MODULE: %modname% for %target_env% environment  
echo ===================================================================  
echo ===================================================================>> %logfile%  
echo === COMPILING %modtype% MODULE: %modname% for %target_env% environment>> %logfile%  
echo ===================================================================>> %logfile%  

if "%modtype%"=="BMS" (  
  call :COMPILE_BMS  
) else if "%modtype%"=="CBL" (  
  call :COMPILE_COBOL  
) else (  
  echo ERROR: Invalid module type specified: %modtype%  
  echo Valid types are BMS or CBL  
  exit /b 12  
)  

goto :EXIT  

REM =====================================================================  
REM === SECTION 4: BMS COMPILATION                                   ===  
REM =====================================================================  

:COMPILE_BMS  
echo Compiling BMS map: %modname%  
echo Compiling BMS map: %modname%>> %logfile%  

set source_file=%bms_dir%\%modname%.bms  
if not exist "%source_file%" (  
  echo ERROR: BMS source file not found: %source_file%  
  echo ERROR: BMS source file not found: %source_file%>> %logfile%  
  exit /b 8  
)  

echo MFBMSCL %source_file% /BINARY=%loadlib%\ /COBOL="%bms_cpy%"\ /VERBOSE /SDF /HLL /IGNORE /SYSPARM=MAP /SYSPARM=DSECT /MAP=%modname% /DSECT=%modname%>> %logfile%  
MFBMSCL %source_file% /BINARY=%loadlib%\ /COBOL="%bms_cpy%"\ /VERBOSE /SDF /HLL /IGNORE /SYSPARM=MAP /SYSPARM=DSECT /MAP=%modname% /DSECT=%modname%>> %logfile% 2>&1  

set _rc=%errorlevel%  

REM Copy .cpy file if generated  
if exist "%modname%.cpy" (  
  move /Y "%modname%.cpy" "%bms_cpy%\%modname%.cpy">> %logfile% 2>&1  
  echo Moved copybook to %bms_cpy%\%modname%.cpy  
  echo Moved copybook to %bms_cpy%\%modname%.cpy>> %logfile%  
)  

REM Copy compiled module to target execution directory  
if %_rc% leq 8 (  
  copy /Y "%loadlib%\%modname%.MOD" "%execpath%\%modname%.MOD">> %logfile% 2>&1  
  echo Copied compiled module to %execpath%\%modname%.MOD  
  echo Copied compiled module to %execpath%\%modname%.MOD>> %logfile%  
)  

exit /b %_rc%  

REM =====================================================================  
REM === SECTION 5: COBOL COMPILATION                                 ===  
REM =====================================================================  

:COMPILE_COBOL  
echo Compiling COBOL program: %modname%  
echo Compiling COBOL program: %modname%>> %logfile%  

REM Check if in bypass list  
for %%G in (%BYPASSCBL%) do (  
  if "%%~G"=="%modname%" (  
    echo Bypassing %modname% - Marked as Do Not Compile  
    echo Bypassing %modname% - Marked as Do Not Compile>> %logfile%  
    exit /b 1  
  )  
)  

set source_file=%cbl_dir%\%modname%.cbl  
if not exist "%source_file%" (  
  echo ERROR: COBOL source file not found: %source_file%  
  echo ERROR: COBOL source file not found: %source_file%>> %logfile%  
  exit /b 8  
)  

REM Get directives file  
set directives=C:\ES\SHARED\DIRECTIVES\%modname%.dir  
if not exist "%directives%" (  
  set directives=C:\ES\SHARED\DIRECTIVES\CBL.dir  
  
  REM Create default directive file if it doesn't exist  
  if not exist "%directives%" (  
    echo Creating default directive file: %directives%  
    echo Creating default directive file: %directives%>> %logfile%  
    
    if not exist "%build_base%\directives" mkdir "%build_base%\directives"  
    
    echo sourcetabs >> "%directives%"  
    echo cicsecm(int) >> "%directives%"  
    echo charset(ascii) >> "%directives%"  
    echo dialect(mf) >> "%directives%"  
    echo anim >> "%directives%"  
  )  
)  

REM Setup COBCPY environment  
set COBCPY=%bms_cpy%;%cpy_dir%;%COBCPY%  
echo Using COBCPY=%COBCPY%>> %logfile%  

REM Run the compilation  
echo cobol %source_file%,nul, %listing%\%modname%.lst,nul, ANIM GNT(%loadlib%\%modname%.gnt) COBIDY(%loadlib%) USE(%directives%) NOQUERY ;>> %logfile%  
cobol %source_file%,nul, %listing%\%modname%.lst,nul, ANIM GNT(%loadlib%\%modname%.gnt) COBIDY(%loadlib%) USE(%directives%) NOQUERY ;>> %logfile% 2>&1  

set _rc=%errorlevel%  

REM Copy compiled files to execution directory if successful  
if %_rc% leq 8 (  
  copy /Y "%loadlib%\%modname%.gnt" "%execpath%\%modname%.gnt">> %logfile% 2>&1  
  copy /Y "%loadlib%\%modname%.idy" "%execpath%\%modname%.idy">> %logfile% 2>&1  
  echo Copied compiled files to execution directory: %execpath%  
  echo Copied compiled files to execution directory: %execpath%>> %logfile%  
)  

exit /b %_rc%  

REM =====================================================================  
REM === SECTION 6: EXIT                                              ===  
REM =====================================================================  

:EXIT  
echo Compilation complete with return code %_rc%  
echo Compilation complete with return code %_rc%>> %logfile%  
exit /b %_rc%  
