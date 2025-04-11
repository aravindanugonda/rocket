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

set "CORE_CMD=call "!SETUP_SCRIPT_PATH!" 32 && (echo RETCODE_INNER=0& set COBDIR) || (echo RETCODE_INNER=1& set COBDIR)"
echo DEBUG: Prepared core command. Value assigned is:
echo.!CORE_CMD!
echo DEBUG: --- End of Prepared core command value ---
echo DEBUG: Will execute: cmd /c "!CORE_CMD!" > "!TEMP_ENV_FILE!"

cmd /c "!CORE_CMD!" > "!TEMP_ENV_FILE!"
set CALL_EXITCODE=!ERRORLEVEL!
echo DEBUG: Sub-shell execution finished with exit code: !CALL_EXITCODE!

if not exist "!TEMP_ENV_FILE!" (
  echo ERROR: Temp environment file was not created. Exit code: !CALL_EXITCODE!
  exit /b 2
)
for %%F in ("!TEMP_ENV_FILE!") do if %%~zF==0 (
  if !CALL_EXITCODE! NEQ 0 if !CALL_EXITCODE! NEQ 1 (
     echo ERROR: Temp file empty/small and failure exit code !CALL_EXITCODE!.
     del "!TEMP_ENV_FILE!"
     exit /b 3
  )
)

echo DEBUG: Attempting to parse temp file "!TEMP_ENV_FILE!":
type "!TEMP_ENV_FILE!"
echo DEBUG: --- End of temp file contents ---

set RETCODE=999
set COBDIR=
for /f "usebackq tokens=1* delims==" %%a in ("!TEMP_ENV_FILE!") do (
  for /f "tokens=* delims= " %%X in ("%%a") do set "varName=%%X"
  for /f "tokens=* delims= " %%Y in ("%%b") do set "varValue=%%Y"
  if /i "!varName!"=="RETCODE_INNER" set RETCODE=!varValue!
  if /i "!varName!"=="COBDIR" set COBDIR=!varValue!
)

if exist "!TEMP_ENV_FILE!" del "!TEMP_ENV_FILE!"

echo Setup script sub-shell completed with internal return code: !RETCODE!
echo COBDIR captured from sub-shell: !COBDIR!

rem --- Perform checks using captured values ---
if !RETCODE! EQU 0 goto CheckCobdirCaptured
echo ERROR: Environment setup script failed in sub-shell with code !RETCODE!.
exit /b !RETCODE!

:CheckCobdirCaptured
echo DEBUG: RETCODE was 0, proceeding...
rem Replace 'if "!COBDIR!"=="" (' with goto logic
if not "!COBDIR!"=="" goto CobdirOk
echo ERROR: Setup script succeeded (RETCODE=0) but COBDIR was NOT captured or was empty from sub-shell.
exit /b 1

:CobdirOk
echo DEBUG: COBDIR was captured successfully.

rem --- Cleanup COBDIR captured ---
set "COBDIR_CLEAN=!COBDIR:"=!"
rem Replace 'if "!COBDIR_CLEAN:~-1!"==";" (' with goto logic
if not "!COBDIR_CLEAN:~-1!"==";" goto SkipSemicolonRemoval
set "COBDIR_CLEAN=!COBDIR_CLEAN:~0,-1!"
:SkipSemicolonRemoval
echo DEBUG: Cleaned COBDIR is: !COBDIR_CLEAN!

rem --- Export variable to GitHub Actions environment ---
rem Replace 'if defined GITHUB_ENV (' with goto logic
if not defined GITHUB_ENV goto GithubEnvNotDefined
echo COBDIR=!COBDIR_CLEAN!>>"%GITHUB_ENV%"
echo DEBUG: Exported COBDIR=!COBDIR_CLEAN! to GITHUB_ENV file "%GITHUB_ENV%".
goto EndScript

:GithubEnvNotDefined
echo WARNING: GITHUB_ENV variable not found. Cannot export COBDIR to workflow environment.

:EndScript
echo Environment setup successful.
exit /b 0
