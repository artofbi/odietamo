#
# Check that the required external commands are available.
#
function CheckDependencies {
	
	$FN = "CheckDependencies"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	$SCMSystemTypeName = $OdiScmConfig["SCM System"]["Type Name"]
	
	if ($SCMSystemTypeName -eq "TFS") {
		$ToNull = tf.exe
		if ($LastExitCode -ne 0) {
			write-host "$EM command tf.exe is not available. Ensure PATH is correctly set"
			return $False
		}
		
		$ToNull = psexec.exe cmd /c dir
		if ($LastExitCode -ne 0) {
			write-host "$EM command
			psexec.exe is not available. Ensure PATH is correctly set"
			return $False
		}
	}
	elseif ($SCMSystemTypeName -eq "SVN") {
		$ToNull = svn.exe help
		if ($LastExitCode -ne 0) {
			write-host "$EM command svn.exe is not available. Ensure PATH is correctly set"
			return $False
		}
	}
	
	# We don't require UnxUtils for this process.
	# $ToNull = fgrep.exe --help
	# if ($LastExitCode -ne 0) {
		# write-host "$EM command fgrep.exe is not available. Ensure PATH is correctly set"
		# return $False
	# }
	
	write-host "$IM completed checking dependencies"
	return $True
}

#
# Validate a ChangeSet range string.
#
function ChangeSetRangeIsValid ([string] $ChangeSetRange) {
	
	if (! $ChangeSetRange.contains("~")) {
		return $False
	}
	
	if ($ChangeSetRange.substring(0,1) -eq "~") {
		return $False
	}
	
	$intTildeCount = 0
	$arrCharRange = $ChangeSetRange.ToCharArray()
	
	$arrCharRange | foreach-object -process {
		if ($_ -eq "~") {
			$intTildeCount += 1
		}
	}
	
	if ($intTildeCount -gt 1) {
		return $False
	}
	
	[array] $ChangeSetParts = @([regex]::split($ChangeSetRange,"~"))
	
	[boolean] $IsNumber = $False
	
	[int]::TryParse($ChangeSetRange[0],[ref]$IsNumber)
	if (! $IsNumber) {
		return $False
	}
	
	[int] $intFromChangeSet = $ChangeSetRange[0]
	
	[int]::TryParse($ChangeSetRange[0],[ref]$IsNumber)
	
	if ($ChangeSetRange[1] -eq "") {
		return $True
	}
	
	[int]::TryParse($ChangeSetRange[1],[ref]$IsNumber)
	if (! $IsNumber) {
		return $False
	}
	
	[int] $intToChangeSet = $ChangeSetRange[1]
	
	if ($intFromChangeSet -gt $intToChangeSet) {
		return $False
	}
	
	if ($intFromChangeSet -lt 1 -or $intFromChangeSet -gt 2147483647) {
		return $False
	}
	
	if ($intFromChangeTo -lt 1 -or $intFromChangeTo -gt 2147483647) {
		return $False
	}
	
	return $True
}

function GetNewChangeSetNumber {
	
	$SCMSystemTypeName = $OdiScmConfig["SCM System"]["Type Name"]
	
	switch ($SCMSystemTypeName) {
		"TFS" { GetNewTFSChangeSetNumber }
		"SVN" { GetNewSVNRevisionNumber }
	}
}

#
# Get the latest revision number from the SVN repository.
#
function GetNewSVNRevisionNumber {
	
	$FN = "GetNewSVNRevisionNumber"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	write-host "$IM starts"
	
	write-host "$IM Getting the latest revision number from the SVN repository"
	
	#
	# Generate a unique file name (with path included).
	#
	$SCMSystemUrl = $OdiScmConfig["SCM System"]["System Url"]
	$SCMBranchUrl = $OdiScmConfig["SCM System"]["Branch Url"]
	
	$CmdLine = "svn.exe info ${SCMSystemUrl}/${SCMBranchUrl}"
	$CmdOutput = invoke-expression $CmdLine
	if ($LastExitCode -ne 0) {
		write-host "$EM executing command <$CmdLine>"
		return $False
	}
	
	$NewRevNo = ""
	
	foreach ($CmdOutputLine in $CmdOutput) {
		if ($CmdOutputLine.StartsWith("Last Changed Rev:")) {
			$NewRevNo = $CmdOutputLine.Replace("Last Changed Rev:","").Trim()
		}
	}
	
	write-host "$IM new Revision number is <$NewRevNo>"
	
	write-host "$IM ends"
	return $NewRevNo
}

#
# Get the latest ChangeSet number from the TFS server.
#
function GetNewTFSChangeSetNumber {
	
	$FN = "GetNewTFSChangeSetNumber"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	write-host "$IM starts"
	
	write-host "$IM Getting the latest ChangeSet number from the TFS server"
	
	$SCMSystemUrl = $OdiScmConfig["SCM System"]["System Url"]
	$SCMBranchUrl = $OdiScmConfig["SCM System"]["Branch Url"]
	
	$TFSGlobalUserName = $OdiScmConfig["SCM System"]["Global User Name"]
	$TFSGlobalUserPassword = $OdiScmConfig["SCM System"]["Global User Password"]
	
	#
	# Generate a unique file name (with path included).
	#
	$TempFileNameStub = "$GenScriptRootDir\psexec_out_${VersionString}"
	
	$CmdArgs = "changeset /noprompt /latest /server:${SCMSystemUrl}"
	$CmdLine = "psexec.exe "
	if ($TFSGlobalUserName -ne "") {
		$CmdLine = $CmdLine + "-u $TFSGlobalUserName -p $TFSGlobalUserPassword "
	}
	
	$CmdLine = $CmdLine + "cmd.exe /c " + '"' + "set ODI_SCM_HOME=%ODI_SCM_HOME%&&$ScriptsRootDir\OdiScmRedirCmd.bat" + '" ' + "tf.exe" + ' ' + "$TempFileNameStub" + ' ' + " $CmdArgs"
	write-host "$DEBUG running: $CmdLine"
	invoke-expression $CmdLine
	
	$changesetText = get-content "$TempFileNameStub.stdout" | out-string
	###write-host "changesetText: $changesetText" 
	if ($changesetText.IndexOf("needs Read permission(s) for at least one item in changeset") -gt 1) {
		$newChangeset = $changesetText.Substring($changesetText.IndexOf("at least one item in changeset") + "at least one item in changeset".length, 6)
	}
	else {
		$changeset = "Changeset:"
		$user = "User: "
		$changeset_len = $changeset.length
		$ChangeSetTextChangeSetPos = $changesetText.IndexOf($changeset)
		$ChangeSetTextUserPos = $changesetText.IndexOf($user)
		###write-host "changeset_len = $changeset_len"
		###write-host "ChangeSetTextChangeSetPos = $ChangeSetTextChangeSetPos"
		###write-host "ChangeSetTextUserPos = $ChangeSetTextUserPos"
		$newChangeset = $changesetText.Substring($ChangeSetTextChangeSetPos + $changeset_len, $ChangeSetTextUserPos - $ChangeSetTextChangeSetPos - $changeset_len - 1)
	}
	
	$ChangeSetLog = $newChangeset.Trim()
	write-host "$IM new ChangeSet number is <$ChangeSetLog>"
	
	write-host "$IM ends"
	return $ChangeSetLog
}

#
# Get the list of changed files in the received ChangeSet range by parsing the details of each ChangeSet
# obtained from the TFS server.
#
# function GetTFSDifference ([string] $difference) {
	
	# $IM = "GetDifference: INFO:"
	# $EM = "GetDifference: ERROR:"
	# $DEBUG = "GetDifference: DEBUG:"
	
	# write-host "$IM starts"
	# write-host "$IM getting changed files list from TFS for Changesets <$difference>"
	
	# $difference = $difference.Replace(" ","")
	
	# write-host "$IM command to be executed <tf history $TFSBranchName /format:detailed /recursive /collection:${TFSServer} /version:${difference}>"
	
	# $CmdLine = "tf history " + '"' + $WorkingCopyRootDir + '"' + " /format:detailed /recursive /collection:${TFSServer} /version:${difference} | out-string"
	# $ChangeHistoryDiff = invoke-expression $CmdLine
	
	# #write-host "$DEBUG ChangeHistoryDiff: " $ChangeHistoryDiff
	# $IndexCheckinNotes = $ChangeHistoryDiff.IndexOf("Check-in Notes:")
	# #write-host "$DEBUG IndexOf `'Check-in Notes`':" $IndexCheckinNotes
	# $IndexItems = $ChangeHistoryDiff.IndexOf("Items:") 
	# #write-host "$DEBUG IndexOf Items: " $IndexItems
	
	# $CountOfItemInList = 0
	# [array] $outFileList = @()
		
	# if ($ChangeHistoryDiff.IndexOf("Check-in Notes:") -gt 0) {
		
		# $ChangeLogList = @([regex]::split($ChangeHistoryDiff,"Changeset: "))
		
		# foreach ($item in $ChangeLogList) { 
		
			# #
			# # Don't process the first/empty element.
			# #
			# if ($CountOfItemInList -ne 0) {
				
				# $IndexCheckinNotes = $item.IndexOf("Check-in Notes:")
				# $IndexItems = $item.IndexOf("Items:") 
				# #write-host "$DEBUG IndexCheckinNotes:" $IndexCheckinNotes
				# #write-host "$DEBUG IndexTtems: " $IndexItems
				
				# $item2 = $item.Substring($item.IndexOf("Items:") + 6, $item.IndexOf("Check-in Notes:") - $item.IndexOf("Items:") - 6)
				# $item2 = $item2.Trim()
				# #write-host "$DEBUG item2: " $item2
				
				# $item3 = @([regex]::split($item2,[Environment]::NewLine))
				# #write-host "$DEBUG item3: " $item3
				# foreach ($item4 in $item3) {
					# $item5 = $item4.Replace("add ", "").Replace("edit ", "").Trim()
					# $item5 = $item5.Replace(("$/" + $TFSMoiProjectName + "/"),"")
					# #write-host ("$IM final parsed item>>>" + $item5 + "<<<")
					# #
					# ################## Ensure we add a file system rather than a string object to the output array.
					# #
					# #$item6 = get-childitem $item5
					# $item6 = $item5
					# #write-host "$IM adding to list" $item6.Fullname
					# #$outFileList += @($item6)
					# #
					# # Ignore the creation of the actual branch root in TFS.
					# #
					# if ($item6 -ne $TFSMoiBranchName) {
						# #write-host "$IM adding to list" $item6
						# $outFileList += $item6
					# }
					# #DebuggingPause
				# }
			# }
			# $CountOfItemInList += 1
		# }
	# }
	# else {
		# write-host "$IM there are no changed files"
	# }
	
	# # 
	# # Exception trap for any exception raised in all code in this function up until this point.
	# #
	# &{trap	{
			# write-host "$EM exception trapped <$_.Exception>"
			# #
			# # Return an null array upon failure.
			# #
			# return
		# }
	# }
	
	# write-host "$IM ends"
	# return $outFileList
# }

