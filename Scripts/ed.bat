@echo off
setlocal enabledelayedexpansion

echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====

set "TEMP_ENV_FILE=%TEMP%\ed_env_vars_%RANDOM%.tmp"
echo DEBUG: Using temp file: !TEMP_ENV_FILE!
if exist "!TEMP_ENV_FILE!" del "!TEMP_ENV_FILE!"

set "SETUP_SCRIPT_PATH=C:\Program Files (x86)\Micro Focus\Enterprise Developer\SetupEnv.bat"
echo DEBUG: SETUP_SCRIPT_PATH is !SETUP_SCRIPT_PATH!

if not exist "!SETUP_SCRIPT_PATH!" (
  echo ERROR: Setup script not found at !SETUP_SCRIPT_PATH!
  exit /b 9009
)

set "CORE_CMD=call "!SETUP_SCRIPT_PATH!" 32 && (echo RETCODE_INNER=0& set COBDIR& set PATH& set LIB& set INCLUDE& set CLASSPATH) || (echo RETCODE_INNER=1& set COBDIR& set PATH& set LIB& set INCLUDE& set CLASSPATH)"
echo DEBUG: Prepared core command to capture multiple variables.
echo DEBUG: Will execute: cmd /c "!CORE_CMD!" > "!TEMP_ENV_FILE!"

cmd /c "!CORE_CMD!" > "!TEMP_ENV_FILE!"
set CALL_EXITCODE=!ERRORLEVEL!
echo DEBUG: Sub-shell execution finished with exit code: !CALL_EXITCODE! # Line 47 OK

rem --- *** SIMPLIFIED Check if temp file was created *** ---
if not exist "!TEMP_ENV_FILE!" (
  echo ERROR: Temp environment file was not created. Exit code: !CALL_EXITCODE!
  exit /b 2
)
echo DEBUG: Temp file found. Skipping size/exit code check for now.
rem --- *** END SIMPLIFIED Check *** ---

rem --- Removed the complex FOR loop block temporarily ---
rem for %%F in ("!TEMP_ENV_FILE!") do if %%~zF==0 (
rem   if !CALL_EXITCODE! NEQ 0 if !CALL_EXITCODE! NEQ 1 (
rem      echo ERROR: Temp file empty/small and failure exit code !CALL_EXITCODE!.
rem      del "!TEMP_ENV_FILE!"
rem      exit /b 3
rem   )
rem )


echo DEBUG: Attempting to parse temp file "!TEMP_ENV_FILE!": # Should execute next
type "!TEMP_ENV_FILE!"
echo DEBUG: --- End of temp file contents ---

rem --- Parse the temp file to get ALL variables back ---
set RETCODE=999
set COBDIR=
set ED_PATH=
set ED_LIB=
set ED_INCLUDE=
set ED_CLASSPATH=

for /f "usebackq tokens=1* delims==" %%a in ("!TEMP_ENV_FILE!") do (
  for /f "tokens=* delims= " %%X in ("%%a") do set "varName=%%X"
  for /f "tokens=* delims= " %%Y in ("%%b") do set "varValue=%%Y"
  if /i "!varName!"=="RETCODE_INNER" set RETCODE=!varValue!
  if /i "!varName!"=="COBDIR" set COBDIR=!varValue!
  if /i "!varName!"=="Path" set ED_PATH=!varValue!
  if /i "!varName!"=="LIB" set ED_LIB=!varValue!
  if /i "!varName!"=="INCLUDE" set ED_INCLUDE=!varValue!
  if /i "!varName!"=="CLASSPATH" set ED_CLASSPATH=!varValue!
)

if exist "!TEMP_ENV_FILE!" del "!TEMP_ENV_FILE!"

echo Setup script sub-shell completed with internal return code: !RETCODE!
echo COBDIR captured: !COBDIR!
echo PATH captured: !ED_PATH!

rem --- Proceed only if setup succeeded ---
rem Use goto logic again to avoid the parenthesis bug if it's still present
if !RETCODE! EQU 0 goto SetupSuccess_Isolated

echo ERROR: Environment setup script failed in sub-shell with code !RETCODE!.
exit /b !RETCODE!

:SetupSuccess_Isolated
echo DEBUG: RETCODE was 0, proceeding...

rem Use goto logic for checks
if not "!COBDIR!"=="" goto CheckPathCaptured_Isolated
echo ERROR: COBDIR was NOT captured. & exit /b 1

:CheckPathCaptured_Isolated
if not "!ED_PATH!"=="" goto CobdirCleanup_Isolated
echo ERROR: PATH was NOT captured. & exit /b 1

:CobdirCleanup_Isolated
REM Add checks for LIB/INCLUDE if critical here using goto

rem --- Cleanup COBDIR captured ---
set "COBDIR_CLEAN=!COBDIR:"=!"
if not "!COBDIR_CLEAN:~-1!"==";" goto ExportVars_Isolated
set "COBDIR_CLEAN=!COBDIR_CLEAN:~0,-1!"

:ExportVars_Isolated
echo DEBUG: Cleaned COBDIR is: !COBDIR_CLEAN!

rem --- Export ALL required variables to GitHub Actions environment ---
if not defined GITHUB_ENV goto GithubEnvNotDefined_Isolated
echo COBDIR=!COBDIR_CLEAN!>>"%GITHUB_ENV%"
echo PATH=!ED_PATH!>>"%GITHUB_ENV%"
echo LIB=!ED_LIB!>>"%GITHUB_ENV%"
echo INCLUDE=!ED_INCLUDE!>>"%GITHUB_ENV%"
echo CLASSPATH=!ED_CLASSPATH!>>"%GITHUB_ENV%"
echo DEBUG: Exported ED environment variables to GITHUB_ENV file "%GITHUB_ENV%".
goto EndScript_Isolated

:GithubEnvNotDefined_Isolated
echo WARNING: GITHUB_ENV variable not found. Cannot export environment.

:EndScript_Isolated
echo Environment setup successful.
exit /b 0
