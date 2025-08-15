#!/usr/bin/env bash
# Godspeed Universal Installer
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Godspeed Universal Installer${NC}"
echo "=================================="

detect_system() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get >/dev/null; then
            echo "ubuntu"
        elif command -v yum >/dev/null; then
            echo "rhel"
        elif command -v pacman >/dev/null; then
            echo "arch"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

install_godspeed() {
    local system=$(detect_system)
    echo -e "${YELLOW}Detected system: $system${NC}"
    
    case $system in
        macos)
            if command -v brew >/dev/null; then
                echo -e "${GREEN}Installing via Homebrew...${NC}"
                brew tap dambu07/godspeed
                brew install godspeed
            else
                install_manual
            fi
            ;;
        *)
            install_manual
            ;;
    esac
}

install_manual() {
    local install_dir="$HOME/.local/bin"
    local godspeed_dir="$HOME/.godspeed"
    
    mkdir -p "$install_dir" "$godspeed_dir"
    
    if command -v curl >/dev/null; then
        curl -fsSL https://raw.githubusercontent.com/dambu07/godspeed/main/godspeed.sh -o "$install_dir/godspeed"
    elif command -v wget >/dev/null; then
        wget -O "$install_dir/godspeed" https://raw.githubusercontent.com/dambu07/godspeed/main/godspeed.sh
    else
        echo -e "${RED}Error: curl or wget required${NC}"
        exit 1
    fi
    
    chmod +x "$install_dir/godspeed"
    
    if [[ ":$PATH:" != *":$install_dir:"* ]]; then
        echo "export PATH=\"$install_dir:\$PATH\"" >> "$HOME/.bashrc"
        echo "export PATH=\"$install_dir:\$PATH\"" >> "$HOME/.zshrc" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Godspeed installed successfully!${NC}"
}

install_godspeed
echo -e "${GREEN}🎉 Installation complete!${NC}"
