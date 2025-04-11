@echo off
setlocal enabledelayedexpansion

echo ===== ENTERPRISE DEVELOPER ENVIRONMENT SETUP =====

rem Define temp file path using system %TEMP% variable
set "TEMP_ENV_FILE=%TEMP%\ed_env_vars_%RANDOM%.tmp"
echo DEBUG: Using temp file: %TEMP_ENV_FILE%
rem Ensure temp file doesn't exist from a previous failed run
if exist "%TEMP_ENV_FILE%" del "%TEMP_ENV_FILE%"

rem --- Prepare the command to run SetupEnv in a subshell and capture vars ---
rem Use full path for safety
set "SETUP_SCRIPT_PATH=C:\Program Files (x86)\Micro Focus\Enterprise Developer\SetupEnv.bat"

rem Check if SetupEnv.bat actually exists before trying to run the sub-command
if not exist "%SETUP_SCRIPT_PATH%" (
  echo ERROR: Setup script not found at %SETUP_SCRIPT_PATH%
  exit /b 9009
)

rem The command below does:
rem 1. Start cmd /c "..." - Run commands in a new cmd process and exit
rem 2. Inside "": call SetupEnv.bat 32
rem 3. && (...) - If call succeeds (ERRORLEVEL 0): echo custom RETCODE=0 and run 'set COBDIR' (prints COBDIR=value)
rem 4. || (...) - If call fails (ERRORLEVEL non-0): echo custom RETCODE=1 and run 'set COBDIR' (might print nothing or old value)
rem 5. > "%TEMP_ENV_FILE%" - Redirect all output (RETCODE and set COBDIR) to the temp file
set "SUB_CMD=cmd /c ""call "%SETUP_SCRIPT_PATH%" 32 && (echo RETCODE_INNER=0& set COBDIR) || (echo RETCODE_INNER=1& set COBDIR)"" > "%TEMP_ENV_FILE%""

echo DEBUG: Prepared sub-command to run.
rem Echoing the command itself might be complex due to quotes, skip for now unless needed

rem --- Execute the sub-command ---
echo DEBUG: Executing SetupEnv.bat in isolated sub-shell...
%SUB_CMD%
set CALL_EXITCODE=!ERRORLEVEL!
echo DEBUG: Sub-shell execution finished with exit code: !CALL_EXITCODE!

rem --- Check if temp file was created and has content ---
if not exist "%TEMP_ENV_FILE%" (
  echo ERROR: Temp environment file was not created. Sub-shell failed severely.
  exit /b 2
)
rem Check if file is empty
for %%F in ("%TEMP_ENV_FILE%") do if %%~zF==0 (
  echo ERROR: Temp environment file is empty. Sub-shell likely failed early. Exit code was !CALL_EXITCODE!.
  del "%TEMP_ENV_FILE%"
  exit /b 3
)


echo DEBUG: Attempting to parse temp file "%TEMP_ENV_FILE%":
type "%TEMP_ENV_FILE%"
echo DEBUG: --- End of temp file contents ---

rem --- Parse the temp file to get variables back ---
set RETCODE=999  REM Default to error
set COBDIR=     REM Ensure COBDIR is clear initially in this scope
for /f "usebackq tokens=1* delims==" %%a in ("%TEMP_ENV_FILE%") do (
  echo DEBUG: Parsing line: "%%a=%%b"
  rem Trim potential whitespace artifacts (though unlikely with echo)
  for /f "tokens=* delims= " %%X in ("%%a") do set "varName=%%X"
  for /f "tokens=* delims= " %%Y in ("%%b") do set "varValue=%%Y"
  if /i "!varName!"=="RETCODE_INNER" set RETCODE=!varValue!
  if /i "!varName!"=="COBDIR" set COBDIR=!varValue!
)

rem --- Cleanup temp file ---
if exist "%TEMP_ENV_FILE%" del "%TEMP_ENV_FILE%"

echo Setup script sub-shell completed with internal return code: !RETCODE!
echo COBDIR captured from sub-shell: !COBDIR!

rem --- Now perform checks using the captured values in the *current* clean(er) scope ---
rem This IF statement should now work correctly as the current scope wasn't affected by SetupEnv.bat
if !RETCODE! EQU 0 goto SetupSuccess

echo ERROR: Environment setup script failed in sub-shell with code !RETCODE!.
exit /b !RETCODE!

:SetupSuccess
echo DEBUG: RETCODE was 0, proceeding...

rem Check if COBDIR was actually captured
if "!COBDIR!"=="" (
  echo ERROR: Setup script succeeded (RETCODE=0) but COBDIR was NOT captured or was empty from sub-shell. Check temp file parsing.
  exit /b 1
)

rem --- Cleanup COBDIR captured from sub-shell ---
set "COBDIR_CLEAN=!COBDIR:"=!"
if "!COBDIR_CLEAN:~-1!"==";" (
  set "COBDIR_CLEAN=!COBDIR_CLEAN:~0,-1!"
)
echo DEBUG: Cleaned COBDIR is: !COBDIR_CLEAN!

rem --- Export variable to GitHub Actions environment ---
if defined GITHUB_ENV (
  echo COBDIR=!COBDIR_CLEAN!>>"%GITHUB_ENV%"
  echo DEBUG: Exported COBDIR=!COBDIR_CLEAN! to GITHUB_ENV file.
) else (
  echo WARNING: GITHUB_ENV variable not found. Cannot export COBDIR to workflow environment.
)

echo Environment setup successful.

exit /b 0
