# PowerShell setup script - installs profile, Oh My Posh, Nerd Fonts, Chocolatey, and utilities

#region Prerequisites

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    exit 1
}

function Test-InternetConnection {
    try {
        Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        Write-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

if (-not (Test-InternetConnection)) {
    exit 1
}

#endregion

#region Helper Functions

function Get-ProfileDir {
    if ($PSVersionTable.PSEdition -eq "Core") {
        return "$env:USERPROFILE\Documents\PowerShell"
    }
    if ($PSVersionTable.PSEdition -eq "Desktop") {
        return "$env:USERPROFILE\Documents\WindowsPowerShell"
    }
    Write-Error "Unsupported PowerShell edition: $($PSVersionTable.PSEdition)"
    exit 1
}

function Install-NerdFonts {
    param(
        [string]$FontName = "CascadiaCode",
        [string]$FontDisplayName = "CaskaydiaCove NF",
        [string]$Version = "3.2.1"
    )

    try {
        Add-Type -AssemblyName System.Drawing
        $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
        if ($fontFamilies -contains $FontDisplayName) {
            Write-Host "Font $FontDisplayName already installed."
            return $true
        }

        $fontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v$Version/$FontName.zip"
        $zipFilePath = "$env:TEMP\$FontName.zip"
        $extractPath = "$env:TEMP\$FontName"

        Invoke-WebRequest -Uri $fontZipUrl -OutFile $zipFilePath -UseBasicParsing
        Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force

        $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
        Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf" | ForEach-Object {
            if (-not (Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                $destination.CopyHere($_.FullName, 0x10)
            }
        }

        Remove-Item -Path $extractPath -Recurse -Force
        Remove-Item -Path $zipFilePath -Force
        Write-Host "Installed font: $FontDisplayName"
        return $true
    }
    catch {
        Write-Error "Failed to install $FontDisplayName font. Error: $_"
        return $false
    }
}

function Install-OhMyPoshTheme {
    param(
        [string]$ThemeName = "cobalt2",
        [string]$ThemeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json"
    )

    $profilePath = Get-ProfileDir
    if (-not (Test-Path -Path $profilePath)) {
        New-Item -Path $profilePath -ItemType Directory -Force | Out-Null
    }

    $themeFilePath = Join-Path $profilePath "$ThemeName.omp.json"
    try {
        Invoke-RestMethod -Uri $ThemeUrl -OutFile $themeFilePath
        Write-Host "Oh My Posh theme '$ThemeName' downloaded to [$themeFilePath]"
        return $themeFilePath
    }
    catch {
        Write-Error "Failed to download Oh My Posh theme. Error: $_"
        return $null
    }
}

#endregion

#region Profile Setup

$profileDir = Get-ProfileDir
if (-not (Test-Path -Path $profileDir)) {
    New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
}

# Repo root (parent of windows/ folder)
$repoRoot = Split-Path $PSScriptRoot -Parent

# Use local profile from this repo (not Chris Titus). Update-Profile still fetches upstream updates.
$profileSource = Join-Path $PSScriptRoot "Microsoft.PowerShell_profile.ps1"
$profileUrlFallback = "https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1"
$profileNote = "If you want personal changes, use [$profileDir\Profile.ps1] - the installed profile uses a hash-based updater that overwrites direct edits."

if (-not (Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        if (Test-Path $profileSource) {
            Copy-Item -Path $profileSource -Destination $PROFILE -Force
            Write-Host "Profile created at [$PROFILE] (from this repo)"
        }
        else {
            Invoke-RestMethod $profileUrlFallback -OutFile $PROFILE
            Write-Host "Profile created at [$PROFILE] (from Chris Titus - local file not found)"
        }
        Write-Host "NOTE: $profileNote"
    }
    catch {
        Write-Error "Failed to create profile. Error: $_"
    }
}
else {
    try {
        $backupPath = Join-Path (Split-Path $PROFILE) "oldprofile.ps1"
        Move-Item -Path $PROFILE -Destination $backupPath -Force
        if (Test-Path $profileSource) {
            Copy-Item -Path $profileSource -Destination $PROFILE -Force
            Write-Host "Profile updated at [$PROFILE] from this repo. Backup saved to [$backupPath]"
        }
        else {
            Invoke-RestMethod $profileUrlFallback -OutFile $PROFILE
            Write-Host "Profile updated at [$PROFILE] from Chris Titus. Backup saved to [$backupPath]"
        }
        Write-Host "NOTE: $profileNote"
    }
    catch {
        Write-Error "Failed to backup and update profile. Error: $_"
    }
}

# Copy my_layout.omp.json from repo if it exists (for profile.ps1 Get-Theme_Override)
$themeSrc = Join-Path $repoRoot "my_layout.omp.json"
if (Test-Path $themeSrc) {
    Copy-Item -Path $themeSrc -Destination (Join-Path $profileDir "my_layout.omp.json") -Force
    Write-Host "Custom theme (my_layout.omp.json) copied to profile directory."
}

# Copy profile.ps1 template if it doesn't exist
$profilePs1Src = Join-Path $PSScriptRoot "profile.ps1"
$profilePs1Dest = Join-Path $profileDir "Profile.ps1"
if ((Test-Path $profilePs1Src) -and -not (Test-Path $profilePs1Dest)) {
    Copy-Item -Path $profilePs1Src -Destination $profilePs1Dest -Force
    Write-Host "Profile.ps1 template copied. Edit it for custom theme and overrides."
}

#endregion

#region Package Installs

try {
    winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
}
catch {
    Write-Error "Failed to install Oh My Posh. Error: $_"
}

try {
    winget install -e --accept-source-agreements --accept-package-agreements ajeetdsouza.zoxide
    Write-Host "zoxide installed."
}
catch {
    Write-Error "Failed to install zoxide. Error: $_"
}

#endregion

#region Fonts & Themes

$fontInstalled = Install-NerdFonts -FontName "CascadiaCode" -FontDisplayName "CaskaydiaCove NF"
$themeInstalled = Install-OhMyPoshTheme -ThemeName "cobalt2"

#endregion

#region Chocolatey

try {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $chocoScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
    Invoke-Expression $chocoScript
    Write-Host "Chocolatey installed."
}
catch {
    Write-Error "Failed to install Chocolatey. Error: $_"
}

#endregion

#region PowerShell Modules

try {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force -Scope CurrentUser
    Write-Host "Terminal-Icons module installed."
}
catch {
    Write-Error "Failed to install Terminal-Icons module. Error: $_"
}

#endregion

#region Summary

Write-Host ""
Write-Host "Setup complete. Restart your PowerShell session to apply changes."

#endregion