function GenerateOdiImportScript ([array] $filesToImport) {
	
	$FN = "GenerateOdiImportScript"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	$DEBUG = $FN + ": DEBUG"
	
	write-host "$IM starts"
	
	$ExitStatus = $False
	
	write-host "$IM passed <$($filesToImport.length)> files to import"
	write-host "$IM writing output to <$OdiImportScriptFile>"
	
	#
	# Import script initialisation commands - CWD to the ODI bin directory.
	#
	$OutScriptHeader  = '@echo off' + [Environment]::NewLine
	$OutScriptHeader += "set IM=$OdiImportScriptName" + ": INFO:" + [Environment]::NewLine
	$OutScriptHeader += "set EM=$OdiImportScriptName" + ": ERROR:" + [Environment]::NewLine + [Environment]::NewLine
	
	$OutScriptHeader += 'if /i "%1" == "/b" (' + [Environment]::NewLine
	$OutScriptHeader += '	set IsBatchExit=/b' + [Environment]::NewLine
	$OutScriptHeader += '	shift' + [Environment]::NewLine
	$OutScriptHeader += ') else (' + [Environment]::NewLine
	$OutScriptHeader += '	set IsBatchExit=' + [Environment]::NewLine
	$OutScriptHeader += ')' + [Environment]::NewLine + [Environment]::NewLine
	
	$OutScriptHeader += 'call "' + $ScriptsRootDir + '\OdiScmSetTempDir.bat"' + [Environment]::NewLine
	$OutScriptHeader += 'if ERRORLEVEL 1 (' + [Environment]::NewLine
	$OutScriptHeader += '	echo %EM% creating temporary working directory ^<%TEMPDIR%^>' + [Environment]::NewLine
	$OutScriptHeader += '	goto ExitFail' + [Environment]::NewLine
	$OutScriptHeader += ')' + [Environment]::NewLine + [Environment]::NewLine
	$OutScriptHeader += "set OLDPWD=%CD%" + [Environment]::NewLine + [Environment]::NewLine
	
	$OutScriptHeader += "cd /d $GenScriptRootDir" + [Environment]::NewLine
	$OutScriptHeader | out-file $OdiImportScriptFile -encoding ASCII
	
	#
	# Loop through each extension and file files for which to include import commands.
	#
	foreach ($ext in $orderedExtensions) {
		
		$fileObjType = $ext.Replace("*.","")
		write-host "$IM processing object type <$fileObjType>"
		
		$extensionFileCount = 0
		
		foreach ($fileToImport in $filesToImport) {
			
			if ($fileToImport.EndsWith($fileObjType)) {
				
				$FileToImportName = split-path $fileToImport -leaf
				$FileToImportPathName = split-path $fileToImport -parent
				$SourceFile = $fileToImport
				$extensionFileCount += 1
				
				$ImportText = "echo %IM% date ^<%date%^> time ^<%time%^>" + [Environment]::NewLine
				$ImportText += "set MSG=importing file ^<" + $FileToImportName + "^> from directory ^<" + $FileToImportPathName + "^>" + [Environment]::NewLine
				
				#
				# Work around (yet another) bug in ODI (as of 11.1.1.6.4) where an SnpProject can't be imported
				# unless it has the file name prefix "PROJ_".
				#
				if ($fileObjType -eq "SnpProject") {
					$ImportText += "echo %EM% creating renamed SnpProject file for source file ^<$FileToImportName^>" + [Environment]::NewLine
					$FileToImportPathName = "%TEMPDIR%"
					$FileToImportName = "PROJ_" + $FileToImportName + ".xml"
					$SourceFile = $FileToImportPathName + "\" + $FileToImportName
					$ImportText += 'copy "' + $fileToImport + '" "' + $SourceFile + '" >NUL' + [Environment]::NewLine
				}
				
				if (!($containerExtensions -contains $ext)) {
					$ImportText += 'call "' + $ScriptsRootDir + '\OdiScmFork.bat" ^"' + $OdiScmOdiStartCmdBat + ' OdiImportObject ' + '-FILE_NAME=' + $SourceFile + " -IMPORT_MODE=$ODIImportModeInsertUpdate -WORK_REP_NAME=$OdiRepoWORK_REP_NAME" + [Environment]::NewLine
				}
				else {
					$ImportText += 'call "' + $ScriptsRootDir + '\OdiScmFork.bat" ^"' + $OdiScmOdiStartCmdBat + ' OdiImportObject ' + '-FILE_NAME=' + $SourceFile + " -IMPORT_MODE=$ODIImportModeInsert -WORK_REP_NAME=$OdiRepoWORK_REP_NAME" + [Environment]::NewLine
					$ImportText += "if ERRORLEVEL 1 goto ExitFail" + [Environment]::NewLine
					$ImportText += 'call "' + $ScriptsRootDir + '\OdiScmFork.bat" ^"' + $OdiScmOdiStartCmdBat + ' OdiImportObject ' + '-FILE_NAME=' + $SourceFile + " -IMPORT_MODE=$ODIImportModeUpdate -WORK_REP_NAME=$OdiRepoWORK_REP_NAME" + [Environment]::NewLine
				}
				$ImportText += "if ERRORLEVEL 1 goto ExitFail" + [Environment]::NewLine
				$ImportText += "echo " + $OdiImportScriptName + ": INFO: import of file ^<" + $FileToImportName + "^> completed succesfully" + [Environment]::NewLine
				$ImportText | out-file -filepath $OdiImportScriptFile -encoding ASCII -append
			}
		}
	}
	
	#
	# Import script termination commands - the common Exit labels.
	#
	$OutScriptTail  = [Environment]::NewLine
	$OutScriptTail  = ":ExitOk" + [Environment]::NewLine
	$OutScriptTail += "echo %IM% import process completed" + [Environment]::NewLine
	$OutScriptTail += "cd /d %OLDPWD%" + [Environment]::NewLine
	$OutScriptTail += "exit %IsBatchExit% 0" + [Environment]::NewLine + [Environment]::NewLine
	$OutScriptTail += ":ExitFail" + [Environment]::NewLine
	$OutScriptTail += "echo %EM% %MSG%" + [Environment]::NewLine
	$OutScriptTail += "cd /d %OLDPWD%" + [Environment]::NewLine
	$OutScriptTail += "exit %IsBatchExit% 1" + [Environment]::NewLine
	$OutScriptTail | out-file $OdiImportScriptFile -encoding ASCII -append
	
	write-host "$IM lines in generated script content <$(((get-content $OdiImportScriptFile).Count)-1)>"
	
	$ExitStatus = $True
	
	write-host "$IM ends"
	return $ExitStatus
}

function GetOdiScmConfiguration {
	
	$FN = "GetOdiScmConfiguration"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	$WM = $FN + ": WARNING:"
	$DEBUG = $FN + ": DEBUG:"
	
	write-host "$IM starts"
	
	#
	# Load the OdiScm configuration.
	#
	write-host "$IM using configuration file <$SCMConfigurationFile>"
	$script:OdiScmConfig = GetIniContent "$SCMConfigurationFile"
	if ($OdiScmConfig -eq $False) {
		write-host "$EM reading OdiScm configuration"
		return $False
	}
	
	if (!($OdiScmConfig.ContainsKey("SCM System"))) {
		write-host "$EM configuration INI file is missing section <SCM System>"
		return $False
	}
	
	#
	# Load the SCM system configuration.
	#
	$SCMSystemTypeName = $OdiScmConfig["SCM System"]["Type Name"]
	
	if (($SCMSystemTypeName -eq $Null) -or ($SCMSystemTypeName -eq "")) {
		write-host "$EM cannot retrieve SCM System Type Name from configuration INI file"
		return $False
	}
	
	if ((($SCMSystemTypeName) -ne "TFS") -and (($SCMSystemTypeName) -ne "SVN")) {
		write-host "$EM retrieved unrecognised SCM System Type Name <$SCMSystemTypeName> from configuration INI file"
		return $False
	}
	
	$SCMSystemUrl = $OdiScmConfig["SCM System"]["System Url"]
	
	if (($SCMSystemUrl -eq $Null) -or ($SCMSystemUrl -eq "")) {
		write-host "$EM cannot retrieve SCM System URL from configuration INI file"
		return $False
	}
	
	$SCMBranchUrl = $OdiScmConfig["SCM System"]["Branch Url"]
	
	if (($SCMBranchUrl -eq $Null) -or ($SCMBranchUrl -eq "")) {
		write-host "$EM cannot retrieve SCM Branch URL from configuration INI file"
		return $False
	}
	
	if ($OdiScmConfig["SCM System"].ContainsKey("Global User Name")) {
		$SCMUserName = $OdiScmConfig["SCM System"]["Global User Name"]
		write-host "$IM using SCM Global User Name <$SCMUserName>"
		
		if (!($OdiScmConfig["SCM System"].ContainsKey("Global User Password"))) {
			write-host "$EM no Global User Password entry in INI file for SCM user <$SCMUserName>"
			return $False
		}
		else {
			$SCMUserPassword = $OdiScmConfig["SCM System"]["Global User Password"]
			#if (($SCMUserPassword -eq $Null) -or ($SCMUserPassword -eq "")) {
			#	write-host "$EM no Global User Password entry in INI file for SCM user <$SCMUserName>"
			#	return $False
			#}
		}
	}
	
	if ($OdiScmConfig["SCM System"].ContainsKey("Working Copy Root")) {
		$script:WorkingCopyRootDir = $OdiScmConfig["SCM System"]["Working Copy Root"]
		if ($WorkingCopyRootDir -eq "" -or $WorkingCopyRootDir -eq $Null) {
			$WorkingCopyRootDir = get-location | out-string
		}
		else {
			$WorkingCopyRootDir = $OdiScmConfig["SCM System"]["Working Copy Root"]
		}
	}
	
	#
	# Determine the ODI home directory to use.
	#
	$script:OdiHomeDir = ""
	
	if ($OdiScmConfig.ContainsKey("OracleDI")) {
		if ($OdiScmConfig["OracleDI"].ContainsKey("Home")) {
			$script:OdiHomeDir = $OdiScmConfig["OracleDI"]["Home"]
			write-host "$IM found ODI home directory <$OdiHomeDir> from INI file"
		}
	}
	
	if ($OdiHomeDir -eq "") {
		write-host "$EM no Home entry in OracleDI section in INI file"
		return $False
	}
	else {
		write-host "$IM using OracleDI home directory <$OdiHomeDir>"
	}
	
	###$script:OdiBinDir = $OdiHomeDir + "\bin"
	
	#
	# Determine the Java home directory to use with ODI.
	#
	$script:OdiJavaHomeDir = ""
	
	if ($OdiScmConfig.ContainsKey("OracleDI")) {
		if ($OdiScmConfig["OracleDI"].ContainsKey("Java Home")) {
			$script:OdiJavaHomeDir = $OdiScmConfig["OracleDI"]["Java Home"]
			write-host "$IM found OracleDI Java Home directory <$OdiJavaHomeDir> from INI file"
		}
	}
	
	if ($OdiJavaHomeDir -eq "") {
		write-host "$EM no Java Home entry in OracleDU section in INI file"
		return $False
	}
	else {
		write-host "$IM using OracleDI Java Home directory <$OdiJavaHomeDir>"
	}
	
	#
	# Determine the Java home directory to use with Jisql.
	#
	$script:JisqlJavaHomeDir = ""
	
	if ($OdiScmConfig.ContainsKey("Tools")) {
		if ($OdiScmConfig["Tools"].ContainsKey("Jisql Java Home")) {
			$script:JisqlJavaHomeDir = $OdiScmConfig["Tools"]["Jisql Java Home"]
			write-host "$IM found Jisql Java Home directory <$JisqlJavaHomeDir> from INI file"
		}
	}
	
	if ($JisqlJavaHomeDir -eq "") {
		write-host "$EM no Jisql Java Home entry in Tools section in INI file"
		return $False
	}
	else {
		write-host "$IM using Jisql Java Home home directory <$JisqlJavaHomeDir>"
	}
	
	#
	# Determine the Jisql home directory to use.
	#
	$script:JisqlHomeDir = ""
	
	if ($OdiScmConfig.ContainsKey("Tools")) {
		if ($OdiScmConfig["Tools"].ContainsKey("Jisql Home")) {
			$script:JisqlHomeDir = $OdiScmConfig["Tools"]["Jisql Home"]
			write-host "$IM found Jisql Home <$JisqlHomeDir> from INI file"
		}
	}
	
	if ($JisqlHomeDir -eq "") {
		write-host "$EM no Jisql Home entry in Tools section in INI file"
		return $False
	}
	else {
		write-host "$IM using Jisql Home home directory <$JisqlHomeDir>"
	}
	
	#
	# Determine the Oracle home directory to use.
	#
	$script:OracleHomeDir = ""
	
	if ($OdiScmConfig.ContainsKey("Tools")) {
		if ($OdiScmConfig["Tools"].ContainsKey("Oracle Home")) {
			$script:OracleHomeDir = $OdiScmConfig["Tools"]["Oracle Home"]
			write-host "$IM found Oracle Home directory <$OracleHomeDir> from INI file"
		}
	}
	
	if ($OracleHomeDir -eq "") {
		write-host "$EM no Oracle Home entry in Tools section in INI file"
		return $False
	}
	else {
		write-host "$IM using Oracle Home home directory <$OracleHomeDir>"
	}
	
	write-host "$IM using SCM System Type Name <$SCMSystemTypeName>"
	write-host "$IM using SCM System URL       <$SCMSystemUrl>"
	write-host "$IM using SCM Branch URL       <$SCMBranchUrl>"
	
	#
	# Add the Import Controls section if not already in the INI file.
	#
	if (!($OdiScmConfig.ContainsKey("Import Controls"))) {
		LogDebug "MM debugging" "Adding Import Controls section"
		###DebuggingPause
		$script:OdiScmConfig["Import Controls"] = @{}
		write-host "added : " $OdiScmConfig["Import Controls"]
	}
	else {
		write-host "$IM configuration INI file contains Import Controls section"
	}
	
	if (!($OdiScmConfig["Import Controls"].ContainsKey("Working Copy Revision"))) {
		if ($OdiScmConfig["SCM System"]["Type Name"] -eq "TFS") {
			LogDebug "MM debugging" "Adding Working Copy Revision key for TFS"
			###DebuggingPause
			$script:OdiScmConfig["Import Controls"]["Working Copy Revision"] = "1"
			write-host "added : " $OdiScmConfig["Import Controls"]["Working Copy Revision"]
		}
		else { # I.e. SVN.
			LogDebug "MM debugging" "Adding Working Copy Revision key for SVN"
			###DebuggingPause
			$script:OdiScmConfig["Import Controls"]["Working Copy Revision"] = "0"
			write-host "added : " $OdiScmConfig["Import Controls"]["Working Copy Revision"]
		}
	}
	else {
		write-host "$IM configuration INI file contains Working Copy Revision key entry in Import Controls section"
		$KeyEntry = $OdiScmConfig["Import Controls"]["Working Copy Revision"]
		write-host "$IM key entry is <$KeyEntry>"
	}
	
	if (!($OdiScmConfig["Import Controls"].ContainsKey("OracleDI Imported Revision"))) {
		if ($OdiScmConfig["SCM System"]["Type Name"] -eq "TFS") {
			LogDebug "MM debugging" "Adding OracleDI Imported Revision key for SVN"
			###DebuggingPause
			$script:OdiScmConfig["Import Controls"]["OracleDI Imported Revision"] = "1"
			write-host "added : " $OdiScmConfig["Import Controls"]["OracleDI Imported Revision"]
		}
		else { # I.e. SVN.
			LogDebug "MM debugging" "Adding OracleDI Imported Revision key for SVN"
			###DebuggingPause
			$script:OdiScmConfig["Import Controls"]["OracleDI Imported Revision"] = "0"
			write-host "added : " $OdiScmConfig["Import Controls"]["OracleDI Imported Revision"]
		}
	}
	else {
		write-host "$IM configuration INI file contains OracleDI Imported Revision key entry in Import Controls section"
		$KeyEntry = $OdiScmConfig["Import Controls"]["OracleDI Imported Revision"]
		write-host "$IM key entry is <$KeyEntry>"
	}
	
	#
	# Look for repository connection details in the INI file overriding those in odiparams.
	#
	if ($OdiScmConfig.ContainsKey("OracleDI")) {
	
		if ($OdiScmConfig["OracleDI"].ContainsKey("Secu Driver")) {
			$script:OdiRepoSECURITY_DRIVER = $OdiScmConfig["OracleDI"]["Secu Driver"]
			write-host "$IM found INI file OracleDI Secu Driver       <$OdiRepoSECURITY_DRIVER>"
		}
		
		if ($OdiScmConfig["OracleDI"].ContainsKey("Secu Url")) {
			$script:OdiRepoSECURITY_URL = $OdiScmConfig["OracleDI"]["Secu Url"]
			write-host "$IM found INI file OracleDI Secu Url          <$OdiRepoSECURITY_URL>"
		}
		
		if ($OdiScmConfig["OracleDI"].ContainsKey("Secu User")) {
			$script:OdiRepoSECURITY_USER = $OdiScmConfig["OracleDI"]["Secu User"]
			write-host "$IM found INI file OracleDI Secu User         <$OdiRepoSECURITY_USER>"
		}
		
		if ($OdiScmConfig["OracleDI"].ContainsKey("Secu Encoded Pass")) {
			$script:OdiRepoSECURITY_PWD = $OdiScmConfig["OracleDI"]["Secu Encoded Pass"]
			write-host "$IM found INI file OracleDI Secu Encoded Pass <$OdiRepoSECURITY_PWD>"
		}
		
		if ($OdiScmConfig["OracleDI"].ContainsKey("Secu Pass")) {
			$script:OdiRepoSECURITY_UNENC_PWD = $OdiScmConfig["OracleDI"]["Secu Pass"]
			write-host "$IM found INI file OracleDI Secu Pass         <$OdiRepoSECURITY_UNENC_PWD>"
		}
		
		if ($OdiScmConfig["OracleDI"].ContainsKey("Secu Work Rep")) {
			$script:OdiRepoWORK_REP_NAME = $OdiScmConfig["OracleDI"]["Secu Work Rep"]
			write-host "$IM found INI file OracleDI Secu Work Rep     <$OdiRepoWORK_REP_NAME>"
		}
		
		if ($OdiScmConfig["OracleDI"].ContainsKey("User")) {
			$script:OdiRepoUSER = $OdiScmConfig["OracleDI"]["User"]
			write-host "$IM found INI file OracleDI User              <$OdiRepoUSER>"
		}
		
		if ($OdiScmConfig["OracleDI"].ContainsKey("Encoded Pass")) {
			$script:OdiRepoPASSWORD = $OdiScmConfig["OracleDI"]["Encoded Pass"]
			write-host "$IM found INI file OracleDI Encoded Pass      <$OdiRepoPASSWORD>"
		}
	}
	
	if ($OdiRepoSECURITY_DRIVER.length -eq 0) {
		write-host "$EM no value for connection parameter OracleDI Secu Driver in INI file"
		return $False
	}
	
	if ($OdiRepoSECURITY_URL.length -eq 0) {
		write-host "$EM no value for connection parameter OracleDI Secu Url in INI file"
		return $False
	}
	
	if ($OdiRepoSECURITY_USER.length -eq 0) {
		write-host "$EM no value for connection parameter OracleDI Secu User in INI file"
		return $False
	}
	
	if ($OdiRepoSECURITY_PWD.length -eq 0) {
		write-host "$EM no value for connection parameter OracleDI Secu Encoded Pass in INI file"
		return $False
	}
	
	if ($OdiRepoSECURITY_UNENC_PWD.length -eq 0) {
		write-host "$EM no value for connection parameter OracleDI Secu Pass in INI file"
		return $False
	}
	
	if ($OdiRepoWORK_REP_NAME.length -eq 0) {
		write-host "$EM no value for connection parameter OracleDI Secu Work Rep in INI file"
		return $False
	}
	
	if ($OdiRepoUSER.length -eq 0) {
		write-host "$EM no value for connection parameter OracleDI User in INI file"
		return $False
	}
	
	if ($OdiRepoPASSWORD.length -eq 0) {
		write-host "$EM no value for connection parameter OracleDI Encoded Pass in INI file"
		return $False
	}
	
	[array] $OdiIniSecuUrlParts = @([regex]::split($OdiRepoSECURITY_URL,":"))
	
	$script:OdiRepoSECURITY_URL_SERVER = $OdiIniSecuUrlParts[3].Replace("@","")
	if ($OdiRepoSECURITY_URL_SERVER.length -eq 0) {
		write-host "$EM no value for server field of connection parameter OracleDI Secu Url in INI file"
		return $False
	}
	
	$script:OdiRepoSECURITY_URL_PORT = $OdiIniSecuUrlParts[4]
	if ($OdiRepoSECURITY_URL_PORT.length -eq 0) {
		write-host "$EM no value for port field of connection parameter OracleDI Secu Url in INI file"
		return $False
	}
	
	$script:OdiRepoSECURITY_URL_SID = $OdiIniSecuUrlParts[5]
	if ($OdiRepoSECURITY_URL_SID.length -eq 0) {
		write-host "$EM no value for SID field of connection parameter OracleDI Secu Url in INI file"
		return $False
	}
	
	write-host "$IM from OracleDI Secu Url extracted server   <$OdiRepoSECURITY_URL_SERVER>"
	write-host "$IM from OracleDI Secu Url extracted port     <$OdiRepoSECURITY_URL_PORT>"
	write-host "$IM from OracleDI Secu Url extracted SID      <$OdiRepoSECURITY_URL_SID>"
	
	#
	# Set process-level environment variables for those read from the INI file.
	# Note process (i.e. session) level environment variables can be set simply using "$env:<var> = <value>".
	#
	#[Environment]::SetEnvironmentVariable("ODI_HOME", "$OdiHomeDir", "Process")
	#[Environment]::SetEnvironmentVariable("ODI_JAVA_HOME", "$OdiJavaHomeDir", "Process")
	#[Environment]::SetEnvironmentVariable("JAVA_HOME", "$JavaHomeDir", "Process")
	#[Environment]::SetEnvironmentVariable("ODI_SCM_JISQL_HOME", "$JisqlHomeDir", "Process")
	
	#
	# Load any behaviour controlling options.
	#
	if ($OdiScmConfig.ContainsKey("Generate")) {
		if ($OdiScmConfig["Generate"].ContainsKey("Output Tag")) {
			$GenScriptTag = $OdiScmConfig["Generate"]["Output Tag"]
			if ($GenScriptTag -ne "") {
				write-host "$IM using fixed output tag <$GenScriptTag>"
			}
		}
	}
	
	write-host "$IM ends"
	return $True
}

