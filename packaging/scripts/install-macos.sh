#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Corese-GUI macOS Installer
# ------------------------------------------------------------------------------
# This script installs or updates the Corese-GUI application on a macOS system.
# It automatically checks for Java (>= 21), installs it if necessary,
# fetches the desired version of Corese-GUI from GitHub, creates desktop
# integration, and optionally adds the binary to the user's PATH.
#
# Usage:
#   ./install-macos-gui.sh                     # Interactive mode
#   ./install-macos-gui.sh --install <version> # Install a specific version (e.g. v4.6.0)
#   ./install-macos-gui.sh --install-latest    # Install the latest available version
#   ./install-macos-gui.sh --uninstall         # Remove Corese-GUI from the system
# ------------------------------------------------------------------------------

INSTALL_DIR="$HOME/.local/corese-gui"
BIN_NAME="corese-gui"
WRAPPER_PATH="$INSTALL_DIR/$BIN_NAME"
JAR_NAME="corese-gui-standalone.jar"
VERSION_FILE="$INSTALL_DIR/version.txt"
GITHUB_REPO="corese-stack/corese-gui-swing"
RELEASE_API="https://api.github.com/repos/$GITHUB_REPO/releases"
APP_DIR="/Applications/Corese-Gui.app"
ICON_FILE="$INSTALL_DIR/fr.inria.corese.CoreseGui.svg"
AUTO_YES=0

check_internet() {
    echo "🌐 Checking internet connection..."
    if ! curl -s --max-time 5 https://github.com/ > /dev/null; then
        echo "❌ No internet connection or GitHub is unreachable. Please connect and retry."
        exit 1
    fi
    echo "✅ Internet connection is OK."
    echo
}

check_java() {
    echo "🔍 Checking Java..."

    if ! command -v java &> /dev/null; then
        echo "❌ Java is not installed."
        prompt_install_java
        return
    fi

    set +e
    JAVA_OUTPUT=$(java -version 2>&1)
    JAVA_EXIT_CODE=$?
    set -e

    if [ "$JAVA_EXIT_CODE" -ne 0 ]; then
        echo "❌ Failed to execute java -version."
        prompt_install_java
        check_java
        return
    fi

    if echo "$JAVA_OUTPUT" | grep -qE "No Java runtime present|Unable to locate a Java Runtime"; then
        echo "❌ Java is not actually installed (Apple stub detected)."
        prompt_install_java
        check_java
        return
    fi

    JAVA_VERSION=$(echo "$JAVA_OUTPUT" | grep -oE 'version "([0-9]+)' | grep -oE '[0-9]+')

    if ! [[ "$JAVA_VERSION" =~ ^[0-9]+$ ]]; then
        echo "⚠️ Unable to detect a valid Java version."
        prompt_install_java
        check_java
        return
    fi

    if [ "$JAVA_VERSION" -lt 21 ]; then
        echo "❌ Java version 21 or higher is required (found: $JAVA_VERSION)."
        prompt_install_java
        check_java
    else
        echo "✅ Java version $JAVA_VERSION detected."
    fi

    echo
}

prompt_install_java() {
    if [[ "$AUTO_YES" -eq 1 ]]; then
        install_java_by_distro
        return
    fi

    read -rp "→ Install OpenJDK 21 using Homebrew? [Y/n] " answer
    if [[ "$answer" =~ ^[Nn]$ ]]; then
        echo "❌ Java is required. Aborting."
        exit 1
    fi

    if ! command -v brew >/dev/null 2>&1; then
        echo "❌ Homebrew is not installed. Please install it first: https://brew.sh/"
        exit 1
    fi

    echo "📦 Installing OpenJDK 21..."
    brew install openjdk@21

    echo "🔗 Linking Java 21 into your environment..."
    sudo ln -sfn "$(brew --prefix)/opt/openjdk@21/libexec/openjdk.jdk" \
     /Library/Java/JavaVirtualMachines/openjdk-21.jdk

    echo "✅ Java 21 installed. Test:"
    /usr/libexec/java_home -v 21
    java -version
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
        echo -n "→ Enter the number of the version to install [default: 1]: "
        read -r VERSION_INDEX

        if [[ -z "$VERSION_INDEX" ]]; then
            VERSION_INDEX=1
            break
        elif [[ "$VERSION_INDEX" =~ ^[0-9]+$ && "$VERSION_INDEX" -ge 1 && "$VERSION_INDEX" -le "${#VERSIONS[@]}" ]]; then
            break
        else
            echo "❌ Invalid input. Please enter a number between 1 and ${#VERSIONS[@]}."
        fi
    done

    VERSION_TAG="${VERSIONS[$((VERSION_INDEX - 1))]}"
    echo
    echo "✔️  Selected version: $VERSION_TAG"
    echo
}

