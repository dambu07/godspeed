#!/usr/bin/env bash
# shellcheck disable=SC2155,SC2002
set -euo pipefail

################################################################################
# GODSPEED.SH v0.7 — Ultimate Full-Stack Dev Shell (Optimized & Automated)
# Front-end name: "Godspeed AI" (provider-agnostic). All features included.
################################################################################

# ═══════════════════════════════════════════════════════════════════════════════
# CORE CONFIGURATION & GLOBAL VARIABLES
# ═══════════════════════════════════════════════════════════════════════════════
readonly GS_DIR="$HOME/development/godspeed"
readonly GS_SCRIPT="$GS_DIR/godspeed.sh"
readonly GS_MEM="$GS_DIR/.gs_memory"
readonly GS_LOG="$GS_DIR/logs/error.log"
readonly GS_REGISTRY="$GS_DIR/.godspeed.registry.json"
readonly PROJ_CFG=".godspeed.project"
readonly API_KEYS_DIR="$GS_DIR/api_keys"
readonly API_KEYS_FILE="$GS_DIR/.gs_apikeys"
PLATFORM="unknown"

init_dirs(){ mkdir -p "$GS_DIR/logs" "$API_KEYS_DIR" "$GS_DIR/ports" 2>/dev/null || true; }
detect_os(){ case "$(uname -s)" in
  Darwin*) PLATFORM="macos";;
  Linux*) grep -qi microsoft /proc/version 2>/dev/null && PLATFORM="windows" || PLATFORM="linux";;
  CYGWIN*|MINGW*) PLATFORM="windows";;
esac; }

# ═══════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS & HELPERS
# ═══════════════════════════════════════════════════════════════════════════════
log_cmd(){ echo "[$(date '+%H:%M:%S')] $1" | tee -a "$GS_LOG"; }
run_cmd(){ log_cmd "Running: $1"; eval "$1" 2>>"$GS_LOG" || { log_cmd "Failed: $1"; return 1; }; }
safe_cmd(){ "$@" 2>/dev/null || true; }
check_file(){ [[ -f "$1" ]]; }
check_dir(){ [[ -d "$1" ]]; }
project_name(){ basename "$(pwd)"; }

# ═══════════════════════════════════════════════════════════════════════════════
# CROSS-PLATFORM USER INTERFACE
# ═══════════════════════════════════════════════════════════════════════════════
gs_prompt(){ local title="Godspeed v0.7" text="$1" default="${2:-}" result=""
  export TEXT="$text" DEFAULT="$default"
  if [[ "$PLATFORM" == "macos" ]] && command -v osascript >/dev/null; then
    result=$(osascript <<'EOF' 2>/dev/null || echo "$default"
try
  set answer to text returned of (display dialog (system attribute "TEXT") default answer (system attribute "DEFAULT") with title "Godspeed v0.7")
  return answer
on error
  return system attribute "DEFAULT"
end try
EOF
    )
  elif command -v zenity >/dev/null; then
    result=$(zenity --entry --title="$title" --text="$text" --entry-text="$default" 2>/dev/null || echo "$default")
  else
    read -rp "$text [${default}]: " result; result="${result:-$default}"
  fi; echo "$result"
}

gs_confirm(){ local title="Godspeed v0.7" q="$1"
  if [[ "$PLATFORM" == "macos" ]] && command -v osascript >/dev/null; then
    osascript -e "display dialog \"$q\" buttons {\"No\", \"Yes\"} default button \"Yes\" with title \"$title\"" 2>/dev/null | grep -q "Yes"
  elif command -v zenity >/dev/null; then
    zenity --question --title="$title" --text="$q" 2>/dev/null
  else
    read -rp "$q [y/N]: " yn; [[ "$yn" =~ ^[Yy]$ ]]
  fi
}

gs_tick_select() {
  local prompt="$1"
  shift
  local options=("$@")
  local selected=()
  local current=0
  local toggle_all=false
  local ESC=$'\033'
  
  for i in "${!options[@]}"; do selected[i]=false; done
  while true; do
    clear
    echo -e "\n🔧 Install: $prompt"
    echo ""
    for i in "${!options[@]}"; do
      local mark="☐"
      [[ "${selected[i]}" == "true" ]] && mark="☑"
      [[ $i -eq $current ]] && echo "  → $mark ${options[i]}" || echo "    $mark ${options[i]}"
    done
    echo -e "\nSelected: $(get_selected_count "${selected[@]}")/${#options[@]}"
    echo "[SPACE] toggle | [A] all/none | [ENTER] OK | [Q] Cancel"
    read -s -n1 key
    case "$key" in
      $ESC) read -s -n2 key; case "$key" in
        "[A") ((current > 0)) && ((current--));;  # up
        "[B") ((current < ${#options[@]} - 1)) && ((current++));;  # down
      esac;;
      " ") selected[current]=$([[ "${selected[current]}" == "true" ]] && echo "false" || echo "true");;
      [aA]) # all/none toggle
        toggle_all=$([[ "$toggle_all" == "false" ]] && echo "true" || echo "false")
        for i in "${!options[@]}"; do selected[i]=$toggle_all; done;;
      "") # Enter confirms
        break;;
      [qQ]) # Cancel
        return 1;;
    esac
  done
  local result=()
  for i in "${!options[@]}"; do [[ "${selected[i]}" == "true" ]] && result+=("${options[i]}"); done
  printf '%s\n' "${result[@]}"
}
get_selected_count() {
  local count=0; for x in "$@"; do [[ "$x" == "true" ]] && ((count++)); done; echo "$count"
}

gs_notify(){ local msg="$1"
  safe_cmd osascript -e "display notification \"$msg\" with title \"Godspeed\"" ||
  safe_cmd notify-send "Godspeed" "$msg"
  echo "[Godspeed] $msg"
}

# ═══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE TICK-BASED SELECTION SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════
gs_multi_select(){
  local title="$1" prompt="$2"
  shift 2
  local options=("$@")
  local selected=()
  local current=0
  local toggle_all=false
  for i in "${!options[@]}"; do selected[i]=false; done
  while true; do
    clear
    echo "🔧 $title"
    echo "$prompt"
    echo ""
    echo "Use ↑/↓ arrows, SPACE to toggle, A for all/none, ENTER to confirm:"
    echo ""
    for i in "${!options[@]}"; do
      local checkbox="☐"
      [[ "${selected[i]}" == "true" ]] && checkbox="☑"
      if [[ $i -eq $current ]]; then
        echo "  → $checkbox ${options[i]}"
      else
        echo "    $checkbox ${options[i]}"
      fi
    done
    echo ""
    echo "Selected: $(get_selected_count "${selected[@]}")/${#options[@]} items"
    echo ""
    echo "[SPACE] Toggle  [A] All/None  [ENTER] Continue  [Q] Quit"
    read -n1 -s key
    case "$key" in
      $'\033')
        read -n1 -s key
        if [[ "$key" == "[" ]]; then
          read -n1 -s key
          case "$key" in
            A) ((current > 0)) && ((current--));;
            B) ((current < ${#options[@]} - 1)) && ((current++));;
          esac
        fi;;
      " ")
        if [[ "${selected[current]}" == "true" ]]; then selected[current]=false; else selected[current]=true; fi;;
      [aA])
        if [[ "$toggle_all" == "false" ]]; then
          for i in "${!selected[@]}"; do selected[i]=true; done; toggle_all=true
        else
          for i in "${!selected[@]}"; do selected[i]=false; done; toggle_all=false
        fi;;
      "")
        break;;
      [qQ])
        return 1;;
    esac
  done
  local result=()
  for i in "${!options[@]}"; do [[ "${selected[i]}" == "true" ]] && result+=("${options[i]}"); done
  printf '%s\n' "${result[@]}"
}

get_selected_count(){
  local count=0
  for item in "$@"; do [[ "$item" == "true" ]] && ((count++)); done
  echo "$count"
}