#
# Set output file and directory name contants.
#
function SetOutputNames {
	
	$FN = "SetOutputNames"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	$WM = $FN + ": WARNING:"
	$DEBUG = $FN + ": DEBUG:"
	
	if ($OdiScmConfig.ContainsKey("Generate")) {
		if ($OdiScmConfig["Generate"].ContainsKey("Output Tag")) {
			$OutputTag = $OdiScmConfig["Generate"]["Output Tag"]
			if ($OutputTag -ne "") {
				write-host "$IM using fixed output tag <$OutputTag>"
			}
			else {
				$OutputTag = ${VersionString}
				write-host "$IM using variable output tag <$OutputTag>"
			}
		}
	}
	else {
		$OutputTag = ${VersionString}
		write-host "$IM using variable output tag <$OutputTag>"
	}
	
	#
	# Generated script locations and names.
	#
	$script:GenScriptRootDir = $LogRootDir + "\${OutputTag}"
	
	$script:OdiScmOdiStartCmdBat = $GenScriptRootDir + "\OdiScmStartCmd_${OutputTag}.bat"
	$script:OdiScmJisqlRepoBat = $GenScriptRootDir + "\OdiScmJisqlRepo_${OutputTag}.bat"
	$script:OdiScmRepositoryBackUpBat = $GenScriptRootDir + "\OdiScmRepositoryBackUp_${OutputTag}.bat"
	$script:OdiScmBuildBat = $GenScriptRootDir + "\OdiScmBuild_${OutputTag}.bat"
	$script:OdiScmGenScenPreImportBat = $GenScriptRootDir + "\OdiScmGenScenPreImport_${OutputTag}.bat"
	$script:OdiScmGenScenPostImportBat = $GenScriptRootDir + "\OdiScmGenScenPostImport_${OutputTag}.bat"
	$script:OdiScmGenScenDeleteOldSql = $GenScriptRootDir + "\OdiScmGenScen20DeleteOldScen_${OutputTag}.sql"
	$script:OdiScmGenScenNewSql = $GenScriptRootDir + "\OdiScmGenScen40NewScen_${OutputTag}.sql"
	$script:OdiScmRepoInfrastructureSetupSql = $GenScriptRootDir + "\OdiScmCreateInfrastructure_${OutputTag}.sql"
	$script:OdiScmRepoSetNextImport = $GenScriptRootDir + "\OdiScmSetNextImport_${OutputTag}.sql"
	$script:OdiScmBuildNote = $GenScriptRootDir + "\OdiScmBuildNote_${OutputTag}.txt"
	
	$script:ImportScriptStubName = "OdiScmImport_" + ${OutputTag}
	$script:OdiImportScriptName = $ImportScriptStubName + ".bat"
	$script:OdiImportScriptFile = $GenScriptRootDir + "\$OdiImportScriptName"
	
	if (Test-Path $GenScriptRootDir) { 
		write-host "$IM generated scripts root directory <$GenScriptRootDir> already exists"
	}
	else {  
		write-host "$IM creating generated scripts root directory <$GenScriptRootDir>"
		New-Item -itemtype directory $GenScriptRootDir 
	}
	
	$script:GetLatestVersionOutputFile = $GenScriptRootDir + "\GetFromSCM_" + ${OutputTag} + ".txt"
	write-host "$IM GetIncremental output will be written to <$GetLatestVersionOutputFile>"
	$script:GetLatestVersionConflictsOutputFile = $GenScriptRootDir + "\GetLatestVersionConflicts_Results_" + ${OutputTag} + ".txt"
	
	if (Test-Path $OdiImportScriptFile) {
		write-host "$IM generated ODI import batch file <$OdiImportScriptFile> already exists"
	}
	else {
		write-host "$IM creating empty generated ODI import batch file <$OdiImportScriptFile>"
			New-Item -itemtype file $OdiImportScriptFile 
	}
	
	write-host "$IM ends"
	return $True
}

