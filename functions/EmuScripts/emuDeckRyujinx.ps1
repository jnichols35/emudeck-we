function Ryujinx_install(){
	setMSG "Downloading Ryujinx"
	$url_ryu = getLatestReleaseURLGH "Ryujinx/release-channel-master" "zip"
	download $url_ryu "Ryujinx.zip"
	moveFromTo "$temp/Ryujinx/publish" "$emusPath\Ryujinx"
	createLauncher "Ryujinx"
}
function Ryujinx_init(){
	setMSG "Ryujinx - Configuration"
	$destination="$emusPath\Ryujinx"
	mkdir "$destination\portable" -ErrorAction SilentlyContinue
	Copy-Item -Path "$env:USERPROFILE\AppData\Roaming\EmuDeck\backend\configs\Ryujinx\Config.json" -Destination "$destination\portable\Config.json"
	Ryujinx_setEmulationFolder	
	Ryujinx_setupSaves
	Ryujinx_setResolution $yuzuResolution
	
	
	sedFile "$destination\portable\Config.json" "C:\\Emulation" "$emulationPath"
	sedFile "$destination\portable\Config.json" ":\Emulation" ":\\Emulation"
	
	
	setMSG "Ryujinx - Creating Keys  Links"
	#Firmware
	$simLinkPath = "$emusPath\Ryujinx\portable\system"
	$emuSavePath = -join($emulationPath,"\bios\ryujinx\keys")
	mkdir "bios\ryujinx" -ErrorAction SilentlyContinue
	mkdir $simLinkPath -ErrorAction SilentlyContinue
	createSymlink $simLinkPath $emuSavePath
	
}

function Ryujinx_update(){
	Write-Output "NYI"
}
function Ryujinx_setEmulationFolder(){
	$destination="$emusPath\Ryujinx"
	sedFile $destination\portable\Config.json "/run/media/mmcblk0p1/Emulation/roms/switch" "$romsPath/switch"
}
function Ryujinx_setupSaves(){
  setMSG "Ryujinx - Saves Links"
  $simLinkPath = "$emusPath\Ryujinx\portable\bis\user\save\"  
  $emuSavePath = -join($emulationPath,"\saves\ryujinx\saves")
  createSymlink $simLinkPath $emuSavePath
  
  $simLinkPath = "$emusPath\Ryujinx\portable\bis\user\saveMeta\"  
  $emuSavePath = -join($emulationPath,"\saves\ryujinx\saveMeta")
  createSymlink $simLinkPath $emuSavePath
	
}

function Ryujinx_setResolution($resolution){
	switch ( $resolution )
	{
		"720P" { $multiplier = 1;  $docked="false"}
		"1080P" { $multiplier = 1; $docked="true"   }
		"1440P" { $multiplier = 2;  $docked="false" }
		"4K" { $multiplier = 2; $docked="true" }
	}	
	
	$jsonConfig = Get-Content -Path "$emusPath\Ryujinx\portable\Config.json" | ConvertFrom-Json
	$jsonConfig.docked_mode = $docked
	$jsonConfig.res_scale = $multiplier
}
function Ryujinx_setupStorage(){
	Write-Output "NYI"
}
function Ryujinx_wipe(){
	Write-Output "NYI"
}
function Ryujinx_uninstall(){
	Write-Output "NYI"
}
function Ryujinx_migrate(){
	Write-Output "NYI"
}
function Ryujinx_setABXYstyle(){
	Write-Output "NYI"
}
function Ryujinx_wideScreenOn(){
	Write-Output "NYI"
}
function Ryujinx_wideScreenOff(){
	Write-Output "NYI"
}
function Ryujinx_bezelOn(){
	Write-Output "NYI"
}
function Ryujinx_bezelOff(){
	Write-Output "NYI"
}
function Ryujinx_finalize(){
	Write-Output "NYI"
}
function Ryujinx_IsInstalled(){
	$test=Test-Path -Path "$emusPath\Ryujinx"
	if($test){
		Write-Output "true"
	}
}
function Ryujinx_resetConfig(){
	Ryujinx_init
	if($?){
		Write-Output "true"
	}
}