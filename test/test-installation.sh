#!/usr/bin/env bash
set -euo pipefail

echo "🧪 Testing Installation"

# Test script is executable
[[ -x godspeed.sh ]] || exit 1

echo "✅ Installation test passed!"