#
# The main function.
#
function GetIncremental {
	
	$FN = "GetIncremental"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	$DEBUG = $FN + ": DEBUG:"
	
	write-host "$IM starts"
	$ExitStatus = $False
	
	if (!(GetOdiScmConfiguration)) {
		write-host "$EM error loading SCM server configuration"
		return $False
	}
	
	if (!(SetOutputNames)) {
		write-host "$EM error setting output file and directory names"
		return $False
	}
	
	if (!(CheckDependencies)) {
		return $ExitStatus
	}
	
	#
	# Set up the ODI repository SQL access script.
	#
	if (!(SetOdiScmJisqlRepoBatContent)) {
		write-host "$EM error creating custom ODI repository SQL access script"
		return $ExitStatus
	}
	
	#
	# Set up the OdiScm repository infrastructure creation script.
	#
	if (!(SetOdiScmRepoCreateInfractureSqlContent)) {
		write-host "$EM error creating OdiScm infrastructure creation script"
		return $ExitStatus
	}
	
	#
	# Ensure the OdiScm repository infrastructure has been set up.
	#
	$CmdOutput = ExecOdiRepositorySql("$OdiScmRepoInfrastructureSetupSql")
	if (! $CmdOutput) {
		write-host "$EM error creating OdiScm repository infrastructure"
		return $ExitStatus
	}
	###DebuggingPause
	#
	# Get the last Revision number successfully applied to the local workspace
	# from the local metadata.
	#
	$LocalControlChangeSet = $OdiScmConfig["Import Controls"]["Working Copy Revision"]
	
	###if (($LocalControlChangeSet.substring(($LocalControlChangeSet.length) - 1)) -ne "~") {
	if (($LocalControlChangeSet -eq "") -or ($LocalControlChangeSet -eq $Null)) {
		write-host "$EM format of local workspace next import metadata <$LocalControlChangeSet> is invalid"
		write-host "$EM format must be '<last imported revision number>'"
		return $False
	}
	###$LocalControlLastChangeSet = $LocalControlChangeSet.substring(0,($LocalControlChangeSet.length) - 1)
	$LocalControlLastChangeSet = $LocalControlChangeSet
	write-host "$IM local metadata: last Revision applied to the local workspace <$LocalControlLastChangeSet>"
	###DebuggingPause
	#
	# Get the last Revision number successfully applied to the ODI repository
	# from the local metadata.
	#
	$LocalODIControlChangeSet = $OdiScmConfig["Import Controls"]["OracleDI Imported Revision"]
	
	###if (($LocalODIControlChangeSet.substring(($LocalODIControlChangeSet.length) - 1) -ne "~")) {
	if (($LocalODIControlChangeSet -eq "") -or ($LocalODIControlChangeSet -eq $Null)) {
		write-host "$EM format of local workspace next import metadata <$LocalODIControlChangeSet> is invalid"
		write-host "$EM format must be '<last imported revision number>'"
		return $False
	}
	###$LocalODIControlLastChangeSet = $LocalODIControlChangeSet.substring(0,($LocalODIControlChangeSet.length) - 1)
	$LocalODIControlLastChangeSet = $LocalODIControlChangeSet
	write-host "$IM local metadata: last Revision applied to the ODI repository <$LocalODIControlLastChangeSet>"
	###DebuggingPause
	#
	# Check that the Revisions applied to the local workspace have been imported into the
	# ODI repository.
	#
	if ($LocalControlLastChangeSet -ne $LocalODIControlLastChangeSet) {
		write-host "$EM the local workspace version <$LocalControlLastChangeSet> is different to the ODI repository"
		write-host "$EM version <$LocalODIControlLastChangeSet>. The ODI repository must be updated to the same version"
		write-host "$EM before this script can be run again".
		return $False
	}
	###DebuggingPause
	#
	# Get the OdiScm metadata from the ODI repository.
	#
	$CmdOutput = ExecOdiRepositorySql("$ScriptsRootDir\OdiScmGetLastImport.sql")
	if (! $CmdOutput) {
		write-host "$EM error retrieving last imported revision from OdiScm repository metadata"
		return $ExitStatus
	}
	###DebuggingPause
	$CmdOutput = $CmdOutput.TrimStart("ExecOdiRepositorySql:")
	$StringList = @([regex]::split($CmdOutput.TrimStart("ExecOdiRepositorySql:"),"!!"))
	$OdiRepoBranchName = $StringList[0]
	###DebuggingPause
	###$OdiLastImportList = @([regex]::split($StringList[1],"~"))
	###[string] $OdiRepoLastImportTo = $OdiLastImportList[0]
	[string] $OdiRepoLastImportTo = $StringList[1]
	###DebuggingPause
	write-host "$IM from ODI repository: got Branch URL             <$OdiRepoBranchName>"
	write-host "$IM from ODI repository: got Last Imported Revision <$OdiRepoLastImportTo>"
	###DebuggingPause
	#
	# Get the latest Revision number from the SCM repository.
	#
	write-host "$IM getting latest Revision number from the SCM repository"
	$HighChangeSetNumber = GetNewChangeSetNumber
	write-host "$IM latest Revision number returned is <$HighChangeSetNumber>"
	###DebuggingPause
	$difference = $LocalODIControlChangeSet + "~" + $HighChangeSetNumber
	write-host "$IM new Revision range to apply to the local workspace is <$difference>"
	
	if (!(ChangeSetRangeIsValid($difference))) {
		write-host "$EM the derived Revision range <$difference> is invalid"
		return $ExitStatus
	}
	###DebuggingPause
	# TODO: pass references to $LocalLastImportFrom/$LocalLastImportTo and make ChangeSetRangeIsValid
	#       set the values.
	$StringList = @([regex]::split($difference,"~"))
	[string] $LocalLastImportFrom = $StringList[0]
	[string] $LocalLastImportTo = $StringList[1]
	###DebuggingPause
	
	$SCMSystemTypeName = $OdiScmConfig["SCM System"]["Type Name"]
	if ($SCMSystemTypeName -eq "TFS") {
		if ($LocalLastImportFrom -ne "1") {
			write-host "$IM this is not the initial GetIncremental update. An incremental Get will be run"
			$FullImportInd = $False
		}
		else {
			write-host "$IM this is the initial GetIncremental update. An full/initial Get will be run"
			$FullImportInd = $True
		}
	}
	elseif ($SCMSystemTypeName -eq "SVN") {
		if ($LocalLastImportFrom -ne "0") {
			write-host "$IM this is not the initial GetIncremental update. An incremental Get will be run"
			$FullImportInd = $False
		}
		else {
			write-host "$IM this is the initial GetIncremental update. An full/initial Get will be run"
			$FullImportInd = $True
		}
	}
	###DebuggingPause
	#
	# Check the ODI repository infrastructure metadata against the local workspace metadata.
	#
	if ($FullImportInd) {
		####if (($OdiRepoBranchName -ne "") -or ($OdiRepoLastImportFrom -ne "") -or ($OdiRepoLastImportTo -ne "")) {
		if (($OdiRepoBranchName -ne "") -or ($OdiRepoLastImportTo -ne "")) {
			write-host "$EM The ODI repository metadata indicates that the ODI repository has been previously updated"
			write-host "$EM by this mechanism but the local workspace metadata indicates that a full import operation"
			write-host "$EM should be run. Perform one of the following actions before rerunning this script:"
			write-host "$EM 1) Delete all repository contents via the Designer/Topology Manager GUIs."
			write-host "$EM 2) Create a new repository with a previously unused internal ID and update your odiparams.bat"
			write-host "$EM    with the new repository details."
			write-host "$EM 3) If you fully understand the potential consequences and still REALLY want to perform the"
			write-host "$EM    import into the ODI repository then delete the existing branch and ChangeSet metadata from"
			write-host "$EM    the ODI repository table ODISCM_CONTROLS"
			write-host "$EM NOTE: do not drop the repository and recreate it with the same ID if there is ANY chance of"
			write-host "$EM       objects having been created in it that have been distributed to other repositories"
			write-host "$EM       as this will cause conflicts and potential repository corruption."
			write-host "$EM       In order to perform this action safely you MUST the repository pre-TearDown and and"
			write-host "$EM       post-Rebuild scripts provided in the Scripts directory"
			return $ExitStatus
		}
	}
	###DebuggingPause
	if (!($FullImportInd)) {
		if ($OdiRepoBranchName -ne ($OdiScmConfig["SCM System"]["Branch Url"]).Trim()) {
			write-host "$EM The local workspace metadata indicates that the ODI repository has been previously updated"
			write-host "$EM by this mechanism but the ODI repository branch name does not match the local workspace branch name."
			write-host "$EM Perform one of the following actions before rerunning this script:"
			write-host "$EM 1) Delete all repository contents via the Designer/Topology Manager GUIs."
			write-host "$EM 2) Create a new repository with a previously unused internal ID and update your odiparams.bat"
			write-host "$EM    with the new repository details."
			write-host "$EM 3) If you fully understand the potential consequences and still REALLY want to perform the"
			write-host "$EM    import into the ODI repository then update the existing branch and ChangeSet metadata in"
			write-host "$EM    the ODI repository."
			write-host "$EM NOTE: do not drop the repository and recreate it with the same ID if there is ANY chance of"
			write-host "$EM       objects having been created in it that have been distributed to other repositories"
			write-host "$EM       as this will cause conflicts and potential repository corruption."
			write-host "$EM       In order to perform this action safely you MUST the repository pre-TearDown and and"
			write-host "$EM       post-Rebuild scripts provided in the Scripts directory"
			LogDebug "$FN" "OdiRepoBranchName <$OdiRepoBranchName>"
			LogDebug "$FN" ("OdiScmConfig[SCM System][Branch Url] <" + ($OdiScmConfig["SCM System"]["Branch Url"]).Trim() + ">")
			return $ExitStatus
		}
	}
	###DebuggingPause
	if (!($FullImportInd) -and ($OdiRepoLastImportTo -ne $LocalLastImportFrom)) {
		write-host "$EM the last ODI repository imported ChangeSet <$OdiLastImportTo> number does not match"
		write-host "$EM the last ChangeSet number <$LocalLastImportFrom> from the local workspace"
		return $ExitStatus
	}
	###DebuggingPause
	[array] $fileList = @()
	###DebuggingPause
	if ($LocalLastImportFrom -eq $LocalLastImportTo) {
		write-host "$IM the local workspace is already up to date with the SCM repository"
		$ExitStatus = $True
		return $ExitStatus
	}
	
	#
	# Create a backup of the configuration INI file.
	#
	$SCMConfigurationBackUpFile = $GenScriptRootDir + "\" + $SCMConfigurationFileName + ".BackUp"
	write-host "$IM creating back-up of configuration file <$SCMConfigurationFile> to <$SCMConfigurationBackUpFile>"
	get-content $SCMConfigurationFile | set-content $SCMConfigurationBackUpFile
	
	#
	# Get the update from the SCM system.
	#
	[array] $TFSGetFileList = @()
	[ref] $ArrayRef = [ref]$TFSGetFileList
	if (!(GetFromSCM $HighChangeSetNumber $ArrayRef)) {
		write-host "$EM failure getting latest code from the SCM repository"
		return $False
	}
	
	write-host "$IM GetFromSCM returned <$($TFSGetFileList.length)> ODI source files to import"
	###DebuggingPause
	#
	# Generate the ODI object import commands in the generated script.
	#
	if (!(GenerateOdiImportScript $TFSGetFileList)) { 
		write-host "$EM call to GenerateOdiImportScript failed"
		return $ExitStatus
	}
	###DebuggingPause
	
	#
	# Set up the startcmd script.
	#
	if (!(SetStartCmdContent)) {
		write-host "$EM call to SetStartCmdContent failed"
		return $ExitStatus
	}
	
	#
	# Set up the OdiScm next import metadata update script.
	#
	if (!(SetOdiScmRepoSetNextImportSqlContent $HighChangeSetNumber)) {
		write-host "$EM call to SetOdiScmRepoSetNextImportSqlContent failed"
		return $ExitStatus
	}
	###DebuggingPause
	#
	# Set up the OdiScm build note.
	#
	if (!(SetOdiScmBuildNoteContent $difference)) {
		write-host "$EM call to SetOdiScmBuildNoteContent failed"
		return $ExitStatus
	}
	###DebuggingPause
	#
	# Set up the OdiScm repository back-up script content.
	#
	if (!(SetOdiScmRepositoryBackUpBatContent)) {
		write-host "$EM call to SetOdiScmRepositoryBackUpBatContent failed"
		return $ExitStatus
	}
	
	#
	# Set up the pre-ODI import script content.
	#
	if (!(SetOdiScmPreImportBatContent)) {
		write-host "$EM setting content in pre-ODI import script"
		return $ExitStatus
	}
	
	#
	# Set up the post-ODI import Scenario deletion generator script content.
	#
	if (!(SetOdiScmGenScenDeleteOldSqlContent)) {
		write-host "$EM call to SetOdiScmGenScenDeleteOldSqlContent failed"
		return $ExitStatus
	}
	
	#
	# Set up the post-ODI import Scenario generation generator script content.
	#
	if (!(SetOdiScmGenScenNewSqlContent)) {
		write-host "$EM call to SetOdiScmGenScenNewSqlContent failed"
		return $ExitStatus
	}
	
	#
	# Set up the post-ODI import script content.
	#
	if (!(SetOdiScmPostImportBatContent)) {
		write-host "$EM setting content in post-ODI import script"
		return $ExitStatus
	}
	###DebuggingPause
	#
	# Set up the top level build script content.
	#
	if (!(SetTopLevelScriptContent $HighChangeSetNumber)) {
		write-host "$EM setting content in main script"
		return $ExitStatus
	}
	###DebuggingPause
	write-host "$IM your local workspace has been updated. Execute the following script to perform"
	write-host "$IM the ODI source code import, Scenario generation and update the local OdiScm metadata"
	write-host "$IM"
	write-host "$IM <$OdiScmBuildBat>"
	
	$ExitStatus = $True
	
	write-host "$IM ends"
	return $ExitStatus
}

#######################################################################################
#
# Set the content of generated scripts.
#
#######################################################################################

