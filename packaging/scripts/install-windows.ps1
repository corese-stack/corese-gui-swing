# Corese-GUI Windows Installer & Updater

<#!
.SYNOPSIS
    Corese-GUI installer for Windows

.DESCRIPTION
    Installs, updates, migrates, or uninstalls Corese-GUI on Windows.
    - Legacy line (4.x): corese-stack/corese-gui-swing
    - New line (5.x+):   corese-stack/corese-gui

.PARAMETER Install
    Installs the specified version (legacy 4.x or new 5.x+).

.PARAMETER InstallLatest
    Installs the latest available version (prefer 5.x+).

.PARAMETER Uninstall
    Removes legacy Corese-GUI Swing installation from this machine.

.PARAMETER Help
    Displays usage instructions.
#>

$InstallDir = "$env:USERPROFILE\.corese-gui"
$BinName = "corese-gui"
$JarName = "corese-gui-standalone.jar"
$WrapperPath = "$InstallDir\$BinName.cmd"
$VersionFile = "$InstallDir\version.txt"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
$IconPath = "$InstallDir\fr.inria.corese.CoreseGui.ico"

$LegacyGitHubRepo = "corese-stack/corese-gui-swing"
$LegacyReleaseApi = "https://api.github.com/repos/$LegacyGitHubRepo/releases"
$NextGitHubRepo = "corese-stack/corese-gui"
$NextReleaseApi = "https://api.github.com/repos/$NextGitHubRepo/releases"
$NextInstallGuideUrl = "https://corese-stack.github.io/corese-gui/"
$NextReleasesPageUrl = "https://github.com/$NextGitHubRepo/releases/latest"
$NextPrereleaseTag = "dev-prerelease"

$Install = ""
$InstallLatest = $false
$Uninstall = $false
$Help = $false
$AutoYes = $false

for ($i = 0; $i -lt $args.Length; $i++) {
    switch ($args[$i]) {
        "--install" {
            if ($i + 1 -lt $args.Length) {
                $Install = $args[$i + 1]
                $i++
            }
        }
        "--install-latest" { $InstallLatest = $true }
        "--uninstall" { $Uninstall = $true }
        "--help" { $Help = $true }
    }
}
$AutoYes = ($Install -or $InstallLatest -or $Uninstall)

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
    }
    catch {
        Write-Error "No internet connection. Please connect and try again."
        exit 1
    }
    Write-Host ""
}

function Test-IsSemverTag([string]$Tag) {
    return $Tag -match '^v?\d+\.\d+\.\d+$'
}

function Test-IsNextGenTag([string]$Tag) {
    if ($Tag -eq $NextPrereleaseTag) {
        return $true
    }

    if (-not (Test-IsSemverTag $Tag)) {
        return $false
    }

    $normalized = $Tag -replace '^v', ''
    $parts = $normalized.Split('.')
    if ($parts.Count -lt 1) {
        return $false
    }

    $major = 0
    if (-not [int]::TryParse($parts[0], [ref]$major)) {
        return $false
    }

    return $major -ge 5
}

