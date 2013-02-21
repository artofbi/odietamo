#
# The following strings are used to prefix messages output from this script to aid identifation
# of the source of the messages.
#
$FN = "OdiScmGlobals"
$IM = $FN + ": INFO:"
$EM = $FN + ": ERROR:"
$DEBUG = $FN + ": DEBUG:"

#
# This variable can be used when calling this script to determine if the complete
# script executed without a known failure. 
# It is set to $True at the end of this script is this script completes successfully.
#
$LoadedGlobals = $True

#
# A string used to create unique generated script and log file names.
#
$VersionString = get-date -format "yyyyMMdd_HHmmss"

##############################################################
# Workstation environment definition.
##############################################################

#
# Root of tools, source code, etc, etc.
#
if (($env:ODI_SCM_HOME -eq $Null) -or ($env:ODI_SCM_HOME -eq "")) {
	write-host "$EM environment variable ODI_SCM_HOME is not set"
	$LoadedGlobals = $False
}
else {
	$OdiScmHomeDir = $env:ODI_SCM_HOME
	write-host "$IM using ODI-SCM home directory <$OdiScmHomeDir> from environment variable ODI_SCM_HOME"
}

$WorkingCopyRootDir = (get-location).Path
$OdiSourceRoot = $WorkingCopyRootDir + "\ODI\Source"

$ConfigurationFolder = $env:ODI_SCM_HOME + "\Configuration"

#
# OdiScm configuration read from/written to INI file.
#
$OdiScmConfig = $Null

#
# SCM configuration.
#
###$SCMSystemTypeName = ""
###$SCMSystemUrl = ""
###$SCMBranchUrl = ""

#
# Local / TFS server environment definition.
#
$SCMConfigurationFileName = "OdiScm.ini"
$SCMConfigurationFile = $WorkingCopyRootDir + "\" + $SCMConfigurationFileName

#
# This file stores records the changesets that have been updated into the
# local workspace using 'tf get'.
#
####$SCMGetLocalControlFile = $WorkingCopyRootDir + "\OdiScmGetChangeSetsLocalControls.ini"

#
# This file stores records the changesets that have been updated into the
# ODI repository using the OdiScm solution.
#
####$SCMGetLocalODIControlFile = $WorkingCopyRootDir + "\OdiScmGetChangeSetsODIRepoControls.ini"

$ScriptsRootDir = $ConfigurationFolder + "\Scripts"

#
# Fixed utility script and file locations and names.
#
$MoiTempEmptyFile = $ConfigurationFolder + "\EmptyFileDoNotDelete.txt"
###$MoiPreImport = $ScriptsRootDir + "\OdiScm_GenScen_PreImport.bat" 
###$OdiScmMoiPreImport = $ScriptsRootDir + "\OdiScm_GenScen_PreImport.bat" 
$OdiScmValidateRepositoryIntegritySql = $ScriptsRootDir + "\OdiScmValidateRepositoryIntegrity.sql"
$OdiScmRestoreRepositoryIntegritySql = $ScriptsRootDir + "\OdiScmRestoreRepositoryIntegrity.sql"
$OdiScmUpdateIniAwk = $ScriptsRootDir + "\OdiScmUpdateIni.awk"

#
# Script Template locations and names.
#
$OdiScmRepositoryBackUpBatTemplate = $ScriptsRootDir + "\OdiScmRepositoryBackUpTemplate.bat"
$OdiScmJisqlRepoBatTemplate = $ScriptsRootDir + "\OdiScmJisqlRepoTemplate.bat"
$OdiScmBuildBatTemplate = $ScriptsRootDir + "\OdiScmBuildTemplate.bat"
$OdiScmGenScenPreImportBatTemplate = $ScriptsRootDir + "\OdiScmGenScenPreImportTemplate.bat"
$OdiScmGenScenPostImportBatTemplate = $ScriptsRootDir + "\OdiScmGenScenPostImportTemplate.bat"
$OdiScmGenScenNewSqlTemplate = $ScriptsRootDir + "\OdiScmGenScen40NewScenTemplate.sql"
$OdiScmRepoInfrastructureSetupSqlTemplate = $ScriptsRootDir + "\OdiScmCreateInfrastructureTemplate.sql"
$OdiScmRepoSetNextImportTemplate = $ScriptsRootDir + "\OdiScm_set_next_import_template.sql"
$OdiScmBuildNoteTemplate = $ScriptsRootDir + "\OdiScmBuildNoteTemplate.txt"

