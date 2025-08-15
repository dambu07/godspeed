#!/usr/bin/env bash
set -euo pipefail

echo "🏗️  Setting up Godspeed repository structure..."

# Create necessary directories
mkdir -p {.github/workflows,docs,examples,tests}

# Create GitHub Actions workflow
cat > .github/workflows/release.yml <<'EOF'
name: Release Godspeed

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:
    inputs:
      version:
        description: 'Release version'
        required: true
        default: '2025.01.01'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Create Release Packages
      run: |
        chmod +x release.sh
        ./release.sh ${{ github.event.inputs.version || github.ref_name }}
    
    - name: Create GitHub Release
      uses: softprops/action-gh-release@v1
      with:
        files: |
          dist/*.tar.gz
          dist/*.zip
          dist/install.sh
          godspeed-*-complete.tar.gz
        body_path: RELEASE_NOTES.md
        draft: false
        prerelease: false
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        
    - name: Upload to Package Registries
      run: |
        echo "Package files ready for manual submission to Homebrew and Chocolatey"
EOF

# Create comprehensive README
cat > README.md <<'EOF'
# 🚀 Godspeed - Ultimate Full-Stack Development Shell

> AI-powered development automation for modern full-stack projects

[![GitHub release](https://img.shields.io/github/release/dambu07/godspeed.svg)](https://github.com/dambu07/godspeed/releases)
[![Homebrew](https://img.shields.io/badge/homebrew-available-brightgreen)](https://github.com/dambu07/homebrew-godspeed)
[![Chocolatey](https://img.shields.io/badge/chocolatey-available-blue)](https://community.chocolatey.org/packages/godspeed)

Godspeed is the ultimate development shell that automates your entire full-stack workflow. From project creation to deployment, with built-in AI assistance and intelligent automation.

## ✨ Features

- 🤖 **AI Integration**: OpenAI & Perplexity for code generation and assistance
- 🚀 **Smart Automation**: Auto-detects and configures any project type
- 🌐 **Multi-Language**: Node.js, Python, PHP, Go, Rust, Java, Flutter support
- 🔧 **Plugin System**: 8 built-in plugins for enhanced functionality
- 🎯 **Port Management**: Smart allocation for multiple concurrent projects
- 🛡️ **Security**: Built-in vulnerability scanning and secret detection
- 📦 **Templates**: Ready-to-use project templates for rapid development

## 📦 Installation

### macOS & Linux (Recommended)
Using Homebrew
brew tap dambu07/godspeed
brew install godspeed
Verify installation
godspeed -version

### Windows
Using Chocolatey
choco install godspeed
Verify installation
godspeed –version

### Universal Install (Any Platform)
curl -fsSL https://raw.githubusercontent.com/dambu07/godspeed/main/install.sh | bash

## 🎯 Quick Start
Create a new React project
godspeed template react my-awesome-app cd my-awesome-app
Install dependencies and start development
godspeed install godspeed go
Configure AI assistance
godspeed ai configure
Generate tests with AI
godspeed tests unit
Deploy to Vercel
godspeed deploy vercel


## 🔧 Core Commands

| Command | Description |
|---------|-------------|
| `godspeed install` | Install all project dependencies |
| `godspeed go` | Start development servers |
| `godspeed ai chat` | Interactive AI coding assistant |
| `godspeed template <type>` | Create project from template |
| `godspeed build` | Smart build with optimization |
| `godspeed deploy` | Deploy to various platforms |
| `godspeed scan` | Security vulnerability scan |
| `godspeed search <term>` | Search GitHub repositories |

## 🌟 Built-in Plugins

- **AI Chat Assistant** - Interactive coding help
- **Clipboard Manager** - Advanced clipboard with history  
- **Error Viewer** - Centralized error tracking
- **Git Inspector** - Visual Git workflow analysis
- **System Monitor** - Real-time performance monitoring
- **Terminal Console** - Enhanced terminal interface
- **Theme Switcher** - Customizable UI themes
- **Todo Manager** - Project task management

## 🏗️ Project Templates

- **React** - TypeScript + Tailwind CSS + Modern tooling
- **Laravel** - PHP 8.2 + optimized configuration
- **Next.js** - App router + TypeScript + Tailwind  
- **Python** - FastAPI + SQLAlchemy + modern Python
- **Full-Stack** - React frontend + Laravel backend + Docker

## 🤖 AI Integration

Godspeed integrates with leading AI providers for intelligent development assistance:
Configure AI providers
godspeed ai configure
Interactive coding chat
godspeed ai chat
AI-powered code generation
godspeed autopilot “add dark mode toggle to my React app”
Generate comprehensive tests
godspeed tests integration

## 🔒 Security Features

- **Secret Detection** - Scans for API keys and credentials
- **Dependency Auditing** - Checks for vulnerable packages
- **File Sensitivity** - Identifies sensitive files
- **Automated Reports** - Security insights and recommendations

## 🚀 Advanced Usage

### Multi-Project Development
Terminal 1: Laravel API (port 8000)
cd my-laravel-api && godspeed go
Terminal 2: React Frontend (port 3000)
cd my-react-app && godspeed go
Terminal 3: Python Service (port 5000)
cd my-python-service && godspeed go
View all running servers
godspeed status


### CI/CD Integration
.github/workflows/ci.yml
	•	name: Setup Godspeed run: | curl -fsSL https://raw.githubusercontent.com/dambu07/godspeed/main/install.sh | bash godspeed install
	•	name: Run Tests & Build run: | godspeed tests godspeed build godspeed scan



## 📚 Documentation

- [Installation Guide](docs/installation.md)
- [Configuration](docs/configuration.md)  
- [AI Setup](docs/ai-integration.md)
- [Plugin Development](docs/plugins.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🌟 Support

- ⭐ Star this repository
- 🐛 [Report bugs](https://github.com/dambu07/godspeed/issues)
- 💡 [Request features](https://github.com/dambu07/godspeed/issues)
- 💬 [Join discussions](https://github.com/dambu07/godspeed/discussions)

---

**Built with ❤️ for the developer community**
EOF

# Create MIT License
cat > LICENSE <<'EOF'
MIT License

Copyright (c) 2025 dambu07

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

echo "✅ Repository structure created!"
echo "📝 Edit README.md and customize for your needs"
echo "🚀 Run: git add . && git commit -m 'Initial release setup'"
