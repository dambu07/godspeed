#!/usr/bin/env bash
set -euo pipefail

# Godspeed Release Automation Script
VERSION="${1:-$(date +%Y.%m.%d)}"
REPO_OWNER="dambu07"
REPO_NAME="godspeed"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

echo "🚀 Godspeed Release Automation v$VERSION"

# Create release directory structure
mkdir -p dist/{macos,linux,windows} packaging/{homebrew,chocolatey}

# ═══════════════════════════════════════════════════════════════════════════════
# PACKAGE THE SCRIPT
# ═══════════════════════════════════════════════════════════════════════════════
echo "📦 Creating distribution packages..."

# Create universal installer script
cat > dist/install.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Godspeed Universal Installer
GODSPEED_DIR="$HOME/development/godspeed"
GODSPEED_URL="https://github.com/dambu07/godspeed/releases/latest/download"

detect_os(){ case "$(uname -s)" in
  Darwin*) echo "macos";;
  Linux*) grep -qi microsoft /proc/version 2>/dev/null && echo "windows" || echo "linux";;
  CYGWIN*|MINGW*) echo "windows";;
  *) echo "unknown";;
esac; }

install_godspeed(){
  local platform=$(detect_os)
  echo "🚀 Installing Godspeed for $platform..."
  
  mkdir -p "$GODSPEED_DIR"
  
  if command -v curl >/dev/null; then
    curl -fsSL "$GODSPEED_URL/godspeed.sh" -o "$GODSPEED_DIR/godspeed.sh"
  elif command -v wget >/dev/null; then
    wget -qO "$GODSPEED_DIR/godspeed.sh" "$GODSPEED_URL/godspeed.sh"
  else
    echo "❌ Neither curl nor wget found. Install one and try again."
    exit 1
  fi
  
  chmod +x "$GODSPEED_DIR/godspeed.sh"
  
  # Add to PATH
  local shell_rc="$HOME/.bashrc"
  [[ -f "$HOME/.zshrc" ]] && shell_rc="$HOME/.zshrc"
  
  if ! grep -q "godspeed" "$shell_rc" 2>/dev/null; then
    echo "" >> "$shell_rc"
    echo "# Godspeed CLI" >> "$shell_rc"
    echo 'export PATH="$HOME/development/godspeed:$PATH"' >> "$shell_rc"
    echo 'alias godspeed="$HOME/development/godspeed/godspeed.sh"' >> "$shell_rc"
  fi
  
  echo "✅ Godspeed installed successfully!"
  echo "📝 Run 'source $shell_rc' or restart your terminal"
  echo "🎯 Usage: godspeed help"
}

install_godspeed
EOF

# Copy main script to dist
cp godspeed.sh dist/

# Create platform-specific packages
tar -czf "dist/godspeed-${VERSION}-macos.tar.gz" -C dist godspeed.sh install.sh
tar -czf "dist/godspeed-${VERSION}-linux.tar.gz" -C dist godspeed.sh install.sh  
zip -j "dist/godspeed-${VERSION}-windows.zip" dist/godspeed.sh dist/install.sh

# ═══════════════════════════════════════════════════════════════════════════════
# HOMEBREW FORMULA
# ═══════════════════════════════════════════════════════════════════════════════
echo "🍺 Creating Homebrew formula..."

# Calculate checksums
MACOS_SHA256=$(shasum -a 256 "dist/godspeed-${VERSION}-macos.tar.gz" | cut -d' ' -f1)
LINUX_SHA256=$(shasum -a 256 "dist/godspeed-${VERSION}-linux.tar.gz" | cut -d' ' -f1)

