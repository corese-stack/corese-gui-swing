#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Corese-GUI Linux Installer
# ------------------------------------------------------------------------------
# This script installs or updates the Corese-GUI application on a Linux system.
# It automatically checks for Java (>= 21), installs it if necessary,
# fetches the desired version of Corese-GUI from GitHub, creates desktop
# integration, and optionally adds the binary to the user's PATH.
#
# Usage:
#   ./install-linux-gui.sh                     # Interactive mode
#   ./install-linux-gui.sh --install <version> # Install a specific version (e.g. v4.6.0)
#   ./install-linux-gui.sh --install-latest    # Install the latest available version
#   ./install-linux-gui.sh --uninstall         # Remove Corese-GUI from the system
# ------------------------------------------------------------------------------

set -e

INSTALL_DIR="$HOME/.local/corese-gui"
BIN_NAME="corese-gui"
WRAPPER_PATH="$INSTALL_DIR/$BIN_NAME"
JAR_NAME="corese-gui-standalone.jar"
VERSION_FILE="$INSTALL_DIR/version.txt"
GITHUB_REPO="corese-stack/corese-gui-swing"
RELEASE_API="https://api.github.com/repos/$GITHUB_REPO/releases"
DESKTOP_FILE="$HOME/.local/share/applications/corese-gui.desktop"
ICON_FILE="$HOME/.local/share/icons/fr.inria.corese.CoreseGui.svg"
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

    JAVA_VERSION=$(java -version 2>&1 | grep -oE 'version "([0-9]+)' | grep -oE '[0-9]+')
    if [[ -z "$JAVA_VERSION" || "$JAVA_VERSION" -lt 21 ]]; then
        echo "❌ Java version 21 or higher is required (found: ${JAVA_VERSION:-unknown})."
        prompt_install_java
        return
    fi

    # Check if AWT is supported (i.e., not headless)
    JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")
    if java --list-modules 2>/dev/null | grep -q '^java.desktop' \
    && find "$JAVA_HOME" -type f -name 'libawt_xawt.so' -print -quit | grep -q . ; then
    echo "✅ AWT / Swing OK"
    else
    echo "⚠️  Pas de support GUI"
    prompt_install_java
    fi

    echo "✅ Java version $JAVA_VERSION with GUI support detected."
    echo
}

prompt_install_java() {
    if [[ "$AUTO_YES" -eq 1 ]]; then
        install_java_by_distro
        return
    fi

    echo -n "→ Install OpenJDK 21 now? [Y/n] "
    read -r answer
    if [[ "$answer" =~ ^[Nn]$ ]]; then
        echo "❌ Java is required. Aborting."
        exit 1
    fi
    install_java_by_distro
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release

        if [[ "$ID_LIKE" =~ (debian|ubuntu) ]]; then
            echo "debian"
        elif [[ "$ID" == "debian" || "$ID" == "ubuntu" || "$ID" == "pop" || "$ID" == "linuxmint" ]]; then
            echo "debian"
        elif [[ "$ID" == "fedora" || "$ID_LIKE" == "fedora" ]]; then
            echo "fedora"
        elif [[ "$ID" == "arch" ]]; then
            echo "arch"
        elif [[ "$ID" == "alpine" ]]; then
            echo "alpine"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

install_java_by_distro() {
    DISTRO=$(detect_distro)
    echo "📦 Installing Java 21 on $DISTRO..."

    case "$DISTRO" in
        debian)
            sudo apt update && sudo apt install -y openjdk-21-jre ;;
        fedora)
            sudo dnf install -y java-21-openjdk ;;
        arch)
            sudo pacman -Sy --noconfirm jdk21-openjdk ;;
        alpine)
            if ! command -v apk &>/dev/null; then
                echo "❌ apk not found. Cannot install on Alpine."
                exit 1
            fi
            echo "📦 Installing openjdk21 using apk..."
            apk add --no-cache openjdk21 ;;
        *)
            echo "❌ Unsupported distro: $DISTRO"
            echo "Please install Java 21 or higher manually."
            exit 1 ;;
    esac
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
    mkdir -p "$(dirname "$ICON_FILE")"

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

create_desktop_file() {
    echo "🖥️  Creating desktop integration..."
    mkdir -p "$(dirname "$DESKTOP_FILE")"

    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Corese-GUI
GenericName=Graphical Semantic Web Platform
Comment=Interact with RDF data and SPARQL queries through a graphical interface.
Categories=Science;ComputerScience;Development;
Icon=$ICON_FILE
Exec=$WRAPPER_PATH
Terminal=false
StartupNotify=true
Keywords=semantic web;RDF;SPARQL;OWL;SHACL;LDScript;STTL;SPARQL Rule;SPARQL*;RDF*;SPARQL Query;SPARQL Graph;SHACL Validation;
X-GNOME-FullName=Corese-GUI
DBusActivatable=false
EOF

    chmod +x "$DESKTOP_FILE"
    echo "   ✅ Desktop file created: $DESKTOP_FILE"
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
    create_desktop_file

    if [[ "$AUTO_YES" -eq 1 ]]; then
        add_to_all_available_shell_rcs
    else
        echo -n "→ Add Corese-GUI to PATH for command-line usage? [Y/n] "
        read -r add_to_path
        if [[ ! "$add_to_path" =~ ^[Nn]$ ]]; then
            add_to_all_available_shell_rcs
        fi
    fi

    echo "✅ Corese-GUI $VERSION_TAG installed successfully!"
    echo "🖥️  Launch from applications menu or run: $BIN_NAME"
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

    command -v bash &>/dev/null && CONFIG_FILES+=("$HOME/.bashrc")
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
                echo "set -gx PATH \$PATH $INSTALL_DIR"
            else
                echo "export PATH=\"$INSTALL_DIR:\$PATH\""
            fi
            echo "$BLOCK_END"
        } >> "$rc"
    done

    echo
    echo "✅ Corese-GUI path added."
    echo "🔁 Restart your terminal or run: source ~/.bashrc | source ~/.zshrc | exec fish"
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
    rm -f "$DESKTOP_FILE"
    rm -f "$ICON_FILE"

    BLOCK_START="# >>> Corese-GUI >>>"
    BLOCK_END="# <<< Corese-GUI <<<"

    echo "🧹 Cleaning PATH from config files..."
    declare -a CONFIG_FILES=()

    [ -f "$HOME/.bashrc" ] && CONFIG_FILES+=("$HOME/.bashrc")
    [ -f "$HOME/.zshrc" ] && CONFIG_FILES+=("$HOME/.zshrc")
    [ -f "$HOME/.config/fish/config.fish" ] && CONFIG_FILES+=("$HOME/.config/fish/config.fish")
    [ -f "$HOME/.profile" ] && CONFIG_FILES+=("$HOME/.profile")

    for rc in "${CONFIG_FILES[@]}"; do
        if [ -f "$rc" ]; then
            sed -i "/$BLOCK_START/,/$BLOCK_END/d" "$rc"
            sed -i '/^$/N;/^\n$/D' "$rc"
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
    echo "│        Linux Installer & Updater       │"
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

# Platform check (Linux only)
if [[ "$(uname)" == "Darwin" ]]; then
    echo "❌ This installer is intended for Linux only."
    echo "Please use the macOS version instead."
    exit 1
fi

# Entry point
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage:"
    echo "  ./install-linux-gui.sh --install <version>       Install specific version"
    echo "  ./install-linux-gui.sh --install-latest          Install latest version"
    echo "  ./install-linux-gui.sh --uninstall               Uninstall Corese-GUI"
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
