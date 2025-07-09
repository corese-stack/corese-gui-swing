# Corese-GUI Windows Installer & Updater

<#
.SYNOPSIS
    Corese-GUI installer for Windows

.DESCRIPTION
    This PowerShell script installs, updates, or uninstalls the Corese-GUI application on Windows.
    It checks for Java 21 or higher, prompts the user if Java is not found,
    and fetches the requested release from GitHub. It also creates desktop shortcuts
    and optionally adds Corese to the user's PATH.

.PARAMETER Install
    Installs the specified version of Corese-GUI (e.g., v4.6.0).

.PARAMETER InstallLatest
    Automatically installs the latest available version.

.PARAMETER Uninstall
    Completely removes Corese-GUI and cleans up the user's PATH.

.PARAMETER Help
    Displays usage instructions.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install-windows-gui.ps1 --install v4.6.0

.NOTES
    This script supports both interactive mode and CLI arguments.
    It should be executed with appropriate permissions to modify PATH and create shortcuts.
#>

$InstallDir = "$env:USERPROFILE\.corese-gui"
$BinName = "corese-gui"
$JarName = "corese-gui-standalone.jar"
$WrapperPath = "$InstallDir\$BinName.cmd"
$VersionFile = "$InstallDir\version.txt"
$GitHubRepo = "corese-stack/corese-gui-swing"
$ReleaseApi = "https://api.github.com/repos/$GitHubRepo/releases"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
$IconPath = "$InstallDir\fr.inria.corese.CoreseGui.ico"

# Argument parsing (for iex compatibility)
$Install = ""
$InstallLatest = $false
$Uninstall = $false
$Help = $false

for ($i = 0; $i -lt $args.Length; $i++) {
    switch ($args[$i]) {
        "--install" {
            if ($i + 1 -lt $args.Length) {
                $Install = $args[$i + 1]
                $i++
            }
        }
        "--install-latest" { $InstallLatest = $true }
        "--uninstall"      { $Uninstall = $true }
        "--help"           { $Help = $true }
    }
}

function Write-Centered($text) {
    $width = [console]::WindowWidth
    $padding = [Math]::Max(0, ($width - $text.Length) / 2)
    $line = (" " * [int]$padding) + $text
    Write-Host $line
}

function Check-Internet {
    Write-Host "Checking internet connection..."
    try {
        $result = Test-Connection -Count 1 -Quiet github.com
        if (-not $result) {
            throw "No response"
        }
        Write-Host "Internet connection is OK."
    } catch {
        Write-Error "No internet connection. Please connect and try again."
        exit 1
    }
    Write-Host ""
}

function Check-Java {
    Write-Host "Checking Java..."
    $java = Get-Command java -ErrorAction SilentlyContinue
    if (-not $java) {
        Write-Host "Java is not installed."
        Ask-Java-Install
        return
    }

    $versionOutput = & java -version 2>&1
    $versionLine = $versionOutput | Where-Object { $_ -match 'version' }

    $major = $null
    if ($versionLine -match 'version "(\d+)(\.(\d+))?') {
        $major = [int]$Matches[1]
    } elseif ($versionLine -match "version ""(\d+)") {
        $major = [int]$Matches[1]
    }

    if ($null -eq $major) {
        Write-Host "Unable to detect Java version."
        Ask-Java-Install
        return
    }

    if ($major -lt 21) {
        Write-Host "Java 21 or higher is required (found: $major)."
        Ask-Java-Install
    } else {
        Write-Host "Java version $major detected."
    }
    Write-Host ""
}

function Ask-Java-Install {
    $ans = Read-Host "Please install Java 21 or higher manually and press Enter to continue (or type N to abort)"
    if ($ans -match '^[Nn]') {
        Write-Host "Java is required. Aborting."
        exit 1
    }
}

function Get-Versions {
    try {
        $releases = Invoke-RestMethod "$ReleaseApi"
        return ($releases |
            Where-Object { -not $_.prerelease -and -not $_.draft } |
            Select-Object -ExpandProperty tag_name) |
            Sort-Object { [version]($_ -replace '[^\d.]') } -Descending
    } catch {
        Write-Error "Failed to fetch versions from GitHub"
        exit 1
    }
}

