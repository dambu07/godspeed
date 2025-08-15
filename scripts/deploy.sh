#!/usr/bin/env bash
# deploy.sh - Deploy Godspeed to various package repositories
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🌐 Godspeed Deployment Automation${NC}"
echo "================================="

VERSION=${1:-$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.7.0")}
VERSION_NUM=${VERSION#v}

echo -e "${GREEN}Deploying Godspeed $VERSION to package repositories...${NC}"

# 1. Deploy to Homebrew Tap
deploy_homebrew() {
    echo -e "${BLUE}📦 Deploying to Homebrew tap...${NC}"
    
    # Check if tap repository exists
    if git remote get-url homebrew 2>/dev/null || [[ -d "../homebrew-godspeed" ]]; then
        echo "Found Homebrew tap repository"
        
        # Copy formula
        if [[ -d "../homebrew-godspeed" ]]; then
            cp Formula/godspeed.rb ../homebrew-godspeed/Formula/
            cd ../homebrew-godspeed
        else
            # Clone tap if needed
            git clone git@github.com:dambu07/homebrew-godspeed.git ../homebrew-godspeed
            cp Formula/godspeed.rb ../homebrew-godspeed/Formula/
            cd ../homebrew-godspeed
        fi
        
        git add Formula/godspeed.rb
        git commit -m "Update godspeed formula to $VERSION"
        git push origin main
        cd - >/dev/null
        
        echo -e "${GREEN}✅ Homebrew tap updated${NC}"
    else
        echo -e "${YELLOW}⚠️ Homebrew tap not found. Create one with:${NC}"
        echo "gh repo create homebrew-godspeed --public"
        echo "git clone git@github.com:dambu07/homebrew-godspeed.git"
    fi
}

# 2. Deploy to AUR (Arch User Repository)
deploy_aur() {
    echo -e "${BLUE}📦 Preparing AUR package...${NC}"
    
    if [[ ! -d "../aur-godspeed" ]]; then
        echo "Creating AUR package directory..."
        mkdir -p ../aur-godspeed
    fi
    
    cp packages/arch/PKGBUILD ../aur-godspeed/
    cd ../aur-godspeed
    
    # Generate .SRCINFO
    if command -v makepkg >/dev/null; then
        makepkg --printsrcinfo > .SRCINFO
    fi
    
    cd - >/dev/null
    
    echo -e "${GREEN}✅ AUR package prepared${NC}"
    echo -e "${YELLOW}Manual step: Submit to AUR repository${NC}"
}

# 3. Create installation packages
create_packages() {
    echo -e "${BLUE}📦 Creating distribution packages...${NC}"
    
    mkdir -p dist/{deb,rpm}
    
    # Create Debian package
    echo "Creating Debian package..."
    mkdir -p "dist/deb/godspeed-$VERSION_NUM"/{DEBIAN,usr/bin}
    
    cp packages/debian/control "dist/deb/godspeed-$VERSION_NUM/DEBIAN/"
    cp godspeed.sh "dist/deb/godspeed-$VERSION_NUM/usr/bin/godspeed"
    chmod +x "dist/deb/godspeed-$VERSION_NUM/usr/bin/godspeed"
    
    # Update control file with correct version
    sed -i "s/Version: .*/Version: $VERSION_NUM/" "dist/deb/godspeed-$VERSION_NUM/DEBIAN/control"
    
    if command -v dpkg-deb >/dev/null; then
        dpkg-deb --build "dist/deb/godspeed-$VERSION_NUM" "dist/godspeed_${VERSION_NUM}_all.deb"
        echo -e "${GREEN}✅ Debian package created: dist/godspeed_${VERSION_NUM}_all.deb${NC}"
    fi
    
    # Create RPM spec
    echo "Preparing RPM package..."
    mkdir -p dist/rpm/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    
    # Create source tarball
    tar -czf "dist/rpm/SOURCES/godspeed-$VERSION_NUM.tar.gz" \
        --transform "s,^,godspeed-$VERSION_NUM/," \
        godspeed.sh README.md LICENSE
    
    cp packages/rpm/godspeed.spec dist/rpm/SPECS/
    
    if command -v rpmbuild >/dev/null; then
        rpmbuild --define "_topdir $(pwd)/dist/rpm" -ba dist/rpm/SPECS/godspeed.spec
        echo -e "${GREEN}✅ RPM package created in dist/rpm/RPMS/${NC}"
    fi
}

# 4. Update installation script CDN
update_cdn() {
    echo -e "${BLUE}🌐 Updating CDN installation script...${NC}"
    
    # Update raw GitHub URLs to latest
    sed "s|/main/|/$VERSION/|g" install/install.sh > dist/install-$VERSION.sh
    
    echo -e "${GREEN}✅ Installation script updated${NC}"
    echo "Upload dist/install-$VERSION.sh to your CDN"
}

# 5. Deploy to package managers
deploy_package_managers() {
    echo -e "${BLUE}📦 Deploying to package managers...${NC}"
    
    # Snap package preparation
    if command -v snapcraft >/dev/null; then
        echo "Preparing Snap package..."
        
        cat > snapcraft.yaml <<EOF
name: godspeed
base: core20
version: '$VERSION_NUM'
summary: Ultimate Full-Stack Development Environment
description: |
  Godspeed is an AI-powered development environment that sets up
  your entire tech stack in minutes.

grade: stable
confinement: classic

parts:
  godspeed:
    plugin: dump
    source: .
    organize:
      godspeed.sh: bin/godspeed

apps:
  godspeed:
    command: bin/godspeed
EOF
        
        echo -e "${YELLOW}Snap package prepared. Run 'snapcraft' to build.${NC}"
    fi
    
    # Flatpak preparation
    echo "Preparing Flatpak manifest..."
    cat > io.github.dambu07.godspeed.yml <<EOF
app-id: io.github.dambu07.godspeed
runtime: org.freedesktop.Sdk
runtime-version: '21.08'
sdk: org.freedesktop.Sdk
command: godspeed

modules:
  - name: godspeed
    buildsystem: simple
    build-commands:
      - install -Dm755 godspeed.sh /app/bin/godspeed
    sources:
      - type: file
        path: godspeed.sh
EOF
    
    echo -e "${GREEN}✅ Flatpak manifest created${NC}"
}

# 6. Update documentation and website
update_docs() {
    echo -e "${BLUE}📝 Updating documentation...${NC}"
    
    # Update installation URLs in README
    sed -i.bak "s|https://raw.githubusercontent.com/dambu07/godspeed/[^/]*/|https://raw.githubusercontent.com/dambu07/godspeed/$VERSION/|g" README.md
    
    echo -e "${GREEN}✅ Documentation updated${NC}"
}

# Main deployment process
main() {
    echo -e "${BLUE}Starting deployment process...${NC}"
    
    # Check prerequisites
    if [[ ! -f "godspeed.sh" ]]; then
        echo -e "${RED}Error: Run from repository root${NC}"
        exit 1
    fi
    
    # Run deployment steps
    deploy_homebrew
    deploy_aur
    create_packages
    update_cdn
    deploy_package_managers
    update_docs
    
    echo ""
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}📋 Deployment Summary:${NC}"
    echo "  • Homebrew tap updated"
    echo "  • AUR package prepared"
    echo "  • Debian/RPM packages created"
    echo "  • Installation script updated"
    echo "  • Snap/Flatpak manifests created"
    echo ""
    echo -e "${BLUE}📦 Installation Methods:${NC}"
    echo "  • Homebrew: brew tap dambu07/godspeed && brew install godspeed"
    echo "  • Curl: curl -fsSL https://godspeed.sh/install | bash"
    echo "  • Wget: wget -qO- https://godspeed.sh/install | bash"
    echo "  • Debian: dpkg -i godspeed_${VERSION_NUM}_all.deb"
    echo ""
    echo -e "${BLUE}🚀 Manual Steps Remaining:${NC}"
    echo "  1. Upload packages to release page"
    echo "  2. Submit AUR package"
    echo "  3. Build and publish Snap package"
    echo "  4. Update website with new version"
    echo "  5. Announce release"
}

# Run main deployment
main "$@"
