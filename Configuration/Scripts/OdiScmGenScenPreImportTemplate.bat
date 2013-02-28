@echo off
setlocal
set FN=OdiScmGenScenPreImport
set IM=%FN%: INFO:
set EM=%FN%: ERROR:

echo %IM% starts

set EXITSTATUS=0
set FILENO=%RANDOM%

if "%TEMP%" == "" goto NoTempDir
set TEMPDIR=%TEMP%
goto GotTempDir

:NoTempDir
if "%TMP%" == "" goto NoTmpDir
set TEMPDIR=%TMP%
goto GotTempDir

:NoTmpDir
set TEMPDIR=%CD%

:GotTempDir
set EMPTYFILE=%TEMPDIR%\%RANDOM%_OdiScm_PreImport_EmptyFile.txt

type NUL > %EMPTYFILE% 2>&1
if ERRORLEVEL 1 goto CreateEmptyFileFail
goto CreateEmptyFileOk

:CreateEmptyFileFail
echo %EM% creating empty file ^<%EMPTYFILE%^>
goto ExitFail

:CreateEmptyFileOk
call :SetDateTimeStrings

set STDOUTFILE=<GenScriptRootDir>\OdiScmGenScen10_Jisql_stdout_%YYYYMMDD%_%HHMM%.txt
set STDERRFILE=<GenScriptRootDir>\OdiScmGenScen10_Jisql_stderr_%YYYYMMDD%_%HHMM%.txt

call <OdiScmJisqlRepoBat> /b <OdiScmHomeDir>\Configuration\Scripts\OdiScmGenScen10Initialise.sql %STDOUTFILE% %STDERRFILE%
if ERRORLEVEL 1 goto BatchFileNotOk10
goto BatchFileOk10

:BatchFileNotOk10
echo OdiScm_GenScen_PreImport: ERROR: Batch file OdiScmJisqlRepo.bat returned non-zero ERRORLEVEL
echo OdiScm_GenScen_PreImport: INFO: StdErr content:
type %STDERRFILE%

set EXITSTATUS=1
goto ExitFail

:BatchFileOk10

rem
rem The called batch file has returned a 0 errorlevel but check for anything in the stderr file.
rem 
echo OdiScm_GenScen_PreImport: INFO: Batch file OdiScmJisqlRepo.bat returned zero ERRORLEVEL
fc %EMPTYFILE% %STDERRFILE% >NUL 2>NUL

if ERRORLEVEL 1 goto StdErrNotEmpty10
goto StdErrEmpty10

:StdErrNotEmpty10
echo OdiScm_GenScen_PreImport: INFO: StdErr content:
type %STDERRFILE%
set EXITSTATUS=1
goto ExitFail

:StdErrEmpty10

echo OdiScm_GenScen_PreImport: INFO: StdOut content:
type %STDOUTFILE%

echo OdiScm_GenScen_PreImport: Scenario generation initialisation completed successfully.
goto Exit

:ExitFail

:Exit
exit /b %EXITSTATUS%

rem *************************************************************
rem **                    S U B R O U T I N E S                **
rem *************************************************************

:SetDateTimeStrings
rem
rem Define unique file name suffixes.
rem
for /f "tokens=1,2,3 delims=/ " %%A in ('date /t') do ( 
	set Day=%%A
	set Month=%%B
	set Year=%%C
	set YYYYMMDD=%%C%%B%%A
)
for /f "tokens=1,2 delims=: " %%A in ('time /t') do ( 
	set Hour=%%A
	set Minute=%%B
	set HHMM=%%B%%A
)