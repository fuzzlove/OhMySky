#!/usr/bin/env sh
set -eu

DIR="$HOME/.ohmysky"
CACHE="$HOME/.cache/ohmysky"
mkdir -p "$DIR" "$CACHE"

cat > "$DIR/common.sh" <<'EOF'
OHMYSKY_CACHE="$HOME/.cache/ohmysky"
mkdir -p "$OHMYSKY_CACHE" 2>/dev/null

cmd_exists(){ command -v "$1" >/dev/null 2>&1; }
cache_age(){ stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }

ohmysky_cached_curl(){
  url="$1"; file="$2"; ttl="$3"
  now="$(date +%s)"
  old="$(cache_age "$file")"
  if [ ! -s "$file" ] || [ $((now-old)) -gt "$ttl" ]; then
    cmd_exists curl && curl -fsS --max-time 3 "$url" > "$file" 2>/dev/null || true
  fi
  cat "$file" 2>/dev/null || printf "?"
}

ohmysky_external_ip(){ ohmysky_cached_curl "https://api.ipify.org" "$OHMYSKY_CACHE/external_ip" 300; }
ohmysky_weather(){ ohmysky_cached_curl "https://wttr.in/?format=%c+%t" "$OHMYSKY_CACHE/weather" 1800; }

ohmysky_lan_ip(){
  ipconfig getifaddr en0 2>/dev/null ||
  ipconfig getifaddr en1 2>/dev/null ||
  hostname -I 2>/dev/null | awk '{print $1}' ||
  printf "?"
}

ohmysky_vpn(){
  if ifconfig 2>/dev/null | grep -Eiq 'utun|tun|tap|wg|ppp'; then printf "VPN:on"; else printf "VPN:off"; fi
}

ohmysky_battery(){
  pmset -g batt 2>/dev/null | awk -F';' '/%/ {gsub(/^ /,"",$2); print $2}' ||
  awk '{print $1"%"}' /sys/class/power_supply/BAT0/capacity 2>/dev/null ||
  printf "?"
}

ohmysky_latency(){
  ping -c 1 -W 1 1.1.1.1 2>/dev/null | awk -F'time=' '/time=/ {print int($2)"ms"}' || printf "?"
}

ohmysky_ram(){
  if [ "$(uname)" = "Darwin" ]; then
    vm_stat 2>/dev/null | awk '
      /Pages active/ {a=$3}
      /Pages wired/ {w=$4}
      END {gsub(/\./,"",a); gsub(/\./,"",w); print int((a+w)*4096/1024/1024)"MB"}'
  else
    awk '/MemAvailable/ {print int($2/1024)"MB free"}' /proc/meminfo 2>/dev/null || printf "?"
  fi
}

ohmysky_git(){
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
  b="$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
  git diff --quiet --ignore-submodules HEAD 2>/dev/null && d="✓" || d="*"
  printf "  %s%s" "$b" "$d"
}

ohmysky_macos_security(){
  [ "$(uname)" = "Darwin" ] || return
  gk="$(spctl --status 2>/dev/null | awk '{print $2}')"
  sip="$(csrutil status 2>/dev/null | grep -o 'enabled\|disabled' | head -1)"
  fv="$(fdesetup status 2>/dev/null | awk '{print $3}' | tr -d '.')"
  printf "GK:%s SIP:%s FV:%s" "${gk:-?}" "${sip:-?}" "${fv:-?}"
}

ohmysky_context(){
  printf "OhMySky | %s | LAN:%s | WAN:%s | %s | BAT:%s | LAT:%s | RAM:%s | %s" \
    "$(ohmysky_weather)" \
    "$(ohmysky_lan_ip)" \
    "$(ohmysky_external_ip)" \
    "$(ohmysky_vpn)" \
    "$(ohmysky_battery)" \
    "$(ohmysky_latency)" \
    "$(ohmysky_ram)" \
    "$(ohmysky_macos_security)"
}

