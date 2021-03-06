$FN = "OdiScmMakeStartCmd"
$IM = $FN + ": INFO:"
$EM = $FN + ": ERROR:"

if ($args.count -ne 1) {
	write-output "$EM usage: OdiScmMakeStartCmd <output path and file name>"
	exit 1
}

if (($env:ODI_SCM_ORACLEDI_HOME -eq $Null) -or ($env:ODI_SCM_ORACLEDI_HOME -eq "")) {
	write-output "$EM environment variable ODI_SCM_ORACLEDI_HOME is not set"
	exit 1
}

$StartCmdBat = $env:ODI_SCM_ORACLEDI_HOME + "\bin\startcmd.bat"

if (!(test-path $StartCmdBat)) {
	write-output "$EM ODI startcmd.bat batch script not found in ODI bin directory <$env:ODI_SCM_ORACLEDI_HOME\bin>"
	exit 1
}

$OdiParamsBat = $env:ODI_SCM_ORACLEDI_HOME + "\bin\odiparams.bat"

if (!(test-path $OdiParamsBat)) {
	write-output "$EM ODI odiparams.bat batch script not found in ODI bin directory <$env:ODI_SCM_ORACLEDI_HOME\bin>"
	exit 1
}

#
# Load odiparams.bat into an array.
#
[array] $arrOdiParamsContent = get-content $OdiParamsBat
###$arrOdiParamsContent | foreach { write-host $_ }
[array]$OdiParamsText
$OdiParamsText += "REM OdiScm: start of odiparams.bat insertion"

$OdiParamsText += $arrOdiParamsContent ###| out-string

$OdiParamsText += "REM OdiScm: end of odiparams.bat insertion"

#
# Run an empty (NUL) Jython script to prime the package cache. Discard stderr so it doesn't interfere with our dectecting of if
# the ODI command actually completed successfully.
#
$OdiParamsText += "REM OdiScm: start of Jython package cache priming insertion"
$OdiParamsText += '%ODI_JAVA_START% org.python.util.jython "-Dpython.home=%ODI_HOME%/lib/scripting" NUL 2>NUL'
$OdiParamsText += "if ERRORLEVEL 1 ("
$OdiParamsText += "	echo %EM% priming Jython package cache"
$OdiParamsText += "	exit /b 1"
$OdiParamsText += ")" + [Environment]::NewLine
$OdiParamsText += "REM OdiScm: end of Jython package cache priming insertion"

$StartCmdOdiParamsCallText = '^call \"%ODI_HOME%\\bin\\odiparams.bat.*$'
$StartCmdContent = get-content $StartCmdBat

$OutStartCmdScriptFileContent = $StartCmdContent -Replace $StartCmdOdiParamsCallText, $OdiParamsText
####write-host "printing.............................................................."
###$OutStartCmdScriptFileContent | foreach { write-host $_ }

#######################################################################
# Expand variable values.
#######################################################################
$ScriptFileContent = $OutStartCmdScriptFileContent

$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%ODI_HOME%"         , $env:ODI_SCM_ORACLEDI_HOME }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%ODI_JAVA_HOME%"    , $env:ODI_SCM_ORACLEDI_JAVA_HOME }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%JAVA_HOME%"        , $env:ODI_SCM_ORACLEDI_JAVA_HOME }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%ODI_SECU_WORK_REP%", $env:ODI_SCM_ORACLEDI_SECU_WORK_REP }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%ODI_USER%"         , $env:ODI_SCM_ORACLEDI_USER }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%ODI_ENCODED_PASS%" , $env:ODI_SCM_ORACLEDI_ENCODED_PASS }
#
# ODI 10g variables.
#
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%ODI_SECU_DRIVER%"      , $env:ODI_SCM_ORACLEDI_SECU_DRIVER }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%ODI_SECU_URL%"         , $env:ODI_SCM_ORACLEDI_SECU_URL }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%ODI_SECU_USER%"        , $env:ODI_SCM_ORACLEDI_SECU_USER }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%ODI_SECU_ENCODED_PASS%", $env:ODI_SCM_ORACLEDI_SECU_ENCODED_PASS }
#
# ODI 11g variables.
#
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%ODI_MASTER_DRIVER%"      , $env:ODI_SCM_ORACLEDI_SECU_DRIVER }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%ODI_MASTER_URL%"         , $env:ODI_SCM_ORACLEDI_SECU_URL }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%ODI_MASTER_USER%"        , $env:ODI_SCM_ORACLEDI_SECU_USER }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "%ODI_MASTER_ENCODED_PASS%", $env:ODI_SCM_ORACLEDI_SECU_ENCODED_PASS }

