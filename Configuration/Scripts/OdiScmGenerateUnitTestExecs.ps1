$FN = "OdiScmGenerateUnitTestExec"
$IM = $FN + ": INFO:"
$EM = $FN + ": ERROR:"

function Usage() {
	write-host "$IM usage: $FN <output-path-and-file-name> <output-test-set-type> <output-ODI-test-call-type>"
	write-host "$IM where: <output-test-set-type>::= incremental | full"
	write-host "$IM          <output-ODI-test-call-type>::= individual | suite"
}

#
# Global debugging on/off switch.
#
$DebuggingActive = $False

#
# Perform basic environment check.
#
if (($env:ODI_SCM_HOME -eq $Null) -or ($env:ODI_SCM_HOME -eq "")) {
	write-host "$EM environment variable ODI_SCM_HOME is not set"
	exit 1
}
else {
	$OdiScmHomeDir = $env:ODI_SCM_HOME
	write-host "$IM using ODI-SCM home directory <$OdiScmHomeDir> from environment variable ODI_SCM_HOME"
}

if (($env:ODI_SCM_INI -eq $Null) -or ($env:ODI_SCM_INI -eq "")) {
	write-host "$EM environment variable ODI_SCM_INI is not set"
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

if ($args.length -ne 3) {
	write-host "$EM invalid number of arguments specified"
	Usage
	exit 1
}

if (($args[0] -eq "") -or ($args[0] -eq $Null)) {
	write-host "$EM invalid output file path/name specified"
	Usage
	exit 1
}

if (($args[1].ToLower() -ne "incremental") -and ($args[1].ToLower() -ne "full")) {
	write-host "$EM invalid output test set type argument specified"
	Usage
	exit 1
}

if (($args[2].ToLower() -ne "individual") -and ($args[2].ToLower() -ne "suite")) {
	write-host "$EM invalid output ODI test call type"
	Usage
	exit 1
}

if (($args[1].ToLower() -eq "incremental") -and ($args[2].ToLower() -eq "suite")) {
	write-host "$EM invalid parameter argument combination:"
	write-host "$EM incremental test execution can be specified only with individual ODI scenario"
	write-host "$EM test execution, not suite-level execution"
	Usage
	exit 1
}

#
# Set output file and directory names.
#
$ResultMain = SetOutputNames
if (!($ResultMain)) {
	exit 1
}

#
# Execute the central function.
#
$ResultMain = GenerateUnitTestExecScript $args[0] $args[1] $args[2]
if ($ResultMain) {
	exit 0
}
else {
	exit 1
}