#
# Logging and generated scripts directory structure.
#
$LogRootDir = $OdiScmHomeDir + "\Logs"
$GenScriptRootDir = $LogRootDir + "\${VersionString}"

#
# Generated script locations and names.
#
$OdiScmStartCmdBat = $GenScriptRootDir + "\OdiScmStartCmd_${VersionString}.bat"
$OdiScmJisqlRepoBat = $GenScriptRootDir + "\OdiScmJisqlRepo_${VersionString}.bat"
$OdiScmRepositoryBackUpBat = $GenScriptRootDir + "\OdiScmRepositoryBackUp_${VersionString}.bat"
$OdiScmBuildBat = $GenScriptRootDir + "\OdiScmBuild_${VersionString}.bat"
$OdiScmGenScenPreImportBat = $GenScriptRootDir + "\OdiScmGenScenPreImport_${VersionString}.bat"
$OdiScmGenScenPostImportBat = $GenScriptRootDir + "\OdiScmGenScenPostImport_${VersionString}.bat"
$OdiScmGenScenNewSql = $GenScriptRootDir + "\OdiScmGenScen40NewScenTemplate_${VersionString}.bat"
$OdiScmRepoInfrastructureSetupSql = $GenScriptRootDir + "\OdiScmCreateInfrastructure_${VersionString}.sql"
$OdiScmRepoSetNextImport = $GenScriptRootDir + "\OdiScmSetNextImport_${VersionString}.sql"
$OdiScmBuildNote = $GenScriptRootDir + "\OdiScmBuildNote_${VersionString}.txt"

$ImportScriptStubName = "OdiScmImport_" + $VersionString
$OdiImportScriptName = $ImportScriptStubName + ".bat"
$OdiImportScriptFile = $GenScriptRootDir + "\$OdiImportScriptName"

#
# ODI configuration.
#
$OdiHomeDir = ""
$OdiJavaHomeDir = ""
$OdiBinDir = ""
$OdiParamFile = ""
$OdiScmOdiStartCmdBat = $GenScriptRootDir + "\startcmd_${VersionString}.bat"

#
# General Java configuration.
#
$JavaHomeDir = ""

#
# Jisql configuration.
#
$JisqlHomeDir = ""

#
# The following strings are used to derive data from TFS by parsing the output
# of the command line interface tool "tf.exe".
#
$GetLatestSearchText = "you have a conflicting edit"
$endOfConflictText= "Unable to perform the get"
$GetLatestSummaryText = "---- Summary"

#
# The following string is used to delimit output of multiple commands in a
# single text file.
#
$strOdiScmCmdOutputSeparator = "xxxOdiScm_Output_Separatorxxx"

#
# Create the standard logging/generated scripts directory tree.
#
if (Test-Path $LogRootDir) { 
	write-host "$IM logs root directory $LogRootDir already exists"
}
else {  
	write-host "$IM creating logs root diretory $LogRootDir"
	New-Item -itemtype directory $LogRootDir 
}

if (Test-Path $GenScriptRootDir) { 
	write-host "$IM generated scripts root directory $GenScriptRootDir already exists"
}
else {  
	write-host "$IM creating generated scripts root directory $GenScriptRootDir"
	New-Item -itemtype directory $GenScriptRootDir 
}

if (Test-Path $MoiTempEmptyFile) { 
	write-host "$IM empty file check file $MoiTempEmptyFile already exists" 
}
else {  
	write-host "$IM creating empty file check file $MoiTempEmptyFile"
	New-Item -itemtype file $MoiTempEmptyFile 
}

##################################################
### 1. Get Latest Results                      ### 
##################################################

$GetLatestVersionOutputFile = $GenScriptRootDir + "\GetFromSCM_" + $VersionString + ".txt"
write-host "$IM GetIncremental output will be written to $GetLatestVersionOutputFile"
$GetLatestVersionConflictsOutputFile = $GenScriptRootDir + "\GetLatestVersionConflicts_Results_" + $VersionString + ".txt"

if (Test-Path $OdiImportScriptFile) {
	write-host "$IM generated ODI import batch file <$OdiImportScriptFile> already exists"
}
else {
	write-host "$IM creating empty generated ODI import batch file <$OdiImportScriptFile>"
	New-Item -itemtype file $OdiImportScriptFile 
}

