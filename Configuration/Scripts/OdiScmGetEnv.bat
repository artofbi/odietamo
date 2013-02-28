@echo off
setlocal enabledelayedexpansion
REM ===============================================
REM Show environment variables for the OdiScm configuration
REM that will be used by the system.
REM ===============================================
set FN=OdiScmGetEnv
set IM=%FN%: INFO:
set EM=%FN%: ERROR:

if /i "%1" == "/b" (
	set IsBatchExit=/b
	shift
) else (
	set IsBatchExit=
)

set /a ISSUES=0

if "%ODI_SCM_INI%" == "" (
	echo %IM% OdiScm configuration INI file environment variable ODI_SCM_INI is not set
) else (
	echo %IM% OdiScm configuration INI file environment variable ODI_SCM_INI is set
	echo %IM% environment variable ODI_SCM_INI is set to ^<%ODI_SCM_INI%^>
	if exist "%ODI_SCM_INI%" (
		echo %IM% OdiScm configuration INI file ^<%ODI_SCM_INI%^> exists
	) else (
		echo %EM% OdiScm configuration INI file ^<%ODI_SCM_INI%^> does not exist
		set /a ISSUES=!ISSUES!+1
	)
)
echo %IM%
REM echo %IM% total environment issues found is ^<%ISSUES%^>

if "%ODI_SCM_HOME%" == "" (
	echo %EM% OdiScm home directory environment variable ODI_SCM_HOME is not set
	set /a ISSUES=!ISSUES!+1
) else (
	echo %IM% OdiScm home directory environment variable ODI_SCM_HOME is set
	echo %IM% environment variable ODI_SCM_HOME is setto ^<%ODI_SCM_HOME%^>
	if exist "%ODI_SCM_HOME%" (
		echo %IM% OdiScm home directory exists
		if exist "%ODI_SCM_HOME%\Configuration" (
			echo %IM% OdiScm configuration directory ^<%ODI_SCM_HOME%\Configuration^> exists
			if exist "%ODI_SCM_HOME%\Configuration\Scripts" (
				echo %IM% OdiScm scripts directory ^<%ODI_SCM_HOME%\Configuration\Scripts^> exists
				if exist "%ODI_SCM_HOME%\Configuration\Scripts\OdiScmGet.bat" (
					echo %IM% OdiScm scripts detected in directory ^<%ODI_SCM_HOME%\Configuration\Scripts^>
				) else (
					echo %EM% OdiScm scripts not detected in directory ^<%ODI_SCM_HOME%\Configuration\Scripts^>
					set /a ISSUES=!ISSUES!+1
				)
			) else (
				echo %EM% OdiScm scripts directory ^<%ODI_SCM_HOME%\Configuration\Scripts^> does not exist
				set /a ISSUES=!ISSUES!+1
			)
		) else (
			echo %EM% OdiScm configuration directory ^<%ODI_SCM_HOME%\Configuration^> does not exist
			set /a ISSUES=!ISSUES!+1
		)
	) else (
		echo %EM% OdiScm home directory ^<%ODI_SCM_HOME%\Configuration^> does not exist
		set /a ISSUES=!ISSUES!+1
	)
)
echo %IM%
REM echo %IM% total environment issues found is ^<%ISSUES%^>