function Test-IsLegacyTag([string]$Tag) {
    if (-not (Test-IsSemverTag $Tag)) {
        return $false
    }

    $normalized = $Tag -replace '^v', ''
    $parts = $normalized.Split('.')
    if ($parts.Count -lt 1) {
        return $false
    }

    $major = 0
    if (-not [int]::TryParse($parts[0], [ref]$major)) {
        return $false
    }

    return $major -lt 5
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
    $versionLine = $versionOutput | Where-Object { $_ -match 'version' } | Select-Object -First 1

    $major = $null
    if ($versionLine -match 'version "(\d+)') {
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
    }
    else {
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

function Get-LegacyVersions {
    try {
        $releases = Invoke-RestMethod "$LegacyReleaseApi"

        $tags = $releases |
            Where-Object { -not $_.prerelease -and -not $_.draft } |
            Select-Object -ExpandProperty tag_name |
            Where-Object { Test-IsLegacyTag $_ }

        return $tags |
            Sort-Object { [version](($_ -replace '^v', '')) } -Descending
    }
    catch {
        Write-Error "Failed to fetch legacy versions from GitHub"
        exit 1
    }
}

function Get-NextVersions {
    try {
        $releases = Invoke-RestMethod "$NextReleaseApi"

        $allTags = $releases |
            Where-Object { -not $_.draft } |
            Select-Object -ExpandProperty tag_name |
            Where-Object { Test-IsNextGenTag $_ }

        $seen = @{}
        $stable = @()
        $hasDev = $false

        foreach ($tag in $allTags) {
            if ($seen.ContainsKey($tag)) {
                continue
            }
            $seen[$tag] = $true

            if ($tag -eq $NextPrereleaseTag) {
                $hasDev = $true
                continue
            }

            if (Test-IsSemverTag $tag) {
                $stable += $tag
            }
        }

        $stable = $stable | Sort-Object { [version](($_ -replace '^v', '')) } -Descending

        $ordered = @()
        $ordered += $stable
        if ($hasDev) {
            $ordered += $NextPrereleaseTag
        }

        return $ordered
    }
    catch {
        Write-Error "Failed to fetch next-generation versions from GitHub"
        exit 1
    }
}

function Get-VersionCatalog {
    $catalog = @()

    foreach ($tag in (Get-NextVersions)) {
        $label = if ($tag -eq $NextPrereleaseTag) {
            "$tag (preview, new repo)"
        }
        else {
            "$tag (new repo 5.x+)"
        }
        $catalog += [PSCustomObject]@{
            Tag = $tag
            Source = "next"
            Label = $label
        }
    }

    foreach ($tag in (Get-LegacyVersions)) {
        $catalog += [PSCustomObject]@{
            Tag = $tag
            Source = "legacy"
            Label = "$tag (legacy Swing 4.x)"
        }
    }

    return $catalog
}

function Resolve-VersionSource([string]$Tag) {
    if (Test-IsNextGenTag $Tag) {
        return "next"
    }
    if (Test-IsLegacyTag $Tag) {
        return "legacy"
    }
    return ""
}

function Choose-Version {
    $catalog = Get-VersionCatalog
    if (-not $catalog -or $catalog.Count -eq 0) {
        Write-Error "No versions found."
        exit 1
    }

    Write-Host "`nAvailable versions:"
    for ($i = 0; $i -lt $catalog.Count; $i++) {
        $label = if ($i -eq 0) { "$($catalog[$i].Label) (latest)" } else { $catalog[$i].Label }
        Write-Host "   [$($i + 1)] $label"
    }

    while ($true) {
        $choice = Read-Host "`nEnter version number to install [default: 1]"

        if (-not $choice) {
            $index = 0
            break
        }
        elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $catalog.Count) {
            $index = [int]$choice - 1
            break
        }
        else {
            Write-Host "Invalid input. Please enter a number between 1 and $($catalog.Count)."
        }
    }

    $selected = $catalog[$index]
    Write-Host ""
    Write-Host "Selected version: $($selected.Tag)"
    Write-Host ""
    return $selected
}

function Get-LatestVersionFromCatalog {
    $catalog = Get-VersionCatalog
    if (-not $catalog -or $catalog.Count -eq 0) {
        Write-Error "No versions found."
        exit 1
    }
    return $catalog[0]
}

function Show-Installed-Version {
    Write-Host "Current installation:"
    if (Test-Path "$InstallDir\$JarName") {
        if (Test-Path $VersionFile) {
            $installedVersion = Get-Content $VersionFile -ErrorAction SilentlyContinue
            Write-Host "   Installed: $installedVersion"
        }
        else {
            Write-Host "   Installed: version unknown (legacy installation)"
        }
    }
    else {
        Write-Host "   No version currently installed."
    }
    Write-Host ""
}

function Get-DownloadsDirectory {
    $downloads = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"
    if (-not (Test-Path $downloads)) {
        New-Item -ItemType Directory -Path $downloads -Force | Out-Null
    }
    if (-not (Test-Path $downloads)) {
        return $env:TEMP
    }
    return $downloads
}

function Reveal-DownloadedFile([string]$Path) {
    if (-not (Test-Path $Path)) {
        return
    }
    try {
        Start-Process explorer.exe "/select,`"$Path`"" | Out-Null
    }
    catch {
        try {
            Start-Process explorer.exe "`"$([System.IO.Path]::GetDirectoryName($Path))`"" | Out-Null
        }
        catch {
            # Ignore explorer launch failures
        }
    }
}

