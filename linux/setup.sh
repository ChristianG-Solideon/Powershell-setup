#!/usr/bin/env bash
# Bash setup script - installs profile, Oh My Posh, Nerd Fonts, zoxide, and utilities
# Supports Linux, macOS, and WSL
#
# Run from GitHub: curl -sL "https://github.com/ChristianG-Solideon/Powershell-setup/raw/main/linux/setup.sh" | bash

set -e

# Repo URL for remote mode (when run via curl | bash). Override with first arg if needed.
REPO_URL="${1:-https://github.com/ChristianG-Solideon/Powershell-setup}"
REPO_RAW_BASE=""
if [[ -n "$REPO_URL" ]]; then
    # Convert github.com/owner/repo to raw.githubusercontent.com/owner/repo/main
    REPO_RAW_BASE="${REPO_URL/https:\/\/github.com/https://raw.githubusercontent.com}"
    REPO_RAW_BASE="${REPO_RAW_BASE/%\/}/main"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin*) echo "macos" ;;
        MINGW*|MSYS*|CYGWIN*) echo "gitbash" ;;
        *)       echo "unknown" ;;
    esac
}

# Check for required commands
check_requirements() {
    local missing=()
    for cmd in curl unzip; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        log_info "Install them with your package manager (apt, brew, etc.)"
        exit 1
    fi
}

# Test internet connectivity
test_internet() {
    if curl -s --connect-timeout 5 -o /dev/null https://www.google.com 2>/dev/null; then
        return 0
    fi
    log_error "Internet connection required. Please check your connection."
    exit 1
}

# Get config directory (XDG-compliant)
get_config_dir() {
    if [[ -n "$XDG_CONFIG_HOME" ]]; then
        echo "$XDG_CONFIG_HOME/bash"
    else
        echo "$HOME/.config/bash"
    fi
}

# Install Oh My Posh
install_oh_my_posh() {
    local os
    os=$(detect_os)

    if command -v oh-my-posh &>/dev/null; then
        log_info "Oh My Posh already installed."
        return 0
    fi

    log_info "Installing Oh My Posh..."
    if [[ "$os" == "macos" ]] && command -v brew &>/dev/null; then
        brew install jandedobbeleer/oh-my-posh/oh-my-posh
    else
        curl -s https://ohmyposh.dev/install.sh | bash -s
        # Ensure oh-my-posh is in PATH
        if [[ -f "$HOME/bin/oh-my-posh" ]]; then
            export PATH="$HOME/bin:$PATH"
        elif [[ -f "$HOME/.local/bin/oh-my-posh" ]]; then
            export PATH="$HOME/.local/bin:$PATH"
        fi
    fi
    log_info "Oh My Posh installed."
}

# Install zoxide
install_zoxide() {
    local os
    os=$(detect_os)

    if command -v zoxide &>/dev/null; then
        log_info "zoxide already installed."
        return 0
    fi

    log_info "Installing zoxide..."
    if [[ "$os" == "macos" ]] && command -v brew &>/dev/null; then
        brew install zoxide
    elif [[ "$os" == "gitbash" ]]; then
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    elif [[ "$os" == "linux" ]] || [[ "$os" == "wsl" ]]; then
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y zoxide 2>/dev/null || {
                curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            }
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y zoxide
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm zoxide
        else
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
        fi
    fi
    log_info "zoxide installed."
}

# Install eza (modern ls with icons - bash equivalent of Terminal-Icons)
install_eza() {
    local os
    os=$(detect_os)

    if command -v eza &>/dev/null; then
        log_info "eza already installed."
        return 0
    fi

    if [[ "$os" == "gitbash" ]]; then
        log_warn "eza: Install manually via scoop/cargo on Windows, or use standard ls"
        return 0
    fi

    log_info "Installing eza..."
    if [[ "$os" == "macos" ]] && command -v brew &>/dev/null; then
        brew install eza
    elif [[ "$os" == "linux" ]] || [[ "$os" == "wsl" ]]; then
        if command -v apt-get &>/dev/null; then
            if sudo apt-get install -y eza 2>/dev/null; then
                log_info "eza installed via apt."
            else
                install_eza_from_github
            fi
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y eza
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm eza
        else
            install_eza_from_github
        fi
    fi
}