if "%ODI_HOME%" == "" (
	echo %EM% ODI home directory environment variable ODI_HOME is not set
	set /a ISSUES=!ISSUES!+1
) else (
	echo %IM% ODI home directory environment variable ODI_HOME is set
	echo %IM% environment variable ODI_HOME is set to ^<%ODI_HOME%^>
	if exist "%ODI_HOME%" (
		echo %IM% ODI home directory ^<%ODI_HOME%^> exists
		if exist "%ODI_HOME%\bin" (
			echo %IM% ODI bin directory ^<%ODI_HOME%\bin^> exists
			if exist "%ODI_HOME%\bin\odiparams.bat" (
				echo %IM% ODI scripts detected in directory ^<%ODI_HOME%\bin^>
			) else (
				echo %IM% ODI scripts not detected in directory ^<%ODI_HOME%\bin^>
				set /a ISSUES=!ISSUES!+1
			)
		) else (
			echo %EM% ODI bin directory ^<%ODI_HOME%\bin^> does not exist
			set /a ISSUES=!ISSUES!+1
		)
		if exist "%ODI_HOME%\drivers" (
			echo %IM% ODI drivers directory ^<%ODI_HOME%\drivers^> exists
		) else (
			echo %EM% ODI bin drivers ^<%ODI_HOME%\drivers^> does not exist
			set /a ISSUES=!ISSUES!+1
		)
	) else (
		echo %EM% ODI home directory ^<%ODI_HOME%^> does not exist
		set /a ISSUES=!ISSUES!+1
	)
)
echo %IM%

REM echo %IM% total environment issues found is ^<%ISSUES%^>
if "%ODI_JAVA_HOME%" == "" (
	echo %EM% ODI JVM home directory environment variable ODI_JAVA_HOME is not set
	set /a ISSUES=!ISSUES!+1
) else (
	echo %IM% ODI JVM home directory environment variable ODI_JAVA_HOME is set
	echo %IM% environment variable ODI_JAVA_HOME is set to ^<%ODI_JAVA_HOME%^>
	if exist "%ODI_JAVA_HOME%" (
		echo %IM% ODI JVM home directory ^<%ODI_JAVA_HOME%^> exists
		if exist "%ODI_JAVA_HOME%\bin" (
			echo %IM% ODI JVM bin directory ^<%ODI_JAVA_HOME%\bin^> exists
			if exist "%ODI_JAVA_HOME%\bin\java.exe" (
				echo %IM% ODI JVM binaries detected in directory ^<%ODI_JAVA_HOME%\bin^>
			) else (
				echo %IM% ODI JVM binaries not detected in directory ^<%ODI_JAVA_HOME%\bin^>
				set /a ISSUES=!ISSUES!+1
			)
		) else (
			echo %EM% ODI JVM bin directory ^<%ODI_JAVA_HOME%\bin^> does not exist
			set /a ISSUES=!ISSUES!+1
		)
	) else (
		echo %EM% ODI JVM home directory ^<%ODI_HOME%^> does not exist
		set /a ISSUES=!ISSUES!+1
	)
)
echo %IM%

REM echo %IM% total environment issues found is ^<%ISSUES%^>
if "%JAVA_HOME%" == "" (
	echo %EM% JVM home directory environment variable JAVA_HOME is not set
	set /a ISSUES=!ISSUES!+1
) else (
	echo %IM% JVM home directory environment variable JAVA_HOME is set
	echo %IM% environment variable JAVA_HOME is set to ^<%JAVA_HOME%^>
	if exist "%JAVA_HOME%" (
		echo %IM% JVM home directory ^<%JAVA_HOME%^> exists
		if exist "%JAVA_HOME%\bin" (
			echo %IM% JVM bin directory ^<%JAVA_HOME%\bin^> exists
			if exist "%JAVA_HOME%\bin\java.exe" (
				echo %IM% JVM binaries detected in directory ^<%JAVA_HOME%\bin^>
			) else (
				echo %IM% JVM binaries not detected in directory ^<%JAVA_HOME%\bin^>
				set /a ISSUES=!ISSUES!+1
			)
		) else (
			echo %EM% JVM bin directory ^<%JAVA_HOME%\bin^> does not exist
			set /a ISSUES=!ISSUES!+1
		)
	) else (
		echo %EM% JVM home directory ^<%JAVA_HOME%^> does not exist
		set /a ISSUES=!ISSUES!+1
	)
)
echo %IM%
REM echo %IM% total environment issues found is ^<%ISSUES%^>

