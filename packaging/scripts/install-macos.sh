#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Corese-GUI macOS Minimal Installer (App Only)
# ------------------------------------------------------------------------------
# This script installs the standalone Corese-GUI JAR in a proper .app bundle
# in /Applications. Requires Java 21+ to be installed on the system.
# ------------------------------------------------------------------------------

APP_DIR="/Applications/Corese-GUI.app"
GITHUB_REPO="corese-stack/corese-gui-swing"
RELEASE_API="https://api.github.com/repos/$GITHUB_REPO/releases"
JAR_NAME="corese-gui-standalone.jar"
AUTO_YES=0

check_internet() {
    echo "🌐 Checking internet connection..."
    if ! curl -s --max-time 5 https://github.com/ > /dev/null; then
        echo "❌ No internet connection or GitHub is unreachable."
        exit 1
    fi
    echo "✅ Internet OK"
    echo
}

list_versions() {
    curl -s "$RELEASE_API" \
        | jq -r '.[] | select(.prerelease == false and .draft == false) | [.tag_name, .published_at] | @tsv' \
        | sort -k2 -r \
        | cut -f1
}

choose_version() {
    echo "📦 Available versions:"
    VERSIONS=()
    while IFS= read -r line; do
        VERSIONS+=("$line")
    done < <(list_versions)

    for i in "${!VERSIONS[@]}"; do
        if [ "$i" -eq 0 ]; then
            printf "   [%d] %s (latest)\n" $((i + 1)) "${VERSIONS[$i]}"
        else
            printf "   [%d] %s\n" $((i + 1)) "${VERSIONS[$i]}"
        fi
    done

    while true; do
        echo -n "→ Choose version to install [default: 1]: "
        read -r VERSION_INDEX
        [[ -z "$VERSION_INDEX" ]] && VERSION_INDEX=1 && break
        if [[ "$VERSION_INDEX" =~ ^[0-9]+$ && "$VERSION_INDEX" -ge 1 && "$VERSION_INDEX" -le "${#VERSIONS[@]}" ]]; then
            break
        else
            echo "❌ Invalid input."
        fi
    done

    VERSION_TAG="${VERSIONS[$((VERSION_INDEX - 1))]}"
    echo "✔️  Selected version: $VERSION_TAG"
    echo
}

check_java() {
    echo "🔍 Checking Java..."
    if ! command -v java &>/dev/null; then
        echo "❌ Java is not installed."
        prompt_install_java
        return
    fi

    JAVA_VERSION=$(java -version 2>&1 | grep -oE 'version "([0-9]+)' | grep -oE '[0-9]+')
    if [[ "$JAVA_VERSION" -lt 21 ]]; then
        echo "❌ Java 21+ is required (found: $JAVA_VERSION)"
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
        echo "❌ Java is required. Aborting."
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

download_and_install() {
    TEMP_DIR=$(mktemp -d)
    JAR_PATH="$TEMP_DIR/$JAR_NAME"

    echo "⬇️  Downloading Corese-GUI $VERSION_TAG..."
    RESPONSE=$(curl -s "$RELEASE_API/tags/$VERSION_TAG")
    JAR_URL=$(echo "$RESPONSE" | grep "browser_download_url" | grep "$JAR_NAME" | cut -d '"' -f 4 | head -n 1)

    if [[ -z "$JAR_URL" ]]; then
        echo "❌ .jar not found for version $VERSION_TAG"
        exit 1
    fi

    curl --progress-bar -L "$JAR_URL" -o "$JAR_PATH"
    create_app_bundle "$JAR_PATH"
    download_icon
    rm -rf "$TEMP_DIR"

    echo "✅ Installed Corese-GUI $VERSION_TAG!"
    echo "🍎 You can launch it from Applications folder."
}

create_app_bundle() {
    local JAR_FILE="$1"
    echo "🍏 Creating .app bundle..."

    [ -d "$APP_DIR" ] && rm -rf "$APP_DIR"
    mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$APP_DIR/Contents/Java"
    cp "$JAR_FILE" "$APP_DIR/Contents/Java/"

    cat > "$APP_DIR/Contents/Info.plist" <<EOF
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
EOF

    cat > "$APP_DIR/Contents/MacOS/corese-gui" <<EOF
#!/bin/bash
cd "\$(dirname "\$0")"
java -Xdock:name="Corese-GUI" -Dawt.useSystemAAFontSettings=on -jar "../Java/$JAR_NAME" "\$@"
EOF

    chmod +x "$APP_DIR/Contents/MacOS/corese-gui"
    echo "✅ .app bundle created: $APP_DIR"
}

download_icon() {
    echo "🎨 Downloading icon..."
    local ICON_SVG="$APP_DIR/Contents/Resources/corese-gui.svg"
    local ICON_ICNS="$APP_DIR/Contents/Resources/corese-gui.icns"

    ICON_URLS=(
        "https://raw.githubusercontent.com/$GITHUB_REPO/main/packaging/assets/logo/fr.inria.corese.CoreseGui.svg"
        "https://raw.githubusercontent.com/$GITHUB_REPO/develop/packaging/assets/logo/fr.inria.corese.CoreseGui.svg"
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

uninstall() {
    echo
    if [[ "$AUTO_YES" -ne 1 ]]; then
        echo "⚠️  This will delete Corese-GUI.app"
        read -rp "→ Confirm? [y/N] " confirm
        [[ ! "$confirm" =~ ^[Yy]$ ]] && echo "❌ Cancelled" && exit 0
    fi

    echo "🗑️  Removing Corese-GUI.app..."
    rm -rf "$APP_DIR"
    echo "✅ Uninstalled"
}

main() {
    echo
    echo "╭────────────────────────────────────────╮"
    echo "│     Corese-GUI macOS App Installer     │"
    echo "╰────────────────────────────────────────╯"
    echo

    echo "┌──────────── Menu ─────────────┐"
    echo "│ [1] Install or update         │"
    echo "│ [2] Uninstall                 │"
    echo "│ [3] Exit                      │"
    echo "└───────────────────────────────┘"
    echo
    read -rp "👉 Select an option [1/2/3]: " choice
    case "$choice" in
        1)
            check_internet
            check_java
            choose_version
            download_and_install
            ;;
        2) uninstall ;;
        3) echo "👋 Bye!" && exit 0 ;;
        *) echo "❌ Invalid option" && main ;;
    esac
}

# macOS only
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ This installer is for macOS only."
    exit 1
fi

# CLI
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage:"
    echo "  ./install-macos.sh --install <version>"
    echo "  ./install-macos.sh --install-latest"
    echo "  ./install-macos.sh --uninstall"
    exit 0
fi

if [[ "$1" == "--install" && -n "$2" ]]; then
    AUTO_YES=1
    VERSION_TAG="$2"
    check_internet
    check_java
    download_and_install
    exit 0
fi

if [[ "$1" == "--install-latest" ]]; then
    AUTO_YES=1
    VERSION_TAG=$(list_versions | head -n 1)
    check_internet
    check_java
    download_and_install
    exit 0
fi

if [[ "$1" == "--uninstall" ]]; then
    AUTO_YES=1
    uninstall
    exit 0
fi

main