gs_single_select(){
  local title="$1" prompt="$2"
  shift 2
  local options=("$@")
  local current=0
  while true; do
    clear
    echo "🎯 $title"
    echo "$prompt"
    echo ""
    echo "Use ↑/↓ arrows, ENTER to select, Q to quit:"
    echo ""
    for i in "${!options[@]}"; do
      local radio="○"
      [[ $i -eq $current ]] && radio="●"
      if [[ $i -eq $current ]]; then
        echo "  → $radio ${options[i]}"
      else
        echo "    $radio ${options[i]}"
      fi
    done
    echo ""
    echo "[↑/↓] Navigate  [ENTER] Select  [Q] Quit"
    read -n1 -s key
    case "$key" in
      $'\033')
        read -n1 -s key
        if [[ "$key" == "[" ]]; then
          read -n1 -s key
          case "$key" in
            A) ((current > 0)) && ((current--));;
            B) ((current < ${#options[@]} - 1)) && ((current++));;
          esac
        fi;;
      "")
        echo "${options[current]}"
        return 0;;
      [qQ])
        return 1;;
    esac
  done
}

gs_confirm_enhanced(){
  local title="$1" message="$2" default="${3:-yes}"
  local current=0
  local options=("Yes" "No")
  [[ "$default" == "no" ]] && current=1
  while true; do
    clear
    echo "❓ $title"
    echo "$message"
    echo ""
    for i in "${!options[@]}"; do
      local radio="○"
      [[ $i -eq $current ]] && radio="●"
      if [[ $i -eq $current ]]; then
        echo "  → $radio ${options[i]}"
      else
        echo "    $radio ${options[i]}"
      fi
    done
    echo ""
    echo "[←/→] Navigate  [ENTER] Select  [Y/N] Quick select"
    read -n1 -s key
    case "$key" in
      $'\033')
        read -n1 -s key
        if [[ "$key" == "[" ]]; then
          read -n1 -s key
          case "$key" in
            C) current=0;;
            D) current=1;;
          esac
        fi;;
      "")
        [[ $current -eq 0 ]] && return 0 || return 1;;
      [yY])
        return 0;;
      [nN])
        return 1;;
    esac
  done
}

# ═══════════════════════════════════════════════════════════════════════════════
# SMART PORT MANAGEMENT SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════
get_next_port(){ local base=$1 port=$base
  while lsof -i :"$port" >/dev/null 2>&1; do ((port++)); done; echo "$port"
}

store_port(){ local type="$1" port="$2" project="$(project_name)"
  echo "$project:$port:$(date +%s):$(pwd)" >> "$GS_DIR/ports/${type}_ports.log"
}

show_servers(){ echo "🌐 Active Development Servers:"
  for type in node php python html; do
    local log="$GS_DIR/ports/${type}_ports.log"
    [[ -f "$log" ]] || continue
    # Fixed: Replace $(echo ${type:0:1} | tr '[:lower:]' '[:upper:]')${type:1} with portable capitalization
    echo "  $(echo ${type:0:1} | tr '[:lower:]' '[:upper:]')${type:1}:" && tail -5 "$log" | while IFS=: read -r project port timestamp path; do
      lsof -i :"$port" >/dev/null 2>&1 && echo "    • $project → http://localhost:$port"
    done
  done
}