cat > packaging/homebrew/godspeed.rb <<EOF
class Godspeed < Formula
  desc "Ultimate Full-Stack Development Shell with AI Integration"
  homepage "https://github.com/$REPO_OWNER/$REPO_NAME"
  version "$VERSION"
  license "MIT"

  if OS.mac?
    url "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/v$VERSION/godspeed-$VERSION-macos.tar.gz"
    sha256 "$MACOS_SHA256"
  elsif OS.linux?
    url "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/v$VERSION/godspeed-$VERSION-linux.tar.gz"  
    sha256 "$LINUX_SHA256"
  end

  depends_on "jq"
  depends_on "git"
  depends_on "curl"

  def install
    bin.install "godspeed.sh" => "godspeed"
    prefix.install "install.sh"
    
    # Create godspeed directory
    (var/"godspeed").mkpath
    (var/"godspeed/logs").mkpath
    (var/"godspeed/api_keys").mkpath
  end

  def post_install
    # Set up initial configuration
    system "#{bin}/godspeed", "setup-global", "minimal" if build.with?("setup")
  end

  test do
    assert_match "Godspeed v", shell_output("#{bin}/godspeed --version")
    assert_match "Ultimate Full-Stack", shell_output("#{bin}/godspeed help")
  end

  def caveats
    <<~EOS
      🚀 Godspeed has been installed!
      
      Quick Start:
        godspeed help               # Show all commands
        godspeed template react     # Create React project
        godspeed ai configure       # Setup AI providers
      
      For full setup including development tools:
        godspeed setup-global
    EOS
  end
end
EOF

# ═══════════════════════════════════════════════════════════════════════════════
# CHOCOLATEY PACKAGE  
# ═══════════════════════════════════════════════════════════════════════════════
echo "🍫 Creating Chocolatey package..."

mkdir -p packaging/chocolatey/tools

# Chocolatey nuspec
cat > packaging/chocolatey/godspeed.nuspec <<EOF
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>godspeed</id>
    <version>$VERSION</version>
    <packageSourceUrl>https://github.com/$REPO_OWNER/$REPO_NAME</packageSourceUrl>
    <owners>$REPO_OWNER</owners>
    <title>Godspeed - Ultimate Full-Stack Development Shell</title>
    <authors>$REPO_OWNER</authors>
    <projectUrl>https://github.com/$REPO_OWNER/$REPO_NAME</projectUrl>
    <copyright>2025 $REPO_OWNER</copyright>
    <licenseUrl>https://github.com/$REPO_OWNER/$REPO_NAME/blob/main/LICENSE</licenseUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <projectSourceUrl>https://github.com/$REPO_OWNER/$REPO_NAME</projectSourceUrl>
    <tags>development shell ai automation full-stack laravel react php nodejs python</tags>
    <summary>AI-powered development shell for full-stack projects</summary>
    <description>
Godspeed is an ultimate full-stack development shell that automates project setup, dependency management, and development workflows. Features include:

• AI-powered code generation and assistance
• Multi-language support (Node.js, Python, PHP, Go, Rust, Java)
• Automatic development server management with smart port allocation  
• Built-in security scanning and vulnerability detection
• Project template system for rapid MVP development
• GitHub integration for repository search and import
• Cross-platform support (Windows, macOS, Linux)
    </description>
    <dependencies>
      <dependency id="git" />
    </dependencies>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
EOF

# Chocolatey install script
cat > packaging/chocolatey/tools/chocolateyinstall.ps1 <<EOF
\$ErrorActionPreference = 'Stop'
\$packageName = 'godspeed'
\$version = '$VERSION'
\$url = "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/v\$version/godspeed-\$version-windows.zip"