function Choose-Version {
    $versions = Get-Versions
    if (-not $versions) {
        Write-Error "No versions found."
        exit 1
    }

    Write-Host "`nAvailable versions:"
    for ($i = 0; $i -lt $versions.Count; $i++) {
        $label = if ($i -eq 0) { "$($versions[$i]) (latest)" } else { $versions[$i] }
        Write-Host "   [$($i + 1)] $label"
    }

    while ($true) {
        $choice = Read-Host "`nEnter version number to install [default: 1]"

        if (-not $choice) {
            $index = 0
            break
        }
        elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $versions.Count) {
            $index = [int]$choice - 1
            break
        }
        else {
            Write-Host "Invalid input. Please enter a number between 1 and $($versions.Count)."
        }
    }

    Write-Host ""
    Write-Host "Selected version: $($versions[$index])"
    Write-Host ""
    return $versions[$index]
}

function Show-Installed-Version {
    Write-Host "Current installation:"
    if (Test-Path "$InstallDir\$JarName") {
        if (Test-Path $VersionFile) {
            $installedVersion = Get-Content $VersionFile
            Write-Host "   Installed: $installedVersion"
        } else {
            Write-Host "   Installed: version unknown (legacy installation)"
        }
    } else {
        Write-Host "   No version currently installed."
    }
    Write-Host ""
}

function Download-Icon($version) {
    Write-Host "Downloading application icon..."

    # Try main branch first, fallback to develop
    $iconUrls = @(
        "https://raw.githubusercontent.com/$GitHubRepo/main/packaging/assets/logo/fr.inria.corese.CoreseGui.ico",
        "https://raw.githubusercontent.com/$GitHubRepo/develop/packaging/assets/logo/fr.inria.corese.CoreseGui.ico"
    )

    $iconDownloaded = $false
    foreach ($iconUrl in $iconUrls) {
        try {
            Invoke-WebRequest $iconUrl -OutFile "$InstallDir\fr.inria.corese.CoreseGui.ico" -ErrorAction Stop
            $iconDownloaded = $true
            Write-Host "   Icon downloaded successfully"
            break
        } catch {
            # Continue to next URL
        }
    }

    if (-not $iconDownloaded) {
        Write-Host "   Could not download icon, using fallback"
        # Create a simple fallback
        New-Item -ItemType File -Path "$InstallDir\fr.inria.corese.CoreseGui.ico" -Force | Out-Null
    }
}

function Create-Shortcuts {
    Write-Host "Creating desktop shortcuts..."

    $javaExe = "javaw.exe"
    if (-not (Get-Command $javaExe -ErrorAction SilentlyContinue)) {
        $javaExe = "java.exe"
    }

    $WshShell = New-Object -ComObject WScript.Shell

    foreach ($target in @(
        @{Path="$DesktopPath\Corese-GUI.lnk"},
        @{Path="$StartMenuPath\Corese-GUI.lnk"}
    )) {
        $s = $WshShell.CreateShortcut($target.Path)
        $s.TargetPath  = $javaExe
        $s.Arguments   = "-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -jar `"$InstallDir\$JarName`""
        $s.WorkingDirectory = $InstallDir
        $s.Description = "Corese-GUI - Graphical Semantic Web Platform"
        if (Test-Path $IconPath) {
            $iconFull = (Resolve-Path $IconPath).Path
            $s.IconLocation = "$iconFull,0"
        }
        $s.Save()
    }

    Write-Host "   Desktop and Start-Menu shortcuts created."
}


function Download-And-Install($version) {
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir | Out-Null
    }

    Write-Host "`nDownloading Corese-GUI $version..."
    try {
        $release = Invoke-RestMethod "$ReleaseApi/tags/$version" -ErrorAction Stop
    } catch {
        Write-Host ""
        Write-Host "Error: the version '$version' was not found on GitHub." -ForegroundColor Red
        $allVersions = Get-Versions
        Write-Host "`nAvailable versions are:"
        foreach ($v in $allVersions) {
            Write-Host " - $v"
        }
        exit 1
    }

    $assetUrl = $release.assets |
        Where-Object { $_.name -eq $JarName } |
        Select-Object -ExpandProperty browser_download_url -ErrorAction SilentlyContinue

    if (-not $assetUrl) {
        Write-Warning "Could not find asset '$JarName' in release '$version'."
        exit 1
    }

    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -L -# -o "$InstallDir\$JarName" $assetUrl
    } else {
        Invoke-WebRequest $assetUrl -OutFile "$InstallDir\$JarName"
    }
    Write-Host ""

    # Save version information
    Set-Content -Path $VersionFile -Value $version -Encoding UTF8

    Write-Host "Creating launcher script..."
    $launcherContent = "@echo off`njava -Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dfile.encoding=UTF-8 -jar `"$InstallDir\$JarName`" %*"
    Set-Content -Path $WrapperPath -Value $launcherContent -Encoding ASCII
    Write-Host "   Wrapper created: $WrapperPath"

    Download-Icon $version
    Create-Shortcuts

    $addToPath = Read-Host "`nAdd Corese-GUI to PATH for command-line usage? [Y/n]"
    if ($addToPath -notmatch '^[Nn]') {
        Add-ToPath
    }

    Write-Host ""
    Write-Host "Corese-GUI $version installed successfully!"
    Write-Host "Launch from Desktop/Start Menu or run: $BinName"
    Write-Host "Installed in: $InstallDir"
    Write-Host ""
}