ohmysky_banner(){
cat <<'BANNER'

╔══════════════════════════════════════════════╗
║                                              ║
║   ██████╗ ██╗  ██╗    ███╗   ███╗██╗   ██╗  ║
║  ██╔═══██╗██║  ██║    ████╗ ████║╚██╗ ██╔╝  ║
║  ██║   ██║███████║    ██╔████╔██║ ╚████╔╝   ║
║  ██║   ██║██╔══██║    ██║╚██╔╝██║  ╚██╔╝    ║
║  ╚██████╔╝██║  ██║    ██║ ╚═╝ ██║   ██║     ║
║   ╚═════╝ ╚═╝  ╚═╝    ╚═╝     ╚═╝   ╚═╝     ║
║                                              ║
║              O H   M Y   S K Y              ║
║                                              ║
║         Security Research Terminal           ║
║                                              ║
╚══════════════════════════════════════════════╝

BANNER
}
EOF

cat > "$DIR/bash.sh" <<'EOF'
[ -n "$BASH_VERSION" ] || return 0 2>/dev/null || exit 0
. "$HOME/.ohmysky/common.sh"

RESET="\[\033[0m\]"
GRAY="\[\033[38;5;245m\]"
MINT="\[\033[38;5;121m\]"
SKY="\[\033[38;5;117m\]"
LAV="\[\033[38;5;141m\]"
GOLD="\[\033[38;5;221m\]"
CYAN="\[\033[38;5;87m\]"
RED="\[\033[38;5;203m\]"

ohmysky_bash_status(){
  c=$?
  [ "$c" -eq 0 ] && printf "\033[38;5;84m✔\033[0m" || printf "\033[38;5;203m✘ %s\033[0m" "$c"
}

[ -z "${OHMYSKY_LOADED:-}" ] && {
  export OHMYSKY_LOADED=1
  ohmysky_banner
  [ -n "$SSH_CONNECTION" ] && echo "[ WARNING ] Remote SSH session detected."
  [ "$EUID" -eq 0 ] && echo "[ DANGER ] Security Research Mode: ROOT"
}

[ "$EUID" -eq 0 ] && MARK="${RED}#${RESET}" || MARK="${CYAN}❯${RESET}"

PS1="${GRAY}\t ${MINT}\u${GRAY}@${SKY}\h ${LAV}\w${GOLD}\$(ohmysky_git)${RESET}
${GRAY}\$(ohmysky_context)${RESET}
\$(ohmysky_bash_status) ${MARK} "
EOF

cat > "$DIR/zsh.zsh" <<'EOF'
[ -n "$ZSH_VERSION" ] || return 0 2>/dev/null || exit 0
. "$HOME/.ohmysky/common.sh"

autoload -Uz colors 2>/dev/null && colors
setopt PROMPT_SUBST 2>/dev/null

ohmysky_zsh_status(){
  c=$?
  [ "$c" -eq 0 ] && printf "%%F{84}✔%%f" || printf "%%F{203}✘ %s%%f" "$c"
}

ohmysky_zsh_context(){
  printf "%%F{245}%s%%f" "$(ohmysky_context)"
}

[ -z "${OHMYSKY_LOADED:-}" ] && {
  export OHMYSKY_LOADED=1
  ohmysky_banner
  [ -n "$SSH_CONNECTION" ] && print -P "%F{203}[ WARNING ] Remote SSH session detected.%f"
  [ "$EUID" -eq 0 ] && print -P "%F{203}[ DANGER ] Security Research Mode: ROOT%f"
}

[ "$EUID" -eq 0 ] && MARK='%F{203}#%f' || MARK='%F{87}❯%f'

PROMPT='%F{245}%* %F{121}%n%F{245}@%F{117}%m %F{141}%~%F{221}$(ohmysky_git)%f
$(ohmysky_zsh_context)
$(ohmysky_zsh_status) '"$MARK"' '
EOF

add_line(){
  file="$1"
  line="$2"
  touch "$file"
  grep -Fq "$line" "$file" 2>/dev/null || printf '\n%s\n' "$line" >> "$file"
}

add_line "$HOME/.bashrc" '[ -f "$HOME/.ohmysky/bash.sh" ] && . "$HOME/.ohmysky/bash.sh"'
add_line "$HOME/.bash_profile" '[ -f "$HOME/.ohmysky/bash.sh" ] && . "$HOME/.ohmysky/bash.sh"'
add_line "$HOME/.zshrc" '[ -f "$HOME/.ohmysky/zsh.zsh" ] && . "$HOME/.ohmysky/zsh.zsh"'

echo "OhMySky installed for Bash and Zsh."
echo "Reload with:"
echo "  source ~/.zshrc"
echo "  source ~/.bashrc"