#######################################################################
# Modify variable SET statements.
#######################################################################
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set ODI_HOME=.*$"         , "set ODI_HOME=$env:ODI_SCM_ORACLEDI_HOME" }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set ODI_JAVA_HOME=.*$"    , "set ODI_JAVA_HOME=$env:ODI_SCM_ORACLEDI_JAVA_HOME" }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set JAVA_HOME=.*$"        , "set JAVA_HOME=$env:ODI_SCM_ORACLEDI_JAVA_HOME" }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set ODI_SECU_WORK_REP=.*$", "set ODI_SECU_WORK_REP=$env:ODI_SCM_ORACLEDI_SECU_WORK_REP" }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set ODI_USER=.*$"         , "set ODI_USER=$env:ODI_SCM_ORACLEDI_USER" }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set ODI_ENCODED_PASS=.*$" , "set ODI_ENCODED_PASS=$env:ODI_SCM_ORACLEDI_ENCODED_PASS" }
#
# ODI 10g variables.
#
$ScriptFileContent | foreach { write-host $_; $_ -match "^set ODI_SECU_DRIVER=.*" }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set ODI_SECU_DRIVER=.*$"      , "set ODI_SECU_DRIVER=$env:ODI_SCM_ORACLEDI_SECU_DRIVER" }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set ODI_SECU_URL=.*$"         , "set ODI_SECU_URL=$env:ODI_SCM_ORACLEDI_SECU_URL" }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set ODI_SECU_USER=.*$"        , "set ODI_SECU_USER=$env:ODI_SCM_ORACLEDI_SECU_USER" }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set ODI_SECU_ENCODED_PASS=.*$", "set ODI_SECU_ENCODED_PASS=$env:ODI_SCM_ORACLEDI_SECU_ENCODED_PASS" }
#
# ODI 11g variables.
#
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set ODI_MASTER_DRIVER=.*$"      , "set ODI_MASTER_DRIVER=$env:ODI_SCM_ORACLEDI_SECU_DRIVER" }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set ODI_MASTER_URL=.*$"         , "set ODI_MASTER_URL=$env:ODI_SCM_ORACLEDI_SECU_URL" }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set ODI_MASTER_USER=.*$"        , "set ODI_MASTER_USER=$env:ODI_SCM_ORACLEDI_SECU_USER" }
$ScriptFileContent = $ScriptFileContent | foreach { $_ -replace "^set ODI_MASTER_ENCODED_PASS=.*$", "set ODI_MASTER_ENCODED_PASS=$env:ODI_SCM_ORACLEDI_SECU_ENCODED_PASS" }

$OutStartCmdScriptFileContent = $ScriptFileContent

write-host "printing again.............................................................."
$OutStartCmdScriptFileContent | foreach { write-host $_ }

###write-host "OutStartCmdScriptFileContent: " $OutStartCmdScriptFileContent

#######################################################################
# Define output file names.
#######################################################################
$OutWrapperBat = $args[0]
$OutWrapperBatFile = split-path $OutWrapperBat -leaf
$OutDir = split-path $OutWrapperBat -parent