get_latest_port(){ for log in "$GS_DIR/ports"/*_ports.log; do
  [[ -f "$log" ]] || continue
  local entry=$(tail -1 "$log" 2>/dev/null) port=$(echo "$entry" | cut -d: -f2)
  lsof -i :"$port" >/dev/null 2>&1 && echo "$port" && return; done
}

# ═══════════════════════════════════════════════════════════════════════════════
# KEY-VALUE STORAGE & API MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════
set_mem(){ echo "$1:$2" >> "$GS_MEM"; }
get_mem(){ grep -E "^$1:" "$GS_MEM" 2>/dev/null | tail -1 | cut -d: -f2- || true; }
set_cfg(){ echo "$1:$2" >> "$PROJ_CFG"; }
get_cfg(){ grep -E "^$1:" "$PROJ_CFG" 2>/dev/null | tail -1 | cut -d: -f2- || true; }
set_apikey(){ echo "$2" > "$API_KEYS_DIR/$1"; chmod 600 "$API_KEYS_DIR/$1" 2>/dev/null; }
get_apikey(){ local v=""
  [[ -f "$API_KEYS_DIR/$1" ]] && v=$(cat "$API_KEYS_DIR/$1" 2>/dev/null || true)
  [[ -z "$v" && -f "$API_KEYS_FILE" ]] && v=$(grep -E "^$1:" "$API_KEYS_FILE" 2>/dev/null | tail -1 | cut -d: -f2- || true)
  echo "$v"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ARTIFICIAL INTELLIGENCE INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════════
ai_call(){ local provider="$1" prompt="$2" key model endpoint
  case "$provider" in
    openai) key=$(get_apikey openai); model="gpt-4o"; endpoint="https://api.openai.com/v1/chat/completions";;
    perplexity) key=$(get_apikey perplexity); model="llama-3.1-sonar-huge-128k-online"; endpoint="https://api.perplexity.ai/chat/completions";;
    *) return 1;;
  esac
  [[ -z "$key" ]] && return 1
  curl -sS "$endpoint" -H "Authorization: Bearer $key" -H "Content-Type: application/json" \
    -d "$(jq -n --arg m "$prompt" --arg model "$model" '{model:$model,messages:[{role:"user",content:$m}]}')" 2>/dev/null |
    jq -r '.choices[0].message.content // empty' 2>/dev/null || echo ""
}

select_provider(){ local o=$(get_apikey openai) p=$(get_apikey perplexity)
  if [[ -n "$o" && -n "$p" ]]; then
    case "${1:-}" in explain|suggest|search) echo "perplexity";; *) echo "openai";; esac
  elif [[ -n "$o" ]]; then echo "openai"
  elif [[ -n "$p" ]]; then echo "perplexity"
  else echo ""; fi
}

ai_configure(){ detect_os; echo "🤖 Configure Godspeed AI"
  local k; k=$(gs_prompt "OpenAI API Key (gpt-4o)")
  [[ -n "$k" ]] && set_apikey openai "$k"
  k=$(gs_prompt "Perplexity API Key (llama-3.1)")
  [[ -n "$k" ]] && set_apikey perplexity "$k"
  gs_notify "✅ AI configured successfully"
}

ai_chat(){ echo "🧠 Godspeed AI — type 'exit' to quit"; local prov=$(select_provider chat)
  [[ -z "$prov" ]] && { gs_notify "Configure AI first: godspeed ai configure"; return 1; }
  while true; do
    read -rp "AI> " q || break
    [[ "$q" == "exit" ]] && break; [[ -z "$q" ]] && continue
    local out=$(ai_call "$prov" "$q")
    echo -e "\n${out:-No response}\n" | tee -a "$GS_DIR/logs/ai_chat.log"
  done
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROJECT STACK DETECTION & ANALYSIS
# ═══════════════════════════════════════════════════════════════════════════════
detect_stacks(){ local local stacks=())
  check_file package.json && stacks+=(nodejs)
  (check_file requirements.txt || check_file pyproject.toml || check_file Pipfile) && stacks+=(python)
  (check_file composer.json || check_file index.php) && stacks+=(php)
  check_file pubspec.yaml && stacks+=(flutter)
  check_file go.mod && stacks+=(golang)
  check_file Cargo.toml && stacks+=(rust)
  (check_file build.gradle || check_file pom.xml) && stacks+=(java)
  (check_file index.html && ! check_file package.json && ! check_file composer.json) && stacks+=(html)
  printf '%s\n' "${stacks[@]}"
}

detect_frameworks(){ check_file package.json || return 0
  local local frameworks=())
  grep -q 'react' package.json 2>/dev/null && frameworks+=(react)
  grep -q 'next' package.json 2>/dev/null && frameworks+=(nextjs)
  grep -q 'vue' package.json 2>/dev/null && frameworks+=(vue)
  grep -q 'express' package.json 2>/dev/null && frameworks+=(express)
  grep -q 'tailwind' package.json 2>/dev/null && frameworks+=(tailwindcss)
  printf '%s\n' "${frameworks[@]}"
}

analyze_project(){ local project="$(project_name)" stacks frameworks
  # Bash 3.2 compatible array population
  local IFS=$'\n'
  local stacks=()$(detect_stacks))
  local frameworks=()$(detect_frameworks))
  echo "📊 Project Analysis: $project"
  echo "  Stacks: ${stacks[*]:-none}"
  echo "  Frameworks: ${frameworks[*]:-none}"
  printf '%s\n' "${stacks[@]}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# AUTOMATED ENVIRONMENT SETUP
# ═══════════════════════════════════════════════════════════════════════════════
setup_env(){ 
  check_file .env.example && ! check_file .env && cp .env.example .env
  if ! check_file .env; then
    cat > .env <<'EOF'
NODE_ENV=development
PORT=3000
API_PORT=5000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dev_db
DB_USER=dev
DB_PASS=devpass
JWT_SECRET=dev_jwt_secret
EOF
  fi
  grep -q '^\.env$' .gitignore 2>/dev/null || echo ".env" >> .gitignore
}

setup_dirs(){ mkdir -p logs tmp storage public/uploads assets dist build; }

setup_configs(){ 
  check_file .gitignore || cat > .gitignore <<'EOF'
.env
node_modules/
vendor/
venv/
.venv/
.DS_Store
logs/
dist/
build/
.next/
EOF
  check_file README.md || cat > README.md <<EOF
# $(project_name)

Bootstrapped by Godspeed v0.7

## Quick Start
\`\`\`bash
godspeed install
godspeed go
\`\`\`
EOF
}

cleanup_deps(){
  # Remove conflicting lock files
  check_file package.json && check_file package-lock.json && check_file yarn.lock && rm -f yarn.lock
  # Clean corrupted node_modules
  check_dir node_modules && ! npm ls >/dev/null 2>&1 && rm -rf node_modules
  # Clean pip cache
  safe_cmd pip cache purge
  # Clean corrupted composer vendor
  check_dir vendor && ! composer validate >/dev/null 2>&1 && rm -rf vendor
}

fix_permissions(){
  find . -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
  check_dir storage && chmod -R 755 storage 2>/dev/null || true
  check_dir bootstrap/cache && chmod -R 755 bootstrap/cache 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCY RESOLUTION SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════
resolve_deps(){ local local stacks=()$(analyze_project))
  for stack in "${stacks[@]}"; do
    case "$stack" in
      nodejs) resolve_node;;
      python) resolve_python;;
      php) resolve_php;;
      flutter) resolve_flutter;;
      golang) resolve_go;;
      rust) resolve_rust;;
      java) resolve_java;;
    esac
  done
}

resolve_node(){ check_file package.json || return; local pm="npm"
  check_file yarn.lock && pm=yarn
  check_file pnpm-lock.yaml && pm=pnpm
  case "$pm" in
    yarn) yarn install || { yarn cache clean; rm -rf node_modules; yarn install --network-timeout 100000; };;
    pnpm) pnpm install || { pnpm store prune; rm -rf node_modules; pnpm install; };;
    *) npm install || { npm cache clean --force; rm -rf node_modules package-lock.json; npm install --legacy-peer-deps || npm install --force; };;
  esac
}

resolve_python(){ (check_file requirements.txt || check_file pyproject.toml || check_file Pipfile) || return
  check_dir venv || check_dir .venv || python3 -m venv venv 2>/dev/null || python -m venv venv
  # shellcheck disable=SC1091
  source venv/bin/activate 2>/dev/null || source venv/Scripts/activate 2>/dev/null || true
  check_file requirements.txt && { pip install -r requirements.txt || { pip install --upgrade pip; pip install --no-cache-dir -r requirements.txt; }; }
  check_file pyproject.toml && pip install -e . || true
  check_file Pipfile && { pip install pipenv && pipenv install; } || true
}

resolve_php(){ check_file composer.json || return
  command -v composer >/dev/null || { curl -sS https://getcomposer.org/installer | php; alias composer='php composer.phar'; }
  composer install --no-interaction || { composer clear-cache; rm -rf vendor composer.lock; composer install --no-scripts --ignore-platform-reqs; }
}

resolve_flutter(){ check_file pubspec.yaml && command -v flutter >/dev/null && flutter pub get || true; }
resolve_go(){ check_file go.mod && go mod tidy || true; }
resolve_rust(){ check_file Cargo.toml && cargo build || true; }
resolve_java(){
  check_file pom.xml && command -v mvn >/dev/null && mvn -q -DskipTests clean install || true
  (check_file build.gradle || check_file build.gradle.kts) && { chmod +x ./gradlew 2>/dev/null; ./gradlew build 2>/dev/null || { command -v gradle >/dev/null && gradle build; }; } || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# INTELLIGENT DEVELOPMENT SERVER LAUNCHER
# ═══════════════════════════════════════════════════════════════════════════════
launch_servers(){ local local stacks=()$(analyze_project))
  start_databases
  for stack in "${stacks[@]}"; do
    case "$stack" in
      nodejs) launch_node;;
      python) launch_python;;
      php) launch_php;;
      html) launch_html;;
    esac
  done
  sleep 2; show_status
}

launch_node(){ check_file package.json || return
  local port=$(get_next_port 3000) project="$(project_name)"
  log_cmd "🚀 Starting Node.js server: $project on port $port"
  
  if grep -q '"dev"' package.json 2>/dev/null; then
    PORT="$port" npm run dev > "logs/dev-$port.log" 2>&1 &
  elif grep -q 'vite' package.json 2>/dev/null; then
    npx vite --port "$port" > "logs/vite-$port.log" 2>&1 &
  elif grep -q '"start"' package.json 2>/dev/null; then
    PORT="$port" npm start > "logs/start-$port.log" 2>&1 &
  else
    npx serve -s build -l "$port" > "logs/serve-$port.log" 2>&1 &
  fi
  
  check_file server.js && { local api_port=$(get_next_port 3100)
    PORT="$api_port" node server.js > "logs/backend-$api_port.log" 2>&1 &
    store_port "node_api" "$api_port"; }
  
  store_port "node" "$port"
  echo "✅ Node.js: http://localhost:$port"
}

launch_python(){ (check_file app.py || check_file main.py || check_file manage.py || check_file app/__init__.py) || return
  local port=$(get_next_port 5000) project="$(project_name)"
  log_cmd "🚀 Starting Python server: $project on port $port"
  
  # shellcheck disable=SC1091
  source venv/bin/activate 2>/dev/null || source .venv/bin/activate 2>/dev/null || true
  
  if check_file app.py; then
    FLASK_ENV=development FLASK_APP=app.py flask run --port="$port" > "logs/flask-$port.log" 2>&1 &
  elif check_file main.py && grep -q "uvicorn\|fastapi" main.py 2>/dev/null; then
    uvicorn main:app --port="$port" --reload > "logs/fastapi-$port.log" 2>&1 &
  elif check_file main.py; then
    PORT="$port" python main.py > "logs/python-$port.log" 2>&1 &
  elif check_file manage.py; then
    python manage.py runserver "localhost:$port" > "logs/django-$port.log" 2>&1 &
  elif check_file app/__init__.py; then
    FLASK_APP=app flask run --port="$port" > "logs/flask-$port.log" 2>&1 &
  else
    python -m http.server "$port" > "logs/python-$port.log" 2>&1 &
  fi
  
  store_port "python" "$port"
  echo "✅ Python: http://localhost:$port"
}

launch_php(){ (check_file artisan || check_file index.php) || return
  local port=$(get_next_port 8000) project="$(project_name)"
  log_cmd "🚀 Starting PHP server: $project on port $port"
  
  if check_file artisan; then
    php artisan serve --port="$port" > "logs/laravel-$port.log" 2>&1 &
  else
    php -S "localhost:$port" > "logs/php-$port.log" 2>&1 &
  fi
  
  store_port "php" "$port"
  echo "✅ PHP: http://localhost:$port"
}

launch_html(){ check_file index.html || return
  local port=$(get_next_port 4000) project="$(project_name)"
  log_cmd "🚀 Starting HTML server: $project on port $port"
  
  if command -v live-server >/dev/null; then
    live-server --port="$port" > "logs/html-$port.log" 2>&1 &
  elif command -v npx >/dev/null; then
    npx live-server --port="$port" > "logs/html-$port.log" 2>&1 &
  else
    python3 -m http.server "$port" > "logs/html-$port.log" 2>&1 &
  fi
  
  store_port "html" "$port"
  echo "✅ HTML: http://localhost:$port"
}

start_databases(){ check_file docker-compose.yml && command -v docker >/dev/null &&
  { command -v docker-compose >/dev/null && docker-compose up -d db postgres mysql mongodb 2>/dev/null ||
    docker compose up -d db postgres mysql mongodb 2>/dev/null; } || true
}

show_status(){ echo ""; show_servers; echo ""
  echo "🎯 Quick Actions:"
  echo "  • godspeed status    - View all servers"
  echo "  • godspeed stop      - Stop all servers"  
  echo "  • godspeed logs all  - View all logs"
  
  local port=$(get_latest_port)
  [[ -n "$port" ]] && gs_confirm "Open http://localhost:$port in browser?" && {
    case "$PLATFORM" in
      macos) open "http://localhost:$port";;
      linux) xdg-open "http://localhost:$port" 2>/dev/null || true;;
    esac
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INTEGRATED PLUGIN SYSTEM WITH AUTO-INSTALLATION
# ═══════════════════════════════════════════════════════════════════════════════
install_core_plugins(){
  local plugins=(
    "ai-chat-assistant:AI Chat Assistant:Interactive AI coding assistant"
    "clipboard-manager:Clipboard Manager:Advanced clipboard with history"
    "error-viewer:Error Viewer:Centralized error tracking dashboard"
    "git-inspector:Git Inspector:Advanced Git workflow visualization"
    "system-monitor:System Monitor:Real-time performance monitoring"
    "terminal-console:Terminal Console:Enhanced terminal interface"
    "theme-switcher:Theme Switcher:Dark/light mode and UI themes"
    "todo-manager:Todo Manager:Project task management system"
  )
  
  mkdir -p plugins
  for plugin_data in "${plugins[@]}"; do
    IFS=: read -r slug name desc <<< "$plugin_data"
    create_plugin "$slug" "$name" "$desc"
  done
  gs_notify "✅ Core plugins installed"
}

create_plugin(){ local slug="$1" name="$2" desc="$3" dir="plugins/$slug"
  [[ -d "$dir" ]] && return
  mkdir -p "$dir"
  
  cat > "$dir/plugin.json" <<EOF
{
  "name": "$slug",
  "displayName": "$name",
  "version": "1.0.0",
  "description": "$desc",
  "main": "index.tsx",
  "enabled": true,
  "author": "Godspeed",
  "keywords": ["godspeed", "plugin", "development"],
  "engines": {"godspeed": ">=0.7.0"}
}
EOF

  cat > "$dir/index.tsx" <<EOF
import React, {useState, useEffect} from 'react';

export default function ${name//[^a-zA-Z]/}Plugin({title="$name"}) {
  const [data, setData] = useState({});
  const [loading, setLoading] = useState(false);
  
  useEffect(() => {
    // Plugin initialization
    setData({initialized: true, timestamp: Date.now()});
  }, []);
  
  return (
    <div className="plugin-container bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-lg p-6 shadow-lg">
      <h2 className="text-2xl font-bold mb-4">🔌 {title}</h2>
      <p className="mb-4">$desc</p>
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white/20 rounded p-3">
          <h3 className="font-semibold">Status</h3>
          <p className="text-sm">Active & Ready</p>
        </div>
        <div className="bg-white/20 rounded p-3">
          <h3 className="font-semibold">Features</h3>
          <p className="text-sm">All Enabled</p>
        </div>
      </div>
      <button 
        className="mt-4 px-4 py-2 bg-white text-blue-600 rounded hover:bg-gray-100 transition-colors"
        onClick={() => setLoading(!loading)}
      >
        {loading ? 'Loading...' : 'Activate'}
      </button>
    </div>
  );
}
EOF

  echo "# $name" > "$dir/README.md"
  echo "" >> "$dir/README.md"
  echo "$desc" >> "$dir/README.md"
  echo "" >> "$dir/README.md"
  echo "Created by Godspeed v0.7" >> "$dir/README.md"
}

list_plugins(){ echo "🔌 Installed Plugins:"
  check_dir plugins || { echo "  (none)"; return; }
  for dir in plugins/*/; do
    [[ -d "$dir" ]] || continue
    local manifest="$dir/plugin.json" name="$(basename "$dir")"
    if check_file "$manifest" && command -v jq >/dev/null; then
      local display_name=$(jq -r '.displayName // .name' "$manifest" 2>/dev/null || echo "$name")
      local version=$(jq -r '.version' "$manifest" 2>/dev/null || echo "unknown")
      local enabled=$(jq -r '.enabled' "$manifest" 2>/dev/null || echo "true")
      local status="✅"; [[ "$enabled" != "true" ]] && status="❌"
      echo "  $status $display_name (v$version)"
    else
      echo "  ⚠️ $name (no manifest)"
    fi
  done
}

