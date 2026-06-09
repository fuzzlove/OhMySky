#!/usr/bin/env sh

#chmod +x ohmysky.sh
#./ohmysky.sh
#source ~/.zshrc

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
  if ifconfig 2>/dev/null | grep -Eiq 'utun|tun|tap|wg|ppp'; then
    printf "VPN:on"
  else
    printf "VPN:off"
  fi
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
║   ██████╗ ██╗  ██╗    ███╗   ███╗██╗   ██╗   ║
║  ██╔═══██╗██║  ██║    ████╗ ████║╚██╗ ██╔╝   ║
║  ██║   ██║███████║    ██╔████╔██║ ╚████╔╝    ║
║  ██║   ██║██╔══██║    ██║╚██╔╝██║  ╚██╔╝     ║
║  ╚██████╔╝██║  ██║    ██║ ╚═╝ ██║   ██║      ║
║   ╚═════╝ ╚═╝  ╚═╝    ╚═╝     ╚═╝   ╚═╝      ║
║                                              ║
║              O H   M Y   S K Y               ║
║                                              ║
║         Security Research Terminal           ║
║                                              ║
╚══════════════════════════════════════════════╝

BANNER
}
EOF

cat > "$DIR/guard-patterns.txt" <<'EOF'
sudo su
su root
passwd
/etc/passwd
/etc/shadow
authorized_keys
id_rsa
id_ed25519
.ssh
ssh-keygen
ssh-add
security find-generic-password
security find-internet-password
security dump-keychain
security unlock-keychain
security list-keychains
keychain
login.keychain
osascript
osascript -e
launchctl
LaunchAgents
LaunchDaemons
.plist
crontab
at now
periodic
chmod +x
chmod 777
chown root
chflags
xattr -d
spctl --master-disable
csrutil disable
tccutil reset
sqlite3 ~/Library
~/Library/Application Support
~/Library/LaunchAgents
/Library/LaunchAgents
/Library/LaunchDaemons
/tmp
/var/tmp
curl
wget
python -c
python3 -c
perl -e
ruby -e
php -r
bash -i
sh -i
zsh -i
nc
netcat
ncat
socat
mkfifo
/dev/tcp
base64 -d
base64 --decode
openssl enc
xxd -r
hexdump
tar
gzip
gunzip
zip
unzip
7z
ditto
scp
sftp
rsync
ftp
tftp
ssh
sshpass
whoami
id
groups
uname -a
sw_vers
system_profiler
ioreg
ifconfig
ipconfig
netstat
lsof -i
arp -a
route -n
scutil
dscacheutil
dscl
last
lastlog
w
who
users
ps aux
pgrep
top
vm_stat
df -h
du -sh
mount
diskutil
find /
find ~
mdfind
mdls
ls -la
ls -al
cat ~/.zsh_history
cat ~/.bash_history
history -c
unset HISTFILE
export HISTFILE=/dev/null
rm ~/.zsh_history
rm ~/.bash_history
killall Terminal
killall iTerm2
tcpdump
tshark
wireshark
nmap
masscan
arp-scan
dig
nslookup
host
whois
traceroute
ping -c
curl ifconfig.me
curl ipinfo.io
curl api.ipify.org
plutil
defaults read
defaults write
open -a
open /Applications
codesign
codesign -dv
otool
strings
file
shasum
md5
xxd
dyld
DYLD_INSERT_LIBRARIES
DYLD_LIBRARY_PATH
install_name_tool
kextload
kextunload
kmutil
systemextensionsctl
profiles
profiles show
profiles list
fdesetup
spctl
csrutil
tmutil
softwareupdate
pkgutil
installer
hdiutil attach
hdiutil mount
diskutil erase
dd if=
mkfs
rm -rf /
rm -rf ~
rm -rf /Users
srm
shred
pkill
kill -9
killall
launchctl unload
launchctl bootout
launchctl bootstrap
launchctl kickstart
launchctl print
launchctl list
curl -o
curl -O
wget -O
wget -q
chmod u+s
setuid
sudoers
visudo
/etc/sudoers
dsenableroot
sysadminctl
dscl . -create
dscl . -append
dscl . -passwd
dseditgroup
createhomedir
networksetup
airport
wdutil
pfctl
pfctl -d
pfctl -f
/etc/pf.conf
iptables
ufw disable
systemctl
service
journalctl
log show
log stream
log erase
sqlite3
browser cookies
Cookies.binarycookies
Login Data
History
Chrome
Firefox
Safari
Brave
Keychain
AddressBook
Messages
Mail
Notes
Calendar
Photos
ScreenCapture
screencapture
screencapture -x
say
pbpaste
pbcopy
ioreg -l
system_profiler SPUSBDataType
system_profiler SPBluetoothDataType
system_profiler SPAirPortDataType
system_profiler SPApplicationsDataType
system_profiler SPConfigurationProfileDataType
pspy
linpeas
linpeas.sh
mimikatz
hydra
john
hashcat
gobuster
ffuf
dirsearch
sqlmap
metasploit
msfconsole
empire
sliver
cobaltstrike
beacon
ngrok
cloudflared tunnel
chisel
frp
frpc
frps
tailscale
zerotier
tor
torsocks
proxychains
ssh -D
ssh -L
ssh -R
socat TCP
socat EXEC
python3 -m http.server
python -m SimpleHTTPServer
php -S
ruby -run
openssl s_client
openssl rsautl
gpg
age
tar czf
zip -r
scp -r
rsync -av
curl -F
curl -X POST
wget --post-file
aws configure
aws s3
gcloud auth
az login
docker ps
docker exec
docker run
kubectl get secrets
kubectl config
kubectl exec
kubectl cp
helm
terraform
vault
ansible
ansible-playbook
EOF

