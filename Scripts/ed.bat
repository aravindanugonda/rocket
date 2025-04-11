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

rem --- Construct the CORE command to run inside cmd /c ---
rem REMOVED extra quotes from beginning and end of the value being assigned
set "CORE_CMD=call "!SETUP_SCRIPT_PATH!" 32 && (echo RETCODE_INNER=0& set COBDIR) || (echo RETCODE_INNER=1& set COBDIR)"

echo DEBUG: Prepared core command. Value assigned is:
rem Using echo.!VAR! is safer for potentially complex strings
echo.!CORE_CMD!
echo DEBUG: --- End of Prepared core command value ---
echo DEBUG: Will execute: cmd /c "!CORE_CMD!" > "!TEMP_ENV_FILE!"

rem --- Execute cmd /c with the core command, redirecting output HERE ---
rem Ensure the command passed to /c is quoted, as it contains spaces/special chars
cmd /c "!CORE_CMD!" > "!TEMP_ENV_FILE!"
set CALL_EXITCODE=!ERRORLEVEL!
echo DEBUG: Sub-shell execution finished with exit code: !CALL_EXITCODE!

rem --- Check if temp file was created and has content ---
if not exist "!TEMP_ENV_FILE!" (
  echo ERROR: Temp environment file was not created. Redirection or sub-shell failed. Exit code: !CALL_EXITCODE!
  exit /b 2
)
for %%F in ("!TEMP_ENV_FILE!") do if %%~zF==0 (
  if !CALL_EXITCODE! NEQ 0 if !CALL_EXITCODE! NEQ 1 (
     echo ERROR: Temp file empty/small and sub-shell exit code !CALL_EXITCODE! indicates failure.
     del "!TEMP_ENV_FILE!"
     exit /b 3
  ) else (
     echo DEBUG: Temp file empty or small, but exit code !CALL_EXITCODE! might be expected on SetupEnv failure. Proceeding to parse.
  )
)

echo DEBUG: Attempting to parse temp file "!TEMP_ENV_FILE!":
type "!TEMP_ENV_FILE!"
echo DEBUG: --- End of temp file contents ---

rem --- Parse the temp file to get variables back ---
set RETCODE=999
set COBDIR=
for /f "usebackq tokens=1* delims==" %%a in ("!TEMP_ENV_FILE!") do (
  echo DEBUG: Parsing line: "%%a=%%b"
  for /f "tokens=* delims= " %%X in ("%%a") do set "varName=%%X"
  for /f "tokens=* delims= " %%Y in ("%%b") do set "varValue=%%Y"
  if /i "!varName!"=="RETCODE_INNER" set RETCODE=!varValue!
  if /i "!varName!"=="COBDIR" set COBDIR=!varValue!
)

if exist "!TEMP_ENV_FILE!" del "!TEMP_ENV_FILE!"

echo Setup script sub-shell completed with internal return code: !RETCODE!
echo COBDIR captured from sub-shell: !COBDIR!

rem --- Now perform checks using the captured values ---
if !RETCODE! EQU 0 goto SetupSuccess

echo ERROR: Environment setup script failed in sub-shell with code !RETCODE!.
exit /b !RETCODE!

:SetupSuccess
echo DEBUG: RETCODE was 0, proceeding...

if "!COBDIR!"=="" (
  echo ERROR: Setup script succeeded (RETCODE=0) but COBDIR was NOT captured or was empty from sub-shell. Check temp file parsing.
  exit /b 1
)

rem --- Cleanup COBDIR captured ---
set "COBDIR_CLEAN=!COBDIR:"=!"
if "!COBDIR_CLEAN:~-1!"==";" (
  set "COBDIR_CLEAN=!COBDIR_CLEAN:~0,-1!"
)
echo DEBUG: Cleaned COBDIR is: !COBDIR_CLEAN!

rem --- Export variable to GitHub Actions environment ---
if defined GITHUB_ENV (
  echo COBDIR=!COBDIR_CLEAN!>>"%GITHUB_ENV%"
  echo DEBUG: Exported COBDIR=!COBDIR_CLEAN! to GITHUB_ENV file "%GITHUB_ENV%".
) else (
  echo WARNING: GITHUB_ENV variable not found. Cannot export COBDIR to workflow environment.
)

echo Environment setup successful.

exit /b 0