# ═══════════════════════════════════════════════════════════════════════════════
# GITHUB INTEGRATION & REPOSITORY SEARCH
# ═══════════════════════════════════════════════════════════════════════════════
search_github(){ 
  local search_options=(
    "🔍 Search by keywords"
    "🌟 Browse trending repositories"
    "📂 Search by language"
    "🏷️ Search by topic"
  )
  
  local search_type=$(gs_single_select "GitHub Search" "How would you like to search?" "${search_options[@]}")
  local query=""
  
  case "$search_type" in
    *"keywords"*)
      query=$(gs_prompt 'GitHub search keywords' 'awesome react components')
      ;;
    *"trending"*)
      query="stars:>1000 pushed:>2024-01-01"
      ;;
    *"language"*)
      local languages=("JavaScript" "TypeScript" "Python" "PHP" "Go" "Rust" "Java")
      local selected_lang=$(gs_single_select "Programming Language" "Choose a language:" "${languages[@]}")
      query="language:$selected_lang stars:>100"
      ;;
    *"topic"*)
      local topics=("react" "laravel" "fastapi" "flutter" "docker" "kubernetes" "ai" "machine-learning")
      local selected_topic=$(gs_single_select "Topic" "Choose a topic:" "${topics[@]}")
      query="topic:$selected_topic stars:>50"
      ;;
  esac
  
  gs_notify "🔍 Searching GitHub: $query"
  local response=$(curl -s -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/search/repositories?q=${query}&sort=stars&order=desc&per_page=10" 2>/dev/null || echo '{"items":[]}')
  
  echo "🎯 Top Repositories:"
  if command -v jq >/dev/null; then
    echo "$response" | jq -r '.items[] | "📦 \(.full_name) (⭐ \(.stargazers_count))\n   📝 \(.description // "No description")\n   🔗 \(.html_url)\n"' 2>/dev/null || echo "No results"
  else
    echo "Install jq for formatted results"
  fi
  
  if gs_confirm_enhanced "Import Repository" "Would you like to import one of these repositories?"; then
    local repo=$(gs_prompt "Repository to import (user/repo)" "")
    [[ -n "$repo" ]] && {
      local import_dir="imported-repos/$(basename "$repo")"
      mkdir -p imported-repos
      git clone --depth=1 "https://github.com/$repo.git" "$import_dir" && gs_notify "✅ Imported: $repo → $import_dir"
    }
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# AI-POWERED CODE GENERATION & TESTING
# ═══════════════════════════════════════════════════════════════════════════════
generate_tests(){ local test_type=$(gs_prompt "Test type (unit|integration|e2e)" "unit")
  local framework=$(gs_prompt "Framework (jest|cypress|playwright|pytest)" "jest")
  local context=""
  
  check_file package.json && command -v jq >/dev/null && {
    context+="Dependencies: $(jq -r '.dependencies // {} | keys | join(", ")' package.json 2>/dev/null)\n"
  }
  
  local source_files=$(find src -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" \) 2>/dev/null | head -3)
  for file in $source_files; do
    context+="File: $file\n$(head -15 "$file" 2>/dev/null)\n\n"
  done
  
  local prompt="Generate comprehensive ${test_type} tests using ${framework}. Include setup, teardown, main functionality, edge cases, and modern testing patterns.\n\nProject Context:\n${context}"
  local provider=$(select_provider test) response=""
  
  [[ -n "$provider" ]] && response=$(ai_call "$provider" "$prompt") || response="// AI not configured"
  
  mkdir -p tests/generated
  local output_file="tests/generated/${test_type}-tests-$(date +%Y%m%d_%H%M%S).js"
  echo "$response" > "$output_file"
  gs_notify "🧪 Tests generated: $output_file"
  echo "$response"
}

autopilot_code(){ local task="${*:-$(gs_prompt 'Describe coding task' 'Add dark mode toggle')}"
  [[ -z "$task" ]] && { gs_notify "No task specified"; return 1; }
  
  local provider=$(select_provider autopilot)
  [[ -z "$provider" ]] && { gs_notify "Configure AI: godspeed ai configure"; return 1; }
  
  local context="Project: $(project_name)\nTask: $task\n\nCurrent Structure:\n"
  context+="$(find . -maxdepth 2 -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.php" -o -name "*.py" \) 2>/dev/null | head -8 | while read -r file; do
    echo "File: $file"; head -20 "$file" 2>/dev/null; echo ""
  done)"
  
  local prompt="Generate code changes for: $task\n\n$context\n\nProvide complete, production-ready code with proper error handling."
  local response=$(ai_call "$provider" "$prompt")
  
  mkdir -p autopilot/patches
  local patch_file="autopilot/patches/$(date +%Y%m%d_%H%M%S)_${task// /_}.patch"
  echo "$response" > "$patch_file"
  
  gs_notify "🤖 Code generated: $patch_file"
  echo "$response"
  
  gs_confirm "Apply changes automatically?" && {
    git apply --check "$patch_file" 2>/dev/null && git apply "$patch_file" && gs_notify "✅ Changes applied" ||
    gs_notify "⚠️ Manual review needed: $patch_file"
  }
}

 ═══════════════════════════════════════════════════════════════════════════════