cat > "$DIR/guard.sh" <<'EOF'
OHMYSKY_GUARD_LOG="$HOME/.ohmysky/ohmysky-guard.log"
OHMYSKY_GUARD_PATTERNS="$HOME/.ohmysky/guard-patterns.txt"

ohmysky_guard_warn(){
  echo
  echo "======================================================"
  echo "              AUTHORIZED USE ONLY"
  echo "======================================================"
  echo "This system is monitored. Unauthorized access or use"
  echo "may violate the Computer Fraud and Abuse Act (CFAA),"
  echo "18 U.S.C. § 1030, and applicable state or local laws."
  echo
  echo "Your command has been logged."
  echo "======================================================"
  echo
}

ohmysky_guard_log(){
  matched="$1"
  cmd="$2"

  {
    echo "----- OHMYSKY GUARD ALERT -----"
    date
    echo "USER: $(id -un 2>/dev/null)"
    echo "UID:  $(id -u 2>/dev/null)"
    echo "HOST: $(hostname)"
    echo "PWD:  $(pwd)"
    echo "SHELL: ${SHELL:-unknown}"
    echo "MATCH: $matched"
    echo "CMD: $cmd"
    echo
  } >> "$OHMYSKY_GUARD_LOG"
}

ohmysky_guard_check(){
  cmd="$1"

  [ -f "$OHMYSKY_GUARD_PATTERNS" ] || return 0
  [ -z "$cmd" ] && return 0

  while IFS= read -r pattern || [ -n "$pattern" ]; do
    case "$pattern" in
      ""|\#*) continue ;;
    esac

    case "$cmd" in
      *"$pattern"*)
        ohmysky_guard_log "$pattern" "$cmd"
        ohmysky_guard_warn

        if [ "${OHMYSKY_GUARD_STRICT:-0}" = "1" ]; then
          exit 126
        fi

        return 0
        ;;
    esac
  done < "$OHMYSKY_GUARD_PATTERNS"
}
EOF

cat > "$DIR/bash.sh" <<'EOF'
[ -n "$BASH_VERSION" ] || return 0 2>/dev/null || exit 0
. "$HOME/.ohmysky/common.sh"
. "$HOME/.ohmysky/guard.sh"

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

ohmysky_guard_bash_trap(){
  case "$BASH_COMMAND" in
    ohmysky_*|trap*|PS1=*|PROMPT_COMMAND*|return*|source*|.*ohmysky*) return ;;
  esac
  ohmysky_guard_check "$BASH_COMMAND"
}

trap ohmysky_guard_bash_trap DEBUG

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
. "$HOME/.ohmysky/guard.sh"

autoload -Uz colors 2>/dev/null && colors
setopt PROMPT_SUBST 2>/dev/null

ohmysky_zsh_status(){
  c=$?
  [ "$c" -eq 0 ] && printf "%%F{84}✔%%f" || printf "%%F{203}✘ %s%%f" "$c"
}

ohmysky_zsh_context(){
  printf "%%F{245}%s%%f" "$(ohmysky_context)"
}

preexec(){
  ohmysky_guard_check "$1"
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
echo "Pattern file: $HOME/.ohmysky/guard-patterns.txt"
echo "Guard log:    $HOME/.ohmysky/ohmysky-guard.log"
echo
echo "Reload with:"
echo "  source ~/.zshrc"
echo "  source ~/.bashrc"
echo
echo "Optional strict mode:"
echo "  export OHMYSKY_GUARD_STRICT=1"