if "%ODI_SCM_JISQL_HOME%" == "" (
	echo %EM% Jisql home directory environment variable ODI_SCM_JISQL_HOME is not set
	set /a ISSUES=!ISSUES!+1
) else (
	echo %IM% Jisql home directory environment variable ODI_SCM_JISQL_HOME is set
	echo %IM% environment variable ODI_SCM_JISQL_HOME is set to ^<%ODI_SCM_JISQL_HOME%^>
	if exist "%ODI_SCM_JISQL_HOME%" (
		echo %IM% Jisql home directory ^<%ODI_SCM_JISQL_HOME%^> exists
		if exist "%ODI_SCM_JISQL_HOME%\runit.bat" (
			echo %IM% Jisql binaries detected in directory ^<%ODI_SCM_JISQL_HOME%\bin^>
		) else (
			echo %IM% Jisql binaries not detected in directory ^<%ODI_SCM_JISQL_HOME%\bin^>
			set /a ISSUES=!ISSUES!+1
		)
	) else (
		echo %EM% Jisql home directory ^<%ODI_SCM_JISQL_HOME%^> does not exist
		set /a ISSUES=!ISSUES!+1
	)
)
echo %IM%

if "%ORACLE_HOME%" == "" (
	echo %EM% Oracle home directory environment variable ORACLE_HOME is not set
	set /a ISSUES=!ISSUES!+1
) else (
	echo %IM% Oracle home directory environment variable ORACLE_HOME is set
	echo %IM% environment variable ORACLE_HOME is set to ^<%ORACLE_HOME%^>
	if exist "%ORACLE_HOME%" (
		echo %IM% Oracle home directory ^<%ORACLE_HOME%^> exists
		if exist "%ORACLE_HOME%\bin" (
			echo %IM% Oracle bin directory ^<%ORACLE_HOME%\bin^> exists
			if exist "%ORACLE_HOME%\bin\exp.exe" (
				echo %IM% Oracle binaries detected in directory ^<%ORACLE_HOME%\bin^>
			) else (
				echo %IM% Oracle binaries not detected in directory ^<%ORACLE_HOME%\bin^>
				set /a ISSUES=!ISSUES!+1
			)
		) else (
			echo %IM% Oracle bin directory ^<%ORACLE_HOME%\bin^ does not exist
			set /a ISSUES=!ISSUES!+1
		)
	) else (
		echo %EM% Oracle home directory ^<%ODI_SCM_JISQL_HOME%^> does not exist
		set /a ISSUES=!ISSUES!+1
	)
)
echo %IM%

rem setlocal enabledelayedexpansion
for /f "tokens=*" %%g in ('echo %ODI_SCM_HOME%\Configuration\Scripts ^| sed "s/\\/\\\\/g" ^| sed "s/ //g"') do (
	set OdiScmHomeEscaped=%%g
)
REM echo OdiScmHomeEscaped is %OdiScmHomeEscaped%

set OdiScmInPath=
for /f "tokens=* eol=# delims=;" %%g in ('echo %PATH% ^| sed "s/ //g" ^| grep -i %OdiScmHomeEscaped%') do (
	set OdiScmInPath=%%g
)

REM set OdiScmInPath=
REM for /f "tokens=* eol=# delims=!" %%g in ('echo "%PATH%" ^| sed "s/ //g" ^| sed "s/;/\r\n/g"') do (
	REM echo doing line %%g
	REM for /f "tokens=* eol=# delims=!" %%h in ('echo %%g ^| grep %OdiScmHomeEscaped%') do (
		REM echo inner doing %%h
		REM set OdiScmInCurrPathDir=%%h
	REM )
REM )

if "%OdiScmInPath%" == "" (
	echo %EM% OdiScm scripts directory is not in the command PATH environment variable
	set /a ISSUES=!ISSUES!+1
) else (
	echo %IM% OdiScm scripts directory is in the command PATH environment variable
)

echo %IM%
echo %IM% total number of environment issues found is ^<%ISSUES%^>

if %ISSUES% EQU 0 (
	exit %IsBatchExit% 0
) else (
	exit %IsBatchExit% 1
)