# BUILD SYSTEM & DEPLOYMENT AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════
smart_build(){ gs_notify "⚡ Smart build initiated"
  if check_file nx.json; then
    log_cmd "🎯 Nx monorepo build"; npx nx run-many --target=build --parallel
  elif check_file turbo.json; then
    log_cmd "🚄 Turbo build"; npx turbo build
  elif check_file bazel || check_file WORKSPACE; then
    log_cmd "🏗️ Bazel build"; bazel build //...
  elif check_file Makefile; then
    log_cmd "🔨 Make build"; make build
  elif check_file package.json; then
    log_cmd "📦 npm build"; npm run build
  elif check_file composer.json; then
    log_cmd "🐘 PHP build"; composer install --optimize-autoloader --no-dev
  else
    gs_notify "⚠️ No build system detected"; return 1
  fi
  gs_notify "✅ Build completed successfully"
}

deploy_project(){ 
  local deployment_options=(
    "🚀 Vercel (Frontend apps)"
    "🌐 Netlify (Static sites)"
    "🐳 Docker (Containerized apps)"
    "☁️ AWS (Enterprise scale)"
    "📋 Manual (Custom hosting)"
  )
  
  local platform=$(gs_single_select "Deployment Platform" "Where would you like to deploy?" "${deployment_options[@]}")
  
  case "$platform" in
    *"Vercel"*)
      command -v vercel >/dev/null || npm i -g vercel
      vercel --prod
      ;;
    *"Netlify"*)
      command -v netlify >/dev/null || npm i -g netlify-cli
      netlify deploy --prod
      ;;
    *"Docker"*)
      if check_file Dockerfile; then
        docker build -t "$(project_name)" .
        gs_notify "✅ Docker image built: $(project_name)"
      else
        gs_notify "❌ No Dockerfile found"
      fi
      ;;
    *"AWS"*)
      command -v aws >/dev/null || { gs_notify "Install AWS CLI first"; return 1; }
      gs_notify "Configure AWS deployment in your CI/CD pipeline"
      ;;
    *"Manual"*)
      cat > deploy.md <<'EOF'
# Deployment Guide
## Build
npm run build
or
composer install –optimize-autoloader –no-dev

## Upload
Upload `dist/`, `build/`, or `public/` to your hosting provider.

## Environment
Set environment variables from `.env` in your hosting dashboard.

## Database
Run migrations if applicable:
php artisan migrate
or
python manage.py migrate
EOF
      gs_notify "✅ Manual deployment guide created: deploy.md";;
  esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECURITY & VULNERABILITY SCANNING
# ═══════════════════════════════════════════════════════════════════════════════
security_scan(){ gs_notify "🔒 Security scan initiated"
  
  # Install security tools if needed
  command -v trufflehog >/dev/null || pip install trufflehog3 2>/dev/null || true
  
  # Scan for secrets
  command -v trufflehog >/dev/null && { echo "🔍 Scanning for secrets"; trufflehog . --only-verified 2>/dev/null; } || true
  
  # Node.js vulnerabilities
  check_file package.json && { echo "📦 Node.js audit"; npm audit; npx audit-ci 2>/dev/null; } || true
  
  # Python vulnerabilities  
  check_file requirements.txt && { echo "🐍 Python security"; pip install safety 2>/dev/null || true; safety check 2>/dev/null; } || true
  
  # PHP vulnerabilities
  check_file composer.json && command -v composer >/dev/null && { echo "🐘 PHP security"; composer audit 2>/dev/null; } || true
  
  # Find sensitive files
  echo "🔐 Sensitive files:"
  find . \( -name "*.key" -o -name "*.pem" -o -name "*.p12" -o -name "*.crt" \) 2>/dev/null | sed 's/^/  ⚠️ /' || echo "  None found"
  
  gs_notify "🛡️ Security scan completed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DEVELOPMENT TOOLS & UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════
find_files(){ local term="${1:-$(gs_prompt 'Search term' 'config')}"
  echo "🔍 Files matching '$term':"
  find . -iname "*$term*" -type f 2>/dev/null | head -15
}

search_code(){ local pattern="${1:-$(gs_prompt 'Search pattern' 'TODO')}"
  echo "🔎 Code containing '$pattern':"
  grep -r --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx" --include="*.py" --include="*.php" "$pattern" . 2>/dev/null | head -15 || echo "  No matches found"
}

view_logs(){ local type="${1:-error}"
  case "$type" in
    error) check_file "$GS_LOG" && tail -50 "$GS_LOG" || echo "No error logs";;
    ai) check_file "$GS_DIR/logs/ai_chat.log" && tail -50 "$GS_DIR/logs/ai_chat.log" || echo "No AI logs";;
    all) find "$GS_DIR/logs" -name "*.log" -exec echo "=== {} ===" \; -exec tail -10 {} \; 2>/dev/null || echo "No logs";;
    *) echo "Log types: error, ai, all";;
  esac
}

stop_all_servers(){ echo "🛑 Stopping all development servers"
  pkill -f "php artisan serve\|npm run dev\|flask run\|uvicorn\|live-server\|python.*http.server" 2>/dev/null || true
  gs_notify "✅ All servers stopped"
}

update_system(){ detect_os; gs_notify "🔄 Updating system tools"
  case "$PLATFORM" in
    macos) command -v brew >/dev/null && { brew update; brew upgrade; };;
    linux) command -v apt-get >/dev/null && { sudo apt-get update; sudo apt-get -y upgrade; } || 
           { command -v yum >/dev/null && sudo yum -y update; };;
  esac
  safe_cmd npm i -g npm; safe_cmd pip install --upgrade pip
  gs_notify "✅ System updated"
}

share_session(){ command -v tmate >/dev/null || { gs_notify "Installing tmate"; detect_os
  case "$PLATFORM" in
    macos) command -v brew >/dev/null && brew install tmate;;
    linux) sudo apt-get install -y tmate 2>/dev/null || sudo yum install -y tmate 2>/dev/null;;
  esac; }
  
  command -v tmate >/dev/null || { gs_notify "Install tmate manually"; return 1; }
  tmate -S /tmp/tmate.sock new-session -d; tmate -S /tmp/tmate.sock wait tmate-ready
  echo "🔗 SSH: $(tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}')"
  echo "🌐 Web: $(tmate -S /tmp/tmate.sock display -p '#{tmate_web}')"
}