# Fallback: install eza from GitHub releases (for Ubuntu versions without eza in apt)
install_eza_from_github() {
    log_info "Installing eza from GitHub releases..."
    local arch
    arch=$(uname -m)
    local eza_arch=""
    case "$arch" in
        x86_64|amd64) eza_arch="x86_64-unknown-linux-gnu" ;;
        aarch64|arm64) eza_arch="aarch64-unknown-linux-gnu" ;;
        armv7l|armhf)  eza_arch="arm-unknown-linux-gnueabihf" ;;
        *) log_warn "Unsupported architecture for eza: $arch. Install manually: https://github.com/eza-community/eza"; return 1 ;;
    esac

    local tmpdir
    tmpdir=$(mktemp -d)
    local url="https://github.com/eza-community/eza/releases/latest/download/eza_${eza_arch}.tar.gz"
    if curl -sL "$url" -o "$tmpdir/eza.tar.gz" && tar xf "$tmpdir/eza.tar.gz" -C "$tmpdir"; then
        local eza_bin
        eza_bin=$(find "$tmpdir" -name "eza" -type f -executable 2>/dev/null | head -1)
        if [[ -n "$eza_bin" ]]; then
            sudo mkdir -p /usr/local/bin
            sudo cp -f "$eza_bin" /usr/local/bin/eza
            sudo chmod +x /usr/local/bin/eza
            log_info "eza installed to /usr/local/bin"
        else
            log_warn "Could not find eza binary in archive. Install manually: https://github.com/eza-community/eza"
        fi
    else
        log_warn "Could not download eza from GitHub. Install manually: https://github.com/eza-community/eza"
    fi
    rm -rf "$tmpdir"
}

# Install Nerd Fonts (Cascadia Code)
install_nerd_fonts() {
    local font_name="CascadiaCode"
    local version="3.2.1"
    local os
    os=$(detect_os)

    if [[ "$os" == "gitbash" ]]; then
        log_warn "Nerd Fonts: On Windows, run the PowerShell setup for font install, or install manually from https://www.nerdfonts.com/font-downloads"
        return 0
    fi

    if [[ "$os" == "macos" ]]; then
        if command -v brew &>/dev/null; then
            log_info "Installing Nerd Font (Cascadia Code)..."
            brew tap homebrew/cask-fonts 2>/dev/null || true
            brew install --cask font-caskaydia-cove-nerd-font 2>/dev/null || brew install --cask font-cascadia-code-nerd-font
            log_info "Nerd Font installed. Set it in your terminal preferences."
            return 0
        fi
    fi

    local font_dir
    font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
    mkdir -p "$font_dir"

    if fc-list 2>/dev/null | grep -qi "CaskaydiaCove Nerd Font"; then
        log_info "CaskaydiaCove Nerd Font already installed."
        return 0
    fi

    log_info "Installing CaskaydiaCove Nerd Font..."
    local zip_dir
    zip_dir=$(mktemp -d)
    local zip_file="$zip_dir/${font_name}.zip"
    curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${font_name}.zip" -o "$zip_file"
    unzip -q -o "$zip_file" -d "$zip_dir"
    cp -f "$zip_dir"/*.ttf "$font_dir/" 2>/dev/null || cp -f "$zip_dir"/*/*.ttf "$font_dir/" 2>/dev/null || true
    rm -rf "$zip_dir"
    fc-cache -fv 2>/dev/null || true
    log_info "Font installed to $font_dir. Set 'CaskaydiaCove Nerd Font' in your terminal."
}

# Download Oh My Posh theme (my_layout.omp.json)
install_theme() {
    local config_dir
    config_dir=$(get_config_dir)
    mkdir -p "$config_dir"

    local theme_dest="$config_dir/my_layout.omp.json"
    local theme_src=""
    local script_dir=""

    if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -d "$(dirname "${BASH_SOURCE[0]}")" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local repo_root
        repo_root="$(cd "$script_dir/.." && pwd)"
        theme_src="$repo_root/my_layout.omp.json"
    fi

    if [[ -f "${theme_src:-}" ]]; then
        cp "$theme_src" "$theme_dest"
        log_info "Theme copied to $theme_dest"
    elif [[ -n "$REPO_RAW_BASE" ]]; then
        log_info "Downloading theme (my_layout.omp.json) from repo..."
        if curl -sL "$REPO_RAW_BASE/my_layout.omp.json" -o "$theme_dest"; then
            log_info "Theme downloaded to $theme_dest"
        else
            log_warn "Could not download my_layout from repo, using cobalt2 fallback"
            curl -sL "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json" -o "$theme_dest"
            log_info "Theme (cobalt2) downloaded to $theme_dest"
        fi
    else
        log_warn "Repo not available, using cobalt2 fallback"
        curl -sL "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json" -o "$theme_dest"
        log_info "Theme (cobalt2) downloaded to $theme_dest"
    fi
}