function Download-File([string]$Url, [string]$OutFile, [string]$Label = "asset") {
    if (-not $Url) {
        throw "Missing download URL for $Label."
    }

    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -L --fail --progress-bar -o "$OutFile" "$Url"
        if ($LASTEXITCODE -ne 0) {
            throw "curl.exe failed with exit code $LASTEXITCODE."
        }
        return
    }

    if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
        Start-BitsTransfer -Source $Url -Destination $OutFile -DisplayName "Corese-GUI $Label" -ErrorAction Stop
        return
    }

    $previousProgressPreference = $ProgressPreference
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest $Url -OutFile $OutFile -ErrorAction Stop
    }
    finally {
        $ProgressPreference = $previousProgressPreference
    }
}

function Download-Icon {
    Write-Host "Downloading application icon..."

    $iconUrls = @(
        "https://raw.githubusercontent.com/$LegacyGitHubRepo/main/packaging/assets/logo/fr.inria.corese.CoreseGui.ico",
        "https://raw.githubusercontent.com/$LegacyGitHubRepo/develop/packaging/assets/logo/fr.inria.corese.CoreseGui.ico"
    )

    $iconDownloaded = $false
    foreach ($iconUrl in $iconUrls) {
        try {
            Invoke-WebRequest $iconUrl -OutFile "$InstallDir\fr.inria.corese.CoreseGui.ico" -ErrorAction Stop
            $iconDownloaded = $true
            Write-Host "   Icon downloaded successfully"
            break
        }
        catch {
            # try next URL
        }
    }

    if (-not $iconDownloaded) {
        Write-Host "   Could not download icon, using fallback"
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
            @{ Path = "$DesktopPath\Corese-GUI.lnk" },
            @{ Path = "$StartMenuPath\Corese-GUI.lnk" }
        )) {
        $s = $WshShell.CreateShortcut($target.Path)
        $s.TargetPath = $javaExe
        $s.Arguments = "-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dfile.encoding=UTF-8 -jar `"$InstallDir\$JarName`""
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

function Add-ToPath {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($null -eq $userPath) {
        $userPath = ""
    }

    if ($userPath -notmatch [regex]::Escape($InstallDir)) {
        Write-Host "Adding Corese-GUI to PATH..."
        if ([string]::IsNullOrWhiteSpace($userPath)) {
            $newPath = $InstallDir
        }
        else {
            $newPath = "$userPath;$InstallDir"
        }
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "   Added to PATH (User)"
        Write-Host "   Restart your terminal to use 'corese-gui'"
    }
    else {
        Write-Host "   Already in PATH"
    }
}

function Remove-LegacyInstallation([switch]$Silent) {
    if (-not $Silent -and -not $AutoYes) {
        $confirm = Read-Host "`nThis will remove legacy Corese-GUI Swing 4.x files. Continue? [y/N]"
        if ($confirm -notmatch '^[Yy]') {
            Write-Host "Cancelled."
            return $false
        }
    }

    Write-Host "`nRemoving legacy Corese-GUI files..."
    if (Test-Path $InstallDir) {
        Remove-Item -Recurse -Force $InstallDir
        Write-Host "   Removed: $InstallDir"
    }

    foreach ($shortcut in @(
            "$DesktopPath\Corese-GUI.lnk",
            "$StartMenuPath\Corese-GUI.lnk"
        )) {
        if (Test-Path $shortcut) {
            Remove-Item $shortcut -Force
            Write-Host "   Removed shortcut: $(Split-Path $shortcut -Leaf)"
        }
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($null -ne $userPath -and $userPath -match [regex]::Escape($InstallDir)) {
        $newPath = (($userPath -split ';') | Where-Object { $_ -and $_ -ne $InstallDir }) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "   Removed from PATH (User)"
    }

    Write-Host ""
    return $true
}