#
# Import modes used when importing ODI objects.
#
$ODIImportModeInsertUpdate = 'SYNONYM_INSERT_UPDATE'
$ODIImportModeInsert = 'SYNONYM_INSERT'
$ODIImportModeUpdate = 'SYNONYM_UPDATE'

#
# Strings used to extract ODI repository connection details from the odiparams script.
#
$OdiRepoSECURITY_DRIVER_TEXT ='set ODI_SECU_DRIVER='
$OdiRepoSECURITY_DRIVER_LEN = $OdiRepoSECURITY_DRIVER_TEXT.length

$OdiRepoSECURITY_URL_TEXT ='set ODI_SECU_URL='
$OdiRepoSECURITY_URL_LEN = $OdiRepoSECURITY_URL_TEXT.length

$OdiRepoSECURITY_USER_TEXT ='set ODI_SECU_USER='
$OdiRepoSECURITY_USER_LEN = $OdiRepoSECURITY_USER_TEXT.length

$OdiRepoSECURITY_PWD_TEXT ='set ODI_SECU_ENCODED_PASS='
$OdiRepoSECURITY_PWD_LEN = $OdiRepoSECURITY_PWD_TEXT.length

$OdiRepoSECURITY_PWD_UNENC_TEXT = 'set ODI_SECU_PASS='
$OdiRepoSECURITY_PWD_UNENC_LEN = $OdiRepoSECURITY_PWD_UNENC_TEXT.length

$OdiRepoSECURITY_WORK_REP_TEXT ='set ODI_SECU_WORK_REP='
$OdiRepoSECURITY_WORK_REP_LEN = $OdiRepoSECURITY_WORK_REP_TEXT.length 

$OdiRepoUSER_TEXT = 'set ODI_USER='
$OdiRepoUSER_LEN = $OdiRepoUSER_TEXT.length

$OdiRepoPASSWORD_TEXT ='set ODI_ENCODED_PASS='
$OdiRepoPASSWORD_LEN = $OdiRepoPASSWORD_TEXT.length

#
# ODI repository details extracted from the odiparams script and optionally overridden by
# values in the INI file.
#
$OdiRepoSECURITY_DRIVER    = ""
$OdiRepoSECURITY_URL       = ""
$OdiRepoSECURITY_USER      = ""
$OdiRepoSECURITY_PWD       = ""
$OdiRepoSECURITY_UNENC_PWD = ""
$OdiRepoWORK_REP_NAME      = ""
$OdiRepoUSER               = ""
$OdiRepoPASSWORD           = ""
# Parts of the URL.
$OdiRepoSECURITY_URL_SERVER = ""
$OdiRepoSECURITY_URL_PORT   = ""
$OdiRepoSECURITY_URL_SID    = ""

#
# Strings used to correctly generate the ODI object imports for nestable object types.
#
$orderedExtensions = @("*.SnpTechno","*.SnpLang","*.SnpContext","*.SnpConnect","*.SnpPschema","*.SnpLschema","*.SnpProject","*.SnpGrpState","*.SnpFolder","*.SnpVar","*.SnpUfunc","*.SnpTrt","*.SnpModFolder","*.SnpModel","*.SnpSubModel","*.SnpTable","*.SnpJoin","*.SnpSequence","*.SnpPop","*.SnpPackage","*.SnpObjState")
$containerExtensions = @("*.SnpConnect","*.SnpModFolder","*.SnpModel","*.SnpSubModel","*.SnpProject","*.SnpFolder")
$nestableContainerExtensions = @("*.SnpModFolder","*.SnpSubModel","*.SnpFolder")
$nestableContainerExtensionParentFields = @("ParIModFolder","ISmodParent","ParIFolder")
$nestableContExtParBegin = '<Field name="XXXXXXXXXXXXXXXXXXXX" type="com.sunopsis.sql.DbInt"><![CDATA['
$nestableContExtParEnd = ']]></Field>'

#
# The custom end-of-section entry in "odiparams.bat" added for this automation.
#
$OdiRepoLAST = 'rem ODI CONNECTION PARAMETERS FINISH'

#
# Global debugging on/off switch.
#
###$DebuggingActive = $True
$DebuggingActive = $False