#
# Generate a version of startcmd.bat that uses the derived repository connection details.
# I.e. extracted from odiparams.bat and optionally overridden in the INI file.
#
function SetStartCmdContent {
	
	$FN = "SetStartCmdContent"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	write-host "$IM starts"
	
	$CmdLine = $CmdLine + "cmd.exe /c " + '"' + "$env:ODI_SCM_HOME\Configuration\Scripts\OdiScmGenStartCmd.bat" + '" "' + "$OdiScmOdiStartCmdBat" + '"'
	write-host "$DEBUG running: $CmdLine"
	invoke-expression $CmdLine
	if ($LastExitCode -ne 0) {
		write-host "$EM generating StartCmd batch script <$OdiScmOdiStartCmdBat>"
		return $False
	}
	
	# $StartCmdBat = $OdiBinDir + "\startcmd.bat"
	
	# $ScriptFileContent = get-content $StartCmdBat | out-string
	# $ScriptFileContent = $ScriptFileContent.Replace("%ODI_SECU_DRIVER%",$OdiRepoSECURITY_DRIVER)
	# $ScriptFileContent = $ScriptFileContent.Replace("%ODI_SECU_URL%",$OdiRepoSECURITY_URL)
	# $ScriptFileContent = $ScriptFileContent.Replace("%ODI_SECU_USER%",$OdiRepoSECURITY_USER)
	# $ScriptFileContent = $ScriptFileContent.Replace("%ODI_SECU_ENCODED_PASS%",$OdiRepoSECURITY_PWD)
	# $ScriptFileContent = $ScriptFileContent.Replace("%ODI_USER%",$OdiRepoUSER)
	# $ScriptFileContent = $ScriptFileContent.Replace("%ODI_ENCODED_PASS%",$OdiRepoPASSWORD)
	# $ScriptFileContent = $ScriptFileContent.Replace("%ODI_SECU_WORK_REP%",$OdiRepoWORK_REP_NAME)
	
	# set-content -path $OdiScmOdiStartCmdBat -value $ScriptFileContent
	
	write-host "$IM ends"
	
	return $True
}

#
# Generate the script to back up the ODI repository.
#
function SetOdiScmRepositoryBackUpBatContent {
	
	$FN = "SetOdiScmRepositoryBackUpBatContent"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	write-host "$IM starts"
	
	#
	# Set up the OdiScm ODI repository back-up script.
	#
	$ScriptFileContent = get-content $OdiScmRepositoryBackUpBatTemplate | out-string
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiWorkRepoUserName>",$OdiRepoSECURITY_USER)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiWorkRepoPassWord>",$OdiRepoSECURITY_UNENC_PWD)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiWorkRepoServer>",$OdiRepoSECURITY_URL_SERVER)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiWorkRepoPort>",$OdiRepoSECURITY_URL_PORT)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiWorkRepoSID>",$OdiRepoSECURITY_URL_SID)
	
	$ExportFileName = "$GenScriptRootDir" + "\OdiScmExportBackUp_${OdiRepoSECURITY_USER}_${OdiRepoSECURITY_URL_SERVER}_${OdiRepoSECURITY_URL_SID}_${VersionString}.dmp"
	$ScriptFileContent = $ScriptFileContent.Replace("<ExportBackUpFile>",$ExportFileName)
	
	set-content -path $OdiScmRepositoryBackUpBat -value $ScriptFileContent
	
	write-host "$IM ends"
	
	return $True
}

#
# Generate the batch file OdiScmJisqlRepo.bat.
# This batch file is used to execute SQL statements directly against the ODI repository
# whose details are specified in "odiparams.bat" and optionally overridden in the INI file.
#
function SetOdiScmJisqlRepoBatContent {
	
	$FN = "SetOdiScmJisqlRepoBatContent"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"

	write-host "$IM starts"
	$fileContent = get-content $OdiScmJisqlRepoBatTemplate | out-string 
	
	$fileContent = $fileContent.Replace("<OdiScmHomeDir>",$OdiScmHomeDir)
	$fileContent = $fileContent.Replace("<ScriptsRootDir>",$ScriptsRootDir)
	$fileContent = $fileContent.Replace("<SECURITY_DRIVER>",$OdiRepoSECURITY_DRIVER)
	$fileContent = $fileContent.Replace("<SECURITY_URL>",$OdiRepoSECURITY_URL)
	$fileContent = $fileContent.Replace("<SECURITY_USER>",$OdiRepoSECURITY_USER)  
	$fileContent = $fileContent.Replace("<SECURITY_UNENC_PWD>",$OdiRepoSECURITY_UNENC_PWD)
	
	set-content $OdiScmJisqlRepoBat -value $fileContent
	
	write-host "$IM completed modifying content of <$OdiScmJisqlRepoBat>"
	write-host "$IM ends"
	
	return $True
}

#
# Generate the script to set up the OdiScm ODI repository metadata infrastructure.
#
function SetOdiScmRepoCreateInfractureSqlContent {
	
	$FN = "SetOdiScmRepoCreateIntractureBatContent"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	write-host "$IM starts"
	
	#
	# Set up the OdiScm metadata infrastructure creation script.
	#
	$ScriptFileContent = get-content $OdiScmRepoInfrastructureSetupSqlTemplate | out-string
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiWorkRepoUserName>",$OdiRepoSECURITY_USER)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiWorkRepoPassWord>",$OdiRepoSECURITY_UNENC_PWD)
	
	###$OraConn = "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$OdiRepoSECURITY_URL_SERVER)(PORT=$OdiRepoSECURITY_URL_PORT))(CONNECT_DATA=(SID=$OdiRepoSECURITY_URL_SID))))"
	$OraConn = "$OdiRepoSECURITY_URL_SERVER:$OdiRepoSECURITY_URL_PORT/$OdiRepoSECURITY_URL_SID"
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiWorkRepoConnectionString>",$OraConn)
	set-content -path $OdiScmRepoInfrastructureSetupSql -value $ScriptFileContent
	
	write-host "$IM ends"
	
	return $True
}

#
# Generate the script to set up the OdiScm ODI repository metata infrastructure.
#
function SetOdiScmRepoSetNextImportSqlContent ($NextImportChangeSetRange) {
	
	$FN = "SetOdiScmRepoSetNextImportSqlContent"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	write-host "$IM starts"
	
	#
	# Set up the OdiScm metadata update script.
	#
	$SCMBranchUrl = $OdiScmConfig["SCM System"]["Branch Url"]
	
	$ScriptFileContent = get-content $OdiScmRepoSetNextImportTemplate | out-string
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmBranchUrl>",$SCMBranchUrl)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmNextImportRevison>",$NextImportChangeSetRange)
	
	set-content -path $OdiScmRepoSetNextImport -value $ScriptFileContent
	
	write-host "$IM ends"
	return $True
}

#
# Generate the build note content.
#
function SetOdiScmBuildNoteContent ($VersionRange) {
	
	$FN = "SetOdiScmBuildNoteContent"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	write-host "$IM starts"
	
	$NoteText = get-content $OdiScmBuildNoteTemplate | out-string
	if (!($?)) {
		write-host "$EM getting build note tempate text from template file <$OdiScmBuildNoteTemplate>"
		return $False
	}
	
	$NoteText = $NoteText.Replace("<ScmSystemTypeName>" , $OdiScmConfig["SCM System"]["Type Name"])
	$NoteText = $NoteText.Replace("<ScmSystemUrl>"      , $OdiScmConfig["SCM System"]["System Url"])
	$NoteText = $NoteText.Replace("<ScmBranchUrl>"      , $OdiScmConfig["SCM System"]["Branch Url"])
	$NoteText = $NoteText.Replace("<VersionRange>"      , $VersionRange)
	$NoteText = $NoteText.Replace("<WorkingCopyRootDir>", $WorkingCopyRootDir)
	
	set-content $OdiScmBuildNote $NoteText
	if (!($?)) {
		write-host "$EM setting build note tempate text in file <$OdiScmBuildNote>"
		return $False
	}
	
	write-host "$IM ends"
	return $True
}

#
# Generate the pre-ODI import script.
#
function SetOdiScmPreImportBatContent {
	
	$FN = "SetOdiScmPreImportBatContent"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	write-host "$IM starts"
	write-host "$IM using script template file <$OdiScmGenScenPreImportBatTemplate>"
	write-host "$IM setting content of pre ODI import script file <$OdiScmGenScenPreImportBat>"
	
	$ExitStatus = $False
	
	$ScriptFileContent = get-content $OdiScmGenScenPreImportBatTemplate | out-string
	
	#
	# Set the script path/names.
	#
	$ScriptFileContent = $ScriptFileContent.Replace("<GenScriptRootDir>",$GenScriptRootDir)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmJisqlRepoBat>",$OdiScmJisqlRepoBat)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmHomeDir>",$OdiScmHomeDir)
	set-content -path $OdiScmGenScenPreImportBat -value $ScriptFileContent
	
	$ExitStatus = $True
	
	write-host "$IM ends"
	return $ExitStatus
}

#
# Generate the Scenario deletion script generation script.
#
function SetOdiScmGenScenDeleteOldSqlContent {
	
	$FN = "SetOdiScmGenScenDeleteOldSqlContent"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	write-host "$IM starts"
	write-host "$IM using script template file <$OdiScmGenScenDeleteOldSqlTemplate>"
	write-host "$IM setting content of pre ODI import script file <$OdiScmGenScenDeleteOldSql>"
	
	$ExitStatus = $False
	
	$ScriptFileContent = get-content $OdiScmGenScenDeleteOldSqlTemplate | out-string
	
	#
	# Set the script path/names.
	#
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmOdiStartCmdBat>",$OdiScmOdiStartCmdBat)
	set-content -path $OdiScmGenScenDeleteOldSql -value $ScriptFileContent
	
	$ExitStatus = $True
	
	write-host "$IM ends"
	return $ExitStatus
}

#
# Generate the Scenario generation script generation script.
#
function SetOdiScmGenScenNewSqlContent {
	
	$FN = "SetOdiScmGenScenNewSqlContent"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	write-host "$IM starts"
	write-host "$IM using script template file <$OdiScmGenScenNewSqlTemplate>"
	write-host "$IM setting content of pre ODI import script file <$OdiScmGenScenNewSql>"
	
	$ExitStatus = $False
	
	$ScriptFileContent = get-content $OdiScmGenScenNewSqlTemplate | out-string
	
	#
	# Set the script path/names.
	#
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmOdiStartCmdBat>",$OdiScmOdiStartCmdBat)
	set-content -path $OdiScmGenScenNewSql -value $ScriptFileContent
	
	$ExitStatus = $True
	
	write-host "$IM ends"
	return $ExitStatus
}

#
# Generate the pre-ODI import script.
#
function SetOdiScmPostImportBatContent {
	
	$FN = "SetOdiScmPostImportBatContent"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	write-host "$IM starts"
	write-host "$IM using script template file <$OdiScmGenScenPostImportBatTemplate>"
	write-host "$IM setting content of script file <$OdiScmGenScenPostImportBat>"
	
	$ExitStatus = $False
	
	$ScriptFileContent = get-content $OdiScmGenScenPostImportBatTemplate | out-string
	
	#
	# Set the script path/names.
	#
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiHomeDir>",$OdiHomeDir)
	$ScriptFileContent = $ScriptFileContent.Replace("<GenScriptRootDir>",$GenScriptRootDir)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmGenScenDeleteOldSql>",$OdiScmGenScenNewSql)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmGenScenNewSql>",$OdiScmGenScenNewSql)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmJisqlRepoBat>",$OdiScmJisqlRepoBat)
	
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmHomeDir>",$OdiScmHomeDir)
	set-content -path $OdiScmGenScenPostImportBat -value $ScriptFileContent
	
	$ExitStatus = $True
	
	write-host "$IM ends"
	return $ExitStatus
}

#
# Generate the top level script that performs the entire import/build process.
#
function SetTopLevelScriptContent ($NextImportChangeSetRange) {
	
	$FN = "SetTopLevelScriptContent"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	write-host "$IM starts"
	write-host "$IM using top level build script template file <$OdiScmBuildBatTemplate>"
	write-host "$IM setting content of top level build script file <$OdiScmBuildBat>"
	
	$ExitStatus = $False
	
	$ScriptFileContent = get-content $OdiScmBuildBatTemplate | out-string
	
	#
	# Set the script path/names, etc.
	#
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiHomeDir>",$OdiHomeDir)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiJavaHomeDir>",$OdiJavaHomeDir)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmHomeDir>",$OdiScmHomeDir)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmIniFile>",$SCMConfigurationFile)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmJisqlHomeDir>",$JisqlHomeDir)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmJisqlJavaHomeDir>",$JisqlJavaHomeDir)
	$ScriptFileContent = $ScriptFileContent.Replace("<OracleHomeDir>",$OracleHomeDir)
	
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmRepositoryBackUpBat>",$OdiScmRepositoryBackUpBat)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmGenScenPreImportBat>",$OdiScmGenScenPreImportBat)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiImportScriptFile>",$OdiImportScriptFile)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmJisqlRepoBat>",$OdiScmJisqlRepoBat)	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmValidateRepositoryIntegritySql>",$OdiScmValidateRepositoryIntegritySql)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmRestoreRepositoryIntegritySql>",$OdiScmRestoreRepositoryIntegritySql)    
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmGenScenPostImportBat>",$OdiScmGenScenPostImportBat)
	$ScriptFileContent = $ScriptFileContent.Replace("<SCMConfigurationFile>",$SCMConfigurationFile)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmLatestChangeSet>",$NextImportChangeSetRange)
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmSetNextImportSql>",$OdiScmRepoSetNextImport)
	$ScriptFileContent = $ScriptFileContent.Replace("<GenScriptRootDir>",$GenScriptRootDir)
	
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiScmUpdateIniAwk>",$OdiScmUpdateIniAwk)
	
	$ScriptFileContent = $ScriptFileContent.Replace("<OdiStandardsCheckScript>",$env:ODI_SCM_TEST_ODI_STANDARDS_SCRIPT)
	
	set-content -path $OdiScmBuildBat -value $ScriptFileContent
	
	$ExitStatus = $True
	
	write-host "$IM ends"
	return $ExitStatus
}