display_installed_version() {
    echo "📦 Current installation:"
    if [ -f "$INSTALL_DIR/$JAR_NAME" ]; then
        if [ -f "$VERSION_FILE" ]; then
            INSTALLED_VERSION=$(cat "$VERSION_FILE")
            echo "   ✔️ Installed: $INSTALLED_VERSION"
        else
            echo "   ✔️ Installed: version unknown (legacy installation)"
        fi
    else
        echo "   ❌ No version installed."
    fi
    echo
}

download_icon() {
    echo "🎨 Downloading application icon..."

    # Try main branch first, fallback to develop
    ICON_URLS=(
        "https://raw.githubusercontent.com/$GITHUB_REPO/main/packaging/assets/logo/fr.inria.corese.CoreseGui.svg"
        "https://raw.githubusercontent.com/$GITHUB_REPO/develop/packaging/assets/logo/fr.inria.corese.CoreseGui.svg"
    )

    for ICON_URL in "${ICON_URLS[@]}"; do
        if curl -s -f -L "$ICON_URL" -o "$ICON_FILE"; then
            echo "   ✅ Icon downloaded successfully"
            return 0
        fi
    done

    echo "   ⚠️  Could not download icon, using fallback"
    # Create a simple fallback icon placeholder
    touch "$ICON_FILE"
}

create_macos_app() {
    echo "🍎 Creating macOS application bundle..."

    # Remove existing app if it exists
    if [ -d "$APP_DIR" ]; then
        rm -rf "$APP_DIR"
    fi

    # Create app bundle structure
    mkdir -p "$APP_DIR/Contents/MacOS"
    mkdir -p "$APP_DIR/Contents/Resources"

    # Create Info.plist
    cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>corese-gui</string>
    <key>CFBundleIconFile</key>
    <string>corese-gui.icns</string>
    <key>CFBundleIdentifier</key>
    <string>fr.inria.corese.gui</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Corese-GUI</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION_TAG</string>
    <key>CFBundleVersion</key>
    <string>$VERSION_TAG</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

    # Create launcher script
    cat > "$APP_DIR/Contents/MacOS/corese-gui" <<EOF
#!/bin/bash
cd "\$(dirname "\$0")"
java -Xdock:name="Corese-GUI" -Xdock:icon="../Resources/corese-gui.icns" -Dawt.useSystemAAFontSettings=on -jar "$INSTALL_DIR/$JAR_NAME" "\$@"
EOF
    chmod +x "$APP_DIR/Contents/MacOS/corese-gui"

    # Copy icon (convert PNG to ICNS if possible)
    if [ -f "$ICON_FILE" ] && command -v sips >/dev/null 2>&1; then
        sips -s format icns "$ICON_FILE" --out "$APP_DIR/Contents/Resources/corese-gui.icns" >/dev/null 2>&1
    else
        cp "$ICON_FILE" "$APP_DIR/Contents/Resources/corese-gui.icns" 2>/dev/null || true
    fi

    echo "   ✅ macOS app created: $APP_DIR"
}

download_and_install() {
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR" || exit 1

    echo "⬇️  Downloading Corese-GUI $VERSION_TAG..."

    if ! RESPONSE=$(curl -s -f "$RELEASE_API/tags/$VERSION_TAG"); then
        echo
        echo "❌ Version '$VERSION_TAG' was not found on GitHub."
        echo
        echo "Available versions:"
        list_versions | sed 's/^/ - /'
        echo
        exit 1
    fi

    ASSET_URL=$(echo "$RESPONSE" | grep "browser_download_url" | grep "$JAR_NAME" | cut -d '"' -f 4 | head -n 1)

    if [[ -z "$ASSET_URL" ]]; then
        echo "❌ Could not find asset '$JAR_NAME' in release '$VERSION_TAG'."
        exit 1
    fi

    curl --progress-bar -L "$ASSET_URL" -o "$JAR_NAME"
    echo

    # Save version information
    echo "$VERSION_TAG" > "$VERSION_FILE"

    create_wrapper
    download_icon
    create_macos_app

    if [[ "$AUTO_YES" -eq 1 ]]; then
        add_to_all_available_shell_rcs
    fi

    echo -n "→ Add Corese-GUI to PATH for command-line usage? [Y/n] "
    read -r add_to_path
    if [[ ! "$add_to_path" =~ ^[Nn]$ ]]; then
        add_to_all_available_shell_rcs
    fi

    echo "✅ Corese-GUI $VERSION_TAG installed successfully!"
    echo "🍎 Launch from Applications folder or run: $BIN_NAME"
    echo "📁 Installed in: $INSTALL_DIR"
    echo
}

