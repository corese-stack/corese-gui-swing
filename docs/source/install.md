<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable MD041 -->

## Installation

```{warning}
You are reading the legacy Corese-GUI Swing 4.x documentation.
New releases (`5.0.0+`) are available in the new repository:

- Docs (latest line): <https://corese-stack.github.io/corese-gui/>
- Latest release: <https://github.com/corese-stack/corese-gui/releases/latest>

The install scripts below remain available to maintain/uninstall legacy 4.x, and can guide migration to 5.x.
```

### Linux

<div style="margin: 10px 5px;">
  <a href="https://flathub.org/fr/apps/fr.inria.corese.CoreseGui">
    <img src="./_static/logo/badge_flathub.svg" alt="Flathub" width="150">
  </a>
</div>

```bash
curl -fsSL https://raw.githubusercontent.com/corese-stack/corese-gui-swing/main/packaging/scripts/install-linux.sh -o /tmp/corese.sh && bash /tmp/corese.sh
```

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/corese-stack/corese-gui-swing/main/packaging/scripts/install-macos.sh -o /tmp/corese.sh && bash /tmp/corese.sh
```

### Windows (Powershell)

```powershell
iwr -useb https://raw.githubusercontent.com/corese-stack/corese-gui-swing/main/packaging/scripts/install-windows.ps1 | iex
```

### Manual / Cross-platform Installation

<div style="margin: 10px 5px;">
  <a href="https://github.com/corese-stack/corese-gui-swing/releases">
    <img src="./_static/logo/badge_github.svg" alt="GitHub Release" width="150">
  </a>
  <a href="https://central.sonatype.com/artifact/fr.inria.corese/corese-gui">
    <img src="./_static/logo/badge_maven.svg" alt="Maven Central" width="150">
  </a>
</div>

> You can update, uninstall, or install a specific Corese-GUI version by rerunning the same script — use `--help` to see all available options.
> If you select `5.0.0` or later in the script, it will remove the legacy 4.x installation and redirect you to the new repository installer flow.
