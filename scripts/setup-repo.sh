#!/usr/bin/env bash
# setup-repo.sh - Prepare repository for package distribution
set -euo pipefail

echo "🔧 Setting up Godspeed repository for distribution..."

# Create necessary directories
mkdir -p {Formula,install,packages/{debian,rpm,arch},docs}

# Generate version from git tag or default
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.7.0")
VERSION_NUM=${VERSION#v}

echo "📋 Repository Setup for Godspeed $VERSION"

# 1. Create Homebrew Formula
cat > Formula/godspeed.rb <<EOF
class Godspeed < Formula
  desc "Ultimate Full-Stack Development Environment with AI Integration"
  homepage "https://github.com/dambu07/godspeed"
  url "https://github.com/dambu07/godspeed/archive/refs/tags/$VERSION.tar.gz"
  version "$VERSION_NUM"
  license "MIT"
  
  depends_on "bash" => :build
  depends_on "git"
  depends_on "curl"
  depends_on "jq"

  def install
    bin.install "godspeed.sh" => "godspeed"
    
    # Create completion scripts
    bash_completion.install "completions/godspeed.bash" if File.exist?("completions/godspeed.bash")
    zsh_completion.install "completions/godspeed.zsh" if File.exist?("completions/godspeed.zsh")
    
    # Install documentation
    man1.install "docs/godspeed.1" if File.exist?("docs/godspeed.1")
  end

  test do
    system "#{bin}/godspeed", "--version"
    system "#{bin}/godspeed", "doctor"
  end
end
EOF

# 2. Create Universal Install Script
cat > install/install.sh <<'EOF'
#!/usr/bin/env bash
# Godspeed Universal Installer
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Godspeed Universal Installer${NC}"
echo "=================================="

# Detect OS and package manager
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
                echo -e "${YELLOW}Homebrew not found. Installing manually...${NC}"
                install_manual
            fi
            ;;
        ubuntu)
            echo -e "${GREEN}Installing via manual installation...${NC}"
            install_manual
            ;;
        arch)
            echo -e "${YELLOW}Arch Linux detected. Install from AUR or manually...${NC}"
            install_manual
            ;;
        *)
            echo -e "${YELLOW}Installing manually...${NC}"
            install_manual
            ;;
    esac
}

install_manual() {
    local install_dir="$HOME/.local/bin"
    local godspeed_dir="$HOME/.godspeed"
    
    echo -e "${GREEN}Manual installation starting...${NC}"
    
    # Create directories
    mkdir -p "$install_dir" "$godspeed_dir"
    
    # Download godspeed script
    if command -v curl >/dev/null; then
        curl -fsSL https://raw.githubusercontent.com/dambu07/godspeed/main/godspeed.sh -o "$install_dir/godspeed"
    elif command -v wget >/dev/null; then
        wget -O "$install_dir/godspeed" https://raw.githubusercontent.com/dambu07/godspeed/main/godspeed.sh
    else
        echo -e "${RED}Error: curl or wget required${NC}"
        exit 1
    fi
    
    # Make executable
    chmod +x "$install_dir/godspeed"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$install_dir:"* ]]; then
        echo "export PATH=\"$install_dir:\$PATH\"" >> "$HOME/.bashrc"
        echo "export PATH=\"$install_dir:\$PATH\"" >> "$HOME/.zshrc" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Godspeed installed successfully!${NC}"
    echo -e "${BLUE}Run 'source ~/.bashrc' or restart your terminal${NC}"
    echo -e "${BLUE}Then run 'godspeed --help' to get started${NC}"
}

# Main installation
install_godspeed

echo -e "${GREEN}🎉 Installation complete!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo "1. godspeed doctor          # Check system status"
echo "2. godspeed setup-global    # Install dev environment"
echo "3. godspeed --help          # View all commands"
EOF

# 3. Create Debian Package Structure
cat > packages/debian/control <<EOF
Package: godspeed
Version: $VERSION_NUM
Section: utils
Priority: optional
Architecture: all
Depends: bash (>= 4.0), git, curl, jq
Maintainer: Godspeed Team <maintainer@godspeed.sh>
Description: Ultimate Full-Stack Development Environment
 Godspeed is an AI-powered development environment that sets up
 your entire tech stack in minutes. Features include project
 templates, AI integration, smart server management, and
 cross-platform compatibility.
EOF

# 4. Create RPM Spec File
cat > packages/rpm/godspeed.spec <<EOF
Name:           godspeed
Version:        $VERSION_NUM
Release:        1%{?dist}
Summary:        Ultimate Full-Stack Development Environment

License:        MIT
URL:            https://github.com/dambu07/godspeed
Source0:        %{name}-%{version}.tar.gz

Requires:       bash >= 4.0, git, curl, jq
BuildArch:      noarch

%description
Godspeed is an AI-powered development environment that sets up
your entire tech stack in minutes. Features include project
templates, AI integration, smart server management, and
cross-platform compatibility.

%prep
%autosetup

%build
# Nothing to build

%install
mkdir -p %{buildroot}%{_bindir}
install -m 755 godspeed.sh %{buildroot}%{_bindir}/godspeed

%files
%license LICENSE
%doc README.md
%{_bindir}/godspeed

%changelog
* $(date "+%a %b %d %Y") Godspeed Team <maintainer@godspeed.sh> - $VERSION_NUM-1
- Initial package
EOF

# 5. Create Arch PKGBUILD
cat > packages/arch/PKGBUILD <<EOF
# Maintainer: Godspeed Team <maintainer@godspeed.sh>
pkgname=godspeed
pkgver=$VERSION_NUM
pkgrel=1
pkgdesc="Ultimate Full-Stack Development Environment with AI Integration"
arch=('any')
url="https://github.com/dambu07/godspeed"
license=('MIT')
depends=('bash>=4.0' 'git' 'curl' 'jq')
source=("\$pkgname-\$pkgver.tar.gz::https://github.com/dambu07/godspeed/archive/refs/tags/v\$pkgver.tar.gz")
sha256sums=('SKIP')

package() {
    cd "\$srcdir/\$pkgname-\$pkgver"
    install -Dm755 godspeed.sh "\$pkgdir/usr/bin/godspeed"
    install -Dm644 LICENSE "\$pkgdir/usr/share/licenses/\$pkgname/LICENSE"
    install -Dm644 README.md "\$pkgdir/usr/share/doc/\$pkgname/README.md"
}
EOF

echo "✅ Repository setup complete!"
echo "📁 Created:"
echo "  - Formula/godspeed.rb (Homebrew formula)"
echo "  - install/install.sh (Universal installer)"
echo "  - packages/debian/control (Debian package)"
echo "  - packages/rpm/godspeed.spec (RPM spec)"
echo "  - packages/arch/PKGBUILD (Arch package)"
EOF

chmod +x scripts/setup-repo.sh
