#!/usr/bin/env bash
# release.sh - Automated release process for Godspeed
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Godspeed Release Automation${NC}"
echo "==============================="

# Check if we're in the right directory
if [[ ! -f "godspeed.sh" ]]; then
    echo -e "${RED}Error: godspeed.sh not found. Run from repository root.${NC}"
    exit 1
fi

# Check if gh CLI is installed
if ! command -v gh >/dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is required for releases${NC}"
    echo "Install with: brew install gh"
    exit 1
fi

# Get version from command line or prompt
VERSION=${1:-}
if [[ -z "$VERSION" ]]; then
    echo -e "${YELLOW}Enter version (e.g., 0.8.0):${NC}"
    read -r VERSION
fi

# Validate version format
if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid version format. Use semantic versioning (e.g., 0.8.0)${NC}"
    exit 1
fi

FULL_VERSION="v$VERSION"

echo -e "${GREEN}Preparing release $FULL_VERSION...${NC}"

# 1. Run tests
echo -e "${BLUE}1. Running tests...${NC}"
if [[ -f "test/run-tests.sh" ]]; then
    ./test/run-tests.sh
else
    # Basic syntax check
    bash -n godspeed.sh || {
        echo -e "${RED}Syntax error in godspeed.sh${NC}"
        exit 1
    }
fi

# 2. Update version in files
echo -e "${BLUE}2. Updating version references...${NC}"

# Update script header
sed -i.bak "s/# GODSPEED.SH v[0-9]\+\.[0-9]\+/# GODSPEED.SH v$VERSION/g" godspeed.sh

# Update README badges
sed -i.bak "s/version-[0-9]\+\.[0-9]\+\.[0-9]\+-blue/version-$VERSION-blue/g" README.md

# Update package.json if it exists
if [[ -f "package.json" ]]; then
    if command -v jq >/dev/null; then
        jq ".version = \"$VERSION\"" package.json > package.json.tmp && mv package.json.tmp package.json
    fi
fi

# 3. Setup repository for distribution
echo -e "${BLUE}3. Setting up repository structure...${NC}"
./scripts/setup-repo.sh

# 4. Create changelog entry
echo -e "${BLUE}4. Creating changelog...${NC}"
CHANGELOG_FILE="CHANGELOG.md"

if [[ ! -f "$CHANGELOG_FILE" ]]; then
    cat > "$CHANGELOG_FILE" <<EOF
# Changelog

All notable changes to Godspeed will be documented in this file.

## [$FULL_VERSION] - $(date +%Y-%m-%d)

### Added
- Enhanced tick-based UI system
- Improved cross-platform compatibility
- Better error handling and recovery
- Expanded template library

### Changed
- Optimized installation process
- Improved AI integration performance
- Enhanced project detection algorithms

### Fixed
- Various bug fixes and stability improvements
- Better handling of edge cases
EOF
else
    # Add new version to existing changelog
    sed -i.bak "4i\\
\\
## [$FULL_VERSION] - $(date +%Y-%m-%d)\\
\\
### Added\\
- New features and improvements\\
\\
### Changed\\
- Performance optimizations\\
\\
### Fixed\\
- Bug fixes and stability improvements\\
" "$CHANGELOG_FILE"
fi

# 5. Commit changes
echo -e "${BLUE}5. Committing changes...${NC}"
git add .
git commit -m "🚀 Release $FULL_VERSION

- Updated version references
- Generated distribution packages
- Updated changelog
- Prepared release assets"

# 6. Create and push tag
echo -e "${BLUE}6. Creating tag...${NC}"
git tag -a "$FULL_VERSION" -m "Release $FULL_VERSION"
git push origin "$FULL_VERSION"
git push origin main

# 7. Create GitHub release
echo -e "${BLUE}7. Creating GitHub release...${NC}"

# Create release assets
mkdir -p "dist"
cp godspeed.sh "dist/godspeed-$VERSION.sh"
cp install/install.sh "dist/install.sh"

# Create tarball
tar -czf "dist/godspeed-$VERSION.tar.gz" \
    godspeed.sh \
    README.md \
    LICENSE \
    CHANGELOG.md \
    install/ \
    Formula/ \
    packages/

# Create GitHub release
gh release create "$FULL_VERSION" \
    --title "Godspeed $FULL_VERSION" \
    --notes-file CHANGELOG.md \
    --target main \
    "dist/godspeed-$VERSION.sh" \
    "dist/godspeed-$VERSION.tar.gz" \
    "dist/install.sh"

# 8. Update Homebrew tap (if exists)
echo -e "${BLUE}8. Checking for Homebrew tap...${NC}"
if git remote get-url origin | grep -q "dambu07/godspeed"; then
    # Calculate SHA256 for Homebrew formula
    if command -v shasum >/dev/null; then
        SHA256=$(shasum -a 256 "dist/godspeed-$VERSION.tar.gz" | cut -d' ' -f1)
    elif command -v sha256sum >/dev/null; then
        SHA256=$(sha256sum "dist/godspeed-$VERSION.tar.gz" | cut -d' ' -f1)
    fi
    
    # Update formula with new SHA
    if [[ -n "${SHA256:-}" ]]; then
        sed -i.bak "s/sha256 \".*\"/sha256 \"$SHA256\"/" Formula/godspeed.rb
        git add Formula/godspeed.rb
        git commit -m "📦 Update Homebrew formula for $FULL_VERSION"
        git push origin main
    fi
fi

# 9. Cleanup
echo -e "${BLUE}9. Cleaning up...${NC}"
rm -f *.bak
rm -rf dist/

echo -e "${GREEN}🎉 Release $FULL_VERSION completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Release Summary:${NC}"
echo "  • Version: $FULL_VERSION"
echo "  • GitHub Release: https://github.com/dambu07/godspeed/releases/tag/$FULL_VERSION"
echo "  • Install command: curl -fsSL https://raw.githubusercontent.com/dambu07/godspeed/main/install/install.sh | bash"
echo ""
echo -e "${BLUE}📦 Package Installation:${NC}"
echo "  • Homebrew: brew tap dambu07/godspeed && brew install godspeed"
echo "  • Manual: bash <(curl -fsSL https://godspeed.sh/install)"
echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo "  1. Test installation on different platforms"
echo "  2. Update documentation website"
echo "  3. Announce release on social media"
echo "  4. Monitor for issues and feedback"
