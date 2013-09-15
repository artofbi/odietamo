$FN = "OdiScmGenerateUnitTestExec"
$IM = $FN + ": INFO:"
$EM = $FN + ": ERROR:"

#
# Global debugging on/off switch.
#
###$DebuggingActive = $True
$DebuggingActive = $False

#
# Perform basic environment check.
#
if (($env:ODI_SCM_HOME -eq $Null) -or ($env:ODI_SCM_HOME -eq "")) {
	write-host "$EM: environment variable ODI_SCM_HOME is not set"
	exit 1
}
else {
	$OdiScmHomeDir = $env:ODI_SCM_HOME
	write-host "$IM using ODI-SCM home directory <$OdiScmHomeDir> from environment variable ODI_SCM_HOME"
}

if (($env:ODI_SCM_INI -eq $Null) -or ($env:ODI_SCM_INI -eq "")) {
	write-host "$EM: environment variable ODI_SCM_INI is not set"
	exit 1
}
else {
	write-host "$IM using ODI-SCM INI file <$env:ODI_SCM_INI> from environment variable ODI_SCM_INI"
}

#
# Load common functions.
#
. "$env:ODI_SCM_HOME\Configuration\Scripts\OdiScmCommon.ps1"

#
# Global debugging on/off switch.
#
$DebuggingActive = $False

if (($args.length -ne 2) -or (($args[0] -eq "") -or ($args[0] -eq $Null)) -or (($args[1] -ne "incremental") -and ($args[1] -ne "full"))) {
	write-host "$EM invalid arguments specified"
	write-host "$EM usage: $FN <output path and file name> <incremental | full>"
	return $False
}

#
# Set output file and directory names.
#
$ResultMain = SetOutputNames
if ($ResultMain) {
	exit 0
}
else {
	exit 1
}

#
# Execute the central function.
#
$ResultMain = GenerateUnitTestExecScript $args[0] $args[1]
if ($ResultMain) {
	exit 0
}
else {
	exit 1
}