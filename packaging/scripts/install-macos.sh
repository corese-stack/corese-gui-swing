#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Corese-GUI macOS Installer
# ------------------------------------------------------------------------------
# Legacy line (4.x): corese-stack/corese-gui-swing
# Next-generation line (5.x+): corese-stack/corese-gui
# ------------------------------------------------------------------------------

set -euo pipefail

APP_DIR="/Applications/Corese-GUI.app"
LEGACY_GITHUB_REPO="corese-stack/corese-gui-swing"
NEXT_GITHUB_REPO="corese-stack/corese-gui"
LEGACY_RELEASE_API="https://api.github.com/repos/$LEGACY_GITHUB_REPO/releases"
NEXT_RELEASE_API="https://api.github.com/repos/$NEXT_GITHUB_REPO/releases"
NEXT_DOCS_URL="https://corese-stack.github.io/corese-gui/"
NEXT_RELEASES_PAGE_URL="https://github.com/$NEXT_GITHUB_REPO/releases/latest"
JAR_NAME="corese-gui-standalone.jar"
AUTO_YES=0
VERSION_TAG=""
VERSION_SOURCE=""

check_internet() {
    echo "🌐 Checking internet connection..."
    if ! curl -s --max-time 5 https://github.com/ > /dev/null; then
        echo "❌ No internet connection or GitHub is unreachable."
        exit 1
    fi
    echo "✅ Internet OK"
    echo
}

version_is_next_gen() {
    local tag="$1"
    local normalized="${tag#v}"

    if [[ "$tag" == "dev-prerelease" ]]; then
        return 0
    fi

    local major="${normalized%%.*}"
    [[ "$major" =~ ^[0-9]+$ ]] && [[ "$major" -ge 5 ]]
}

resolve_version_source() {
    if [[ -n "$VERSION_SOURCE" ]]; then
        return
    fi

    if version_is_next_gen "$VERSION_TAG"; then
        VERSION_SOURCE="next"
    else
        VERSION_SOURCE="legacy"
    fi
}

list_legacy_versions() {
    curl -fsSL "$LEGACY_RELEASE_API" \
        | jq -r '.[] | select(.prerelease == false and .draft == false) | .tag_name' \
        | awk 'NF' \
        | awk '
            /^v?[0-9]+\.[0-9]+\.[0-9]+$/ {
                v=$0
                sub(/^v/, "", v)
                split(v, a, ".")
                if (a[1] < 5) print $0
            }
        ' \
        | sort -V -r
}

