#!/usr/bin/env bash
set -euo pipefail

echo "🧪 Running Godspeed Tests"

# Syntax check
echo "Checking syntax..."
bash -n godspeed.sh || exit 1

echo "✅ All tests passed!"