# ═══════════════════════════════════════════════════════════════════════════════
# GLOBAL DEVELOPMENT ENVIRONMENT INSTALLER
# ═══════════════════════════════════════════════════════════════════════════════
install_global_dev_environment(){
  detect_os
  gs_notify "🚀 Installing complete development environment..."
  
  # Interactive selection or auto-detect
  local mode="${1:-interactive}"
  local install_all=false
  
  if [[ "$mode" == "all" ]]; then
    install_all=true
  elif [[ "$mode" == "interactive" ]]; then
    echo "🎯 Development Environment Setup"
    echo "1. Minimal (Git, VS Code, Node.js, Python)"
    echo "2. Full Stack (All languages + tools)"
    echo "3. Custom (Choose specific tools)"
    local choice=$(gs_prompt "Choose option (1-3)" "2")
    case "$choice" in
      1) install_minimal_dev;;
      2) install_all=true;;
      3) install_custom_dev;;
    esac
  fi
  
  if $install_all; then
    install_system_prerequisites
    install_package_managers
    install_development_languages
    install_vscode_and_extensions
    install_mobile_toolchain
    install_cloud_tools
    install_container_tools
    setup_development_directories
    configure_development_environment
  fi
  
  gs_notify "✅ Development environment installation completed!"
  echo ""
  echo "🎯 What's been installed:"
  echo "  • Package managers (Homebrew/Chocolatey/APT)"
  echo "  • Languages: Node.js, Python, PHP, Go, Rust, Java"
  echo "  • VS Code with 18+ essential extensions"
  echo "  • Mobile: Flutter, Android Studio, iOS tools"
  echo "  • Cloud: AWS CLI, Azure CLI, Google Cloud SDK"
  echo "  • Containers: Docker, Kubernetes"
  echo ""
  echo "🚀 Next steps:"
  echo "  • Restart your terminal or run: source ~/.bashrc"
  echo "  • Test: godspeed doctor"
  echo "  • Create project: godspeed template react my-app"
}

install_minimal_dev(){
  gs_notify "📦 Installing minimal development setup..."
  install_system_prerequisites
  install_package_managers
  install_essential_languages
  install_vscode_and_extensions
}

install_custom_dev(){
  local tool_choices=("node" "python" "php" "go" "rust" "java" "mobile" "cloud" "docker")
mapfile -t langs < <(gs_tick_select "Which tools to install?" "${tool_choices[@]}")
[[ ${#langs[@]} -eq 0 ]] && { echo "[Godspeed] Cancelled. Returning to Godspeed menu."; return 0; }

  IFS=',' read -ra selected <<< "$tools"
  
  install_system_prerequisites
  install_package_managers
  
  for tool in "${selected[@]}"; do
    case "$tool" in
      node) install_nodejs;;
      python) install_python;;
      php) install_php;;
      go) install_golang;;
      rust) install_rust;;
      java) install_java;;
      mobile) install_mobile_toolchain;;
      cloud) install_cloud_tools;;
      docker) install_container_tools;;
    esac
  done
  
  install_vscode_and_extensions
}

install_system_prerequisites(){
  gs_notify "🔧 Installing system prerequisites..."
  case "$PLATFORM" in
    macos)
      # Install Xcode Command Line Tools
      if ! xcode-select -p >/dev/null 2>&1; then
        gs_notify "Installing Xcode Command Line Tools..."
        xcode-select --install || true
        echo "⏳ Please complete Xcode installation and rerun this command"
        return 1
      fi
      
      # Install Rosetta for M1 Macs
      if [[ "$(uname -m)" == "arm64" ]] && ! /usr/bin/pgrep oahd >/dev/null 2>&1; then
        gs_notify "Installing Rosetta for M1 compatibility..."
        softwareupdate --install-rosetta --agree-to-license || true
      fi
      ;;
    linux)
      sudo apt-get update -y 2>/dev/null || sudo yum update -y 2>/dev/null || true
      sudo apt-get install -y build-essential curl wget git || sudo yum install -y gcc gcc-c++ curl wget git || true
      ;;
    windows)
      gs_notify "Windows detected. Install Git for Windows if not present."
      ;;
  esac
}

install_package_managers(){
  gs_notify "📦 Setting up package managers..."
  case "$PLATFORM" in
    macos)
      if ! command -v brew >/dev/null; then
        gs_notify "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add to PATH
        if [[ -f /opt/homebrew/bin/brew ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
          echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        else
          eval "$(/usr/local/bin/brew shellenv)"
          echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
        fi
      fi
      brew install jq ripgrep git gh curl wget unzip gnupg
      ;;
    linux)
      # APT/YUM already available, install essentials
      sudo apt-get install -y jq ripgrep git curl wget unzip gnupg || sudo yum install -y jq ripgrep git curl wget unzip gnupg || true
      ;;
    windows)
      if command -v winget >/dev/null; then
        winget install -e --id Git.Git
        winget install -e --id jqlang.jq
      elif command -v choco >/dev/null; then
        choco install -y git jq
      else
        gs_notify "Please install Chocolatey or winget first"
      fi
      ;;
  esac
}

install_development_languages(){
  install_nodejs
  install_python
  install_php
  install_golang
  install_rust
  install_java
}

install_essential_languages(){
  install_nodejs
  install_python
}

install_nodejs(){
  gs_notify "📦 Installing Node.js and package managers..."
  case "$PLATFORM" in
    macos)
      brew install nvm
      mkdir -p ~/.nvm
      echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
      echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"' >> ~/.zshrc
      # Install latest LTS
      export NVM_DIR="$HOME/.nvm"
      [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
      nvm install --lts && nvm use --lts
      # Install global packages
      npm install -g npm@latest yarn pnpm create-react-app @vue/cli @angular/cli next vercel netlify-cli
      ;;
    linux)
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      nvm install --lts && nvm use --lts
      npm install -g npm@latest yarn pnpm create-react-app @vue/cli @angular/cli next vercel netlify-cli
      ;;
    windows)
      winget install -e --id OpenJS.NodeJS.LTS || choco install -y nodejs
      npm install -g npm@latest yarn pnpm create-react-app @vue/cli @angular/cli next vercel netlify-cli
      ;;
  esac
}

install_python(){
  gs_notify "🐍 Installing Python and tools..."
  case "$PLATFORM" in
    macos)
      brew install pyenv python@3.12
      echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
      echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
      echo 'eval "$(pyenv init -)"' >> ~/.zshrc
      # Install latest Python
      pyenv install 3.12.0 && pyenv global 3.12.0
      pip install --upgrade pip pipx poetry black flake8 pytest django fastapi flask
      pipx install cookiecutter
      ;;
    linux)
      sudo apt-get install -y python3 python3-pip python3-venv || sudo yum install -y python3 python3-pip
      curl https://pyenv.run | bash
      echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
      echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
      echo 'eval "$(pyenv init -)"' >> ~/.bashrc
      pip3 install --upgrade pip pipx poetry black flake8 pytest django fastapi flask
      ;;
    windows)
      winget install -e --id Python.Python.3.12 || choco install -y python
      pip install --upgrade pip pipx poetry black flake8 pytest django fastapi flask
      ;;
  esac
}

install_php(){
  gs_notify "🐘 Installing PHP and Composer..."
  case "$PLATFORM" in
    macos)
      brew install php@8.2 composer
      echo 'export PATH="/opt/homebrew/opt/php@8.2/bin:$PATH"' >> ~/.zshrc
      composer global require laravel/installer laravel/valet
      ;;
    linux)
      sudo apt-get install -y php8.2 php8.2-cli php8.2-curl php8.2-xml php8.2-mbstring php8.2-zip || true
      curl -sS https://getcomposer.org/installer | php
      sudo mv composer.phar /usr/local/bin/composer
      composer global require laravel/installer
      ;;
    windows)
      winget install -e --id shivammathur.php || choco install -y php composer
      composer global require laravel/installer
      ;;
  esac
}

install_golang(){
  gs_notify "🔵 Installing Go..."
  case "$PLATFORM" in
    macos) brew install go;;
    linux) sudo apt-get install -y golang || sudo yum install -y golang;;
    windows) winget install -e --id GoLang.Go || choco install -y golang;;
  esac
}

install_rust(){
  gs_notify "🦀 Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source ~/.cargo/env || true
}

install_java(){
  gs_notify "☕ Installing Java..."
  case "$PLATFORM" in
    macos) brew install --cask temurin;;
    linux) sudo apt-get install -y default-jdk || sudo yum install -y java-11-openjdk-devel;;
    windows) winget install -e --id EclipseAdoptium.Temurin.21.JDK || choco install -y temurin;;
  esac
}