list_next_versions() {
    local rows
    rows=$(
        curl -fsSL "$NEXT_RELEASE_API" \
            | jq -r '.[] | select(.draft == false) | [.tag_name, .published_at] | @tsv' \
            | sort -k2 -r
    )

    local has_dev=0
    declare -A seen=()
    while IFS=$'\t' read -r tag _published; do
        [[ -z "${tag:-}" ]] && continue
        [[ -n "${seen[$tag]:-}" ]] && continue
        seen[$tag]=1

        if [[ "$tag" == "dev-prerelease" ]]; then
            has_dev=1
            continue
        fi

        if [[ "$tag" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            local normalized="${tag#v}"
            local major="${normalized%%.*}"
            if [[ "$major" =~ ^[0-9]+$ ]] && [[ "$major" -ge 5 ]]; then
                echo "$tag"
            fi
        fi
    done <<< "$rows"

    if [[ "$has_dev" -eq 1 ]]; then
        echo "dev-prerelease"
    fi
}

choose_version() {
    echo "📦 Available versions:"

    VERSIONS=()
    VERSION_SOURCES=()

    mapfile -t LEGACY_VERSIONS < <(list_legacy_versions)
    mapfile -t NEXT_VERSIONS < <(list_next_versions)

    local idx=1

    if [[ ${#NEXT_VERSIONS[@]} -gt 0 ]]; then
        echo
        echo "Next-generation line (corese-gui 5.x+):"
        for tag in "${NEXT_VERSIONS[@]}"; do
            if [[ "$tag" == "dev-prerelease" ]]; then
                printf "   [%d] %s (preview, new repo)\n" "$idx" "$tag"
            else
                printf "   [%d] %s (new repo)\n" "$idx" "$tag"
            fi
            VERSIONS+=("$tag")
            VERSION_SOURCES+=("next")
            idx=$((idx + 1))
        done
    fi

    if [[ ${#LEGACY_VERSIONS[@]} -gt 0 ]]; then
        echo
        echo "Legacy line (corese-gui-swing 4.x):"
        for tag in "${LEGACY_VERSIONS[@]}"; do
            printf "   [%d] %s (legacy)\n" "$idx" "$tag"
            VERSIONS+=("$tag")
            VERSION_SOURCES+=("legacy")
            idx=$((idx + 1))
        done
    fi

    if [[ ${#VERSIONS[@]} -eq 0 ]]; then
        echo "❌ No installable versions were found."
        exit 1
    fi

    while true; do
        echo -n "→ Choose version to install [default: 1]: "
        read -r VERSION_INDEX
        if [[ -z "$VERSION_INDEX" ]]; then
            VERSION_INDEX=1
            break
        fi
        if [[ "$VERSION_INDEX" =~ ^[0-9]+$ && "$VERSION_INDEX" -ge 1 && "$VERSION_INDEX" -le "${#VERSIONS[@]}" ]]; then
            break
        fi
        echo "❌ Invalid input."
    done

    local array_index=$((VERSION_INDEX - 1))
    VERSION_TAG="${VERSIONS[$array_index]}"
    VERSION_SOURCE="${VERSION_SOURCES[$array_index]}"

    echo "✔️  Selected version: $VERSION_TAG"
    if [[ "$VERSION_SOURCE" == "next" ]]; then
        echo "   This is a Corese-GUI 5.x+ release from the new repository."
    fi
    echo
}

check_java() {
    echo "🔍 Checking Java..."
    if ! command -v java &>/dev/null; then
        echo "❌ Java is not installed."
        prompt_install_java
        return
    fi

    JAVA_VERSION=$(java -version 2>&1 | grep -oE 'version "([0-9]+)' | grep -oE '[0-9]+' || true)
    if [[ -z "$JAVA_VERSION" || "$JAVA_VERSION" -lt 21 ]]; then
        echo "❌ Java 21+ is required (found: ${JAVA_VERSION:-unknown})"
        prompt_install_java
    else
        echo "✅ Java $JAVA_VERSION detected"
    fi
    echo
}

prompt_install_java() {
    if [[ "$AUTO_YES" -eq 1 ]]; then
        echo "🚫 Cannot install Java automatically in headless mode."
        exit 1
    fi

    read -rp "→ Install OpenJDK 21 via Homebrew? [Y/n] " answer
    if [[ "$answer" =~ ^[Nn]$ ]]; then
        echo "❌ Java is required for Corese-GUI 4.x. Aborting."
        exit 1
    fi

    if ! command -v brew >/dev/null 2>&1; then
        echo "❌ Homebrew not found. Install it first from https://brew.sh/"
        exit 1
    fi

    echo "📦 Installing OpenJDK 21..."
    brew install openjdk@21
    sudo ln -sfn "$(brew --prefix)/opt/openjdk@21/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-21.jdk
    echo "✅ Java 21 installed."
}

open_url() {
    local url="$1"
    if command -v open >/dev/null 2>&1; then
        open "$url" >/dev/null 2>&1 || true
    fi
}

resolve_downloads_dir() {
    local downloads_dir="$HOME/Downloads"
    if [[ ! -d "$downloads_dir" ]]; then
        mkdir -p "$downloads_dir" 2>/dev/null || true
    fi
    if [[ ! -d "$downloads_dir" || ! -w "$downloads_dir" ]]; then
        downloads_dir="/tmp"
    fi
    echo "$downloads_dir"
}

reveal_downloaded_file() {
    local file_path="$1"
    if command -v open >/dev/null 2>&1; then
        open -R "$file_path" >/dev/null 2>&1 || open "$(dirname "$file_path")" >/dev/null 2>&1 || true
    fi
}

fetch_next_release_json() {
    local tag="$1"
    curl -fsSL "$NEXT_RELEASE_API/tags/$tag"
}

resolve_next_asset_url() {
    local release_json="$1"
    local arch_token="x64"

    case "$(uname -m)" in
        arm64|aarch64)
            arch_token="arm64"
            ;;
        x86_64|amd64)
            arch_token="x64"
            ;;
    esac

    echo "$release_json" | jq -r --arg arch "$arch_token" '
        (.assets[] | select(.name | test("macos-" + $arch + "\\.dmg$")) | .browser_download_url),
        (.assets[] | select(.name | test("standalone-macos-" + $arch + "\\.jar$")) | .browser_download_url)
    ' | head -n 1
}

cleanup_legacy_installation() {
    echo "🗑️  Removing legacy Corese-GUI.app..."
    rm -rf "$APP_DIR"
    echo
}

create_app_bundle() {
    local JAR_FILE="$1"
    echo "🍏 Creating .app bundle..."

    [ -d "$APP_DIR" ] && rm -rf "$APP_DIR"
    mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$APP_DIR/Contents/Java"
    cp "$JAR_FILE" "$APP_DIR/Contents/Java/"

    cat > "$APP_DIR/Contents/Info.plist" <<EOINFO
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>corese-gui</string>
    <key>CFBundleIconFile</key>
    <string>corese-gui.icns</string>
    <key>CFBundleIdentifier</key>
    <string>fr.inria.corese.gui</string>
    <key>CFBundleName</key>
    <string>Corese-GUI</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>$VERSION_TAG</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION_TAG</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOINFO

    cat > "$APP_DIR/Contents/MacOS/corese-gui" <<EORUN
#!/bin/bash
cd "\$(dirname "\$0")"
java -Xdock:name="Corese-GUI" -Dawt.useSystemAAFontSettings=on -jar "../Java/$JAR_NAME" "\$@"
EORUN

    chmod +x "$APP_DIR/Contents/MacOS/corese-gui"
    echo "✅ .app bundle created: $APP_DIR"
}

download_icon() {
    echo "🎨 Downloading icon..."
    local ICON_SVG="$APP_DIR/Contents/Resources/corese-gui.svg"
    local ICON_ICNS="$APP_DIR/Contents/Resources/corese-gui.icns"

    ICON_URLS=(
        "https://raw.githubusercontent.com/$LEGACY_GITHUB_REPO/main/packaging/assets/logo/fr.inria.corese.CoreseGui.svg"
        "https://raw.githubusercontent.com/$LEGACY_GITHUB_REPO/develop/packaging/assets/logo/fr.inria.corese.CoreseGui.svg"
    )

    for URL in "${ICON_URLS[@]}"; do
        if curl -s -f -L "$URL" -o "$ICON_SVG"; then
            if command -v sips &>/dev/null; then
                sips -s format icns "$ICON_SVG" --out "$ICON_ICNS" >/dev/null 2>&1 && rm -f "$ICON_SVG"
            else
                mv "$ICON_SVG" "$ICON_ICNS"
            fi
            echo "✅ Icon ready"
            return
        fi
    done

    echo "⚠️  Failed to download icon — using blank"
    touch "$ICON_ICNS"
}

install_legacy_version() {
    check_java

    TEMP_DIR=$(mktemp -d)
    JAR_PATH="$TEMP_DIR/$JAR_NAME"

    echo "⬇️  Downloading Corese-GUI (legacy) $VERSION_TAG..."
    RESPONSE=$(curl -fsSL "$LEGACY_RELEASE_API/tags/$VERSION_TAG")
    JAR_URL=$(echo "$RESPONSE" | jq -r --arg name "$JAR_NAME" '.assets[] | select(.name == $name) | .browser_download_url' | head -n 1)

    if [[ -z "$JAR_URL" || "$JAR_URL" == "null" ]]; then
        echo "❌ .jar not found for legacy version $VERSION_TAG"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    curl --progress-bar -L "$JAR_URL" -o "$JAR_PATH"
    create_app_bundle "$JAR_PATH"
    download_icon
    rm -rf "$TEMP_DIR"

    echo "✅ Installed Corese-GUI $VERSION_TAG (legacy line)!"
    echo "🍎 You can launch it from Applications folder."
}

migrate_to_next_gen_version() {
    echo "🚀 Selected version '$VERSION_TAG' belongs to Corese-GUI 5.x+ (new repository)."
    echo "ℹ️  Legacy Corese-GUI 4.x app will be removed before migration."

    if [[ "$AUTO_YES" -ne 1 ]]; then
        read -rp "→ Continue migration to the new repository? [Y/n] " confirm
        if [[ "$confirm" =~ ^[Nn]$ ]]; then
            echo "❌ Migration cancelled."
            exit 0
        fi
    fi

    cleanup_legacy_installation

    local release_json
    if ! release_json=$(fetch_next_release_json "$VERSION_TAG" 2>/dev/null); then
        echo
        echo "❌ Version '$VERSION_TAG' was not found in the new repository."
        echo
        echo "Available versions from corese-gui:"
        list_next_versions | sed 's/^/ - /'
        echo
        exit 1
    fi

    local release_page
    release_page=$(echo "$release_json" | jq -r '.html_url // empty')
    if [[ -z "$release_page" || "$release_page" == "null" ]]; then
        release_page="$NEXT_RELEASES_PAGE_URL"
    fi

    local asset_url
    asset_url=$(resolve_next_asset_url "$release_json")

    echo
    echo "✅ Legacy installation removed."
    echo "➡️  Continue with the new installer flow:"
    echo "   - Docs: $NEXT_DOCS_URL"
    echo "   - Release page: $release_page"
    if [[ -n "$asset_url" && "$asset_url" != "null" ]]; then
        echo "   - Recommended download for this Mac/arch: $asset_url"
        local downloads_dir
        downloads_dir="$(resolve_downloads_dir)"
        local download_path="$downloads_dir/$(basename "$asset_url")"
        echo "⬇️  Downloading platform asset: $(basename "$asset_url")"
        curl --progress-bar -L "$asset_url" -o "$download_path"
        echo
        echo "   - Downloaded to: $download_path"
        echo "📂 Opening Finder on downloaded file..."
        reveal_downloaded_file "$download_path"
        echo "➡️  Please run the downloaded installer/package."
    fi
    echo
    echo "Note: selecting 5.x+ migrates away from this legacy line."
    echo

    open_url "$NEXT_DOCS_URL"
}

download_and_install() {
    resolve_version_source

    if [[ "$VERSION_SOURCE" == "next" ]]; then
        migrate_to_next_gen_version
    else
        install_legacy_version
    fi
}

uninstall() {
    echo
    if [[ "$AUTO_YES" -ne 1 ]]; then
        echo "⚠️  This will delete Corese-GUI.app"
        read -rp "→ Confirm? [y/N] " confirm
        [[ ! "$confirm" =~ ^[Yy]$ ]] && echo "❌ Cancelled" && exit 0
    fi

    cleanup_legacy_installation
    echo "✅ Uninstalled"
}

main() {
    echo
    echo "╭──────────────────────────────────────────────╮"
    echo "│      Corese-GUI macOS Installer/Migration    │"
    echo "╰──────────────────────────────────────────────╯"
    echo

    echo "┌──────────── Menu ─────────────┐"
    echo "│ [1] Install or migrate        │"
    echo "│ [2] Uninstall legacy 4.x      │"
    echo "│ [3] Exit                      │"
    echo "└───────────────────────────────┘"
    echo
    read -rp "👉 Select an option [1/2/3]: " choice
    case "$choice" in
        1)
            check_internet
            choose_version
            download_and_install
            ;;
        2) uninstall ;;
        3) echo "👋 Bye!" && exit 0 ;;
        *) echo "❌ Invalid option" && main ;;
    esac
}

if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ This installer is for macOS only."
    exit 1
fi

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage:"
    echo "  ./install-macos.sh --install <version>       Install a legacy 4.x version or migrate to a 5.x+ version"
    echo "  ./install-macos.sh --install-latest          Install latest available version (prefer 5.x+)"
    echo "  ./install-macos.sh --uninstall               Uninstall legacy Corese-GUI 4.x"
    exit 0
fi

if [[ "${1:-}" == "--install" && -n "${2:-}" ]]; then
    AUTO_YES=1
    VERSION_TAG="$2"
    check_internet
    download_and_install
    exit 0
fi

if [[ "${1:-}" == "--install-latest" ]]; then
    AUTO_YES=1
    check_internet
    VERSION_TAG="$(list_next_versions | head -n 1)"
    VERSION_SOURCE="next"
    if [[ -z "$VERSION_TAG" ]]; then
        VERSION_TAG="$(list_legacy_versions | head -n 1)"
        VERSION_SOURCE="legacy"
    fi
    if [[ -z "$VERSION_TAG" ]]; then
        echo "❌ No version found."
        exit 1
    fi
    download_and_install
    exit 0
fi

if [[ "${1:-}" == "--uninstall" ]]; then
    AUTO_YES=1
    uninstall
    exit 0
fi

main
