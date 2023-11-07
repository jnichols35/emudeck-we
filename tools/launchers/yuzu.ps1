$steamRunning = Get-Process -Name "Steam" -ErrorAction SilentlyContinue
if ($steamRunning) {
	$emulatorFile = "$env:USERPROFILE/EmuDeck/EmulationStation-DE/Emulators/yuzu/yuzu-windows-msvc/yuzu.exe"
	$scriptFileName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
	$NewTitle = "EmuDeck Launcher - $scriptFileName"
	[Console]::Title = $NewTitle
	. "$env:USERPROFILE/AppData/Roaming/EmuDeck/backend/functions/allCloud.ps1"
	cloud_sync_init($scriptFileName)
	if($args){
		$formattedArgs = $args | ForEach-Object { '"' + $_ + '"' }
		Start-Process $emulatorFile -WindowStyle Maximized -Wait -Args ($formattedArgs -join ' ')
	}else{
		Start-Process $emulatorFile -WindowStyle Maximized -Wait
	}
	rm -fo "$savesPath/.watching" -ErrorAction SilentlyContinue
	rm -fo "$savesPath/.emulator" -ErrorAction SilentlyContinue
} else {
	. "$env:USERPROFILE/AppData/Roaming/EmuDeck/backend/functions/allCloud.ps1"
	showNotification -ToastTitle "Steam error" -ToastText "Steam is not running in the background, closing..."
	Start-Sleep -Seconds 2
	$toast.Close()
}
