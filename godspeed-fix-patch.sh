#!/usr/bin/env bash
# Automatic patch to fix known Godspeed.sh errors
set -euo pipefail

echo "🔧 Godspeed Script Auto-Fix Patch"
echo "=================================="

# Fix 1: Replace ${type^} with Bash 3.2 compatible syntax
fix_bash_compatibility(){
  echo "Fixing Bash 3.2 compatibility issues..."
  if [[ -f "godspeed.sh" ]]; then
    # Replace ${type^} with portable capitalization
    sed -i.bak 's/\${type\^}/$(echo ${type:0:1} | tr '\''[:lower:]'\'' '\''[:upper:]'\'')${type:1}/g' godspeed.sh
    
    # Fix unbound variable issues by initializing arrays
    sed -i.bak 's/stacks=(/local stacks=()/g' godspeed.sh
    sed -i.bak 's/frameworks=(/local frameworks=()/g' godspeed.sh
    
    # Replace mapfile with Bash 3.2 compatible version
    sed -i.bak 's/mapfile -t \([^<]*\) < <(\([^)]*\))/local IFS=$'"'"'\n'"'"'; \1=(\2)/g' godspeed.sh
    
    echo "✅ Bash compatibility fixes applied"
  else
    echo "❌ godspeed.sh not found in current directory"
  fi
}

# Fix 2: Ensure proper array initialization
fix_array_initialization(){
  echo "Fixing array initialization..."
  cat >> temp_fix.txt <<'EOF'
# Add at beginning of functions that use arrays
local stacks=()
local frameworks=()
local selected=()
EOF
  echo "✅ Array initialization template created (temp_fix.txt)"
}

# Fix 3: Fix permissions and cleanup
fix_permissions_and_cleanup(){
  echo "Fixing permissions and cleaning up..."
  [[ -f "godspeed.sh" ]] && chmod +x godspeed.sh
  find . -name "*.sh" -type f -exec chmod +x {} + 2>/dev/null || true
  
  # Remove conflicting lock files
  [[ -f yarn.lock && -f package-lock.json ]] && rm -f yarn.lock
  
  # Clean corrupted node_modules if npm ls fails
  if [[ -d node_modules ]] && ! npm ls >/dev/null 2>&1; then
    echo "Cleaning corrupted node_modules..."
    rm -rf node_modules
  fi
  
  echo "✅ Permissions and cleanup completed"
}

# Fix 4: Add missing main() dispatcher entries
fix_main_dispatcher(){
  echo "Fixing main() command dispatcher..."
  if [[ -f "godspeed.sh" ]] && ! grep -q "setup-global\|install-global" godspeed.sh; then
    # Add missing commands to main() function
    sed -i.bak '/help|--help|-h|\*) main_help;;/i\
    setup-global|install-global) godspeed_install_global_tools;;\
    doctor|check) run_system_check;;' godspeed.sh
    echo "✅ Main dispatcher updated with missing commands"
  fi
}

# Execute all fixes
fix_bash_compatibility
fix_array_initialization
fix_permissions_and_cleanup
fix_main_dispatcher

echo ""
echo "🎉 Auto-fix patch completed!"
echo "📝 Backup files created with .bak extension"
echo "🚀 Try running your script again"
