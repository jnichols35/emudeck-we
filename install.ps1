clear

#
##
###
#### Vars
###
##
#

$PSversionMajor = $PSVersionTable.PSVersion.Major
$PSversionMinor = $PSVersionTable.PSVersion.Minor
$PSversion = "$PSversionMajor$PSversionMinor"
$osInfo = (systeminfo | findstr /B /C:"OS Name") | ForEach-Object { $_ -replace 'OS Name:', '' }


#
##
###
#### Functions
###
##
#

Function NewWPFDialog() {
	<#
	.SYNOPSIS
	This neat little function is based on the one from Brian Posey's Article on Powershell GUIs

	.DESCRIPTION
	  I re-factored a bit to return the resulting XaML Reader and controls as a single, named collection.

	.PARAMETER XamlData
	 XamlData - A string containing valid XaML data

	.EXAMPLE

	  $MyForm = New-WPFDialog -XamlData $XaMLData
	  $MyForm.Exit.Add_Click({...})
	  $null = $MyForm.UI.Dispatcher.InvokeAsync{$MyForm.UI.ShowDialog()}.Wait()

	.NOTES
	Place additional notes here.

	.LINK
	  http://www.windowsnetworking.com/articles-tutorials/netgeneral/building-powershell-gui-part2.html

	.INPUTS
	 XamlData - A string containing valid XaML data

	.OUTPUTS
	 a collection of WPF GUI objects.
  #>

	Param([Parameter(Mandatory = $True, HelpMessage = 'XaML Data defining a GUI', Position = 1)]
		[string]$XamlData)

	# Add WPF and Windows Forms assemblies
	try {
		Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase, system.windows.forms
	}
	catch {
		Throw 'Failed to load Windows Presentation Framework assemblies.'
	}

	# Create an XML Object with the XaML data in it
	[xml]$xmlWPF = $XamlData

	# Create the XAML reader using a new XML node reader, UI is the only hard-coded object name here
	Set-Variable -Name XaMLReader -Value @{ 'UI' = ([Windows.Markup.XamlReader]::Load((new-object -TypeName System.Xml.XmlNodeReader -ArgumentList $xmlWPF))) }

	# Create hooks to each named object in the XAML reader
	$Elements = $xmlWPF.SelectNodes('//*[@Name]')
	ForEach ( $Element in $Elements ) {
		$VarName = $Element.Name
		$VarValue = $XaMLReader.UI.FindName($Element.Name)
		$XaMLReader.Add($VarName, $VarValue)
	}

	return $XaMLReader
}

function yesNoDialog {
	param (
		[string]$TitleText = "Do you want to continue?",
		[string]$MessageText = "",
		[string]$OKButtonText = "Continue",
		[string]$CancelButtonText = "Cancel",
		[bool]$ShowCancelButton = $true

	)
	# This is the XAML that defines the GUI.

	$WPFXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		Title="Popup" AllowsTransparency="True" Background="Transparent" Foreground="#FFFFFFFF" ResizeMode="NoResize" WindowStartupLocation="CenterScreen" SizeToContent="WidthAndHeight" WindowStyle="None" MaxWidth="600" Padding="20" Margin="0" Topmost="True">
<Border CornerRadius="10" BorderBrush="#222" BorderThickness="2" Background="#222">
 <Grid Name="grid">
			<ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
				<StackPanel>
					<Border Margin="20,10,0,20" Background="Transparent">
						<TextBlock Name="Title" Margin="0,10,0,10" TextWrapping="Wrap" Text="_TITLE_" FontSize="24" FontWeight="Bold" HorizontalAlignment="Left"/>
					</Border>
					<Border Margin="20,0,20,0" Background="Transparent">
						<TextBlock Name="Message" Margin="0,0,0,20" TextWrapping="Wrap" Text="_CONTENT_" FontSize="18"/>
					</Border>
					<Border Margin="20,0,20,20" Background="Transparent">
					<StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
						<Border CornerRadius="20" BorderBrush="#5bf" BorderThickness="1" Background="#5bf" Margin="0,0,10,0" >
							<Button Name="OKButton" BorderBrush="Transparent" Content="_OKBUTTONTEXT_" Background="Transparent" FontSize="16" Foreground="White">
								<Button.Style>
									<Style TargetType="Button">
										<Setter Property="Background" Value="#5bf" />
										<Setter Property="Template">
											<Setter.Value>
												<ControlTemplate TargetType="Button">
													<Border CornerRadius="20" Background="{TemplateBinding Background}" BorderThickness="1" Margin="16,8,16,8">
														<ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
													</Border>
													<ControlTemplate.Triggers>
														<Trigger Property="IsMouseOver" Value="True">
															<Setter Property="Background" Value="#fff" />
														</Trigger>
													</ControlTemplate.Triggers>
												</ControlTemplate>
											</Setter.Value>
										</Setter>
									</Style>
								</Button.Style>
							</Button>
						</Border>
						<Border CornerRadius="20" BorderBrush="#666" BorderThickness="1" Background="#666">
							<Button Name="CancelButton" Content="_CANCELBUTTONTEXT_" Margin="0"  Background="Transparent" BorderBrush="Transparent" FontSize="16" Foreground="White">
								<Button.Style>
									<Style TargetType="Button">
										<Setter Property="Background" Value="#666" />
										<Setter Property="Template">
											<Setter.Value>
												<ControlTemplate TargetType="Button">
													<Border CornerRadius="20" Background="{TemplateBinding Background}" BorderThickness="1" Margin="16,8,16,8">
														<ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
													</Border>
													<ControlTemplate.Triggers>
														<Trigger Property="IsMouseOver" Value="True">
															<Setter Property="Background" Value="#fff" />
														</Trigger>
													</ControlTemplate.Triggers>
												</ControlTemplate>
											</Setter.Value>
										</Setter>
									</Style>
								</Button.Style>
							</Button>
						</Border>
					</StackPanel>
					</Border>
				</StackPanel>
			</ScrollViewer>
		</Grid>
</Border>
</Window>
'@

	# Build Dialog
	$WPFGui = NewWPFDialog -XamlData $WPFXaml
	$WPFGui.Message.Text = $MessageText
	$WPFGui.Title.Text = $TitleText
	$WPFGui.Message.Text = $MessageText

	$WPFGui.OKButton.Content = $OKButtonText
	$WPFGui.CancelButton.Content = $CancelButtonText

	# Create a script block to handle the button click event
	$buttonClickEvent = {
		param($sender, $e)
		$global:Result = $sender.Name
		$WPFGui.UI.Close()
	}

	# Add the script block to the button's Click event
	$WPFGui.OKButton.Add_Click($buttonClickEvent)

	# Create a script block to handle the button click event for "Cancel" button
	$cancelButtonClickEvent = {
		param($sender, $e)
		$global:Result = $sender.Name  # Set the Result to the name of the clicked button ("CancelButton")
		$WPFGui.UI.Close()
	}

	# Add the script block to the "Cancel" button's Click event
	$WPFGui.CancelButton.Add_Click($cancelButtonClickEvent)

	# Create a variable to hold the result
	$global:Result = $null

	# Show the dialog
	$null = $WPFGUI.UI.Dispatcher.InvokeAsync{ $WPFGui.UI.ShowDialog() }.Wait()

	# Return the result
	return $global:Result
}