function GetFromSCM ($HighChangeSetNumber, [ref] $FileList) {
	
	switch ($SCMSystemTypeName) {
		"TFS" { GetFromTFS $HighChangeSetNumber $FileList }		# Note: FileList is already a reference, don't cast it again!
		"SVN" { GetFromSVN $HighChangeSetNumber $FileList }		# Note: FileList is already a reference, don't cast it again!
	}
}

#
# Perform an SVN UPDATE operation for the entire branch URL.
#
function GetFromSVN ($HighChangeSetNumber, [ref] $FileList) {
	
	# SVN CHECKOUT/MERGE/UPDATE status codes for a file.
	# A  Added
    # D  Deleted
    # U  Updated
    # C  Conflict
    # G  Merged
    # E  Existed
	
	$FN = "GetFromSVN"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	$DEBUG = $FN + ": DEBUG:"
	
	write-host "$IM starts"
	$ExitStatus = $False
	
	LogDebug "$FN" "getting from SVN to revision number <${HighChangeSetNumber}>"
	LogDebug "$FN" "changing directory to WorkingCopyRootDir of <$WorkingCopyRootDir>"
	
	#
	# need to assume current dir is an svn WC (for now at least) so we can do SVN UPDATE.
	# create the empty WC using SVN CHECKOUT <repo URL> --REVISION 0
	
	write-host "$IM previewing SVN UPDATE using SVN MERGE. Output will be recorded in file <$GetLatestVersionOutputFile>"
	
	$SCMUserName = $OdiScmConfig["SCM System"]["Global User Name"]
	$SCMUserPassword = $OdiScmConfig["SCM System"]["Global User Password"]
	
	if ($SCMUserName -ne "" -and $SCMUserName -ne $Null) {
		$SCMAuthText = "--username $SCMUserName --password $SCMUserPassword"
	}
	else {
		$SCMAuthText = ""
	}
	
	$ScmSystemSystemUrl = $OdiScmConfig["SCM System"]["System Url"]
	$ScmSystemSystemUrl.split("/") | foreach { $ScmSystemSystemUrlLastPart = $_ } | out-string
	if ($ScmSystemSystemUrlLastPart -eq "" -or $ScmSystemSystemUrlLastPart -eq $Null) {
		write-host "%EM last path component of SCM system URL <$ScmSystemSystemUrl> is empty"
		return $ExitStatus
	}
	
	$ScmSystemBranchUrl = $OdiScmConfig["SCM System"]["Branch Url"]
	$ScmSystemSystemUrl.split("/") | foreach { $ScmSystemBranchUrlLastPart = $_ } | out-string
	if ($ScmSystemBranchUrlLastPart -eq "" -or $ScmSystemBranchUrlLastPart -eq $Null) {
		write-host "%EM last path component of SCM branch URL <$ScmSystemBranchUrl> is empty"
		return $ExitStatus
	}
	
	if ($ScmSystemBranchUrlLastPart -eq ".") {
		$WcAppend = "\" + $ScmSystemSystemUrlLastPart
	}
	else {
		$WcAppend = "\" + $ScmSystemBranchUrlLastPart
	}
	
	###$CurrentWorkingDir = get-location
	###LogDebug "$FN" "CWD is $CurrentWorkingDir"
	
	$WcPath = ($WorkingCopyRootDir + $WcAppend) -replace "/", "\"
	set-location $WcPath
	if (!($?)) {
		write-host "$EM cannot change working directory to working copy root directory <$WcPath>"
		return $ExitStatus
	}
	
	$CmdLine = "svn merge --dry-run --revision BASE:" + "${HighChangeSetNumber} . $SCMAuthText >${GetLatestVersionOutputFile} 2>&1"
	write-host "$IM executing command <$CmdLine>"
	invoke-expression $CmdLine
	if ($LastExitCode -ge 1) {
		write-host "$EM execution of command failed with exit status <$LastExitCode>"
		write-host "$EM check the output file for details. All conflicts must be resolved in order for this"
		write-host "$EM script to run successfully"
		return $ExitStatus
	}
	
	#
	# Check for a conflict summary in the output.
	#
	if ($GetLatestVersionOutputFile.contains("Summary of conflicts:")) {
		write-host "$EM conflicts detected in local working copy versus repository"
		write-host "$EM check the output file for details. All conflicts must be resolved in order for this"
		write-host "$EM script to be executed successfully"
		return $ExitStatus
	}
	
	write-host "$IM no conflicts detected in local working copy versus repository"
	write-host "$IM getting update from SVN to revision <$HighChangeSetNumber>"
	
	$CmdLine = "svn update $WcPath --revision " + $HighChangeSetNumber + " $SCMAuthText >$GetLatestVersionOutputFile 2>&1" # $WorkingCopyRootDir is optional for this command.
	write-host "$IM executing command <$CmdLine>"
	invoke-expression $CmdLine
	if ($LastExitCode -ge 1) {
		write-host "$EM execution of command failed with exit status <$LastExitCode>"
		return $ExitStatus
	}
	
	#
	# Update the version of the local working copy.
	#
	# Dont use "add-content"? It always writes a newline at the end of the text.
	#(get-content -path $SCMGetLocalControlFile) + [Environment]::NewLine + $HighChangeSetNumber + "~" | set-content -path $SCMGetLocalControlFile
	####([Environment]::NewLine + $HighChangeSetNumber + "~") | add-content $SCMGetLocalControlFile
	###$script:OdiScmConfig["Import Controls"]["Working Copy Revision"] = $HighChangeSetNumber + "~"
	$script:OdiScmConfig["Import Controls"]["Working Copy Revision"] = $HighChangeSetNumber
	SetIniContent $OdiScmConfig "$SCMConfigurationFile"
	
	#
	# Parse the output of the UPDATE command to build the list of ODI source sources that we need to import.
	#
	$TfGetOutput = get-content $GetLatestVersionOutputFile
	write-host "$IM processing command output with <$($TfGetOutput.length)> records"
	$FileCount = 0
	
	# Holds the current file type's list of files (to allow us to sort where required before adding to the main output list).
	[array] $currFileTypeList = @()
	
	#
	# Loop through each extension and file files for which to include import commands.
	#
	foreach ($Extention in $orderedExtensions) {
		
		#
		# Initialise the current file type's list.
		#
		$currFileTypeList = @()
		
		#
		# Remove the asterisk from the file type name pattern.
		#
		$FileObjType = $Extention.Replace("*","")
		$FileObjTypeExt = $FileObjType.replace(".","")
		write-host "$IM processing object type <$FileObjTypeExt>"
		
		$ExtensionFileCount = 0
		###$FileToImportPathName = ""
		
		foreach ($TfGetOutputLine in $TfGetOutput) {
			###write-host "$IM processing text line : $TfGetOutputLine"
			###DebuggingPause
			
			if ($TfGetOutputLine.StartsWith("Updated to revision")) {
				write-host "$IM ignoring text line $TfGetOutputLine"
				continue
			}
			
			if ($TfGetOutputLine.StartsWith("Updating")) {
				write-host "$IM ignoring text line $TfGetOutputLine"
				continue
			}
			
			$TfGetOutputLineFlags = $TfGetOutputLine.Substring(0,5)
			$TfGetOutputLineFileDirActionFlag = $TfGetOutputLineFlags.Substring(0,1)
			$TfGetOutputLineFileDirPropertyActionFlag = $TfGetOutputLineFlags.Substring(1,1)
			$TfGetOutputLineLockBrokenFilePropertyActionFlag = $TfGetOutputLineFlags.Substring(2,1)
			$TfGetOutputLineTreeActionFlag = $TfGetOutputLineFlags.Substring(3,1)	# Tree conflicts are signalled with a "C" in this column.
			$TfGetOutputLineFileDir = $TfGetOutputLine.Substring(5)
			
			###write-host "$DEBUG TfGetOutputLineFlags <$TfGetOutputLineFlags>"
			###write-host "$DEBUG TfGetOutputLineFileDirActionFlag <$TfGetOutputLineFileDirActionFlag>"
			###write-host "$DEBUG TfGetOutputLineFileDirPropertyActionFlag <$TfGetOutputLineFileDirPropertyActionFlag>"
			###write-host "$DEBUG TfGetOutputLineLockBrokenFilePropertyActionFlag <$TfGetOutputLineLockBrokenFilePropertyActionFlag>"
			###write-host "$DEBUG TfGetOutputLineTreeActionFlag <$TfGetOutputLineTreeActionFlag>"
			###write-host "$DEBUG TfGetOutputLineFileDir <$TfGetOutputLineFileDir>"
			###DebuggingPause
			
			if ($TfGetOutputLineFileActionFlag -eq "C" -or $TfGetOutputLineTreeActionFlag -eq "C") {
				write-host "$EM conflicts detected in local working copy versus repository for file or directory <$TfGetOutputLineFileDir>"
				write-host "$EM check the output file for details. All conflicts must be resolved in order for this"
				write-host "$EM script to be executed successfully"
				return $ExitStatus
			}
			
			if ($TfGetOutputLineFileDir.EndsWith($FileObjType)) {
				#
				# This is an ODI source object file name.
				#
				LogDebug "$FN" "found an ODI source file <$TfGetOutputLineFileDir> of type <$FileObjType>"
				if ($TfGetOutputLineFileDirActionFlag -eq "D") {
					write-host "$IM found deleted ODI source file <$TfGetOutputLineFileDir>. Delete using the ODI GUI."
				}
				else {
					$ExtensionFileCount += 1
					$currFileTypeList += $TfGetOutputLineFileDir
					LogDebug "$FN" "adding file <$TfGetOutputLineFileDir> to current file type list"
					###DebuggingPause
					$FileCount += 1
				}
			}
		}
		
		LogDebug "$FN" "completed extraction of files for object type <$FileObjType> from SVN UPDATE output. Starting file sorting"
		
		#
		# FOLLOWING CODE COMMON WITH OTHER SCM SYSTEMS.
		# TODO: move out common code to separate function.
		
		#
		# Sort the file list for nestable types.
		#
		$FileTypeIdx = 0
		foreach ($nestableContainerExtension in $nestableContainerExtensions) {
			###write-host "$DEBUG checking if current extension <$Extention> is nestable extension <$nestableContainerExtension>"
			if ($nestableContainerExtension -eq $Extention) {
				
				LogDebug "$FN" "current object type is a nestable container type. Sorting objects into parent-then-child order"
				
				[array] $sortFileList = @()
				#
				# Load the temporary array that we use to sort the files.
				#
				###write-host "$DEBUG loading object parent IDs"
				foreach ($sortFile in $currFileTypeList) {
					###write-host "$DEBUG loading file <$sortFile> into sorting array"
					$strFileDotParent = split-path $sortFile -leaf
					$strFileDotParent = $strFileDotParent.replace($nestableContainerExtension.replace("*",""),"")
					###write-host "$DEBUG point 1 strFileDotParent is <$strFileDotParent>"
					###DebuggingPause
					$strFileParentContent = get-content $sortFile | where {$_ -match $nestableContainerExtensionParentFields[$FileTypeIdx]}
					###write-host "$DEBUG got parent ID string <$strFileParentContent>"
					###DebuggingPause
					if ($strFileParentContent.length -gt 0) {
						$strFileParExtParBegin = $nestableContExtParBegin.replace("XXXXXXXXXXXXXXXXXXXX",$nestableContainerExtensionParentFields[$FileTypeIdx])
						###write-host "$DEBUG strFileParExtParBegin after replace is <$strFileParExtParBegin>"
						###DebuggingPause
						$strFileParent = $strFileParentContent.replace($strFileParExtParBegin,"")
						###write-host "$DEBUG point 1 strFileParent is <$strFileParent>"
						###DebuggingPause
						$strFileParent = $strFileParent.replace($nestableContExtParEnd,"")
						###write-host "$DEBUG point 2 strFileParent is <$strFileParent>"
						###DebuggingPause
						$strFileParent = $strFileParent.replace("null","")
						###write-host "$DEBUG point 3 strFileParent is <$strFileParent>"
						$strFileParent = $strFileParent.trim()		# Remove any white space.
						###DebuggingPause
						if ($strFileParent -ne "") {
							###write-host "$DEBUG strFileParent <> "" strFileParent <$strFileParent> strFileParent.length <"$strFileParent.length">"
							$strFileDotParent += "." + $strFileParent
						}
						###write-host "$DEBUG point 2 strFileDotParent is <$strFileDotParent>"
						###DebuggingPause
					}
					else {
						write-host "$EM cannot find parent ID field for sort input file <$sortFile>"
						return $False
					}
					$sortFileList += $strFileDotParent
					###write-host "$DEBUG adding child.parent <$strFileDotParent> to sort input"
					###write-host "$DEBUG sortFileList is now <"$sortFileList">"
				}
				
				#
				# Bubble sort the array.
				#
				###DebuggingPause
				LogDebug "$FN" "bubble sorting objects"
				do {
					###write-host "$DEBUG starting bubble sort interation"
					
					$blnSwapped = $False
					for ($i = 0; $i -lt $sortFileList.length - 1; $i++) {
						
						###write-host "$DEBUG i <" $i "> sortFileList[i] <" $sortFileList[$i] ">"
						
						[array] $intParentChild = @([regex]::split($sortFileList[$i],"\."))
						
						###write-host "$DEBUG intParentChild.length <"$intParentChild.length"> intParentChild <"$intParentChild">"
						###write-host "$DEBUG checking position of parent for child <" $intParentChild[0] ">"
						
						###DebuggingPause
						
						if ($intParentChild.length -eq 2) {
							#
							# There is a parent. Search for the parent's position in the working list.
							#
							$intChild = $intParentChild[0]
							$intParent = $intParentChild[1]
							
							###write-host "$DEBUG child <"$intParentChild[0]"> child <$intChild > parent <$intParent>"
							###DebuggingPause
							
							$intParentPos = -1
							for ($j = 0; $j -lt $sortFileList.length - 1; $j++) {
								[array] $intSearchParentChild = @([regex]::split($sortFileList[$j],"\."))
								$intSearchChild = $intSearchParentChild[0]
								if ($intSearchChild -eq $intParent) {
									$intParentPos = $j
									###write-host "$DEBUG found parent in sort list as position <$intParentPos>"
									break
								}
							}
							
							###write-host "$DEBUG child position <$i> parent position <$intParentPos>"
							
							if ($intParentPos -gt $i) {
								# Swap the current item with the next item.
								$tempFileListEntry = $sortFileList[$i]
								$sortFileList[$i]  = $sortFileList[$i + 1]
								$sortFileList[$i + 1]  = $tempFileListEntry
								$blnSwapped = $True
								###write-host "$DEBUG swapped entries <"$sortFileList[$i]"> and <"$sortFileList[$i + 1]">"
								###DebuggingPause
							}
						}
					}
				}
				while ($blnSwapped -eq $True)
				
				LogDebug "$FN" "completed bubble sort"
				###write-host "$DEBUG sortFileList is now <"$sortFileList">"
				###DebuggingPause
				
				#
				# Repopulate the current file type list.
				#
				LogDebug "$FN" "populating the sorted full file name list"
				$sortedCurrFileTypeList = @()
				foreach ($sortedFile in $sortFileList) {
					###write-host "$DEBUG doing sortedFile <"$sortedFile">"
					# Find the child entry.
					[array] $intParentChild = @([regex]::split($sortedFile,"\."))
					$intChild = $intParentChild[0]
					###write-host "$DEBUG for sortedFile <"$sortedFile"> got child <"$intChild">"
					for ($k = 0; $k -lt $currFileTypeList.length; $k++) {
						###write-host "$DEBUG looking for <$intChild> in currFileTypeList entry <$k> which contains <"$currFileTypeList[$k]">"
						$strFileName = split-path $currFileTypeList[$k] -leaf
						$intChildFile = $strFileName.replace($nestableContainerExtension.replace("*",""),"")
						if ($intChild -eq $intChildFile) {
							$sortedCurrFileTypeList += $currFileTypeList[$k]
							###write-host "$DEBUG found <$intChild> / <$intChildFile> at currFileTypeList entry <$k>"
							###write-host "$DEBUG adding entry <"$currFileTypeList[$k]"> to sort output"
							###DebuggingPause
							break
						}
						###else {
						###	write-host "$DEBUG didn't find <$intChild> in currFileTypeList entry <$k>"
						###}
					}
					
				}
				###write-host "$DEBUG final sortedCurrFileTypeList <$sortedCurrFileTypeList>"
				$currFileTypeList = @()
				foreach ($sortedCurrFile in $sortedCurrFileTypeList) {
					$currFileTypeList += $sortedCurrFile
				}
				###write-host "$DEBUG final currFileTypeList <$currFileTypeList>"
			}
			$FileTypeIdx += 1
		}
		LogDebug "$FN" "completed sorting of files for object type <$FileObjType>. Adding sort output to function output list"
		
		#
		# Add the current file type's list to the main output list.
		#
		foreach ($currFileTypeFile in $currFileTypeList) {
			$FileList.value += $currFileTypeFile	# We need to use the 'value' property for references to arrays.
		}
		LogDebug "$FN" "completed sorting of files for object type <$FileObjType>"
	}
	
	write-host "$IM total files parsed from command output is <$FileCount>"
	$ExitStatus = $True
	write-host "$IM ends"
	return $ExitStatus
}

