@echo off
REM Minimal build script for testing basic cobol execution v2
REM Assumes COBDIR, PATH, LIB, INCLUDE etc are set by the caller (ed.bat via GITHUB_ENV)

setlocal enabledelayedexpansion

REM --- Parameters (use defaults for SHARED) ---
set "modtype=CBL"
set "modname=TESTCBL"
set "target_env=SHARED"
if not "%1"=="" set modtype=%1
if not "%2"=="" set modname=%2
if not "%3"=="" set target_env=%3
echo DEBUG Minimal: Type=!modtype!, Name=!modname!, Env=!target_env!

REM --- Essential Paths (Keep consistent) ---
set "source_base=C:\Build\Rehost"
set "loadlib=C:\Build\Rehost\loadlib"
set "listing=C:\Build\Rehost\listing"
set "directives_path=C:\ES\SHARED\DIRECTIVES"
set "source_file=!source_base!\!modname!.cbl"
set "directives_file=!directives_path!\CBL.dir" # Using default for simplicity

REM --- Verify Environment ---
echo DEBUG Minimal: Verifying Environment...
if not defined COBDIR ( echo ERROR Minimal: COBDIR missing & exit /b 98 )
if not defined PATH ( echo ERROR Minimal: PATH missing & exit /b 98 )
echo DEBUG Minimal: COBDIR is !COBDIR!
rem Use findstr to check PATH contains the bin directory
echo "!PATH!" | findstr /i /c:"!COBDIR!bin" > nul
if errorlevel 1 ( echo WARNING Minimal: PATH missing MF BIN! & exit /b 97 )
echo DEBUG Minimal: Environment appears OK.

REM --- Ensure CRITICAL Directories Exist (Minimal) ---
if not exist "!loadlib!" mkdir "!loadlib!" 2>nul
if not exist "!listing!" mkdir "!listing!" 2>nul
if not exist "!directives_path!" mkdir "!directives_path!" 2>nul
REM Assume source file exists via Copy step in YAML

REM --- Ensure Default Directive File Exists ---
 if not exist "!directives_file!" (
    echo DEBUG Minimal: Creating default directive file: !directives_file!
    (echo sourcetabs& echo cicsecm(int)& echo charset(ascii)& echo dialect(mf)& echo anim) > "!directives_file!"
    if not exist "!directives_file!" (echo ERROR Minimal: Failed to create directives & exit /b 96)
 ) else (
    echo DEBUG Minimal: Default directive file exists: !directives_file!
 )


REM --- Construct and Execute COBOL Command ---
set "COBOL_CMD_LINE=cobol "!source_file!",nul,"!listing!\!modname!.lst",nul, ANIM GNT("!loadlib!\!modname!.gnt") COBIDY("!loadlib!") USE("!directives_file!") NOQUERY ;"
echo DEBUG Minimal: Preparing to execute: %COBOL_CMD_LINE%

(call ) REM Reset errorlevel just before execution
%COBOL_CMD_LINE%
set compile_rc=!errorlevel!
echo DEBUG Minimal: COBOL command finished. RC = !compile_rc!

exit /b !compile_rc!
