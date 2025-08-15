#!/usr/bin/env bash
set -euo pipefail

# Godspeed One-Command Deployment
VERSION="${1:-$(date +%Y.%m.%d)}"

echo "🚀 Godspeed One-Command Deployment v$VERSION"

# Setup repository structure (first time only)
if [[ ! -f "release.sh" ]]; then
  echo "📋 Setting up repository structure..."
  chmod +x setup-repo.sh
  ./setup-repo.sh
fi

# Create and upload release
echo "📦 Creating release packages..."
chmod +x release.sh  
./release.sh "$VERSION"

# Commit and push everything
echo "📤 Pushing to GitHub..."
git add .
git commit -m "Release v$VERSION - Complete package distribution"
git tag -a "v$VERSION" -m "Godspeed v$VERSION release"
git push origin main --tags

# Create GitHub release (requires GitHub CLI or manual)
if command -v gh >/dev/null; then
  echo "🚢 Creating GitHub release..."
  gh release create "v$VERSION" \
    --title "Godspeed v$VERSION" \
    --notes-file RELEASE_NOTES.md \
    dist/*.tar.gz \
    dist/*.zip \
    dist/install.sh \
    "godspeed-${VERSION}-complete.tar.gz"
else
  echo "⚠️  Install GitHub CLI (gh) for automated releases, or create manually at:"
  echo "   https://github.com/dambu07/godspeed/releases/new"
fi

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📦 Users can now install via:"
echo "  • Homebrew: brew tap dambu07/godspeed && brew install godspeed"
echo "  • Chocolatey: choco install godspeed"  
echo "  • Direct: curl -fsSL https://github.com/dambu07/godspeed/releases/latest/download/install.sh | bash"
echo ""
echo "🔗 Next steps:"
echo "1. Submit Homebrew formula to homebrew-core"
echo "2. Submit Chocolatey package to community repository"
echo "3. Update documentation and announce release"