#
# Perform a Get Latest Version operation for the entire branch.
#
function GetFromTFS ($HighChangeSetNumber, [ref] $FileList) {
	
	$FN = "GetFromTFS"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	$DEBUG = $FN + ": DEBUG:"
	
	write-host "$IM starts"
	$ExitStatus = $False
	
	set-location $WorkingCopyRootDir
	if (!($?)) {
		write-host "$EM cannot change working directory to branch root directory <$WorkingCopyRootDir>"
		return $ExitStatus
	}
	
	write-host "$IM previewing Get Latest Version. Output will be recorded in file <$GetLatestVersionOutputFile>"
	
	$SCMBranchUrl = $OdiScmConfig["SCM System"]["Branch Url"]
	
	$SCMUserName = $OdiScmConfig["SCM System"]["Global User Name"]
	$SCMUserPassword = $OdiScmConfig["SCM System"]["Global User Password"]
	if ($SCMUserName -ne "") {
		$SCMAuthText = "/login:$SCMUserName,$SCMUserPassword"
	}
	else {
		$SCMAuthText = ""
	}
	
	$CmdLine = "tf get $SCMBranchUrl /overwrite /preview /recursive /noprompt /version:C" + $HighChangeSetNumber + " $SCMAuthText >$GetLatestVersionOutputFile 2>&1"
	write-host "$IM executing command <$CmdLine>"
	invoke-expression $CmdLine
	if ($LastExitCode -ge 2) {
		write-host "$EM execution of command failed with exit status <$LastExitCode>"
		write-host "$EM check the output file for details. All conflicts must be resolved in order for this"
		write-host "$EM script can run successfully"
		return $ExitStatus
	}
	elseif ($LastExitCode -eq 1) {
		write-host "$EM execution of command partially failed with exit status <$LastExitCode>"
		write-host "$EM check the output file for details. All conflicts must be resolved in order for this"
		write-host "$EM script to be executed successfully"
		return $ExitStatus
	}
	
	write-host "$IM no conflicts detected in local working copy versus repository"
	write-host "$IM getting update from TFS to revision <$HighChangeSetNumber>"
	
	set-location $WorkingCopyRootDir
	if (!($?)) {
		write-host "$EM cannot change working directory to branch root directory <$WorkingCopyRootDir>"
		return $ExitStatus
	}
	
	$CmdLine = "tf get $SCMBranchUrl /overwrite /recursive /noprompt /version:C" + $HighChangeSetNumber + " $SCMAuthText >$GetLatestVersionOutputFile 2>&1"
	write-host "$IM executing command <$CmdLine>"
	invoke-expression $CmdLine
	if ($LastExitCode -ge 2) {
		write-host "$EM execution of command failed with exit status <$LastExitCode>"
		return $ExitStatus
	}
	elseif ($LastExitCode -eq 1) {
		write-host "$EM execution of command partially failed with exit status <$LastExitCode>"
		return $ExitStatus
	}
	
	#
	# Update the version of the local workspace.
	#
	# Dont use "add-content"? It always writes a newline at the end of the text.
	#(get-content -path $SCMGetLocalControlFile) + [Environment]::NewLine + $HighChangeSetNumber + "~" | set-content -path $SCMGetLocalControlFile
	####([Environment]::NewLine + $HighChangeSetNumber + "~") | add-content $SCMGetLocalControlFile
	###$script:OdiScmConfig["Import Controls"]["Working Copy Revision"] = $HighChangeSetNumber + "~"
	$script:OdiScmConfig["Import Controls"]["Working Copy Revision"] = $HighChangeSetNumber
	SetIniContent $OdiScmConfig "$SCMConfigurationFile"
	
	#
	# Parse the output of the Get command to build the list of ODI source sources that we need to import.
	#
	$TfGetOutput = get-content $GetLatestVersionOutputFile
	write-host "$IM processing command output with <$($TfGetOutput.length)> records"
	$FileCount = 0
	
	# Holds the current file type's list of files (to allow us to sort where reuired before adding to the main output list).
	[array] $currFileTypeList = @()
	
	#
	# Loop through each extension and find files for which to include import commands.
	#
	foreach ($Extention in $orderedExtensions) {
		#
		# Initialise the current file type's list.
		#
		$currFileTypeList = @()
		
		#
		# Remove the asterisk from the file type name pattern.
		#
		$FileObjType = $Extention.Replace("*","")
		$FileObjTypeExt = $FileObjType.replace(".","")
		write-host "$IM processing object type <$FileObjTypeExt>"
		
		###DebuggingPause
		
		$ExtensionFileCount = 0
		$FileToImportPathName = ""
		
		foreach ($TfGetOutputLine in $TfGetOutput) {
			LogDebug $FN "processing text line <$TfGetOutputLine>"
			LogDebug $FN "checking text line for WC root dir <$WorkingCopyRootDir>"
			LogDebug $FN "WorkingCopyRootDir.ToUpper() <" + $WorkingCopyRootDir.ToUpper() + ">"
			LogDebug $FN "WorkingCopyRootDir.ToUpper() <" + $WorkingCopyRootDir.ToUpper() + ">"
			if (($TfGetOutputLine.ToUpper().StartsWith($WorkingCopyRootDir.ToUpper())) -and ($TfGetOutputLine.EndsWith(":"))) {
				#
				# This is a local directory name. Use it as the file name prefix for subsequent records.
				#
				$FileToImportPathName = $TfGetOutputLine.TrimEnd(":")
				LogDebug $FN "found local directory name <$FileToImportPathName>"
				###DebuggingPause
			}
			
			if ($TfGetOutputLine.EndsWith($FileObjType)) {
				#
				# This is an ODI source object file name.
				#
				$FileToImportName = $TfGetOutputLine -replace("^Getting ","")
				$FileToImportName = $FileToImportName -replace("^Replacing ","")
				$FileToImportName = $FileToImportName -replace("^Adding ","")
				$FileToImportName = $FileToImportName -replace("^Deleting ","")
				
				if ($TfGetOutputLine.StartsWith("Deleting ")) {
					write-host "$IM found deleted ODI source file <$FileToImportName>. Delete using the ODI GUI."
				}
				else {
					$ExtensionFileCount += 1
					$currFileTypeList += "$FileToImportPathName\$FileToImportName"
					LogDebug $FN "adding file <$FileToImportPathName\$FileToImportName> to current file type list"
					###DebuggingPause
					$FileCount += 1
				}
			}
		}
		
		#
		# FOLLOWING CODE COMMON WITH OTHER SCM SYSTEMS.
		# TODO: move out common code to separate function.
		
		#
		# Sort the file list for nestable types.
		#
		$FileTypeIdx = 0
		foreach ($nestableContainerExtension in $nestableContainerExtensions) {
			###write-host "$DEBUG checking if current extension <$Extention> is nestable extension <$nestableContainerExtension>"
			if ($nestableContainerExtension -eq $Extention) {
				###write-host "$DEBUG sorting objects into parent-then-child order"
				
				[array] $sortFileList = @()
				#
				# Load the temporary array that we use to sort the files.
				#
				###write-host "$DEBUG loading object parent IDs"
				foreach ($sortFile in $currFileTypeList) {
					LogDebug $FN "$DEBUG loading file <$sortFile> into sorting array"
					$strFileDotParent = split-path $sortFile -leaf
					$strFileDotParent = $strFileDotParent.replace($nestableContainerExtension.replace("*",""),"")
					###write-host "$DEBUG point 1 strFileDotParent is <$strFileDotParent>"
					###DebuggingPause
					$strFileParentContent = get-content $sortFile | where {$_ -match $nestableContainerExtensionParentFields[$FileTypeIdx]}
					###write-host "$DEBUG got parent ID string <$strFileParentContent>"
					###DebuggingPause
					if ($strFileParentContent.length -gt 0) {
						$strFileParExtParBegin = $nestableContExtParBegin.replace("XXXXXXXXXXXXXXXXXXXX",$nestableContainerExtensionParentFields[$FileTypeIdx])
						###write-host "$DEBUG strFileParExtParBegin after replace is <$strFileParExtParBegin>"
						###DebuggingPause
						$strFileParent = $strFileParentContent.replace($strFileParExtParBegin,"")
						###write-host "$DEBUG point 1 strFileParent is <$strFileParent>"
						###DebuggingPause
						$strFileParent = $strFileParent.replace($nestableContExtParEnd,"")
						###write-host "$DEBUG point 2 strFileParent is <$strFileParent>"
						###DebuggingPause
						$strFileParent = $strFileParent.replace("null","")
						###write-host "$DEBUG point 3 strFileParent is <$strFileParent>"
						$strFileParent = $strFileParent.trim()		# Remove any white space.
						###DebuggingPause
						if ($strFileParent -ne "") {
							###write-host "$DEBUG strFileParent <> "" strFileParent <$strFileParent> strFileParent.length <"$strFileParent.length">"
							$strFileDotParent += "." + $strFileParent
						}
						###write-host "$DEBUG point 2 strFileDotParent is <$strFileDotParent>"
						###DebuggingPause
					}
					else {
						write-host "$EM cannot find parent ID field for sort input file <$sortFile>"
						return $False
					}
					$sortFileList += $strFileDotParent
					###write-host "$DEBUG adding child.parent <$strFileDotParent> to sort input"
					###write-host "$DEBUG sortFileList is now <"$sortFileList">"
				}
				
				#
				# Bubble sort the array.
				#
				###DebuggingPause
				###write-host "$DEBUG bubble sorting objects"
				do {
					###write-host "$DEBUG starting bubble sort interation"
					
					$blnSwapped = $False
					for ($i = 0; $i -lt $sortFileList.length - 1; $i++) {
						
						###write-host "$DEBUG i <" $i "> sortFileList[i] <" $sortFileList[$i] ">"
						
						[array] $intParentChild = @([regex]::split($sortFileList[$i],"\."))
						
						###write-host "$DEBUG intParentChild.length <"$intParentChild.length"> intParentChild <"$intParentChild">"
						###write-host "$DEBUG checking position of parent for child <" $intParentChild[0] ">"
						
						###DebuggingPause
						
						if ($intParentChild.length -eq 2) {
							#
							# There is a parent. Search for the parent's position in the working list.
							#
							$intChild = $intParentChild[0]
							$intParent = $intParentChild[1]
							
							###write-host "$DEBUG child <"$intParentChild[0]"> child <$intChild > parent <$intParent>"
							###DebuggingPause
							
							$intParentPos = -1
							for ($j = 0; $j -lt $sortFileList.length - 1; $j++) {
								[array] $intSearchParentChild = @([regex]::split($sortFileList[$j],"\."))
								$intSearchChild = $intSearchParentChild[0]
								if ($intSearchChild -eq $intParent) {
									$intParentPos = $j
									###write-host "$DEBUG found parent in sort list as position <$intParentPos>"
									break
								}
							}
							
							###write-host "$DEBUG child position <$i> parent position <$intParentPos>"
							
							if ($intParentPos -gt $i) {
								# Swap the current item with the next item.
								$tempFileListEntry = $sortFileList[$i]
								$sortFileList[$i]  = $sortFileList[$i + 1]
								$sortFileList[$i + 1]  = $tempFileListEntry
								$blnSwapped = $True
								###write-host "$DEBUG swapped entries <"$sortFileList[$i]"> and <"$sortFileList[$i + 1]">"
								###DebuggingPause
							}
						}
					}
				}
				while ($blnSwapped -eq $True)
				
				###write-host "$DEBUG completed bubble sort"
				###write-host "$DEBUG sortFileList is now <"$sortFileList">"
				###DebuggingPause
				
				#
				# Repopulate the current file type list.
				#
				###write-host "$DEBUG populating the sorted full file name list"
				$sortedCurrFileTypeList = @()
				foreach ($sortedFile in $sortFileList) {
					###write-host "$DEBUG doing sortedFile <"$sortedFile">"
					# Find the child entry.
					[array] $intParentChild = @([regex]::split($sortedFile,"\."))
					$intChild = $intParentChild[0]
					###write-host "$DEBUG for sortedFile <"$sortedFile"> got child <"$intChild">"
					for ($k = 0; $k -lt $currFileTypeList.length; $k++) {
						###write-host "$DEBUG looking for <$intChild> in currFileTypeList entry <$k> which contains <"$currFileTypeList[$k]">"
						$strFileName = split-path $currFileTypeList[$k] -leaf
						$intChildFile = $strFileName.replace($nestableContainerExtension.replace("*",""),"")
						if ($intChild -eq $intChildFile) {
							$sortedCurrFileTypeList += $currFileTypeList[$k]
							###write-host "$DEBUG found <$intChild> / <$intChildFile> at currFileTypeList entry <$k>"
							###write-host "$DEBUG adding entry <"$currFileTypeList[$k]"> to sort output"
							###DebuggingPause
							break
						}
						###else {
						###	write-host "$DEBUG didn't find <$intChild> in currFileTypeList entry <$k>"
						###}
					}
				}
				###write-host "$DEBUG final sortedCurrFileTypeList <$sortedCurrFileTypeList>"
				$currFileTypeList = @()
				foreach ($sortedCurrFile in $sortedCurrFileTypeList) {
					$currFileTypeList += $sortedCurrFile
				}
				###write-host "$DEBUG final currFileTypeList <$currFileTypeList>"
			}
			$FileTypeIdx += 1
		}
		
		#
		# Add the current file type' list to the main output list.
		#
		foreach ($currFileTypeFile in $currFileTypeList) {
			$FileList.value += $currFileTypeFile	# We need to use the 'value' property for references to arrays.
		}
	}
	
	write-host "$IM total files parsed from command output is <$FileCount>"
	$ExitStatus = $True
	write-host "$IM ends"
	return $ExitStatus
}