\$packageArgs = @{
  packageName   = \$packageName
  unzipLocation = \$env:ChocolateyInstall\lib\\$packageName\tools
  url           = \$url
  checksum      = '$(shasum -a 256 "dist/godspeed-${VERSION}-windows.zip" | cut -d' ' -f1)'
  checksumType  = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

# Create godspeed directory in user profile
\$godspeedDir = "\$env:USERPROFILE\development\godspeed"
New-Item -ItemType Directory -Force -Path \$godspeedDir | Out-Null

# Copy script to godspeed directory  
Copy-Item "\$env:ChocolateyInstall\lib\\$packageName\tools\godspeed.sh" \$godspeedDir -Force

# Add to PATH via registry (requires admin)
\$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
\$currentPath = (Get-ItemProperty -Path \$regPath -Name PATH).PATH
if (\$currentPath -notlike "*\$godspeedDir*") {
    Set-ItemProperty -Path \$regPath -Name PATH -Value "\$currentPath;\$godspeedDir"
    Write-Host "Added Godspeed to system PATH. Restart terminal or run 'refreshenv' to use."
}

Write-Host "✅ Godspeed installed successfully!" -ForegroundColor Green
Write-Host "📝 Usage: godspeed help" -ForegroundColor Cyan
Write-Host "🎯 Quick start: godspeed template react my-app" -ForegroundColor Cyan
EOF

# Chocolatey uninstall script
cat > packaging/chocolatey/tools/chocolateyuninstall.ps1 <<'EOF'
$ErrorActionPreference = 'Stop'
$godspeedDir = "$env:USERPROFILE\development\godspeed"

if (Test-Path $godspeedDir) {
    Remove-Item -Recurse -Force $godspeedDir
    Write-Host "Removed Godspeed directory" -ForegroundColor Green
}

# Remove from PATH
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" 
$currentPath = (Get-ItemProperty -Path $regPath -Name PATH).PATH
if ($currentPath -like "*$godspeedDir*") {
    $newPath = $currentPath -replace [regex]::Escape(";$godspeedDir"), ""
    Set-ItemProperty -Path $regPath -Name PATH -Value $newPath
    Write-Host "Removed Godspeed from system PATH" -ForegroundColor Green
}
EOF

# ═══════════════════════════════════════════════════════════════════════════════
# CREATE GITHUB RELEASE
# ═══════════════════════════════════════════════════════════════════════════════
echo "🚢 Creating GitHub release..."

# Create release notes
cat > RELEASE_NOTES.md <<EOF
# Godspeed v$VERSION

Ultimate Full-Stack Development Shell with AI Integration

## 🚀 New Features
- **AI-Powered Development**: Integrated OpenAI and Perplexity for code generation
- **Smart Port Management**: Automatic port allocation for multiple projects
- **Multi-Language Support**: Node.js, Python, PHP, Go, Rust, Java, Flutter, HTML
- **Built-in Plugin System**: 8 core plugins pre-installed  
- **Advanced Security Scanning**: Vulnerability detection and secrets scanning
- **Project Templates**: Ready-to-use templates for popular frameworks

## 📦 Installation

### macOS & Linux (Homebrew)
\`\`\`bash
# Add tap (first time only)
brew tap $REPO_OWNER/homebrew-godspeed

# Install
brew install godspeed
\`\`\`

### Windows (Chocolatey)
\`\`\`powershell
choco install godspeed
\`\`\`

### Universal (Direct)
\`\`\`bash
curl -fsSL https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest/download/install.sh | bash
\`\`\`

## 🎯 Quick Start
\`\`\`bash
godspeed help                    # Show all commands
godspeed template react my-app   # Create React project
godspeed ai configure            # Setup AI providers
godspeed install && godspeed go  # Install deps & start servers
\`\`\`

## 📋 What's Included
- Multi-project development server management
- AI chat assistant with coding context
- Automated dependency resolution
- Security vulnerability scanning  
- GitHub repository search & import
- Project template system
- Cross-platform compatibility

---
**Full Documentation**: [GitHub Repository](https://github.com/$REPO_OWNER/$REPO_NAME)
EOF

# Create archive with all files
echo "📁 Creating release archive..."
tar -czf "godspeed-${VERSION}-complete.tar.gz" \
  godspeed.sh \
  dist/ \
  packaging/ \
  RELEASE_NOTES.md \
  README.md 2>/dev/null || true

echo "✅ Package creation completed!"
echo ""
echo "📦 Created packages:"
echo "  • dist/godspeed-${VERSION}-macos.tar.gz"
echo "  • dist/godspeed-${VERSION}-linux.tar.gz" 
echo "  • dist/godspeed-${VERSION}-windows.zip"
echo "  • dist/install.sh (universal installer)"
echo ""
echo "🍺 Homebrew formula: packaging/homebrew/godspeed.rb"
echo "🍫 Chocolatey package: packaging/chocolatey/"
echo ""
echo "🚀 Next steps:"
echo "1. Create GitHub release: ./release.sh create-release $VERSION"
echo "2. Submit to Homebrew: ./release.sh submit-homebrew"  
echo "3. Submit to Chocolatey: ./release.sh submit-chocolatey"