install_vscode_and_extensions(){
  gs_notify "💻 Installing VS Code and essential extensions..."
  case "$PLATFORM" in
    macos) brew install --cask visual-studio-code;;
    linux) sudo snap install code --classic 2>/dev/null || {
      curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
      sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
      sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
      sudo apt-get update && sudo apt-get install -y code
    };;
    windows) winget install -e --id Microsoft.VisualStudioCode || choco install -y vscode;;
  esac
  
  # Wait for VS Code to be available
  sleep 3
  
  # Install essential extensions
  local extensions=(
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-vscode.vscode-typescript-next"
    "esbenp.prettier-vscode"
    "dbaeumer.vscode-eslint"
    "bradlc.vscode-tailwindcss"
    "ms-vscode.vscode-json"
    "redhat.vscode-yaml"
    "ms-azuretools.vscode-docker"
    "eamodio.gitlens"
    "github.vscode-github-actions"
    "ms-kubernetes-tools.vscode-kubernetes-tools"
    "hashicorp.terraform"
    "golang.go"
    "rust-lang.rust-analyzer"
    "vscjava.vscode-java-pack"
    "dart-code.dart-code"
    "dart-code.flutter"
    "laravel-goto.laravel-goto"
    "onecentlin.laravel-blade"
    "ryannaddy.laravel-artisan"
  )
  
  for ext in "${extensions[@]}"; do
    code --install-extension "$ext" --force 2>/dev/null || true
  done
  
  gs_notify "✅ VS Code configured with ${#extensions[@]} extensions"
}

install_mobile_toolchain(){
  gs_notify "📱 Installing mobile development tools..."
  case "$PLATFORM" in
    macos)
      brew install --cask android-studio flutter
      sudo gem install cocoapods
      ;;
    linux)
      sudo snap install flutter --classic android-studio --classic 2>/dev/null || true
      ;;
    windows)
      winget install -e --id Google.Flutter || choco install -y flutter
      winget install -e --id Google.AndroidStudio || choco install -y androidstudio
      ;;
  esac
}

install_cloud_tools(){
  gs_notify "☁️ Installing cloud development tools..."
  case "$PLATFORM" in
    macos)
      brew install awscli azure-cli terraform kubectl helm
      brew install --cask google-cloud-sdk
      ;;
    linux)
      # AWS CLI
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip && sudo ./aws/install && rm -rf aws awscliv2.zip
      # Azure CLI
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
      # Terraform
      sudo apt-get install -y terraform || true
      # Kubernetes
      sudo apt-get install -y kubectl || true
      ;;
    windows)
      winget install -e --id Amazon.AWSCLI || choco install -y awscli
      winget install -e --id Microsoft.AzureCLI || choco install -y azure-cli
      winget install -e --id HashiCorp.Terraform || choco install -y terraform
      winget install -e --id Kubernetes.kubectl || choco install -y kubernetes-cli
      ;;
  esac
}

install_container_tools(){
  gs_notify "🐳 Installing container tools..."
  case "$PLATFORM" in
    macos) brew install --cask docker;;
    linux) curl -fsSL https://get.docker.com | sh; sudo usermod -aG docker "$USER";;
    windows) winget install -e --id Docker.DockerDesktop || choco install -y docker-desktop;;
  esac
}

setup_development_directories(){
  gs_notify "📁 Setting up development directories..."
  mkdir -p ~/development/{projects,templates,scripts,tools}
  mkdir -p ~/development/godspeed/{logs,api_keys,ports,plugins}
}

configure_development_environment(){
  gs_notify "⚙️ Configuring development environment..."
  
  # Add common aliases to shell config
  local shell_config="$HOME/.bashrc"
  [[ -f "$HOME/.zshrc" ]] && shell_config="$HOME/.zshrc"
  
  cat >> "$shell_config" <<'EOF'

# Godspeed Development Environment
export GODSPEED_DIR="$HOME/development/godspeed"
export PATH="$GODSPEED_DIR:$PATH"

# Development aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias gs='godspeed'
alias gsi='godspeed install'
alias gsg='godspeed go'
alias gst='godspeed template'
alias gsa='godspeed ai chat'
alias ..='cd ..'
alias ...='cd ../..'

# Git aliases
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gl='git pull'
alias ga='git add'
alias gc='git commit'
alias gm='git commit -m'

# Laravel aliases
alias artisan='php artisan'
alias tinker='php artisan tinker'
alias migrate='php artisan migrate'
alias serve='php artisan serve'

# Node/NPM aliases
alias ni='npm install'
alias ns='npm start'
alias nr='npm run'
alias nd='npm run dev'
alias nb='npm run build'

EOF
}

run_system_check(){
  gs_notify "🔍 Running development environment check..."
  echo "🎯 Development Environment Status:"
  echo ""
  
  # Check core tools
  echo "📦 Core Tools:"
  check_command "git" "Git version control"
  check_command "curl" "HTTP client"
  check_command "jq" "JSON processor"
  check_command "code" "VS Code editor"
  
  echo ""
  echo "🌐 Programming Languages:"
  check_command "node" "Node.js runtime"
  check_command "npm" "Node package manager"
  check_command "python3" "Python interpreter"
  check_command "pip3" "Python package manager"
  check_command "php" "PHP interpreter"
  check_command "composer" "PHP package manager"
  check_command "go" "Go compiler"
  check_command "cargo" "Rust package manager"
  check_command "java" "Java runtime"
  
  echo ""
  echo "☁️ Cloud & DevOps:"
  check_command "docker" "Container runtime"
  check_command "kubectl" "Kubernetes CLI"
  check_command "terraform" "Infrastructure as Code"
  check_command "aws" "AWS CLI"
  check_command "az" "Azure CLI"
  
  echo ""
  echo "📱 Mobile Development:"
  check_command "flutter" "Flutter SDK"
  check_command "android" "Android SDK"
  
  echo ""
  echo "🔧 Godspeed Status:"
  check_command "godspeed" "Godspeed CLI"
  [[ -d "$GS_DIR" ]] && echo "  ✅ Godspeed directory: $GS_DIR" || echo "  ❌ Godspeed directory missing"
  [[ -f "$GS_DIR/godspeed.sh" ]] && echo "  ✅ Godspeed script found" || echo "  ❌ Godspeed script missing"
}

check_command(){
  local cmd="$1" desc="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    local version=$(${cmd} --version 2>/dev/null | head -1 || echo "installed")
    echo "  ✅ $desc: $version"
  else
    echo "  ❌ $desc: not installed"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROJECT TEMPLATE SYSTEM WITH TICK SELECTION
# ═══════════════════════════════════════════════════════════════════════════════
create_template(){
  clear
  echo "🎯 Godspeed Project Templates"
  
  # Template categories with tick system
  local template_categories=(
    "⚛️ Frontend (React, Vue, Next.js, Angular)"
    "🐘 Backend (Laravel, FastAPI, Express, Django)"
    "📱 Mobile (Flutter, React Native)"
    "🔗 Full-Stack (Complete applications)"
    "🎮 Specialized (Static sites, APIs, etc.)"
  )
  
  local category=$(gs_single_select "Template Category" "Choose a project category:" "${template_categories[@]}")
  
  local selected_template=""
  case "$category" in
    *"Frontend"*)
      local frontend_templates=(
        "⚛️ React + TypeScript + Tailwind"
        "🚀 Next.js + App Router + TypeScript"
        "💚 Vue 3 + Composition API + TypeScript"
        "🅰️ Angular + Material Design"
        "⚡ Vite + React + TypeScript"
        "🎨 Static HTML + Tailwind CSS"
      )
      selected_template=$(gs_single_select "Frontend Template" "Choose a frontend template:" "${frontend_templates[@]}")
      ;;
    *"Backend"*)
      local backend_templates=(
        "🐘 Laravel 11 + API + Sanctum"
        "🐍 FastAPI + SQLAlchemy + PostgreSQL"
        "🟨 Express.js + TypeScript + Prisma"
        "🐍 Django + REST Framework"
        "🔵 Go + Gin + GORM"
        "🦀 Rust + Actix + Diesel"
      )
      selected_template=$(gs_single_select "Backend Template" "Choose a backend template:" "${backend_templates[@]}")
      ;;
    *"Mobile"*)
      local mobile_templates=(
        "📱 Flutter + Dart (Cross-platform)"
        "⚛️ React Native + TypeScript"
        "🍎 iOS Native (Swift)"
        "🤖 Android Native (Kotlin)"
      )
      selected_template=$(gs_single_select "Mobile Template" "Choose a mobile template:" "${mobile_templates[@]}")
      ;;
    *"Full-Stack"*)
      local fullstack_templates=(
        "🔗 React + Laravel + MySQL"
        "🚀 Next.js + Prisma + PostgreSQL"
        "💚 Vue + Express + MongoDB"
        "📱 Flutter + FastAPI + PostgreSQL"
        "🎯 MERN Stack (MongoDB + Express + React + Node)"
        "🐘 TALL Stack (Tailwind + Alpine + Laravel + Livewire)"
      )
      selected_template=$(gs_single_select "Full-Stack Template" "Choose a full-stack template:" "${fullstack_templates[@]}")
      ;;
    *"Specialized"*)
      local specialized_templates=(
        "🌐 Static Blog (11ty + Tailwind)"
        "🔧 REST API (Express + Swagger)"
        "📊 Data Dashboard (React + D3.js)"
        "🎮 Game Dev (Unity + C#)"
        "🤖 ML Project (Python + Jupyter)"
      )
      selected_template=$(gs_single_select "Specialized Template" "Choose a specialized template:" "${specialized_templates[@]}")
      ;;
  esac
  
  # Get project name
  local project_name=$(gs_prompt "Project Name" "Enter your project name" "my-awesome-project")
  
  # Additional options with tick system
  local additional_options=(
    "🐳 Include Docker configuration"
    "🚀 Setup CI/CD (GitHub Actions)"
    "🔒 Include authentication system"
    "📊 Add monitoring & analytics"
    "🧪 Include testing setup"
    "📝 Generate documentation"
  )
  
  mapfile -t selected_options < <(gs_multi_select "Additional Features" "Select additional features to include:" "${additional_options[@]}")
  
  # Create project with selected template and options
  execute_template_creation "$selected_template" "$project_name" "${selected_options[@]}"
}