create_wrapper() {
    cat > "$WRAPPER_PATH" <<EOF
#!/usr/bin/env bash
java -Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -jar "$INSTALL_DIR/$JAR_NAME" "\$@"
EOF
    chmod +x "$WRAPPER_PATH"
}

add_to_all_available_shell_rcs() {
    BLOCK_START="# >>> Corese-GUI >>>"
    BLOCK_END="# <<< Corese-GUI <<<"

    echo "🧩 Adding Corese-GUI to available shell configs..."

    declare -a CONFIG_FILES=()

    command -v bash &>/dev/null && CONFIG_FILES+=("$HOME/.bash_profile")
    command -v zsh &>/dev/null && CONFIG_FILES+=("$HOME/.zshrc")
    command -v fish &>/dev/null && CONFIG_FILES+=("$HOME/.config/fish/config.fish")

    CONFIG_FILES+=("$HOME/.profile")

    for rc in "${CONFIG_FILES[@]}"; do
        mkdir -p "$(dirname "$rc")"

        if [[ -f "$rc" && "$(grep -F "$BLOCK_START" "$rc")" ]]; then
            echo "   ✔ Already added in $(basename "$rc")"
            continue
        fi

        echo "   ➕ Updating $(basename "$rc")"

        # Add a newline before the block only if the file doesn't already end with one
        [ -f "$rc" ] && [ "$(tail -c1 "$rc")" != "" ] && echo "" >> "$rc"

        {
            echo "$BLOCK_START"
            if [[ "$rc" == *"fish"* ]]; then
                echo "set -gx PATH $PATH $INSTALL_DIR"
            else
                echo "export PATH=\"$INSTALL_DIR:\$PATH\""
            fi
            echo "$BLOCK_END"
        } >> "$rc"
    done

    echo
    echo "✅ Corese-GUI path added."
    echo "🔁 Restart your terminal or run: source ~/.zshrc | source ~/.bash_profile | exec fish"
    echo
}

uninstall() {
    echo
    if [[ "$AUTO_YES" -ne 1 ]]; then
        echo "⚠️  This will completely remove Corese-GUI from your system."
        echo -n "→ Are you sure? [y/N] "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "❌ Uninstall cancelled."
            echo
            exit 0
        fi
    fi

    echo "🗑️  Removing Corese-GUI files..."
    rm -rf "$INSTALL_DIR"
    rm -rf "$APP_DIR"

    BLOCK_START="# >>> Corese-GUI >>>"
    BLOCK_END="# <<< Corese-GUI <<<"

    echo "🧹 Cleaning PATH from config files..."
    declare -a CONFIG_FILES=()

    [ -f "$HOME/.bash_profile" ] && CONFIG_FILES+=("$HOME/.bash_profile")
    [ -f "$HOME/.zshrc" ] && CONFIG_FILES+=("$HOME/.zshrc")
    [ -f "$HOME/.config/fish/config.fish" ] && CONFIG_FILES+=("$HOME/.config/fish/config.fish")
    [ -f "$HOME/.profile" ] && CONFIG_FILES+=("$HOME/.profile")

    for rc in "${CONFIG_FILES[@]}"; do
        if [ -f "$rc" ]; then
            sed -i '' "/$BLOCK_START/,/$BLOCK_END/d" "$rc"
            sed -i '' '/^$/N;/^\n$/D' "$rc"
            echo "   🧼 Cleaned $(basename "$rc")"
        fi
    done

    echo
    echo "✅ Corese-GUI has been removed."
    echo
}

main() {
    echo
    echo "╭────────────────────────────────────────╮"
    echo "│             Corese-GUI                 │"
    echo "│        macOS Installer & Updater       │"
    echo "╰────────────────────────────────────────╯"
    echo

    display_installed_version

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
        2)
            uninstall
            ;;
        3)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option."
            main
            ;;
    esac
}

# Platform check (macOS only)
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ This installer is intended for macOS only."
    echo "Please use the Linux version instead."
    exit 1
fi

# Entry point
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage:"
    echo "  ./install-macos-gui.sh --install <version>       Install specific version"
    echo "  ./install-macos-gui.sh --install-latest          Install latest version"
    echo "  ./install-macos-gui.sh --uninstall               Uninstall Corese-GUI"
    echo
    exit 0
fi

if [[ "$1" == "--install" && -n "$2" ]]; then
    AUTO_YES=1
    VERSION_TAG="$2"
    check_java
    download_and_install
    exit 0
fi

if [[ "$1" == "--install-latest" ]]; then
    AUTO_YES=1
    VERSION_TAG=$(list_versions | head -n 1)
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