function Install-LegacyVersion([string]$VersionTag) {
    if (-not (Test-IsLegacyTag $VersionTag)) {
        Write-Host "Error: '$VersionTag' is not a supported legacy 4.x version." -ForegroundColor Red
        exit 1
    }

    Check-Java

    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir | Out-Null
    }

    Write-Host "`nDownloading Corese-GUI (legacy) $VersionTag..."
    try {
        $release = Invoke-RestMethod "$LegacyReleaseApi/tags/$VersionTag" -ErrorAction Stop
    }
    catch {
        Write-Host "Error: the legacy version '$VersionTag' was not found on GitHub." -ForegroundColor Red
        exit 1
    }

    $assetUrl = $release.assets |
        Where-Object { $_.name -eq $JarName } |
        Select-Object -ExpandProperty browser_download_url -ErrorAction SilentlyContinue

    if (-not $assetUrl) {
        Write-Warning "Could not find asset '$JarName' in release '$VersionTag'."
        exit 1
    }

    try {
        Download-File -Url $assetUrl -OutFile "$InstallDir\$JarName" -Label "legacy package $VersionTag"
    }
    catch {
        Write-Host "Error downloading legacy package: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    Write-Host ""

    Set-Content -Path $VersionFile -Value $VersionTag -Encoding UTF8

    Write-Host "Creating launcher script..."
    $launcherContent = "@echo off`njava -Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dfile.encoding=UTF-8 -jar `"$InstallDir\$JarName`" %*"
    Set-Content -Path $WrapperPath -Value $launcherContent -Encoding ASCII
    Write-Host "   Wrapper created: $WrapperPath"

    Download-Icon
    Create-Shortcuts

    if ($AutoYes) {
        Add-ToPath
    }
    else {
        $addToPath = Read-Host "`nAdd Corese-GUI to PATH for command-line usage? [Y/n]"
        if ($addToPath -notmatch '^[Nn]') {
            Add-ToPath
        }
    }

    Write-Host ""
    Write-Host "Corese-GUI legacy $VersionTag installed successfully!"
    Write-Host "Launch from Desktop/Start Menu or run: $BinName"
    Write-Host "Installed in: $InstallDir"
    Write-Host ""
}

function Select-NextWindowsAsset($Release) {
    $arch = "x64"

    $asset = $Release.assets | Where-Object { $_.name -match "windows-$arch\.exe$" } | Select-Object -First 1
    if ($asset) { return $asset }

    $asset = $Release.assets | Where-Object { $_.name -match "windows-$arch-portable\.zip$" } | Select-Object -First 1
    if ($asset) { return $asset }

    $asset = $Release.assets | Where-Object { $_.name -match "standalone-windows-$arch\.jar$" } | Select-Object -First 1
    if ($asset) { return $asset }

    return $null
}