function confirmDialog {
	param (
		[string]$TitleText = "Do you want to continue?",
		[string]$MessageText = "",
		[string]$OKButtonText = "Continue",
		[string]$CancelButtonText = "Cancel"
	)
	# This is the XAML that defines the GUI.
	$WPFXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		Title="Popup" AllowsTransparency="True" Background="Transparent"  Foreground="#FFFFFFFF" ResizeMode="NoResize" WindowStartupLocation="CenterScreen" SizeToContent="WidthAndHeight" WindowStyle="None" MaxWidth="600" Padding="20" Margin="0" Topmost="True">
<Border CornerRadius="10" BorderBrush="#222" BorderThickness="2" Background="#222">
 <Grid Name="grid">
			<ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
				<StackPanel>
					<Border Margin="20,10,0,20" Background="Transparent">
						<TextBlock Name="Title" Margin="0,10,0,10" TextWrapping="Wrap" Text="_TITLE_" FontSize="24" FontWeight="Bold" HorizontalAlignment="Left"/>
					</Border>
					<Border Margin="20,0,20,0" Background="Transparent">
						<TextBlock Name="Message" Margin="0,0,0,20" TextWrapping="Wrap" Text="_CONTENT_" FontSize="18"/>
					</Border>
					<StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
						<Border CornerRadius="20" BorderBrush="#5bf" BorderThickness="1" Background="#5bf" Margin="0,0,10,20" >
							<Button Name="OKButton" BorderBrush="Transparent" Content="_OKBUTTONTEXT_" Background="Transparent" FontSize="16" Foreground="White">
								<Button.Style>
									<Style TargetType="Button">
										<Setter Property="Background" Value="#5bf" />
										<Setter Property="Template">
											<Setter.Value>
												<ControlTemplate TargetType="Button">
													<Border CornerRadius="20" Background="{TemplateBinding Background}" BorderThickness="1" Margin="16,8,16,8">
														<ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
													</Border>
													<ControlTemplate.Triggers>
														<Trigger Property="IsMouseOver" Value="True">
															<Setter Property="Background" Value="#fff" />
														</Trigger>
													</ControlTemplate.Triggers>
												</ControlTemplate>
											</Setter.Value>
										</Setter>
									</Style>
								</Button.Style>
							</Button>
						</Border>
					</StackPanel>
				</StackPanel>
			</ScrollViewer>
		</Grid>
</Border>
</Window>
'@

	# Build Dialog
	$WPFGui = NewWPFDialog -XamlData $WPFXaml
	$WPFGui.Message.Text = $MessageText
	$WPFGui.Title.Text = $TitleText
	$WPFGui.Message.Text = $MessageText

	$WPFGui.OKButton.Content = $OKButtonText

	# Create a script block to handle the button click event
	$buttonClickEvent = {
		param($sender, $e)
		$global:Result = $sender.Name
		$WPFGui.UI.Close()
	}

	# Add the script block to the button's Click event
	$WPFGui.OKButton.Add_Click($buttonClickEvent)

	# Create a variable to hold the result
	$global:Result = $null

	# Show the dialog
	$null = $WPFGUI.UI.Dispatcher.InvokeAsync{ $WPFGui.UI.ShowDialog() }.Wait()

	# Return the result
	return $global:Result
}

function getLatestReleaseURLGH($Repository, $FileType, $FindToMatch, $IgnoreText = "pepe"){

	$url = "https://api.github.com/repos/$Repository/releases/latest"

	$url = Invoke-RestMethod -Uri $url | Select-Object -ExpandProperty assets |
		   Where-Object { $_.browser_download_url -Match $FindToMatch -and $_.browser_download_url -like "*.$FileType" -and $_.browser_download_url -notlike "*$IgnoreText*" } |
		   Select-Object -ExpandProperty browser_download_url | Select-Object -First 1
		   return $url

	return $url
}

