# 🚀 Godspeed v0.7 - Ultimate Full-Stack Development Shell

**One command to rule them all.** Godspeed is the most advanced, AI-powered development environment that sets up your entire tech stack in minutes, not hours.

![Godspeed Demo](https://img.shields.io/badge/version-0.7-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-green.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## ✨ What Makes Godspeed Special?

- **🎯 Interactive Setup**: Beautiful tick-based selection UI - no more typing complex commands
- **🤖 AI-Powered**: Built-in OpenAI & Perplexity integration for code generation and assistance
- **🌍 Cross-Platform**: Works seamlessly on macOS, Linux, and Windows
- **📱 Mobile-Ready**: Flutter, Android Studio, iOS tools - complete mobile development stack
- **⚡ Lightning Fast**: Auto-detects your project type and launches the right servers instantly
- **🐳 DevOps Ready**: Docker, Kubernetes, Terraform, cloud CLIs - everything included

## 🎬 Quick Demo

Install Godspeed
curl -fsSL https://godspeed.sh/install | bash
Set up your complete development environment
godspeed setup-global
Create a new project
godspeed template react my-awesome-appcd my-awesome-app
Install dependencies and start developing
godspeed installgodspeed go


## 🏗️ What Gets Installed?

### **Programming Languages & Runtimes**
- **Node.js**: Latest LTS with npm, yarn, pnpm
- **Python**: 3.12+ with pip, pipx, poetry, virtual environments
- **PHP**: 8.2+ with Composer, Laravel installer
- **Go**: Latest stable version
- **Rust**: Complete toolchain with Cargo
- **Java**: OpenJDK with Maven/Gradle support
- **Ruby**: Latest with RubyGems
- **.NET**: Core SDK for cross-platform development

### **Mobile Development**
- **Flutter**: Complete SDK with Dart
- **Android Studio**: Full IDE with Android SDK
- **iOS Tools**: Xcode Command Line Tools (macOS)
- **React Native**: CLI and development tools

### **DevOps & Cloud**
- **Docker**: Desktop with Docker Compose
- **Kubernetes**: kubectl, helm, k9s
- **Terraform**: Infrastructure as Code
- **AWS CLI**: Amazon Web Services
- **Azure CLI**: Microsoft Azure
- **Google Cloud SDK**: Google Cloud Platform

### **Development Tools**
- **VS Code**: 20+ essential extensions pre-installed
- **Git**: Version control with GitHub CLI
- **Database Tools**: PostgreSQL, MySQL, MongoDB clients
- **API Tools**: Postman, curl, HTTPie

### **AI Integration**
- **OpenAI GPT-4**: Code generation and assistance
- **Perplexity**: Research and explanation
- **Built-in Chat**: Interactive AI assistant
- **Auto-completion**: AI-powered code suggestions

## 🚀 Installation

### **One-Line Install**
curl -fsSL https://godspeed.sh/install | bash


### **Manual Install**
git clone https://github.com/dambu07/godspeed-ai.gitcd godspeed-ai./install.sh


### **Verify Installation**
godspeed –versiongodspeed doctor  # Check system status


## 📋 Core Commands

### **🔧 Setup Commands**
godspeed setup-global          # Install complete dev environment
godspeed doctor                # Check installation status
godspeed update                # Update all tools and Godspeed


### **🎯 Project Commands**
godspeed template    # Create new project
godspeed install                 # Install project dependencies
godspeed go                      # Start development servers
godspeed build                   # Build for production
godspeed deploy                  # Deploy to cloud


### **🤖 AI Commands**
godspeed ai configure           # Setup AI providers
godspeed ai chat                # Interactive AI assistant
godspeed autopilot              # AI code generation
godspeed tests                  # Generate AI-powered tests


### **🔍 Utility Commands**
godspeed search       # Search GitHub repositories
godspeed find         # Find files in project
godspeed grep         # Search code patterns
godspeed status       # Show running servers
godspeed stop         # Stop all servers
godspeed logs type    # View logs


## 🎨 Project Templates

Godspeed includes 20+ production-ready templates:

### **Frontend**
- ⚛️ React + TypeScript + Tailwind
- 🚀 Next.js + App Router + TypeScript
- 💚 Vue 3 + Composition API + TypeScript
- 🅰️ Angular + Material Design
- ⚡ Vite + React + TypeScript

### **Backend**
- 🐘 Laravel 11 + API + Sanctum
- 🐍 FastAPI + SQLAlchemy + PostgreSQL
- 🟨 Express.js + TypeScript + Prisma
- 🐍 Django + REST Framework
- 🔵 Go + Gin + GORM

### **Full-Stack**
- 🔗 React + Laravel + MySQL
- 🚀 Next.js + Prisma + PostgreSQL
- 🎯 MERN Stack (Complete)
- 🐘 TALL Stack (Tailwind + Alpine + Laravel + Livewire)

### **Mobile**
- 📱 Flutter + Dart (Cross-platform)
- ⚛️ React Native + TypeScript

## 🤖 AI Features

### **Interactive AI Chat**
godspeed ai chat
AI> How do I add authentication to my React app?
AI> Create a responsive navbar component
AI> Explain this error message


### **Code Generation**
godspeed autopilot “Add dark mode toggle”
godspeed autopilot “Implement user authentication”
godspeed autopilot “Create a data dashboard”


### **Test Generation**
godspeed tests unit     # Generate unit tests
godspeed tests e2e      # Generate end-to-end tests


## 🎯 Smart Project Detection

Godspeed automatically detects your project type and configures everything:

Detects React project
godspeed go  # → Starts Vite dev server on port 3000
Detects Laravel project
godspeed go  # → Starts php artisan serve on port 8000
Detects Python FastAPI
godspeed go  # → Starts uvicorn server on port 5000
Detects multiple projects
godspeed go  # → Starts all detected servers simultaneously


## 🔧 Configuration

### **AI Setup**
godspeed ai configure
→ Interactive setup for OpenAI and Perplexity API keys
→ Choose AI features to enable
→ Test configuration


### **Global Settings**
View current configuration
godspeed config show
Set default ports
godspeed config set default_port 3000
Configure deployment targets
godspeed config set deploy_target vercel


## 🌟 Advanced Features

### **Multi-Project Workspace**
Work with multiple projects simultaneously
godspeed workspace create my-workspace
godspeed workspace add frontend-app
godspeed workspace add backend-api
godspeed workspace start  # Starts all projects


### **Plugin System**
Install community plugins
godspeed plugins install theme-switcher
godspeed plugins install git-inspector
godspeed plugins list


### **GitHub Integration**
Search and import repositories
godspeed search “awesome react components”
godspeed search language:Python topic:machine-learning

Import repository
godspeed import facebook/react


## 📊 Performance

- **Setup Time**: Complete dev environment in < 10 minutes
- **Project Creation**: New project ready in < 30 seconds
- **Server Startup**: All services running in < 5 seconds
- **AI Response**: Code generation in < 10 seconds

## 🛠️ Troubleshooting

### **Common Issues**

**Installation fails on macOS:**
Install Xcode Command Line Tools first
xcode-select –install


**Permission denied errors:**
Fix permissions
chmod +x godspeed.sh
sudo chown -R $USER:$GROUP ~/.godspeed


**Servers won't start:**
Check what’s running
godspeed status
godspeed stop    # Stop all servers
godspeed go      # Restart


**AI not working:**
Reconfigure AI
godspeed ai configure
Test connection
godspeed ai chat


### **Get Help**
godspeed doctor     # System diagnostics 
godspeed logs all   # View all logsgodspeed –help     # Show all commands
<!-- chmod +x godspeed.sh
<!-- chmod +x setup-repo.sh release.sh deploy.sh -->
<!-- chmod +x godspeed-fix-patch.sh -->
<!-- ./godspeed-fix-patch.sh -->
<!-- ./godspeed.sh -->