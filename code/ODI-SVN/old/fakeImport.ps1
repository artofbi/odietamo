਀⸀ ∀䌀㨀尀䴀伀䤀尀爀漀氀氀漀甀琀尀昀愀欀攀䌀漀渀猀琀愀渀琀猀⸀瀀猀㄀∀ഀഊ਀⌀圀攀 眀椀氀氀 氀漀最 愀氀氀 瀀爀攀瘀椀攀眀 爀攀猀甀氀琀猀 椀渀琀漀 愀 甀渀椀焀甀攀 爀攀猀甀氀琀䘀椀氀攀 愀猀 愀 猀琀愀爀琀攀爀ഀഊ#So that we will have full visibility if they make a change or not. ਀⌀䤀渀 昀甀琀甀爀攀 嬀眀栀攀渀 眀攀 愀爀攀 挀漀洀昀漀爀琀愀戀氀攀 眀攀 挀愀渀 眀爀椀琀攀 琀栀攀 爀攀猀甀氀琀猀 椀渀琀漀 琀栀攀 猀愀洀攀 昀椀氀攀 眀椀琀栀 漀瘀攀爀眀爀椀琀椀渀最Ⰰ ഀഊ਀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀ഀഊ## 1. Parameters ##਀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀ഀഊ਀眀爀椀琀攀ⴀ栀漀猀琀 ∀㄀⸀ 瀀愀爀愀洀攀琀攀爀猀 ∀ഀഊ਀␀猀攀愀爀挀栀吀攀砀琀㴀∀礀漀甀 栀愀瘀攀 愀 挀漀渀昀氀椀挀琀椀渀最 攀搀椀琀∀ഀഊ$endOfConflictText= "Unable to perform the get"਀␀猀甀洀洀愀爀礀吀攀砀琀㴀∀ⴀⴀⴀⴀ 匀甀洀洀愀爀礀∀ഀഊ਀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀ഀഊ##  2. Preview    ##਀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀ഀഊfunction GetPreview ਀笀ഀഊ    write-host "2. [GetPreview] Preview Get Latest and write output to " $resultFile਀    琀昀 最攀琀 ␀伀搀椀䘀漀氀搀攀爀 ⼀愀氀氀 ⼀瀀爀攀瘀椀攀眀 ⼀爀攀挀甀爀猀椀瘀攀 ⼀渀漀瀀爀漀洀瀀琀 㸀␀爀攀猀甀氀琀䘀椀氀攀 ㈀㸀☀㄀ഀഊ}਀ഀഊ########################################਀⌀⌀  ㌀⸀ 吀爀礀 琀漀 最攀琀 昀爀漀洀 吀䘀匀 ⌀⌀ഀഊ########################################਀ഀഊfunction GetFromTFS ਀笀ഀഊ    write-host "3. [GetFromTFS] Try to get latest from TFS"਀    眀爀椀琀攀ⴀ栀漀猀琀 ∀㌀⸀ 嬀䜀攀琀䘀爀漀洀吀䘀匀崀 刀攀愀搀 琀栀攀 挀漀渀琀攀渀琀 昀爀漀洀 ∀  ␀爀攀猀甀氀琀䘀椀氀攀ഀഊ    write-host "3. [GetFromTFS] Write the output to " $devResultFile਀ഀഊ    #Once summary did not have details for the conflicts, we may need to check if it has details/we can capture them.਀    ␀椀渀搀攀砀匀甀洀洀愀爀礀㴀 䜀攀琀ⴀ䌀漀渀琀攀渀琀 ␀爀攀猀甀氀琀䘀椀氀攀 簀 漀甀琀ⴀ猀琀爀椀渀最 簀─ 笀␀开⸀䤀渀搀攀砀伀昀⠀␀猀甀洀洀愀爀礀吀攀砀琀⤀紀ഀഊ    $indexConflict= Get-Content $resultFile | out-string |% {$_.LastIndexOf($endOfConflictText)}਀ഀഊ    $x=Get-Content $resultFile | out-string ਀    ␀猀攀愀爀挀栀琀攀砀琀挀漀渀琀攀渀琀㴀  ∀⠀㼀㰀挀漀渀琀攀渀琀㸀⸀⨀⤀∀ ⬀ ␀猀攀愀爀挀栀吀攀砀琀 ഀഊ    if ($x -match  $searchtextcontent )਀            笀 ഀഊ                $message= $matches['content'] +$searchText            ਀                ␀愀 㴀 渀攀眀ⴀ漀戀樀攀挀琀 ⴀ挀漀洀漀戀樀攀挀琀 眀猀挀爀椀瀀琀⸀猀栀攀氀氀ഀഊ                $b = $a.popup($message,0,"MOI ODI Get Latest",1)਀                ␀洀攀猀猀愀最攀 簀 伀甀琀ⴀ䘀椀氀攀 ⴀ昀椀氀攀瀀愀琀栀 ␀搀攀瘀刀攀猀甀氀琀䘀椀氀攀 ⴀ愀瀀瀀攀渀搀ഀഊ                write-host "Finished. There are conflicts. Please check " $devResultFile਀                昀椀渀椀猀栀ഀഊ            }਀    攀氀猀攀ഀഊ    {਀        琀昀 最攀琀 ␀伀搀椀䘀漀氀搀攀爀 ⼀愀氀氀 ⼀爀攀挀甀爀猀椀瘀攀 ⼀渀漀瀀爀漀洀瀀琀 㸀␀爀攀猀甀氀琀䘀椀氀攀 ㈀㸀☀㄀ഀഊ        $a = new-object -comobject wscript.shell਀        ␀戀 㴀 ␀愀⸀瀀漀瀀甀瀀⠀␀洀攀猀猀愀最攀Ⰰ　Ⰰ∀䴀伀䤀 伀䐀䤀 䜀攀琀 䰀愀琀攀猀琀∀Ⰰ㄀⤀ഀഊ        write-host "3. [GetFromTFS] Get Latest Finished. There are no conflicts. Getting latest on local working copy." ਀        ഀഊ    }਀紀ഀഊ਀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀ഀഊ##   4. Get Master to be imported਀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀ഀഊ#By default “Insert_update”  for everything਀⌀䘀漀爀 琀栀攀猀攀 䐀漀 椀渀猀攀爀琀 昀椀爀猀琀Ⰰ 椀昀 昀愀椀氀猀 搀漀 甀瀀搀愀琀攀⸀ ഀഊ#-project਀⌀ⴀ昀漀氀搀攀爀ഀഊ#-model਀⌀ⴀ猀甀戀洀漀搀攀氀ഀഊ########################################਀昀甀渀挀琀椀漀渀 䤀洀瀀漀爀琀䴀愀猀琀攀爀笀ഀഊ਀    眀爀椀琀攀ⴀ栀漀猀琀 ∀㐀⸀ 嬀䤀洀瀀漀爀琀䴀愀猀琀攀爀崀 䜀攀琀琀椀渀最 洀愀猀琀攀爀 昀椀氀攀猀 昀爀漀洀㨀 ∀ ␀伀搀椀䘀漀氀搀攀爀 ഀഊ    write-host "4. [ImportMaster] Writing output to: " $ImportMasterScriptOutput ਀    ␀洀愀猀琀攀爀䘀椀氀攀猀㴀䜀攀琀ⴀ䌀栀椀氀搀䤀琀攀洀  ␀伀搀椀䘀漀氀搀攀爀 ⴀ爀攀挀甀爀猀攀 簀 圀栀攀爀攀ⴀ伀戀樀攀挀琀 笀 ␀开⸀倀匀䤀猀䌀漀渀琀愀椀渀攀爀 紀 簀 圀栀攀爀攀ⴀ伀戀樀攀挀琀 笀 ␀开⸀一愀洀攀 ⴀ挀漀渀琀愀椀渀猀 ∀昀愀欀攀洀愀猀琀攀爀∀ 紀ഀഊ    cd $OdiBinFolder਀ഀഊ    "cd ${odiBinFolder}"| Out-File -filepath $ImportMasterScriptOutput -encoding ASCII -append਀    ⌀眀攀 眀椀氀氀 氀漀漀瀀 昀漀爀 攀愀挀栀 攀砀琀攀渀猀椀漀渀 琀漀 最攀渀攀爀愀琀攀 琀栀攀 椀洀瀀漀爀琀⸀戀愀琀 栀愀瘀攀 漀爀搀攀爀攀搀 挀漀洀洀愀渀搀猀⸀ ഀഊ    foreach($ext in $orderedExtensions) ਀    笀 ഀഊ        write-host "4. [ImportMaster] ext:" $ext ਀        ␀昀椀氀攀猀㴀 最攀琀ⴀ挀栀椀氀搀椀琀攀洀 ␀洀愀猀琀攀爀䘀椀氀攀猀⸀䘀甀氀氀一愀洀攀 ⴀ爀攀挀甀爀猀攀 ⴀ椀渀挀氀甀搀攀 ␀攀砀琀 ഀഊ        write-host "4. [ImportMaster] files.Count" : $files.Count਀        ⌀眀爀椀琀攀ⴀ栀漀猀琀 ∀昀椀氀攀猀㨀∀ ␀昀椀氀攀猀ഀഊ        ਀        椀昀 ⠀␀昀椀氀攀猀⸀䌀漀甀渀琀 ⴀ最攀 ㄀⤀ഀഊ        {਀            ⌀瀀爀漀挀攀猀猀 愀氀氀 昀椀氀攀愀 眀椀琀栀 琀栀椀猀 攀砀琀攀渀猀椀漀渀ഀഊ            foreach($file in $files)਀            笀     ഀഊ                    $fileToImport= $masterFiles.FullName + "\"  +  $file.Name ਀                    眀爀椀琀攀ⴀ栀漀猀琀 ∀㐀⸀ 嬀䤀洀瀀漀爀琀䴀愀猀琀攀爀崀 昀椀氀攀吀漀䤀洀瀀漀爀琀㨀∀ ␀昀椀氀攀吀漀䤀洀瀀漀爀琀ഀഊ                    #direct execution did not work, so we are generating commands and put into a batch file.਀                    ␀琀攀猀琀䌀漀洀洀愀渀搀㴀 ∀挀愀氀氀 猀琀愀爀琀挀洀搀⸀戀愀琀 伀搀椀䤀洀瀀漀爀琀伀戀樀攀挀琀 ⴀ昀椀氀攀开渀愀洀攀㴀∀ ⬀ ␀昀椀氀攀吀漀䤀洀瀀漀爀琀 ⬀ ∀ ⴀ䤀䴀倀伀刀吀开䴀伀䐀䔀㴀∀ ⬀ ␀䤀䴀倀伀刀吀开䴀伀䐀䔀 ⬀ ∀ ⴀ圀伀刀䬀开刀䔀倀开一䄀䴀䔀㴀∀ ⬀ ␀圀伀刀䬀开刀䔀倀开一䄀䴀䔀 ⬀ ∀ ⴀ匀䔀䌀唀刀䤀吀夀开䐀刀䤀嘀䔀刀㴀∀ ⬀ ␀匀䔀䌀唀刀䤀吀夀开䐀刀䤀嘀䔀刀 ⬀ ∀ ⴀ匀䔀䌀唀刀䤀吀夀开唀刀䰀㴀∀ ⬀ ␀匀䔀䌀唀刀䤀吀夀开唀刀䰀 ⬀ ∀  ⴀ匀䔀䌀唀刀䤀吀夀开唀匀䔀刀㴀∀ ⬀ ␀匀䔀䌀唀刀䤀吀夀开唀匀䔀刀 ⬀ ∀ ⴀ匀䔀䌀唀刀䤀吀夀开倀圀䐀㴀∀ ⬀ ␀匀䔀䌀唀刀䤀吀夀开倀圀䐀 ⬀ ∀ ⴀ唀匀䔀刀㴀∀ ⬀ ␀唀匀䔀刀 ⬀ ∀ ⴀ倀䄀匀匀圀伀刀䐀㴀∀ ⬀ ␀倀䄀匀匀圀伀刀䐀 ⬀ ∀㸀∀ ⬀ ␀䤀洀瀀漀爀琀䴀愀猀琀攀爀䰀漀最䘀漀氀搀攀爀 ⬀ ␀昀椀氀攀⸀一愀洀攀 ⬀ ∀ ㈀㸀☀㄀∀ ഀഊ    				਀                    ⌀眀爀椀琀攀ⴀ栀漀猀琀 ␀琀攀猀琀䌀漀洀洀愀渀搀 ഀഊ                    $testCommand | Out-File -filepath $ImportMasterScriptOutput -encoding ASCII -append਀            紀ഀഊ        }਀        ഀഊ    } ਀    眀爀椀琀攀ⴀ栀漀猀琀 ∀㐀⸀ 嬀䤀洀瀀漀爀琀䴀愀猀琀攀爀崀 䘀椀渀椀猀栀攀搀 眀爀椀琀椀渀最 漀甀琀瀀甀琀 琀漀㨀 ∀ ␀䤀洀瀀漀爀琀䴀愀猀琀攀爀匀挀爀椀瀀琀伀甀琀瀀甀琀 ഀഊ}਀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀ഀഊ## 5. Import NonMaster Files਀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀⌀ഀഊfunction ImportNonMaster {਀    ␀伀搀椀䘀漀氀搀攀爀 㴀 ∀䌀㨀尀䴀伀䤀尀䴀伀䤀倀伀䌀尀䐀攀瘀攀氀漀瀀洀攀渀琀尀伀䐀䤀尀匀漀甀爀挀攀尀瀀爀漀樀攀挀琀⸀㤀　　㜀∀ഀഊ    write-host "5.[ImportNonMaster] Getting non master files from: " $OdiFolder਀    眀爀椀琀攀ⴀ栀漀猀琀 ∀㔀⸀嬀䤀洀瀀漀爀琀一漀渀䴀愀猀琀攀爀崀 圀爀椀琀椀渀最 漀甀琀瀀甀琀 琀漀㨀 ∀ ␀䤀洀瀀漀爀琀一漀渀䴀愀猀琀攀爀匀挀爀椀瀀琀伀甀琀瀀甀琀 ഀഊ    ਀    ␀渀漀渀䴀愀猀琀攀爀䘀椀氀攀猀㴀䜀攀琀ⴀ䌀栀椀氀搀䤀琀攀洀  ␀伀搀椀䘀漀氀搀攀爀 ⴀ爀攀挀甀爀猀攀 簀 圀栀攀爀攀ⴀ伀戀樀攀挀琀 笀 ␀开⸀倀匀䤀猀䌀漀渀琀愀椀渀攀爀 紀 簀 圀栀攀爀攀ⴀ伀戀樀攀挀琀 笀  ℀⠀␀开⸀一愀洀攀 ⴀ洀愀琀挀栀 ✀洀愀猀琀攀爀✀ ⤀ 紀ഀഊ    write-host 5.[ImportNonMaster] $nonMasterFiles਀    ഀഊ    cd $OdiBinFolder਀    ∀挀搀 ␀笀漀搀椀䈀椀渀䘀漀氀搀攀爀紀∀ 簀 伀甀琀ⴀ䘀椀氀攀  ␀䤀洀瀀漀爀琀一漀渀䴀愀猀琀攀爀匀挀爀椀瀀琀伀甀琀瀀甀琀 ⴀ攀渀挀漀搀椀渀最 䄀匀䌀䤀䤀 ⴀ愀瀀瀀攀渀搀ഀഊ    #we will loop for each extension to generate the import.bat have ordered commands. ਀    ഀഊ਀    昀漀爀攀愀挀栀⠀␀攀砀琀 椀渀 ␀漀爀搀攀爀攀搀䔀砀琀攀渀猀椀漀渀猀⤀ ഀഊ    { ਀        ⌀眀爀椀琀攀ⴀ栀漀猀琀 ∀䰀漀漀瀀椀渀最 昀漀爀 攀砀琀㨀∀ ␀攀砀琀 ഀഊ        foreach($nonMasterFile in $nonMasterFiles) ਀        笀ഀഊ            #write-host $nonMasterFile.FullName਀            ␀昀椀氀攀猀㴀 䀀⠀最攀琀ⴀ挀栀椀氀搀椀琀攀洀 ␀渀漀渀䴀愀猀琀攀爀䘀椀氀攀⸀䘀甀氀氀一愀洀攀 ⴀ爀攀挀甀爀猀攀 ⴀ椀渀挀氀甀搀攀 ␀攀砀琀⤀ ഀഊ            #write-host "files.Count" : $files.Count਀            ⌀眀爀椀琀攀ⴀ栀漀猀琀 ∀昀椀氀攀猀 ☀ 挀漀甀渀琀㨀∀ ␀昀椀氀攀猀 ∀Ⰰ ∀ ␀昀椀氀攀猀⸀䌀漀甀渀琀 ഀഊ            ਀            椀昀 ⠀␀昀椀氀攀猀⸀䌀漀甀渀琀 ⴀ最攀 ㄀⤀ഀഊ            {਀                ⌀瀀爀漀挀攀猀猀 愀氀氀 昀椀氀攀愀 眀椀琀栀 琀栀椀猀 攀砀琀攀渀猀椀漀渀ഀഊ                foreach($file in $files)਀                笀     ഀഊ                        $fileToImport= $nonMasterFile.FullName + "\"  +  $file.Name ਀                        眀爀椀琀攀ⴀ栀漀猀琀 ∀㔀⸀嬀䤀洀瀀漀爀琀一漀渀䴀愀猀琀攀爀崀 昀椀氀攀吀漀䤀洀瀀漀爀琀㨀∀ ␀昀椀氀攀吀漀䤀洀瀀漀爀琀ഀഊ                        #direct execution did not work, so we are generating commands and put into a batch file.਀                        ␀琀攀猀琀䌀漀洀洀愀渀搀㴀 ∀挀愀氀氀 猀琀愀爀琀挀洀搀⸀戀愀琀 伀搀椀䤀洀瀀漀爀琀伀戀樀攀挀琀 ⴀ昀椀氀攀开渀愀洀攀㴀∀ ⬀ ␀昀椀氀攀吀漀䤀洀瀀漀爀琀 ⬀ ∀ ⴀ䤀䴀倀伀刀吀开䴀伀䐀䔀㴀∀ ⬀ ␀䤀䴀倀伀刀吀开䴀伀䐀䔀 ⬀ ∀ ⴀ圀伀刀䬀开刀䔀倀开一䄀䴀䔀㴀∀ ⬀ ␀圀伀刀䬀开刀䔀倀开一䄀䴀䔀 ⬀ ∀ ⴀ匀䔀䌀唀刀䤀吀夀开䐀刀䤀嘀䔀刀㴀∀ ⬀ ␀匀䔀䌀唀刀䤀吀夀开䐀刀䤀嘀䔀刀 ⬀ ∀ ⴀ匀䔀䌀唀刀䤀吀夀开唀刀䰀㴀∀ ⬀ ␀匀䔀䌀唀刀䤀吀夀开唀刀䰀 ⬀ ∀ ⴀ匀䔀䌀唀刀䤀吀夀开唀匀䔀刀㴀∀ ⬀ ␀匀䔀䌀唀刀䤀吀夀开唀匀䔀刀 ⬀ ∀ ⴀ匀䔀䌀唀刀䤀吀夀开倀圀䐀㴀∀ ⬀ ␀匀䔀䌀唀刀䤀吀夀开倀圀䐀 ⬀ ∀ ⴀ唀匀䔀刀㴀∀ ⬀ ␀唀匀䔀刀 ⬀ ∀ ⴀ倀䄀匀匀圀伀刀䐀㴀∀ ⬀ ␀倀䄀匀匀圀伀刀䐀 ⬀ ∀㸀∀ ⬀ ␀䤀洀瀀漀爀琀一漀渀䴀愀猀琀攀爀䰀漀最䘀漀氀搀攀爀 ⬀ ␀昀椀氀攀⸀一愀洀攀 ⬀ ∀ ㈀㸀☀㄀∀ ഀഊ                        ਀                        ഀഊ                        $testCommand | Out-File -filepath $ImportNonMasterScriptOutput -encoding ASCII -append਀                紀ഀഊ            }਀        紀ഀഊ    } ਀    眀爀椀琀攀ⴀ栀漀猀琀 ∀㔀⸀ 嬀䤀洀瀀漀爀琀一漀渀䴀愀猀琀攀爀崀 䘀椀渀椀猀栀攀搀 眀爀椀琀椀渀最 漀甀琀瀀甀琀 琀漀㨀 ∀ ␀䤀洀瀀漀爀琀一漀渀䴀愀猀琀攀爀匀挀爀椀瀀琀伀甀琀瀀甀琀 ഀഊ}਀⌀䜀攀琀䘀爀漀洀吀䘀匀ഀഊImportMaster਀䤀洀瀀漀爀琀一漀渀䴀愀猀琀攀爀ഀഊ