# Setup bash profile
setup_profile() {
    local config_dir
    config_dir=$(get_config_dir)
    mkdir -p "$config_dir"

    local script_dir=""
    if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -d "$(dirname "${BASH_SOURCE[0]}")" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi

    local bashrc_src="${script_dir:+$script_dir/bashrc}"
    local bashrc_dest="$config_dir/bashrc"
    local profile_bash="$config_dir/profile.bash"

    if [[ -f "${bashrc_src:-}" ]]; then
        cp "$bashrc_src" "$bashrc_dest"
        log_info "Bash profile installed to $bashrc_dest"
    elif [[ -n "$REPO_RAW_BASE" ]]; then
        log_info "Downloading bashrc from repo..."
        curl -sL "$REPO_RAW_BASE/linux/bashrc" -o "$bashrc_dest" || {
            log_error "Could not download bashrc from repo."
            exit 1
        }
        log_info "Bash profile installed to $bashrc_dest"
    else
        log_error "bashrc not found. Run from repo: ./linux/setup.sh"
        exit 1
    fi

    # Create profile.bash if it doesn't exist (user overrides)
    if [[ ! -f "$profile_bash" ]]; then
        local profile_src="${script_dir:+$script_dir/profile.bash}"
        if [[ -f "${profile_src:-}" ]]; then
            cp "$profile_src" "$profile_bash"
        elif [[ -n "$REPO_RAW_BASE" ]]; then
            curl -sL "$REPO_RAW_BASE/linux/profile.bash" -o "$profile_bash" 2>/dev/null || true
        fi
        if [[ ! -f "$profile_bash" ]]; then
            cat > "$profile_bash" << 'PROFILE_EOF'
# User overrides - customize your bash experience here
# This file is sourced after the main bashrc

# Example: custom alias
# alias mycommand='something'

# Example: custom theme path
# export OMP_CONFIG="$HOME/.config/bash/my_layout.omp.json"
PROFILE_EOF
        fi
        log_info "Created $profile_bash for your customizations"
    fi

    # Add sourcing to .bashrc if not already present
    local source_line="[[ -f \"$bashrc_dest\" ]] && source \"$bashrc_dest\""
    if ! grep -qF "$bashrc_dest" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# PowerShell-setup bash profile" >> "$HOME/.bashrc"
        echo "$source_line" >> "$HOME/.bashrc"
        log_info "Added profile to ~/.bashrc"
    else
        log_info "Profile already in ~/.bashrc"
    fi

    # macOS: ensure .bashrc is sourced from .bash_profile for login shells
    if [[ "$(detect_os)" == "macos" ]]; then
        if [[ -f "$HOME/.bash_profile" ]]; then
            if ! grep -qF '.bashrc' "$HOME/.bash_profile" 2>/dev/null; then
                echo "" >> "$HOME/.bash_profile"
                echo "[[ -f ~/.bashrc ]] && source ~/.bashrc" >> "$HOME/.bash_profile"
                log_info "Added .bashrc source to ~/.bash_profile"
            fi
        else
            echo "[[ -f ~/.bashrc ]] && source ~/.bashrc" > "$HOME/.bash_profile"
            log_info "Created ~/.bash_profile to source ~/.bashrc"
        fi
    fi

    # Linux/WSL: re-source .bashrc at end of .profile (after PATH is set, so oh-my-posh is found)
    if [[ "$(detect_os)" == "linux" ]] || [[ "$(detect_os)" == "wsl" ]]; then
        if [[ -f "$HOME/.bash_profile" ]] && ! grep -qF '.bashrc' "$HOME/.bash_profile" 2>/dev/null; then
            echo "" >> "$HOME/.bash_profile"
            echo "[[ -f ~/.bashrc ]] && source ~/.bashrc" >> "$HOME/.bash_profile"
            log_info "Added .bashrc source to ~/.bash_profile"
        fi

        if [[ -f "$HOME/.profile" ]] && ! grep -qF 'Re-source .bashrc after PATH' "$HOME/.profile" 2>/dev/null; then
            echo "" >> "$HOME/.profile"
            echo "# Re-source .bashrc after PATH is set (oh-my-posh in ~/.local/bin)" >> "$HOME/.profile"
            echo "[[ -f ~/.bashrc ]] && . ~/.bashrc" >> "$HOME/.profile"
            log_info "Added .bashrc re-source to end of ~/.profile (WSL/login shells)"
        fi
    fi
}

# Main
main() {
    log_info "Bash setup starting..."
    check_requirements
    test_internet

    local os
    os=$(detect_os)
    log_info "Detected OS: $os"

    setup_profile
    install_oh_my_posh
    install_zoxide
    install_eza
    install_nerd_fonts
    install_theme

    echo ""
    log_info "Setup complete!"
    log_info "Restart your terminal or run: source ~/.bashrc"
    log_info "Set your terminal font to 'CaskaydiaCove Nerd Font' for full icon support."
    if [[ "$(detect_os)" == "wsl" ]]; then
        log_info "WSL: If theme doesn't show on new terminals, ensure ~/.profile sources ~/.bashrc (setup should have fixed this)"
    fi
}

main "$@"
