#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Corese-GUI Linux Installer
# ------------------------------------------------------------------------------
# This script installs, updates, migrates, or uninstalls Corese-GUI.
# - Legacy line (4.x): corese-gui-swing repository
# - New line (5.x+):   corese-gui repository
# ------------------------------------------------------------------------------

set -euo pipefail

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/corese-gui"
BIN_NAME="corese-gui"
WRAPPER_PATH="$INSTALL_DIR/$BIN_NAME"
JAR_NAME="corese-gui-standalone.jar"
VERSION_FILE="$INSTALL_DIR/version.txt"
DESKTOP_FILE="$XDG_DATA_HOME/applications/corese-gui.desktop"
ICON_FILE="$XDG_DATA_HOME/icons/fr.inria.corese.CoreseGui.svg"
AUTO_YES=0

LEGACY_GITHUB_REPO="corese-stack/corese-gui-swing"
LEGACY_RELEASE_API="https://api.github.com/repos/$LEGACY_GITHUB_REPO/releases"
NEXT_GEN_GITHUB_REPO="corese-stack/corese-gui"
NEXT_GEN_RELEASE_API="https://api.github.com/repos/$NEXT_GEN_GITHUB_REPO/releases"
NEXT_GEN_INSTALL_GUIDE_URL="https://corese-stack.github.io/corese-gui/dev-prerelease/install.html"
NEXT_GEN_RELEASES_URL="https://github.com/$NEXT_GEN_GITHUB_REPO/releases"

LEGACY_MIN_VERSION="4.0.0"
NEXT_GEN_MIN_VERSION="5.0.0"
NEXT_GEN_PRERELEASE_TAG="dev-prerelease"

VERSION_TAG=""
VERSION_CHANNEL=""
VERSION_LABEL=""
declare -a VERSION_CATALOG=()

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ Missing required command: $cmd"
        exit 1
    fi
}

check_requirements() {
    require_command curl
    require_command jq
}

normalize_tag_version() {
    local version="$1"
    echo "${version#v}"
}