execute_template_creation(){
  local template="$1" project_name="$2"
  shift 2
  local options=("$@")
  
  gs_notify "🚀 Creating project: $project_name"
  mkdir -p "$project_name" && cd "$project_name" || return 1
  
  # Create project based on template
  case "$template" in
    *"React + TypeScript"*)
      npx create-react-app . --template typescript
      npm install tailwindcss @headlessui/react @heroicons/react
      ;;
    *"Next.js"*)
      npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
      ;;
    *"Vue 3"*)
      npm create vue@latest . -- --typescript --pwa --vitest --cypress
      ;;
    *"Angular"*)
      npx @angular/cli new . --routing --style=scss --package-manager=npm
      ;;
    *"Laravel"*)
      composer create-project laravel/laravel . || curl -s "https://laravel.build/$project_name" | bash
      ;;
    *"FastAPI"*)
      python3 -m venv venv && source venv/bin/activate
      pip install fastapi uvicorn[standard] sqlalchemy alembic
      mkdir -p app/{api,models,schemas}
      cat > app/main.py <<'EOF'
from fastapi import FastAPI
app = FastAPI(title="Godspeed API", version="1.0.0")

@app.get("/")
async def root():
    return {"message": "Hello from Godspeed!", "status": "active"}
EOF
      ;;
    *"Flutter"*)
      flutter create . --project-name="$project_name"
      ;;
    *"MERN Stack"*)
      mkdir -p {frontend,backend}
      cd frontend && npx create-react-app . --template typescript && cd ..
      cd backend && npm init -y && npm install express mongoose dotenv cors && cd ..
      ;;
  esac
  
  # Add selected options
  for option in "${options[@]}"; do
    case "$option" in
      *"Docker"*) create_docker_config;;
      *"CI/CD"*) create_github_actions;;
      *"authentication"*) setup_auth_system;;
      *"testing"*) setup_testing;;
      *"documentation"*) create_documentation;;
    esac
  done
  
  # Setup environment and configs
  setup_env
  setup_configs
  setup_dirs
  
  gs_notify "✅ Project '$project_name' created successfully!"
  echo "Next steps:"
  echo "  cd $project_name"
  echo "  godspeed install"
  echo "  godspeed go"
}

create_docker_config(){
  cat > Dockerfile <<'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 4000
CMD ["npm", "start"]
EOF

  cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  app:
    build: .
    ports:
      - "4000:4000"
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
EOF
}

create_github_actions(){
  mkdir -p .github/workflows
  cat > .github/workflows/ci.yml <<'EOF'
name: CI/CD Pipeline
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm test
      - run: npm run build
EOF
}

setup_auth_system(){
  if check_file package.json; then
    npm install next-auth bcryptjs jsonwebtoken
  elif check_file composer.json; then
    composer require laravel/sanctum
  fi
}

setup_testing(){
  if check_file package.json; then
    npm install --save-dev jest @testing-library/react @testing-library/jest-dom
  elif check_file requirements.txt; then
    echo "pytest" >> requirements.txt
  fi
}

create_documentation(){
  cat > README.md <<EOF
# $project_name

Created with Godspeed v0.7

## Features
- Modern development setup
- Automated tooling
- Production-ready configuration

## Quick Start
\`\`\`bash
godspeed install
godspeed go
\`\`\`

## Development
\`\`\`bash
godspeed ai chat      # Get AI assistance
godspeed build        # Build for production
godspeed deploy       # Deploy to cloud
\`\`\`
EOF
}


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN COMMAND HANDLER & AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════
main_install(){ gs_notify "🚀 Installing project dependencies"
  init_dirs; detect_os; setup_env; cleanup_deps; setup_dirs; resolve_deps; fix_permissions; setup_configs
  install_core_plugins; gs_notify "✅ Project ready! Run 'godspeed go' to start"
}

main_go(){ gs_notify "🎯 Starting development environment"
  init_dirs; detect_os; launch_servers
}

main_help(){ cat <<'EOF'
🚀 GODSPEED v0.7 - Ultimate Full-Stack Development Shell

━━━ CORE COMMANDS ━━━
  install                     Install project dependencies & setup
  go                         Start development servers automatically  
  ai [configure|chat]        Configure/use Godspeed AI
  template <type> <name>     Create new project from template
  autopilot <task>           AI-powered code generation

━━━ SYSTEM SETUP ━━━
  setup-global               Install complete dev environment (VS Code, languages, tools)
  doctor                     Check development environment status
  update                     Update system & development tools

━━━ BUILD & DEPLOY ━━━  
  build                      Smart build with optimization
  deploy [platform]          Deploy to vercel/netlify/docker
  scan                       Security vulnerability scanning

━━━ PROJECT TOOLS ━━━
  search <keywords>          Search & import GitHub repositories
  find <term>               Find files by name
  grep <pattern>            Search code patterns  
  tests                     Generate AI-powered tests
  status                    Show running servers
  stop                      Stop all development servers

━━━ UTILITIES ━━━
  logs [type]               View logs (error|ai|all)
  session                   Share terminal session via tmate
  plugins                   List installed plugins

━━━ EXAMPLES ━━━
  godspeed setup-global                # Install complete dev environment
  godspeed template react my-app       # Create React project
  godspeed autopilot "add dark mode"   # AI code generation  
  godspeed doctor                      # Check system status

For more help: https://github.com/dambu07/godspeed
EOF
}

main(){ init_dirs; detect_os
  case "${1:-help}" in
    install) main_install;;
    go|start|dev) main_go;;
    ai) shift; case "${1:-chat}" in configure) ai_configure;; *) ai_chat;; esac;;
    template|new) create_template "${2:-}" "${3:-}";;
    autopilot|auto) shift; autopilot_code "$@";;
    build) smart_build;;
    deploy) deploy_project;;
    scan|security) security_scan;;
    search|github) shift; search_github "$@";;
    find) find_files "$2";;
    grep|search-code) search_code "$2";;
    tests|test) generate_tests;;
    status|servers) show_servers;;
    stop|kill) stop_all_servers;;
    logs|log) view_logs "$2";;
    update|upgrade) update_system;;
    session|share) share_session;;
    plugins) list_plugins;;
    # ADD THESE LINES:
    setup-global|install-global) godspeed_install_global_tools;;
    doctor|check) run_system_check;;
    help|--help|-h|*) main_help;;
  esac
}

# Execute main function with all arguments
main "$@"