function Add-ToPath {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notmatch [regex]::Escape($InstallDir)) {
        Write-Host "Adding Corese-GUI to PATH..."
        $newPath = "$userPath;$InstallDir"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "   Added to PATH (User)"
        Write-Host "   Restart your terminal to use 'corese-gui'"
    } else {
        Write-Host "   Already in PATH"
    }
}

function Uninstall {
    $confirm = Read-Host "`nThis will remove Corese-GUI from your system. Are you sure? [y/N]"
    if ($confirm -notmatch '^[Yy]') {
        Write-Host "Uninstall cancelled."
        return
    }

    Write-Host "`nRemoving Corese-GUI files..."
    if (Test-Path $InstallDir) {
        Remove-Item -Recurse -Force $InstallDir
        Write-Host "   Removed: $InstallDir"
    }

    # Remove shortcuts
    $shortcuts = @(
        "$DesktopPath\Corese-GUI.lnk",
        "$StartMenuPath\Corese-GUI.lnk"
    )

    foreach ($shortcut in $shortcuts) {
        if (Test-Path $shortcut) {
            Remove-Item $shortcut -Force
            Write-Host "   Removed shortcut: $(Split-Path $shortcut -Leaf)"
        }
    }

    # Remove from PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -match [regex]::Escape($InstallDir)) {
        $newPath = ($userPath -split ';') -ne $InstallDir -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "   Removed from PATH (User)"
    }

    Write-Host ""
    Write-Host "Corese-GUI has been uninstalled."
    Write-Host ""
}

function Main {
    Write-Host ""
    Write-Centered "----------------------------------------"
    Write-Centered "   Corese-GUI - Windows Installer"
    Write-Centered "----------------------------------------"
    Write-Host ""

    Check-Internet
    Show-Installed-Version

    Write-Host "-------------- Menu --------------"
    Write-Host "| [1] Install or update          |"
    Write-Host "| [2] Uninstall                  |"
    Write-Host "| [3] Exit                       |"
    Write-Host "----------------------------------"

    $opt = Read-Host "`nSelect an option [1/2/3]"
    switch ($opt) {
        1 {
            Check-Java
            $v = Choose-Version
            Download-And-Install $v
        }
        2 { Uninstall }
        3 { Write-Host "Goodbye!" }
        default {
            Write-Host "Invalid option."
            Main
        }
    }
}

# Handle command line arguments
if ($Help) {
    Write-Host "Usage:"
    Write-Host "  install-windows-gui.ps1 --install [version]       Install specific version"
    Write-Host "  install-windows-gui.ps1 --install-latest          Install latest version"
    Write-Host "  install-windows-gui.ps1 --uninstall               Uninstall Corese-GUI"
    Write-Host "  install-windows-gui.ps1 --help                    Show this help"
    exit
}

if ($Install) {
    Check-Internet
    Check-Java
    Download-And-Install $Install
    exit
}

if ($InstallLatest) {
    Check-Internet
    Check-Java
    $v = (Get-Versions)[0]
    Download-And-Install $v
    exit
}

if ($Uninstall) {
    Uninstall
    exit
}

Main
