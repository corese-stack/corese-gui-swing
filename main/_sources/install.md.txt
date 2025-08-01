<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable MD041 -->

## Installation

### Linux

<div style="margin: 10px 5px;">
  <a href="https://flathub.org/fr/apps/fr.inria.corese.CoreseGui">
    <img src="./_static/logo/badge_flathub.svg" alt="Flathub" width="186">
  </a>
</div>

```bash
curl -fsSL https://raw.githubusercontent.com/corese-stack/corese-gui-swing/main/packaging/scripts/install-linux.sh -o /tmp/corese.sh && bash /tmp/corese.sh
```

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/corese-stack/corese-gui-swing/main/packaging/scripts/install-macos.sh -o /tmp/corese.sh && bash /tmp/corese.sh
```

### Windows

```powershell
iwr -useb https://raw.githubusercontent.com/corese-stack/corese-gui-swing/main/packaging/scripts/install-windows.ps1 | iex
```

### Manual / Cross-platform Installation

<div style="margin: 10px 5px;">
  <a href="https://github.com/corese-stack/corese-gui-swing/releases">
    <img src="./_static/logo/badge_github.svg" alt="GitHub Release" width="186">
  </a>
  <a href="https://central.sonatype.com/artifact/fr.inria.corese/corese-gui">
    <img src="./_static/logo/badge_maven.svg" alt="Maven Central" width="186">
  </a>
</div>

## Uninstall / Update

If you installed Corese-GUI using one of the scripts above, you can uninstall or update it by simply running the same script again.

## Advanced usage (CI / silent install)

All install scripts support the following options:

```bash
# Install a specific version
./install-linux.sh --install 4.6.0
./install-macos.sh --install 4.6.0
.\install-windows.ps1 --install 4.6.0

# Install the latest available version
./install-linux.sh --install-latest
./install-macos.sh --install-latest
.\install-windows.ps1 --install-latest

# Uninstall Corese-GUI
./install-linux.sh --uninstall
./install-macos.sh --uninstall
.\install-windows.ps1 --uninstall

# Show help
./install-linux.sh --help
./install-macos.sh --help
.\install-windows.ps1 --help
```