function startScriptWithAdmin {
	param (
		[string]$ScriptContent
	)

	#$scriptContent = @"
	#. "$env:APPDATA\EmuDeck\backend\functions\all.ps1";
	#Write-Host "I'm Admin"
	#"@

	$tempScriptPath = [System.IO.Path]::GetTempFileName() + ".ps1"
	$ScriptContent | Out-File -FilePath $tempScriptPath -Encoding utf8 -Force

	$psi = New-Object System.Diagnostics.ProcessStartInfo
	$psi.Verb = "runas"
	$psi.FileName = "powershell.exe"
	$psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File ""$tempScriptPath"""
	[System.Diagnostics.Process]::Start($psi).WaitForExit()

	Remove-Item $tempScriptPath -Force
}

function download($url, $file) {

	$wc = New-Object net.webclient
	$temp = Join-Path "$env:USERPROFILE" "Downloads"
	$destination="$temp/$file"
	mkdir $temp -ErrorAction SilentlyContinue

	$wc.Downloadfile($url, $destination)

	Write-Host "Done!" -NoNewline -ForegroundColor green -BackgroundColor black
}

if ($osInfo -contains "Windows 10 Home") {
	$developerModeStatus = Get-WindowsDeveloperLicense
	if ($developerModeStatus.DeveloperLicense) {
		Write-Host "Developer Mode detected..."
	} else {
		confirmDialog -TitleText "Windows 10 Home Detected" -MessageText "You need to enable Developer mode inside your Windows Settings to install EmuDeck."
		exit
	}
}



if( (Get-DnsClientServerAddress).ServerAddresses[0] -ne '1.1.1.1' -and (Get-DnsClientServerAddress).ServerAddresses[0] -ne '8.8.8.8' ){


	$result = yesNoDialog -TitleText "Slow DNS Detected" -MessageText "We've detected slow DNS, this might make EmuDeck to get stuck on install. Do you want us to change them for faster ones? 1.1.1.1 (CloudFlare) and 8.8.8.8 (Google)" -OKButtonText "Yes" -CancelButtonText "No"

	if ($result -eq "OKButton") {
	$scriptContent = @"
		Set-DnsClientServerAddress -ServerAddresses "8.8.8.8", "1.1.1.1"  -InterfaceIndex (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).InterfaceIndex
"@
		startScriptWithAdmin -ScriptContent $scriptContent
	}

}



if ( $PSversion -lt 51 ){
	clear
	Write-Host "Updating PowerShell to 5.1" -ForegroundColor white
	Write-Host ""
	Write-Host " Downloading .NET..."
	download "https://go.microsoft.com/fwlink/?linkid=2088631" "dotNet.exe"
	$temp = Join-Path "$env:USERPROFILE" "Downloads"
	&"$temp/dotNet.exe"
	rm -fo -r "$temp/dotNet.exe"

	Write-Host ""
	Write-Host " Downloading WMF 5.1..."
	download "https://go.microsoft.com/fwlink/?linkid=839516" "wmf51.msu"

	$temp = Join-Path "$env:USERPROFILE" "Downloads"
	&"$temp/wmf51.msu"
	rm -fo -r "$temp/wmf51.msu"

	Write-Host ""
	Write-Host " If the WMF installation fails please restart Windows and run the installer again"  -ForegroundColor white
	Read-Host -Prompt "Press ENTER to continue or CTRL+C to quit"
	clear
	Write-Host "PowerShell updated to 5.1" -ForegroundColor white
}

	$FIPSAlgorithmPolicy = Get-ItemProperty -Path HKLM:\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy
	$EnabledValue = $FIPSAlgorithmPolicy.Enabled

	if($EnabledValue -eq 1){
		Write-Host "Windows FIPS detected, we need to turn it off so cloudSync can be used, after that the computer will restart. Once back in the desktop just run this installer again. You can read about FIPS here and why is better to disable it: https://techcommunity.microsoft.com/t5/microsoft-security-baselines/why-we-re-not-recommending-fips-mode-anymore/ba-p/701037" -ForegroundColor white
		Read-Host -Prompt "Press ENTER to apply the fix and restart"
$scriptContent = @"
Set-ItemProperty -Path HKLM:\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy -name Enabled -value 0; Restart-Computer -Force
"@
			startScriptWithAdmin -ScriptContent $scriptContent
	}
#
##
###
#### Start the party
###
##
#

Write-Host "Installing EmuDeck WE Dependencies" -ForegroundColor white
Write-Host ""


confirmDialog -TitleText "Windows Store" -MessageText "Make sure you have the 'App Installer' app up to date in the Windows Store, or the EmuDeck installation. Press Continue to open the App Instaler page in the Microsoft Store and then click update."

Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"

Write-Host "Waiting for user, please update App Installer, close the Microsoft Store after that..."

$storeProcess = Get-Process -Name "WinStore.App"

$storeProcess.WaitForExit()
cls
Write-Host "Updating Winget" -ForegroundColor white
Write-Host ""

$url = "https://cdn.winget.microsoft.com/cache/source.msix"
$destination = "$env:TEMP\source.msix"
Invoke-WebRequest -Uri $url -OutFile $destination
Start-Process -FilePath $destination

Write-Host "Waiting for user, please update / Reinstall Winget..."

$storeProcess = Get-Process -Name "AppInstaller"

$storeProcess.WaitForExit()

Start-Process "winget" -Wait -NoNewWindow -Args "install -e --id Git.Git --accept-package-agreements --accept-source-agreements"


$installDir="$env:ProgramFiles\Git\"
if (-not (Test-Path $installDir)) {


	$Host.UI.RawUI.BackgroundColor = "Red"

	#Clear-Host
	Write-Host ""
	Write-Host "There was an error trying to install GIT using Winget."
	Write-Host "We are gonna try to install it manually..."
	Write-Host ""
	$Host.UI.RawUI.BackgroundColor = "Black"

	#Download git
	Write-Host "Downloading GIT..."
	$url_git = getLatestReleaseURLGH 'git-for-windows/git' 'exe' '64-bit'
	download $url_git "git_install.exe"
	$temp = Join-Path "$env:USERPROFILE" "Downloads"

	Write-Host "Installing GIT in the background, please wait a few minutes..."

	$installDir="$env:ProgramFiles\Git\"

	Start-Process "$temp\git_install.exe" -Wait -Args "/VERYSILENT /INSTALLDIR=\$installDir"
	$file = "$env:USERPROFILE\roms\$system\media\$type\$romName.png"


	if (-not (Test-Path $installDir)) {
		$Host.UI.RawUI.BackgroundColor = "Red"
		Write-Host "GIT Download Failed" -ForegroundColor white
		$Host.UI.RawUI.BackgroundColor = "Black"
		Write-Host "Please visit this url to learn how to install all the dependencies manually by yourself:" -ForegroundColor white
		Write-Host ""
		Write-Host "https://emudeck.github.io/known-issues/windows/#dependencies" -ForegroundColor white
		Write-Host ""
		Write-Host ""
		$Host.UI.RawUI.BackgroundColor = "Black"
		Read-Host -Prompt "Press ENTER to exit"
	}else{
		Write-Host "Please restart this installer to continue"
		Read-Host -Prompt "Press ENTER to exit"
	}

}else{
	Write-Host "All dependencies are installed" -ForegroundColor white
	Write-Host ""
	Write-Host "Downloading EmuDeck..." -ForegroundColor white
	Write-Host ""
	$url_emudeck = getLatestReleaseURLGH 'EmuDeck/emudeck-electron-early' 'exe' 'emudeck'
	download $url_emudeck "emudeck_install.exe"
	$temp = Join-Path "$env:USERPROFILE" "Downloads"
	Write-Host " Launching EmuDeck Installer, please wait..."
	&"$temp/emudeck_install.exe"
}

# SIG # Begin signature block
# MIIvNgYJKoZIhvcNAQcCoIIvJzCCLyMCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDSV2OmAhQ7T6zz
# 5YQA8tYaGHtLixM6Zlm0djjbmnrnWKCCE00wggXJMIIEsaADAgECAhAbtY8lKt8j
# AEkoya49fu0nMA0GCSqGSIb3DQEBDAUAMH4xCzAJBgNVBAYTAlBMMSIwIAYDVQQK
# ExlVbml6ZXRvIFRlY2hub2xvZ2llcyBTLkEuMScwJQYDVQQLEx5DZXJ0dW0gQ2Vy
# dGlmaWNhdGlvbiBBdXRob3JpdHkxIjAgBgNVBAMTGUNlcnR1bSBUcnVzdGVkIE5l
# dHdvcmsgQ0EwHhcNMjEwNTMxMDY0MzA2WhcNMjkwOTE3MDY0MzA2WjCBgDELMAkG
# A1UEBhMCUEwxIjAgBgNVBAoTGVVuaXpldG8gVGVjaG5vbG9naWVzIFMuQS4xJzAl
# BgNVBAsTHkNlcnR1bSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTEkMCIGA1UEAxMb
# Q2VydHVtIFRydXN0ZWQgTmV0d29yayBDQSAyMIICIjANBgkqhkiG9w0BAQEFAAOC
# Ag8AMIICCgKCAgEAvfl4+ObVgAxknYYblmRnPyI6HnUBfe/7XGeMycxca6mR5rlC
# 5SBLm9qbe7mZXdmbgEvXhEArJ9PoujC7Pgkap0mV7ytAJMKXx6fumyXvqAoAl4Va
# qp3cKcniNQfrcE1K1sGzVrihQTib0fsxf4/gX+GxPw+OFklg1waNGPmqJhCrKtPQ
# 0WeNG0a+RzDVLnLRxWPa52N5RH5LYySJhi40PylMUosqp8DikSiJucBb+R3Z5yet
# /5oCl8HGUJKbAiy9qbk0WQq/hEr/3/6zn+vZnuCYI+yma3cWKtvMrTscpIfcRnNe
# GWJoRVfkkIJCu0LW8GHgwaM9ZqNd9BjuiMmNF0UpmTJ1AjHuKSbIawLmtWJFfzcV
# WiNoidQ+3k4nsPBADLxNF8tNorMe0AZa3faTz1d1mfX6hhpneLO/lv403L3nUlbl
# s+V1e9dBkQXcXWnjlQ1DufyDljmVe2yAWk8TcsbXfSl6RLpSpCrVQUYJIP4ioLZb
# MI28iQzV13D4h1L92u+sUS4Hs07+0AnacO+Y+lbmbdu1V0vc5SwlFcieLnhO+Nqc
# noYsylfzGuXIkosagpZ6w7xQEmnYDlpGizrrJvojybawgb5CAKT41v4wLsfSRvbl
# jnX98sy50IdbzAYQYLuDNbdeZ95H7JlI8aShFf6tjGKOOVVPORa5sWOd/7cCAwEA
# AaOCAT4wggE6MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFLahVDkCw6A/joq8
# +tT4HKbROg79MB8GA1UdIwQYMBaAFAh2zcsH/yT2xc3tu5C84oQ3RnX3MA4GA1Ud
# DwEB/wQEAwIBBjAvBgNVHR8EKDAmMCSgIqAghh5odHRwOi8vY3JsLmNlcnR1bS5w
# bC9jdG5jYS5jcmwwawYIKwYBBQUHAQEEXzBdMCgGCCsGAQUFBzABhhxodHRwOi8v
# c3ViY2Eub2NzcC1jZXJ0dW0uY29tMDEGCCsGAQUFBzAChiVodHRwOi8vcmVwb3Np
# dG9yeS5jZXJ0dW0ucGwvY3RuY2EuY2VyMDkGA1UdIAQyMDAwLgYEVR0gADAmMCQG
# CCsGAQUFBwIBFhhodHRwOi8vd3d3LmNlcnR1bS5wbC9DUFMwDQYJKoZIhvcNAQEM
# BQADggEBAFHCoVgWIhCL/IYx1MIy01z4S6Ivaj5N+KsIHu3V6PrnCA3st8YeDrJ1
# BXqxC/rXdGoABh+kzqrya33YEcARCNQOTWHFOqj6seHjmOriY/1B9ZN9DbxdkjuR
# mmW60F9MvkyNaAMQFtXx0ASKhTP5N+dbLiZpQjy6zbzUeulNndrnQ/tjUoCFBMQl
# lVXwfqefAcVbKPjgzoZwpic7Ofs4LphTZSJ1Ldf23SIikZbr3WjtP6MZl9M7JYjs
# NhI9qX7OAo0FmpKnJ25FspxihjcNpDOO16hO0EoXQ0zF8ads0h5YbBRRfopUofbv
# n3l6XYGaFpAP4bvxSgD5+d2+7arszgowgga5MIIEoaADAgECAhEAmaOACiZVO2Wr
# 3G6EprPqOTANBgkqhkiG9w0BAQwFADCBgDELMAkGA1UEBhMCUEwxIjAgBgNVBAoT
# GVVuaXpldG8gVGVjaG5vbG9naWVzIFMuQS4xJzAlBgNVBAsTHkNlcnR1bSBDZXJ0
# aWZpY2F0aW9uIEF1dGhvcml0eTEkMCIGA1UEAxMbQ2VydHVtIFRydXN0ZWQgTmV0
# d29yayBDQSAyMB4XDTIxMDUxOTA1MzIxOFoXDTM2MDUxODA1MzIxOFowVjELMAkG
# A1UEBhMCUEwxITAfBgNVBAoTGEFzc2VjbyBEYXRhIFN5c3RlbXMgUy5BLjEkMCIG
# A1UEAxMbQ2VydHVtIENvZGUgU2lnbmluZyAyMDIxIENBMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEAnSPPBDAjO8FGLOczcz5jXXp1ur5cTbq96y34vuTm
# flN4mSAfgLKTvggv24/rWiVGzGxT9YEASVMw1Aj8ewTS4IndU8s7VS5+djSoMcbv
# IKck6+hI1shsylP4JyLvmxwLHtSworV9wmjhNd627h27a8RdrT1PH9ud0IF+njvM
# k2xqbNTIPsnWtw3E7DmDoUmDQiYi/ucJ42fcHqBkbbxYDB7SYOouu9Tj1yHIohzu
# C8KNqfcYf7Z4/iZgkBJ+UFNDcc6zokZ2uJIxWgPWXMEmhu1gMXgv8aGUsRdaCtVD
# 2bSlbfsq7BiqljjaCun+RJgTgFRCtsuAEw0pG9+FA+yQN9n/kZtMLK+Wo837Q4QO
# ZgYqVWQ4x6cM7/G0yswg1ElLlJj6NYKLw9EcBXE7TF3HybZtYvj9lDV2nT8mFSkc
# SkAExzd4prHwYjUXTeZIlVXqj+eaYqoMTpMrfh5MCAOIG5knN4Q/JHuurfTI5XDY
# O962WZayx7ACFf5ydJpoEowSP07YaBiQ8nXpDkNrUA9g7qf/rCkKbWpQ5boufUnq
# 1UiYPIAHlezf4muJqxqIns/kqld6JVX8cixbd6PzkDpwZo4SlADaCi2JSplKShBS
# ND36E/ENVv8urPS0yOnpG4tIoBGxVCARPCg1BnyMJ4rBJAcOSnAWd18Jx5n858JS
# qPECAwEAAaOCAVUwggFRMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFN10XUwA
# 23ufoHTKsW73PMAywHDNMB8GA1UdIwQYMBaAFLahVDkCw6A/joq8+tT4HKbROg79
# MA4GA1UdDwEB/wQEAwIBBjATBgNVHSUEDDAKBggrBgEFBQcDAzAwBgNVHR8EKTAn
# MCWgI6Ahhh9odHRwOi8vY3JsLmNlcnR1bS5wbC9jdG5jYTIuY3JsMGwGCCsGAQUF
# BwEBBGAwXjAoBggrBgEFBQcwAYYcaHR0cDovL3N1YmNhLm9jc3AtY2VydHVtLmNv
# bTAyBggrBgEFBQcwAoYmaHR0cDovL3JlcG9zaXRvcnkuY2VydHVtLnBsL2N0bmNh
# Mi5jZXIwOQYDVR0gBDIwMDAuBgRVHSAAMCYwJAYIKwYBBQUHAgEWGGh0dHA6Ly93
# d3cuY2VydHVtLnBsL0NQUzANBgkqhkiG9w0BAQwFAAOCAgEAdYhYD+WPUCiaU58Q
# 7EP89DttyZqGYn2XRDhJkL6P+/T0IPZyxfxiXumYlARMgwRzLRUStJl490L94C9L
# GF3vjzzH8Jq3iR74BRlkO18J3zIdmCKQa5LyZ48IfICJTZVJeChDUyuQy6rGDxLU
# UAsO0eqeLNhLVsgw6/zOfImNlARKn1FP7o0fTbj8ipNGxHBIutiRsWrhWM2f8pXd
# d3x2mbJCKKtl2s42g9KUJHEIiLni9ByoqIUul4GblLQigO0ugh7bWRLDm0CdY9rN
# LqyA3ahe8WlxVWkxyrQLjH8ItI17RdySaYayX3PhRSC4Am1/7mATwZWwSD+B7eMc
# ZNhpn8zJ+6MTyE6YoEBSRVrs0zFFIHUR08Wk0ikSf+lIe5Iv6RY3/bFAEloMU+vU
# BfSouCReZwSLo8WdrDlPXtR0gicDnytO7eZ5827NS2x7gCBibESYkOh1/w1tVxTp
# V2Na3PR7nxYVlPu1JPoRZCbH86gc96UTvuWiOruWmyOEMLOGGniR+x+zPF/2DaGg
# K2W1eEJfo2qyrBNPvF7wuAyQfiFXLwvWHamoYtPZo0LHuH8X3n9C+xN4YaNjt2yw
# zOr+tKyEVAotnyU9vyEVOaIYMk3IeBrmFnn0gbKeTTyYeEEUz/Qwt4HOUBCrW602
# NCmvO1nm+/80nLy5r0AZvCQxaQ4wgga/MIIEp6ADAgECAhBUsN7LB9L4KOkgMXsJ
# G1QIMA0GCSqGSIb3DQEBCwUAMFYxCzAJBgNVBAYTAlBMMSEwHwYDVQQKExhBc3Nl
# Y28gRGF0YSBTeXN0ZW1zIFMuQS4xJDAiBgNVBAMTG0NlcnR1bSBDb2RlIFNpZ25p
# bmcgMjAyMSBDQTAeFw0yMzEyMTUxMjQ0NTZaFw0yNDEyMTQxMjQ0NTVaMGUxCzAJ
# BgNVBAYTAkVTMRQwEgYDVQQHDAtWaWxsYWxiaWxsYTEfMB0GA1UECgwWUm9kcmln
# byBTZWRhbm8gSmltZW5lejEfMB0GA1UEAwwWUm9kcmlnbyBTZWRhbm8gSmltZW5l
# ejCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAI2GNPfNadWxZpICb9kW
# U0McDTx7bNxB6ErCPppAGMUFrU7DLnJ8UKDN+sfe4rm+pyghIYLQqHMvPQ54EJeq
# Zs5geqXFvlEenXuwiJs1t4UO0yD+Gbjk32P0q2B8Y0/Lxin4z9EAi1LYvwIh6kEN
# auDg7VBOYl0tDmWKP6mqaqkpGXK/ltgaskS9oR0mXIz1bOcXE6bAfMdvvfwq+YHY
# Lrqq6qjqAL1FvXVC5u32rXlex6yS4rJ5C0s3WuDyQlqfNHm9a8QOzcGitXf2b9GQ
# D2TENA0VrwENaVZGMhm1pmg9yZ9gy7gma42oId0OuZOy6gF/kd+AbaVYMR94r2wi
# Ziy6fYz19FeP/Fk9GrwLCH1HDhWhseBxHI8HXv07XIFDiyH000qi1YTB5OqP99am
# rdkmTR1bbuTjydU3JdNERwetPANiDUN3aBCpEHdAH4+YWUp+VN3fQPJUAaB5WUiC
# BJz4WlTCqTRXtFrOYmJHmnByYkXrT0ftxK+5WnlKyyS+LvzAZu7hZE1NbcGGHzUz
# XQ+Xk3iRmx142j+UrB08SL40h2oF5TBczK1G0PVGAG56LQ8QuQ3SctnPNBOobrqG
# 13jKFM29cxs3ANob75j5IcXxVjrXiabdySsC7o3hY4SyDOnk7e+EUNQBJZbLVIIJ
# 3A/xqlrbBvU3QYaipLuQdbBDAgMBAAGjggF4MIIBdDAMBgNVHRMBAf8EAjAAMD0G
# A1UdHwQ2MDQwMqAwoC6GLGh0dHA6Ly9jY3NjYTIwMjEuY3JsLmNlcnR1bS5wbC9j
# Y3NjYTIwMjEuY3JsMHMGCCsGAQUFBwEBBGcwZTAsBggrBgEFBQcwAYYgaHR0cDov
# L2Njc2NhMjAyMS5vY3NwLWNlcnR1bS5jb20wNQYIKwYBBQUHMAKGKWh0dHA6Ly9y
# ZXBvc2l0b3J5LmNlcnR1bS5wbC9jY3NjYTIwMjEuY2VyMB8GA1UdIwQYMBaAFN10
# XUwA23ufoHTKsW73PMAywHDNMB0GA1UdDgQWBBQQKwRGH7/oAxh3CQEAR0xieePL
# EjBLBgNVHSAERDBCMAgGBmeBDAEEATA2BgsqhGgBhvZ3AgUBBDAnMCUGCCsGAQUF
# BwIBFhlodHRwczovL3d3dy5jZXJ0dW0ucGwvQ1BTMBMGA1UdJQQMMAoGCCsGAQUF
# BwMDMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEAAVPCnrMPQUKb
# lzOxzCq9banT75fHMGi7l+IrI9w+V38iTTrSPEe3aveoZQm3gLfSVr6P1lbD6tnJ
# HlzI626XAz0yzNdk6xkU25t8CLIMsXxNIuKcgiMAzSHTlrDmsaPCwTZ9pttWtMVt
# h6cj8oighuRcUYLSMjm401AaP0gEPEMN6Oxv7Fv124FxrqA6HkRFRaH2vy3fON8j
# SKtqR9yTd3vScKtEOVTY0s2CAmR76TGmEiW5hSr8XKR9d60j9+/EOYivy4g43LdP
# xv0NydG3J2iVsx4RSMRA3qz5E2BjfnY557uug/kVRma6e825yK2STLe9zCoxvk9G
# vFffTfCxkxr2lmu6u6FBTzN7TkiOktyDmLT2y+s6k8iWmOzDeGh/5p9FYy+kDviO
# xtp8jYSfNY+YbBpMvgcAFTvr3h7nde+AeO9CwWvQhfpsZmjZRNhpYE+dOxzHbgfm
# ekm2bwmUIDf4YFm4MJeTS8Vjgznve+0oy8BOhQPCgOyR62fHiW9fitbLNEuq+p74
# NyNdMFERwxa/98r0UqA1q23cFZS2IalbMjFA9csJCzUTUGiNTLJZmXfRZYZR+OJM
# HK4pPhh8Us/EYNAPMJ8vMIlzLUCaBx8dT2DRlBMaas6bSTSCxB4SvabIaAjcJUvK
# bng3ibbgjicHnPRGJ1iW6i/6jyg+H04xghs/MIIbOwIBATBqMFYxCzAJBgNVBAYT
# AlBMMSEwHwYDVQQKExhBc3NlY28gRGF0YSBTeXN0ZW1zIFMuQS4xJDAiBgNVBAMT
# G0NlcnR1bSBDb2RlIFNpZ25pbmcgMjAyMSBDQQIQVLDeywfS+CjpIDF7CRtUCDAN
# BglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
# SIb3DQEJBDEiBCBzMG0/EfA1gZioebJ5ggLiusni5CGQT6FxLu1Vv9ximTANBgkq
# hkiG9w0BAQEFAASCAgApZfR+xfr6RKaw79DHaAyLsKzvPMnyNQd/L5E/08kHKzMV
# Vbf/fdsEW6ejFRiohvaqLAnWDXCGc7rjI9KYKA2DPQ2OLBAW5eyGZVcO2nuOAdpI
# uihDJayaetoLI9oOWO+OnGOhXrbXrAD+sizTRL2rcfQ5pl5Blv78T2/VHO3IMQbc
# 5y+E0BLHbY/OXFTKICGIlXwsFPcRVQG7vYOkoBTyATWNw2XflOcrOH4okeMTdvDS
# eopu7hTR11c8hsA8MpLi7cY8RKhaccxqNTx1B8haVCASuBOCzGD5zRWl5Tbp95Cx
# M725em5GmtbKPLc6vMvYlrRVIjtYZ3rWFBA7rzGW0b3rUW9tw7EFFPEzIv88JEQO
# ZJFtkcM7Y0UCcVlS594GOLKuPwJswQwnxabuViKA0zbERafELNNL8XaJSuqXYq/4
# r2YLdD+HO3ND4NL4VpY3fmsJ7ozHcH3dzIcSBFZxedQiLbivpj3HpruL2CfKGEna
# OfCdipZbOjc+7MUkPWcIbSlfMsKeJ34cuVFuWBPqR29dvbeldA8RcsrlzbbFyQ97
# AjMzzFHILg3HjIwtIsKRPknsOF4hjNpSweee+k82AUJB/sQAMDOYy3e142COtiqy
# OZvWakkoLNJ6USz6y7z5WFN/T/f2i+8ATb2P55e5FxU4/Ngk2qGN/5W7ATgyIqGC
# GCgwghgkBgorBgEEAYI3AwMBMYIYFDCCGBAGCSqGSIb3DQEHAqCCGAEwghf9AgED
# MQ0wCwYJYIZIAWUDBAICMIHOBgsqhkiG9w0BCRABBKCBvgSBuzCBuAIBAQYLKoRo
# AYb2dwIFAQswMTANBglghkgBZQMEAgEFAAQgL63vzPI3LLH0jPfZa1PIN2XCDJFr
# NmGJc2KoQhVF8rkCBwqofDItOSYYDzIwMjMxMjI3MTAzMjMwWjADAgEBoFSkUjBQ
# MQswCQYDVQQGEwJQTDEhMB8GA1UECgwYQXNzZWNvIERhdGEgU3lzdGVtcyBTLkEu
# MR4wHAYDVQQDDBVDZXJ0dW0gVGltZXN0YW1wIDIwMjOgghMjMIIGlTCCBH2gAwIB
# AgIQCcXM+LtmfXE3qsFZgAbLMTANBgkqhkiG9w0BAQwFADBWMQswCQYDVQQGEwJQ
# TDEhMB8GA1UEChMYQXNzZWNvIERhdGEgU3lzdGVtcyBTLkEuMSQwIgYDVQQDExtD
# ZXJ0dW0gVGltZXN0YW1waW5nIDIwMjEgQ0EwHhcNMjMxMTAyMDgzMjIzWhcNMzQx
# MDMwMDgzMjIzWjBQMQswCQYDVQQGEwJQTDEhMB8GA1UECgwYQXNzZWNvIERhdGEg
# U3lzdGVtcyBTLkEuMR4wHAYDVQQDDBVDZXJ0dW0gVGltZXN0YW1wIDIwMjMwggIi
# MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC5Frrqxud9kjaqgkAo85Iyt6ec
# N343OWPztNOFkORvsc6ukhucOOQQ+szxH0jsi3ARjBwG1b9oQwnDx1COOkOpwm2H
# zY2zxtJe2X2qC+H8DMt4+nUNAYFuMEMjReq5ptDTI3JidDEbgcxKdr2azfCwmJ3F
# pqGpKr1LbtCD2Y7iLrwZOxODkdVYKEyJL0UPJ2A18JgNR54+CZ0/pVfCfbOEZag6
# 5oyU3A33ZY88h5mhzn9WIPF/qLR5qt9HKe9u8Y+uMgz8MKQagH/ajWG/uYcqeQK2
# 8AS3Eh5AcSwl4xFfwHGaFwExxBWSXLZRGUbn9aFdirSZKKde20p1COlmZkxImJY+
# bxQYSgw5nEM0jPg6rePD+0IQQc4APK6dSHAOQS3QvBJrfzTWlCQokGtOvxcNIs5c
# OvaANmTcGcLgkH0eHgMBpLFlcyzE0QkY8Heh+xltZFEiAvK5gbn8CHs8oo9o0/Jj
# LqdWYLrW4HnES43/NC1/sOaCVmtslTaFoW/WRRbtJaRrK/03jFjrN921dCntRRin
# B/Ew3MQ1kxPN604WCMeLvAOpT3F5KbBXoPDrMoW9OGTYnYqv88A6hTbVFRs+Ei8U
# Jjk4IlfOknHWduimRKQ4LYDY1GDSA33YUZ/c3Pootanc2iWPNavjy/ieDYIdH8XV
# bRfWqchnDpTE+0NFcwIDAQABo4IBYzCCAV8wDAYDVR0TAQH/BAIwADAdBgNVHQ4E
# FgQUx2k8Lua941lH/xkSwdk06EHP448wHwYDVR0jBBgwFoAUvlQCL79AbHNDzqwJ
# JU6eQ0Qa7uAwDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
# MDMGA1UdHwQsMCowKKAmoCSGImh0dHA6Ly9jcmwuY2VydHVtLnBsL2N0c2NhMjAy
# MS5jcmwwbwYIKwYBBQUHAQEEYzBhMCgGCCsGAQUFBzABhhxodHRwOi8vc3ViY2Eu
# b2NzcC1jZXJ0dW0uY29tMDUGCCsGAQUFBzAChilodHRwOi8vcmVwb3NpdG9yeS5j
# ZXJ0dW0ucGwvY3RzY2EyMDIxLmNlcjBBBgNVHSAEOjA4MDYGCyqEaAGG9ncCBQEL
# MCcwJQYIKwYBBQUHAgEWGWh0dHBzOi8vd3d3LmNlcnR1bS5wbC9DUFMwDQYJKoZI
# hvcNAQEMBQADggIBAHjd7rE6Q+b32Ws4vTJeC0HcGDi7mfQUnbaJ9nFFOQpizPX+
# YIpHuK89TPkOdDF7lOEmTZzVQpw0kwpIZDuB8lSM0Gw9KloOvXIsGjF/KgTNxYM5
# aViQNMtoIiF6W9ysmubDHF7lExSToPd1r+N0zYGXlE1uEX4o988K/Z7kwgE/GC64
# 9S1OEZ5IGSGmirtcruLX/xhjIDA5S/cVfz0We/ElHamHs+UfW3/IxTigvvq4JCbd
# ZHg9DsjkW+UgGGAVtkxB7qinmWJamvdwpgujAwOT1ym/giPTW5C8/MnkL18ZgVQ3
# 8sqKqFdqUS+ZIVeXKfV58HaWtV2Lip1Y0luL7Mswb856jz7zXINk79H4XfbWOryf
# 7AtWBjrus28jmHWK3gXNhj2StVcOI48Dc6CFfXDMo/c/E/ab217kTYhiht2rCWeG
# S5THQ3bZVx+lUPLaDe3kVXjYvxMYQKWu04QX6+vURFSeL3WVrUSO6nEnZu7X2EYc
# i5MUmmUdEEiAVZO/03yLlNWUNGX72/949vU+5ZN9r9EGdp7X3W7mLL1Tx4gLmHnr
# B97O+e9RYK6370MC52siufu11p3n8OG5s2zJw2J6LpD+HLbyCgfRId9Q5UKgsj0A
# 1QuoBut8FI6YdaH3sR1ponEv6GsNYrTyBtSR77csUWLUCyVbosF3+ae0+SofMIIG
# uTCCBKGgAwIBAgIRAOf/acc7Nc5LkSbYdHxopYcwDQYJKoZIhvcNAQEMBQAwgYAx
# CzAJBgNVBAYTAlBMMSIwIAYDVQQKExlVbml6ZXRvIFRlY2hub2xvZ2llcyBTLkEu
# MScwJQYDVQQLEx5DZXJ0dW0gQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxJDAiBgNV
# BAMTG0NlcnR1bSBUcnVzdGVkIE5ldHdvcmsgQ0EgMjAeFw0yMTA1MTkwNTMyMDda
# Fw0zNjA1MTgwNTMyMDdaMFYxCzAJBgNVBAYTAlBMMSEwHwYDVQQKExhBc3NlY28g
# RGF0YSBTeXN0ZW1zIFMuQS4xJDAiBgNVBAMTG0NlcnR1bSBUaW1lc3RhbXBpbmcg
# MjAyMSBDQTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOkSHwQ17bld
# esWmlUG+imV/TnfRbSV102aO2/hhKH9/t4NAoVoipzu0ePujH67y8iwlmWuhqRR4
# xLeLdPxolEL55CzgUXQaq+Qzr5Zk7ySbNl/GZloFiYwuzwWS2AVgLPLCZd5DV8QT
# F+V57Y6lsdWTrrl5dEeMfsxhkjM2eOXabwfLy6UH2ZHzAv9bS/SmMo1PobSx+vHW
# ST7c4aiwVRvvJY2dWRYpTipLEu/XqQnqhUngFJtnjExqTokt4HyzOsr2/AYOm8YO
# coJQxgvc26+LAfXHiBkbQkBdTfHak4DP3UlYolICZHL+XSzSXlsRgqiWD4MypWGU
# 4A13xiHmaRBZowS8FET+QAbMiqBaHDM3Y6wohW07yZ/mw9ZKu/KmVIAEBhrXesxi
# fPB+DTyeWNkeCGq4IlgJr/Ecr1px6/1QPtj66yvXl3uauzPPGEXUk6vUym6nZyE1
# IGXI45uGVI7XqvCt99WuD9LNop9Kd1LmzBGGvxucOo0lj1M3IRi8FimAX3krunSD
# guC5HgD75nWcUgdZVjm/R81VmaDPEP25Wj+C1reicY5CPckLGBjHQqsJe7jJz1CJ
# XBMUtZs10cVKMEK3n/xD2ku5GFWhx0K6eFwe50xLUIZD9GfT7s/5/MyBZ1Ep8Q6H
# +GMuudDwF0mJitk3G8g6EzZprfMQMc3DAgMBAAGjggFVMIIBUTAPBgNVHRMBAf8E
# BTADAQH/MB0GA1UdDgQWBBS+VAIvv0Bsc0POrAklTp5DRBru4DAfBgNVHSMEGDAW
# gBS2oVQ5AsOgP46KvPrU+Bym0ToO/TAOBgNVHQ8BAf8EBAMCAQYwEwYDVR0lBAww
# CgYIKwYBBQUHAwgwMAYDVR0fBCkwJzAloCOgIYYfaHR0cDovL2NybC5jZXJ0dW0u
# cGwvY3RuY2EyLmNybDBsBggrBgEFBQcBAQRgMF4wKAYIKwYBBQUHMAGGHGh0dHA6
# Ly9zdWJjYS5vY3NwLWNlcnR1bS5jb20wMgYIKwYBBQUHMAKGJmh0dHA6Ly9yZXBv
# c2l0b3J5LmNlcnR1bS5wbC9jdG5jYTIuY2VyMDkGA1UdIAQyMDAwLgYEVR0gADAm
# MCQGCCsGAQUFBwIBFhhodHRwOi8vd3d3LmNlcnR1bS5wbC9DUFMwDQYJKoZIhvcN
# AQEMBQADggIBALiTWXfJTBX9lAcIoKd6oCzwQZOfARQkt0OmiQ390yEqMrStHmpf
# ycggfPGlBHdMDDYhHDVTGyvY+WIbdsIWpJ1BNRt9pOrpXe8HMR5sOu71AWOqUqfE
# IXaHWOEs0UWmVs8mJb4lKclOHV8oSoR0p3GCX2tVO+XF8Qnt7E6fbkwZt3/AY/C5
# KYzFElU7TCeqBLuSagmM0X3Op56EVIMM/xlWRaDgRna0hLQze5mYHJGv7UuTCOO3
# wC1bzeZWdlPJOw5v4U1/AljsNLgWZaGRFuBwdF62t6hOKs86v+jPIMqFPwxNJN/o
# u22DqzpP+7TyYNbDocrThlEN9D2xvvtBXyYqA7jhYY/fW9edUqhZUmkUGM++Mvz9
# lyT/nBdfaKqM5otK0U5H8hCSL4SGfjOVyBWbbZlUIE8X6XycDBRRKEK0q5JTsaZk
# soKabFAyRKJYgtObwS1UPoDGcmGirwSeGMQTJSh+WR5EXZaEWJVA6ZZPBlGvjgjF
# YaQ0kLq1OitbmuXZmX7Z70ks9h/elK0A8wOg8oiNVd3o1bb59ms1QF4OjZ45rkWf
# sGuz8ctB9/leCuKzkx5Rt1WAOsXy7E7pws+9k+jrePrZKw2DnmlNaT19QgX2I+hF
# tvhC6uOhj/CgjVEA4q1i1OJzpoAmre7zdEg+kZcFIkrDHgokA5mcIMK1MIIFyTCC
# BLGgAwIBAgIQG7WPJSrfIwBJKMmuPX7tJzANBgkqhkiG9w0BAQwFADB+MQswCQYD
# VQQGEwJQTDEiMCAGA1UEChMZVW5pemV0byBUZWNobm9sb2dpZXMgUy5BLjEnMCUG
# A1UECxMeQ2VydHVtIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MSIwIAYDVQQDExlD
# ZXJ0dW0gVHJ1c3RlZCBOZXR3b3JrIENBMB4XDTIxMDUzMTA2NDMwNloXDTI5MDkx
# NzA2NDMwNlowgYAxCzAJBgNVBAYTAlBMMSIwIAYDVQQKExlVbml6ZXRvIFRlY2hu
# b2xvZ2llcyBTLkEuMScwJQYDVQQLEx5DZXJ0dW0gQ2VydGlmaWNhdGlvbiBBdXRo
# b3JpdHkxJDAiBgNVBAMTG0NlcnR1bSBUcnVzdGVkIE5ldHdvcmsgQ0EgMjCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL35ePjm1YAMZJ2GG5ZkZz8iOh51
# AX3v+1xnjMnMXGupkea5QuUgS5vam3u5mV3Zm4BL14RAKyfT6Lowuz4JGqdJle8r
# QCTCl8en7psl76gKAJeFWqqd3CnJ4jUH63BNStbBs1a4oUE4m9H7MX+P4F/hsT8P
# jhZJYNcGjRj5qiYQqyrT0NFnjRtGvkcw1S5y0cVj2udjeUR+S2MkiYYuND8pTFKL
# KqfA4pEoibnAW/kd2ecnrf+aApfBxlCSmwIsvam5NFkKv4RK/9/+s5/r2Z7gmCPs
# pmt3FirbzK07HKSH3EZzXhliaEVX5JCCQrtC1vBh4MGjPWajXfQY7ojJjRdFKZky
# dQIx7ikmyGsC5rViRX83FVojaInUPt5OJ7DwQAy8TRfLTaKzHtAGWt32k89XdZn1
# +oYaZ3izv5b+NNy951JW5bPldXvXQZEF3F1p45UNQ7n8g5Y5lXtsgFpPE3LG130p
# ekS6UqQq1UFGCSD+IqC2WzCNvIkM1ddw+IdS/drvrFEuB7NO/tAJ2nDvmPpW5m3b
# tVdL3OUsJRXIni54TvjanJ6GLMpX8xrlyJKLGoKWesO8UBJp2A5aRos66yb6I8m2
# sIG+QgCk+Nb+MC7H0kb25Y51/fLMudCHW8wGEGC7gzW3XmfeR+yZSPGkoRX+rYxi
# jjlVTzkWubFjnf+3AgMBAAGjggE+MIIBOjAPBgNVHRMBAf8EBTADAQH/MB0GA1Ud
# DgQWBBS2oVQ5AsOgP46KvPrU+Bym0ToO/TAfBgNVHSMEGDAWgBQIds3LB/8k9sXN
# 7buQvOKEN0Z19zAOBgNVHQ8BAf8EBAMCAQYwLwYDVR0fBCgwJjAkoCKgIIYeaHR0
# cDovL2NybC5jZXJ0dW0ucGwvY3RuY2EuY3JsMGsGCCsGAQUFBwEBBF8wXTAoBggr
# BgEFBQcwAYYcaHR0cDovL3N1YmNhLm9jc3AtY2VydHVtLmNvbTAxBggrBgEFBQcw
# AoYlaHR0cDovL3JlcG9zaXRvcnkuY2VydHVtLnBsL2N0bmNhLmNlcjA5BgNVHSAE
# MjAwMC4GBFUdIAAwJjAkBggrBgEFBQcCARYYaHR0cDovL3d3dy5jZXJ0dW0ucGwv
# Q1BTMA0GCSqGSIb3DQEBDAUAA4IBAQBRwqFYFiIQi/yGMdTCMtNc+EuiL2o+Tfir
# CB7t1ej65wgN7LfGHg6ydQV6sQv613RqAAYfpM6q8mt92BHAEQjUDk1hxTqo+rHh
# 45jq4mP9QfWTfQ28XZI7kZplutBfTL5MjWgDEBbV8dAEioUz+TfnWy4maUI8us28
# 1HrpTZ3a50P7Y1KAhQTEJZVV8H6nnwHFWyj44M6GcKYnOzn7OC6YU2UidS3X9t0i
# IpGW691o7T+jGZfTOyWI7DYSPal+zgKNBZqSpyduRbKcYoY3DaQzjteoTtBKF0NM
# xfGnbNIeWGwUUX6KVKH27595el2BmhaQD+G78UoA+fndvu2q7M4KMYID7zCCA+sC
# AQEwajBWMQswCQYDVQQGEwJQTDEhMB8GA1UEChMYQXNzZWNvIERhdGEgU3lzdGVt
# cyBTLkEuMSQwIgYDVQQDExtDZXJ0dW0gVGltZXN0YW1waW5nIDIwMjEgQ0ECEAnF
# zPi7Zn1xN6rBWYAGyzEwDQYJYIZIAWUDBAICBQCgggFWMBoGCSqGSIb3DQEJAzEN
# BgsqhkiG9w0BCRABBDAcBgkqhkiG9w0BCQUxDxcNMjMxMjI3MTAzMjMwWjA3Bgsq
# hkiG9w0BCRACLzEoMCYwJDAiBCDqlUux0EC0MUBI2GWfj2FdiHQszOBnkuBWAk1L
# ADrTHDA/BgkqhkiG9w0BCQQxMgQwmnLwVDdFBWA8IClH9KAD1bW9GlCAqUOAAZxW
# b9qW9ZoRxb9I97jEc0sa/zkC4e/nMIGfBgsqhkiG9w0BCRACDDGBjzCBjDCBiTCB
# hgQUD0+4VR7/2Pbef2cmtDwT0Gql53cwbjBapFgwVjELMAkGA1UEBhMCUEwxITAf
# BgNVBAoTGEFzc2VjbyBEYXRhIFN5c3RlbXMgUy5BLjEkMCIGA1UEAxMbQ2VydHVt
# IFRpbWVzdGFtcGluZyAyMDIxIENBAhAJxcz4u2Z9cTeqwVmABssxMA0GCSqGSIb3
# DQEBAQUABIICAA16L5P8iA7D0RaF5321CajpzwgQmYaMx1bIWNJ3ZnzT9sXQudtg
# rW9VCbBaatu7ulm9iGTYy99mur6xPICFGPAQfqkkfHG9YSYMOKiKn/KTDCQERfRp
# nvVPUYr6z+n3IXvkAHpELM6O8yqkc5LTFpwnJoEouoE9Vfh/8uH5r1n8XWV+x/BW
# 7pX22laxn6CwDJ6Dx0aXtLV7ktRnpQ7sDqHsBhQjzSELFgccJWZ0xss0lbTdC7X4
# 9e1FFZtFJkeY2O1cKASz2Cp8ucQraV4Jif4uGGR9lzs4xLKiyf32kE8//u2b5j/L
# dvtV+aLfS97NKVauT6DkDOjEe5CxkgSImamHR4D+UW46+YypqZPCNErfn2GfV4bq
# eKtjJB00qqL3ZPqZkxQb93Za5FmKFjxc9OVVG8oJWIUqgPmO0aBMsIb4AEUYXb63
# unlyBavhR9WqwJyxda+LJigBje8ZB/0UahUl4635I9Bbv9fenvSaKYDcjHWeQXMz
# Uj1y8AB3Mt9oS5EXQpcymDNerb7tmEgkd574T1wIAbnFWdO+B94TS7zzz5E+IoXv
# SmhTdjcXm/2RDivaG/3ofzE8BU61fGNqKDXInabVRzJZgM5+zh4Kcg2nx5rIJfB2
# ncsOmBU3EhWvo7Fdy0xxadlsFGc5MzMDAt1xRGvHDfcvEizM1EGeTHA1
# SIG # End signature block