$OutStartCmdBatFile = $OutWrapperBatFile -replace ".bat$", ""
$OutStartCmdBatFile += "_OdiScmStartCmd.bat"
$OutStartCmdBat = $OutDir + "\" + $OutStartCmdBatFile

#
# Create the StartCmd script.
#
set-content -path $OutStartCmdBat -value $OutStartCmdScriptFileContent
if (!($?)) {
	write-output "$EM writing StartCmd script file <$OutStartCmdBat>"
	exit 1
}

#######################################################################
# Create the wrapper script, used to capture and stderr from the
# startcmd script.
#######################################################################

$strStdOutFile = $OutStartCmdBat + ".stdout"
$strStdErrFile = $OutStartCmdBat + ".stderr"
$strEmptyFile = $OutStartCmdBat + ".empty"

$strProc = $OutWrapperBatFile.replace(".bat","")

$ScriptFileContent = ""
$ScriptFileContent += "@echo off" + [Environment]::NewLine
$ScriptFileContent += "set PROC=" + $strProc + [Environment]::NewLine
$ScriptFileContent += "set IM=" + $strProc + ": INFO:" + [Environment]::NewLine
$ScriptFileContent += "set EM=" + $strProc + ": ERROR:" + [Environment]::NewLine

$ScriptFileContent += 'type NUL 1>"' + $strEmptyFile + '"' + [Environment]::NewLine
$ScriptFileContent += "if ERRORLEVEL 1 (" + [Environment]::NewLine
$ScriptFileContent += "	echo %EM% creating empty file ^<" + $strEmptyFile + "^>" + [Environment]::NewLine
$ScriptFileContent += "	goto ExitFail" + [Environment]::NewLine
$ScriptFileContent += ")" + [Environment]::NewLine

$ScriptFileContent += "echo %IM% executing OracleDI command ^<%*^>" + [Environment]::NewLine
$ScriptFileContent += 'call "' + $OutStartCmdBat + '" %*' 
$ScriptFileContent += ' 1>"' + $strStdOutFile +'"'
$ScriptFileContent += ' 2>"' + $strStdErrFile +'"'
$ScriptFileContent += [Environment]::NewLine

$ScriptFileContent += "if ERRORLEVEL 1 (" + [Environment]::NewLine
$ScriptFileContent += "	echo %EM% calling OracleDI command. StdErr text ^<" + [Environment]::NewLine
$ScriptFileContent += '	type "' + $strStdErrFile + '"' + [Environment]::NewLine
$ScriptFileContent += "	echo ^>" + [Environment]::NewLine
$ScriptFileContent += "	goto ExitFail" + [Environment]::NewLine
$ScriptFileContent += ")" + [Environment]::NewLine
$ScriptFileContent += 'fc "' + $strEmptyFile + '" "' + $strStdErrFile + '" >NUL' + [Environment]::NewLine
$ScriptFileContent += "if ERRORLEVEL 1 (" + [Environment]::NewLine
$ScriptFileContent += "	echo %EM% calling OracleDI command. StdErr text ^<" + [Environment]::NewLine
$ScriptFileContent += '	type "' + $strStdErrFile + '"' + [Environment]::NewLine
$ScriptFileContent += "	echo ^>" + [Environment]::NewLine
$ScriptFileContent += "	goto ExitFail" + [Environment]::NewLine
$ScriptFileContent += ")" + [Environment]::NewLine
$ScriptFileContent += [Environment]::NewLine
$ScriptFileContent += ":ExitOk" + [Environment]::NewLine
$ScriptFileContent += "exit 0" + [Environment]::NewLine
$ScriptFileContent += ":ExitFail" + [Environment]::NewLine
$ScriptFileContent += "exit 1" + [Environment]::NewLine

set-content -path $OutWrapperBat -value $ScriptFileContent
if (!($?)) {
	write-output "$EM writing output file"
	exit 1
}

#
# Exit with a success code.
#
exit 0