function ExecOdiRepositorySql ($SqlScriptFile) {
	
	$FN = "ExecOdiRepositorySql"
	$IM = $FN + ": INFO:"
	$EM = $FN + ": ERROR:"
	
	write-host "$IM starts"
	
	$ExitStatus = $True
	
	write-host "$IM SQL script file is <$SqlScriptFile>"
	
	#
	# Capture the command output and display it so that it does not get returned
	# by this function.
	#
#######################$SqlScriptFile = "C:\temp\test.sql"
	$SqlScriptFileName = split-path $SqlScriptFile -leaf
	$StdOutLogFile = "$GenScriptRootDir\ExecOdiRepositorySql_${SqlScriptFileName}_StdOut_${VersionString}.log"
	$StdErrLogFile = "$GenScriptRootDir\ExecOdiRepositorySql_${SqlScriptFileName}_StdErr_${VersionString}.log"
#####$StdOutLogFile = "c:\temp\out.log"
#####$StdErrLogFile = "c:\temp\err.log"
	write-host "$IM StdOut will be captured in file <$StdOutLogFile>"
	write-host "$IM StdErr will be captured in file <$StdErrLogFile>"
	
	write-host "$IM executing command <$OdiScmJisqlRepoBat $SqlScriptFile $StdOutLogFile $StdErrLogFile>"
	###$CmdOutput = cmd /c "$OdiScmJisqlRepoBat $SqlScriptFile $StdOutLogFile $StdErrLogFile"
	$CmdOutput = invoke-expression "$OdiScmJisqlRepoBat $SqlScriptFile $StdOutLogFile $StdErrLogFile"
	$BatchExitCode = $LastExitCode
	
	write-host "$IM command returned exit status <$BatchExitCode>"
	
	if ($BatchExitCode -eq 0) {
		write-host "$IM execution of command completed successfully"
		
		if (test-path $StdErrLogFile) {
			$StdErrText = get-content $StdErrLogFile | out-string
			if (($StdErrText.Trim()).length -ne 0) {
				write-host "$EM executed script produced StdErr output"
				write-host "$EM command captured StdErr >>>"
				write-host (get-content $StdErrLogFile)
				write-host "$EM <<< end of command captured StdErr"
				
				$ExitStatus = $False
				return $ExitStatus
			}
		}
	}
	else {
		write-host "$EM execution of command failed with exit status <$BatchExitCode>"
		
		write-host "$EM command output >>>"
		write-host $CmdOutput
		write-host "$EM <<< end of command output"
		
		if (test-path $StdOutLogFile) {
			write-host "$EM command captured StdOut >>>"
			write-host (get-content $StdOutLogFile)
			write-host "$EM <<< end of command captured StdOut"
		}
		
		if (test-path $StdErrLogFile) {
			write-host "$EM command captured StdErr >>>"
			write-host (get-content $StdErrLogFile)
			write-host "$EM <<< end of command captured StdErr"
		}
		$ExitStatus = $False
		return $ExitStatus
	}
	
	$StdOutText = get-content $StdOutLogFile | out-string
	write-host "$IM ends"
	
	return ($FN + ":" + $StdOutText.Trim())
}

####################################################################
# Main.
####################################################################

$FN = "OdiScmGet"
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
# Prime the write-host mechanism to avoid bug in large outputs.
#
write-host "$IM initialising message output system"
. "$env:ODI_SCM_HOME\Configuration\Scripts\OdiScmPrimePsWriteHost.ps1"

#===================================================================
# Set fixed configuration and script level constants.
#===================================================================

#
# A string used to create unique generated script and log file names.
#
$VersionString = get-date -format "yyyyMMdd_HHmmss"

$WorkingCopyRootDir = ""

$ConfigurationFolder = $env:ODI_SCM_HOME + "\Configuration"

#
# OdiScm configuration read from/written to INI file.
#
$OdiScmConfig = $Null

#
# Local environment definition.
#
$SCMConfigurationFile = $env:ODI_SCM_INI
$SCMConfigurationFileName = split-path -leaf -path "$SCMConfigurationFile"
$ScriptsRootDir = $ConfigurationFolder + "\Scripts"

#
# Fixed utility script and file locations and names.
#
$MoiTempEmptyFile = $ConfigurationFolder + "\EmptyFileDoNotDelete.txt"
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
$OdiScmGenScenDeleteOldSqlTemplate = $ScriptsRootDir + "\OdiScmGenScen20DeleteOldScenTemplate.sql"
$OdiScmGenScenNewSqlTemplate = $ScriptsRootDir + "\OdiScmGenScen40NewScenTemplate.sql"
$OdiScmRepoInfrastructureSetupSqlTemplate = $ScriptsRootDir + "\OdiScmCreateInfrastructureTemplate.sql"
$OdiScmRepoSetNextImportTemplate = $ScriptsRootDir + "\OdiScmSetNextImportTemplate.sql"
$OdiScmBuildNoteTemplate = $ScriptsRootDir + "\OdiScmBuildNoteTemplate.txt"

#
# Logging and generated scripts directory structure.
#
$LogRootDir = $OdiScmHomeDir + "\Logs"

#
# ODI configuration.
#
$OdiHomeDir = ""
$OdiJavaHomeDir = ""
###$OdiBinDir = ""
$OdiParamFile = ""
$OdiJavaHomeDir

#
# General Java configuration.
#
$JavaHomeDir = ""

#
# Jisql configuration.
#
$JisqlHomeDir = ""
$JisqlJavaHomeDir = ""

#
# Oracle client configuration.
#
$OracleHomeDir = ""

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

if (Test-Path $MoiTempEmptyFile) { 
	write-host "$IM empty file check file $MoiTempEmptyFile already exists" 
}
else {  
	write-host "$IM creating empty file check file $MoiTempEmptyFile"
	New-Item -itemtype file $MoiTempEmptyFile 
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
$containerExtensions = @("*.SnpTechno","*.SnpConnect","*.SnpLschema","*.SnpModFolder","*.SnpModel","*.SnpSubModel","*.SnpProject","*.SnpFolder")
$nestableContainerExtensions = @("*.SnpModFolder","*.SnpSubModel","*.SnpFolder")
$nestableContainerExtensionParentFields = @("ParIModFolder","ISmodParent","ParIFolder")
$nestableContExtParBegin = '<Field name="XXXXXXXXXXXXXXXXXXXX" type="com.sunopsis.sql.DbInt"><![CDATA['
$nestableContExtParEnd = ']]></Field>'

#
# The custom end-of-section entry in "odiparams.bat" added for this automation.
#
$OdiRepoLAST = 'rem ODI CONNECTION PARAMETERS FINISH'

#
# Execute the central function.
#
$ResultMain = GetIncremental
if ($ResultMain) {
	exit 0
}
else {
	exit 1
}