function Migrate-ToNextGen([string]$VersionTag) {
    if (-not (Test-IsNextGenTag $VersionTag)) {
        Write-Host "Error: '$VersionTag' is not a supported Corese-GUI 5.x+ version." -ForegroundColor Red
        exit 1
    }

    Write-Host "Selected version '$VersionTag' belongs to the new Corese-GUI repository (5.x+)."

    if (-not $AutoYes) {
        $confirm = Read-Host "Continue migration to the new repository? [Y/n]"
        if ($confirm -match '^[Nn]') {
            Write-Host "Migration cancelled."
            return
        }
    }

    if (Test-Path "$InstallDir\$JarName") {
        $removeLegacy = $true
        if (-not $AutoYes) {
            $answer = Read-Host "Uninstall legacy 4.x Swing installation from this PC now? [Y/n]"
            if ($answer -match '^[Nn]') {
                $removeLegacy = $false
            }
        }

        if ($removeLegacy) {
            [void](Remove-LegacyInstallation -Silent)
            Write-Host "Legacy installation removed."
        }
        else {
            Write-Host "Legacy installation kept."
        }
    }

    try {
        $release = Invoke-RestMethod "$NextReleaseApi/tags/$VersionTag" -ErrorAction Stop
    }
    catch {
        Write-Host "`nError: version '$VersionTag' was not found in the new repository." -ForegroundColor Red
        Write-Host "Open release list: $NextReleasesPageUrl"
        Start-Process $NextInstallGuideUrl | Out-Null
        return
    }

    $releaseUrl = if ($release.html_url) { $release.html_url } else { $NextReleasesPageUrl }
    $asset = Select-NextWindowsAsset $release

    Write-Host ""
    Write-Host "Continue with Corese-GUI 5.x+:"
    Write-Host " - Docs:          $NextInstallGuideUrl"
    Write-Host " - Release page:  $releaseUrl"

    if ($asset) {
        $downloadsDir = Get-DownloadsDirectory
        $targetPath = Join-Path $downloadsDir $asset.name
        Write-Host "Downloading recommended asset: $($asset.name)"
        try {
            Download-File -Url $asset.browser_download_url -OutFile $targetPath -Label $asset.name
        }
        catch {
            Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Open release page manually: $releaseUrl"
            return
        }
        Write-Host "Downloaded to: $targetPath"
        Reveal-DownloadedFile $targetPath
        Write-Host "Please run the downloaded installer/package."

        if ($asset.name -match '\.exe$') {
            if ($AutoYes) {
                Start-Process -FilePath $targetPath | Out-Null
            }
            else {
                $runInstaller = Read-Host "Run this installer now? [Y/n]"
                if ($runInstaller -notmatch '^[Nn]') {
                    Start-Process -FilePath $targetPath | Out-Null
                }
            }
        }
    }
    else {
        Write-Host "No Windows asset was auto-selected for this release."
    }

    try {
        Start-Process $NextInstallGuideUrl | Out-Null
    }
    catch {
        # Ignore browser launch failures
    }

    Write-Host ""
}

function Download-And-Install([string]$VersionTag, [string]$Source) {
    if ($Source -eq "next") {
        Migrate-ToNextGen $VersionTag
    }
    elseif ($Source -eq "legacy") {
        Install-LegacyVersion $VersionTag
    }
    else {
        Write-Host "Unsupported version '$VersionTag'." -ForegroundColor Red
        exit 1
    }
}

function Main {
    Write-Host ""
    Write-Centered "-----------------------------------------------"
    Write-Centered "   Corese-GUI - Windows Installer/Migration"
    Write-Centered "-----------------------------------------------"
    Write-Host ""

    Show-Installed-Version

    Write-Host "-------------- Menu --------------"
    Write-Host "| [1] Install or migrate         |"
    Write-Host "| [2] Uninstall legacy 4.x       |"
    Write-Host "| [3] Exit                       |"
    Write-Host "----------------------------------"

    $opt = Read-Host "`nSelect an option [1/2/3]"
    switch ($opt) {
        1 {
            Check-Internet
            $selected = Choose-Version
            Download-And-Install $selected.Tag $selected.Source
        }
        2 {
            [void](Remove-LegacyInstallation)
        }
        3 { Write-Host "Goodbye!" }
        default {
            Write-Host "Invalid option."
            Main
        }
    }
}

if ($Help) {
    Write-Host "Usage:"
    Write-Host "  install-windows-gui.ps1 --install [version]       Install specific version"
    Write-Host "  install-windows-gui.ps1 --install-latest          Install latest version (prefer 5.x+)"
    Write-Host "  install-windows-gui.ps1 --uninstall               Uninstall legacy Corese-GUI 4.x"
    Write-Host "  install-windows-gui.ps1 --help                    Show this help"
    Write-Host ""
    Write-Host "Docs: $NextInstallGuideUrl"
    exit
}

if ($Install) {
    Check-Internet
    $source = Resolve-VersionSource $Install
    if (-not $source) {
        Write-Host "Unsupported version '$Install'. Use a semantic tag (for example v4.6.2 or v5.0.0) or dev-prerelease." -ForegroundColor Red
        exit 1
    }
    Download-And-Install $Install $source
    exit
}

if ($InstallLatest) {
    Check-Internet
    $selected = Get-LatestVersionFromCatalog
    Download-And-Install $selected.Tag $selected.Source
    exit
}

if ($Uninstall) {
    [void](Remove-LegacyInstallation -Silent)
    exit
}

Main