is_semver_tag() {
    local tag="$1"
    [[ "$tag" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

version_greater_equal() {
    local current="$1"
    local minimum="$2"
    [[ "$(printf '%s\n%s\n' "$current" "$minimum" | sort -V | head -n 1)" == "$minimum" ]]
}

is_next_gen_tag() {
    local tag="$1"

    if [[ "$tag" == "$NEXT_GEN_PRERELEASE_TAG" ]]; then
        return 0
    fi

    if ! is_semver_tag "$tag"; then
        return 1
    fi

    local normalized
    normalized="$(normalize_tag_version "$tag")"
    version_greater_equal "$normalized" "$NEXT_GEN_MIN_VERSION"
}

is_legacy_tag() {
    local tag="$1"

    if ! is_semver_tag "$tag"; then
        return 1
    fi

    local normalized
    normalized="$(normalize_tag_version "$tag")"

    version_greater_equal "$normalized" "$LEGACY_MIN_VERSION" && ! version_greater_equal "$normalized" "$NEXT_GEN_MIN_VERSION"
}

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

    JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")
    if java --list-modules 2>/dev/null | grep -q '^java.desktop' \
        && find "$JAVA_HOME" -type f -name 'libawt_xawt.so' -print -quit | grep -q . ; then
        echo "✅ AWT / Swing OK"
    else
        echo "⚠️  No GUI support found in this Java installation"
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
        # shellcheck disable=SC1091
        . /etc/os-release

        if [[ "${ID_LIKE:-}" =~ (debian|ubuntu) ]]; then
            echo "debian"
        elif [[ "$ID" == "debian" || "$ID" == "ubuntu" || "$ID" == "pop" || "$ID" == "linuxmint" ]]; then
            echo "debian"
        elif [[ "$ID" == "fedora" || "${ID_LIKE:-}" == "fedora" ]]; then
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

list_legacy_versions() {
    curl -s "$LEGACY_RELEASE_API" \
        | jq -r '.[] | select(.prerelease == false and .draft == false) | [.tag_name, .published_at] | @tsv' \
        | sort -k2 -r \
        | cut -f1 \
        | while IFS= read -r tag; do
            if is_legacy_tag "$tag"; then
                echo "$tag"
            fi
        done
}

list_next_gen_versions() {
    curl -s "$NEXT_GEN_RELEASE_API" \
        | jq -r '.[] | select(.draft == false) | [.tag_name, .published_at] | @tsv' \
        | sort -k2 -r \
        | while IFS=$'\t' read -r tag _published; do
            if is_next_gen_tag "$tag"; then
                echo "$tag"
            fi
        done
}

build_version_catalog() {
    VERSION_CATALOG=()
    declare -A seen=()

    while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue
        [[ -n "${seen[$tag]:-}" ]] && continue
        seen[$tag]=1

        if [[ "$tag" == "$NEXT_GEN_PRERELEASE_TAG" ]]; then
            VERSION_CATALOG+=("$tag"$'\t'"next"$'\t'"$tag (new app preview)")
        else
            VERSION_CATALOG+=("$tag"$'\t'"next"$'\t'"$tag (new app 5.x)")
        fi
    done < <(list_next_gen_versions)

    while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue
        [[ -n "${seen[$tag]:-}" ]] && continue
        seen[$tag]=1
        VERSION_CATALOG+=("$tag"$'\t'"legacy"$'\t'"$tag (legacy Swing 4.x)")
    done < <(list_legacy_versions)
}

print_available_versions() {
    if [[ "${#VERSION_CATALOG[@]}" -eq 0 ]]; then
        echo "   (no version found)"
        return
    fi

    for i in "${!VERSION_CATALOG[@]}"; do
        IFS=$'\t' read -r tag _channel label <<< "${VERSION_CATALOG[$i]}"
        if [[ "$i" -eq 0 ]]; then
            printf "   [%d] %s (latest)\n" $((i + 1)) "$label"
        else
            printf "   [%d] %s\n" $((i + 1)) "$label"
        fi
    done
}

choose_version() {
    build_version_catalog

    if [[ "${#VERSION_CATALOG[@]}" -eq 0 ]]; then
        echo "❌ No installable version found from GitHub APIs."
        exit 1
    fi

    echo "📦 Available versions:"
    print_available_versions

    while true; do
        echo -n "→ Enter the number of the version to install [default: 1]: "
        read -r VERSION_INDEX

        if [[ -z "$VERSION_INDEX" ]]; then
            VERSION_INDEX=1
            break
        elif [[ "$VERSION_INDEX" =~ ^[0-9]+$ && "$VERSION_INDEX" -ge 1 && "$VERSION_INDEX" -le "${#VERSION_CATALOG[@]}" ]]; then
            break
        else
            echo "❌ Invalid input. Please enter a number between 1 and ${#VERSION_CATALOG[@]}."
        fi
    done

    IFS=$'\t' read -r VERSION_TAG VERSION_CHANNEL VERSION_LABEL <<< "${VERSION_CATALOG[$((VERSION_INDEX - 1))]}"

    echo
    echo "✔️  Selected version: $VERSION_TAG"
    echo
}

set_latest_version_from_catalog() {
    build_version_catalog

    if [[ "${#VERSION_CATALOG[@]}" -eq 0 ]]; then
        echo "❌ No installable version found from GitHub APIs."
        exit 1
    fi

    IFS=$'\t' read -r VERSION_TAG VERSION_CHANNEL VERSION_LABEL <<< "${VERSION_CATALOG[0]}"
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

open_in_browser() {
    local url="$1"
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" >/dev/null 2>&1 || true
    fi
}

detect_linux_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "x64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "x64"
            ;;
    esac
}

remove_from_all_shell_rcs() {
    local block_start="# >>> Corese-GUI >>>"
    local block_end="# <<< Corese-GUI <<<"

    echo "🧹 Cleaning PATH from config files..."
    declare -a config_files=()

    [ -f "$HOME/.bashrc" ] && config_files+=("$HOME/.bashrc")
    [ -f "$HOME/.zshrc" ] && config_files+=("$HOME/.zshrc")
    [ -f "$HOME/.config/fish/config.fish" ] && config_files+=("$HOME/.config/fish/config.fish")
    [ -f "$HOME/.profile" ] && config_files+=("$HOME/.profile")

    for rc in "${config_files[@]}"; do
        if [ -f "$rc" ]; then
            sed -i "/$block_start/,/$block_end/d" "$rc"
            sed -i '/^$/N;/^\n$/D' "$rc"
            echo "   🧼 Cleaned $(basename "$rc")"
        fi
    done
}

remove_legacy_installation_files() {
    echo "🗑️  Removing legacy Corese-GUI Swing files..."
    rm -rf "$INSTALL_DIR"
    rm -f "$DESKTOP_FILE"
    rm -f "$ICON_FILE"
}

uninstall_legacy_for_migration() {
    if [[ ! -f "$INSTALL_DIR/$JAR_NAME" && ! -d "$INSTALL_DIR" ]]; then
        echo "ℹ️  No legacy Swing installation detected."
        echo
        return
    fi

    if [[ "$AUTO_YES" -ne 1 ]]; then
        echo "⚠️  The selected version belongs to the new Corese-GUI 5.x line."
        echo "⚠️  The current Corese-GUI Swing 4.x installation is legacy."
        echo -n "→ Uninstall legacy 4.x from this machine now? [Y/n] "
        read -r confirm
        if [[ "$confirm" =~ ^[Nn]$ ]]; then
            echo "ℹ️  Legacy installation kept."
            echo
            return
        fi
    fi

    remove_legacy_installation_files
    remove_from_all_shell_rcs
    echo "✅ Legacy Swing installation removed."
    echo
}

select_next_gen_linux_asset_url() {
    local release_json="$1"
    local arch
    arch="$(detect_linux_arch)"

    local archive_url
    archive_url=$(echo "$release_json" | jq -r --arg arch "$arch" '
        [ .assets[].browser_download_url
          | select(test("/corese-gui-linux-" + $arch + "\\.tar\\.gz$"))
        ][0] // empty
    ')

    if [[ -n "$archive_url" ]]; then
        echo "$archive_url"
        return
    fi

    echo "$release_json" | jq -r --arg arch "$arch" '
        [ .assets[].browser_download_url
          | select(test("/corese-gui-.*-standalone-linux-" + $arch + "\\.jar$"))
        ][0] // empty
    '
}

redirect_to_next_gen_release() {
    local tag="$1"

    echo "🔁 Redirecting to the new Corese-GUI 5.x channel..."
    echo "   Selected version: $tag"
    echo "   Migration guide: $NEXT_GEN_INSTALL_GUIDE_URL"

    if ! release_json=$(curl -s -f "$NEXT_GEN_RELEASE_API/tags/$tag"); then
        echo "⚠️  Could not resolve release '$tag' in $NEXT_GEN_GITHUB_REPO."
        echo "➡️  Open this page to continue: $NEXT_GEN_RELEASES_URL"
        open_in_browser "$NEXT_GEN_INSTALL_GUIDE_URL"
        return
    fi

    local release_html_url
    release_html_url=$(echo "$release_json" | jq -r '.html_url // empty')
    [[ -z "$release_html_url" ]] && release_html_url="$NEXT_GEN_RELEASES_URL"

    local asset_url
    asset_url="$(select_next_gen_linux_asset_url "$release_json")"

    if [[ -n "$asset_url" ]]; then
        local download_path="/tmp/$(basename "$asset_url")"
        echo "⬇️  Downloading platform asset: $(basename "$asset_url")"
        curl --progress-bar -L "$asset_url" -o "$download_path"
        echo
        echo "✅ Download complete: $download_path"
    else
        echo "⚠️  No Linux asset detected automatically for your architecture."
    fi

    echo "➡️  Release page: $release_html_url"
    echo "➡️  Install guide: $NEXT_GEN_INSTALL_GUIDE_URL"
    echo

    open_in_browser "$NEXT_GEN_INSTALL_GUIDE_URL"
}

download_icon() {
    echo "🎨 Downloading application icon..."
    mkdir -p "$(dirname "$ICON_FILE")"

    ICON_URLS=(
        "https://raw.githubusercontent.com/$LEGACY_GITHUB_REPO/main/packaging/assets/logo/fr.inria.corese.CoreseGui.svg"
        "https://raw.githubusercontent.com/$LEGACY_GITHUB_REPO/develop/packaging/assets/logo/fr.inria.corese.CoreseGui.svg"
    )

    for ICON_URL in "${ICON_URLS[@]}"; do
        if curl -s -f -L "$ICON_URL" -o "$ICON_FILE"; then
            echo "   ✅ Icon downloaded successfully"
            return 0
        fi
    done

    echo "   ⚠️  Could not download icon, using fallback"
    touch "$ICON_FILE"
}

create_desktop_file() {
    echo "🖥️  Creating desktop integration..."
    mkdir -p "$(dirname "$DESKTOP_FILE")"

    cat > "$DESKTOP_FILE" <<EOT
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
EOT

    chmod +x "$DESKTOP_FILE"
    echo "   ✅ Desktop file created: $DESKTOP_FILE"
}

create_wrapper() {
    cat > "$WRAPPER_PATH" <<EOT
#!/usr/bin/env bash
java -Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -jar "$INSTALL_DIR/$JAR_NAME" "\$@"
EOT
    chmod +x "$WRAPPER_PATH"
}

add_to_all_available_shell_rcs() {
    local block_start="# >>> Corese-GUI >>>"
    local block_end="# <<< Corese-GUI <<<"

    echo "🧩 Adding Corese-GUI to available shell configs..."

    declare -a config_files=()

    command -v bash &>/dev/null && config_files+=("$HOME/.bashrc")
    command -v zsh &>/dev/null && config_files+=("$HOME/.zshrc")
    command -v fish &>/dev/null && config_files+=("$HOME/.config/fish/config.fish")

    config_files+=("$HOME/.profile")

    for rc in "${config_files[@]}"; do
        mkdir -p "$(dirname "$rc")"

        if [[ -f "$rc" && "$(grep -F "$block_start" "$rc")" ]]; then
            echo "   ✔ Already added in $(basename "$rc")"
            continue
        fi

        echo "   ➕ Updating $(basename "$rc")"
        [ -f "$rc" ] && [ "$(tail -c1 "$rc")" != "" ] && echo "" >> "$rc"

        {
            echo "$block_start"
            if [[ "$rc" == *"fish"* ]]; then
                echo "set -gx PATH \$PATH $INSTALL_DIR"
            else
                echo "export PATH=\"$INSTALL_DIR:\$PATH\""
            fi
            echo "$block_end"
        } >> "$rc"
    done

    echo
    echo "✅ Corese-GUI path added."
    echo "🔁 Restart your terminal or run: source ~/.bashrc | source ~/.zshrc | exec fish"
    echo
}

download_and_install() {
    if is_next_gen_tag "$VERSION_TAG"; then
        uninstall_legacy_for_migration
        redirect_to_next_gen_release "$VERSION_TAG"
        return
    fi

    if ! is_legacy_tag "$VERSION_TAG"; then
        echo "❌ Unsupported legacy version tag: $VERSION_TAG"
        exit 1
    fi

    check_java

    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR" || exit 1

    echo "⬇️  Downloading Corese-GUI (legacy) $VERSION_TAG..."

    if ! response=$(curl -s -f "$LEGACY_RELEASE_API/tags/$VERSION_TAG"); then
        echo
        echo "❌ Version '$VERSION_TAG' was not found on GitHub."
        echo
        exit 1
    fi

    asset_url=$(echo "$response" | jq -r --arg jar "$JAR_NAME" '.assets[] | select(.name == $jar) | .browser_download_url' | head -n 1)

    if [[ -z "$asset_url" ]]; then
        echo "❌ Could not find asset '$JAR_NAME' in release '$VERSION_TAG'."
        exit 1
    fi

    curl --progress-bar -L "$asset_url" -o "$JAR_NAME"
    echo

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

    echo "✅ Corese-GUI legacy $VERSION_TAG installed successfully!"
    echo "🖥️  Launch from applications menu or run: $BIN_NAME"
    echo "📁 Installed in: $INSTALL_DIR"
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

    remove_legacy_installation_files
    remove_from_all_shell_rcs

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

if [[ "$(uname)" == "Darwin" ]]; then
    echo "❌ This installer is intended for Linux only."
    echo "Please use the macOS version instead."
    exit 1
fi

check_requirements

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage:"
    echo "  ./install-linux-gui.sh --install <version>       Install specific version"
    echo "  ./install-linux-gui.sh --install-latest          Install latest version"
    echo "  ./install-linux-gui.sh --uninstall               Uninstall Corese-GUI"
    echo
    echo "Notes:"
    echo "  - Versions >= 5.0.0 (and dev-prerelease) migrate to the new repository: $NEXT_GEN_GITHUB_REPO"
    echo "  - Migration guide: $NEXT_GEN_INSTALL_GUIDE_URL"
    echo
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
    set_latest_version_from_catalog
    download_and_install
    exit 0
fi

if [[ "${1:-}" == "--uninstall" ]]; then
    AUTO_YES=1
    uninstall
    exit 0
fi

main
