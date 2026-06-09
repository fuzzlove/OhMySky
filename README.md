# OhMySky

**OhMySky** is a dark-terminal security research prompt and theme for **Bash** and **Zsh**.

Designed for security researchers, developers, system administrators, and power users who want useful system, network, and security information directly in their terminal prompt.

---

## Features

### Terminal Enhancements

* Dark-terminal optimized color palette
* Bash support
* Zsh support
* Automatic shell detection
* Multi-line prompt
* Nerd Font compatible

### Git Integration

* Current branch display
* Clean repository indicator (`✓`)
* Dirty repository indicator (`*`)

### Network Intelligence

* External (WAN) IP address
* Local (LAN) IP address
* VPN detection
* Network latency monitoring

### System Monitoring

* Battery status
* RAM usage
* SSH session detection
* Root shell detection

### Weather

* Current weather conditions
* 30-minute cache
* Lightweight API usage

### macOS Security Monitoring

* Gatekeeper status
* System Integrity Protection (SIP) status
* FileVault status

### Startup Banner

* Oh My Sky ASCII logo
* Security research branding
* SSH warning banner
* Root warning banner

---

# Installation

Make the installer executable:

```bash
chmod +x ohmysky.sh
```

Run the installer:

```bash
./ohmysky.sh
```

Reload your shell:

### Zsh

```bash
source ~/.zshrc
```

### Bash

```bash
source ~/.bashrc
```

### macOS Login Shell

```bash
source ~/.bash_profile
```

---

# Files Installed

OhMySky creates the following files:

```text
~/.ohmysky/common.sh
~/.ohmysky/bash.sh
~/.ohmysky/zsh.zsh
~/.cache/ohmysky/
```

The installer automatically updates:

```text
~/.bashrc
~/.bash_profile
~/.zshrc
```

---

# Example Prompt

```text
21:30:42 user@MacBook-Pro.local ~/Projects/OhMySky  main✓

OhMySky | 🌤️ +92°F | LAN:192.168.1.25 | WAN:172.x.x.x |
VPN:off | BAT:charged | LAT:22ms | RAM:9000MB |
GK:enabled SIP:enabled FV:On

✔ ❯
```

---

# Example Startup Banner

```text
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
```

---

# Cached Data

The following items are cached to improve responsiveness:

| Item        | Cache Duration |
| ----------- | -------------- |
| Weather     | 30 minutes     |
| External IP | 5 minutes      |

This prevents prompt lag caused by network requests.

---

# Supported Platforms

## macOS

Fully supported:

* Bash
* Zsh
* Gatekeeper detection
* SIP detection
* FileVault detection
* Battery status

## Linux

Supported:

* Bash
* Zsh
* Git integration
* LAN/WAN IP detection
* VPN detection
* RAM monitoring
* Battery monitoring (where available)

---

# Uninstall

Remove OhMySky:

```bash
rm -rf ~/.ohmysky
rm -rf ~/.cache/ohmysky
```

Remove shell integration:

```bash
sed -i.bak '/ohmysky/d' ~/.zshrc ~/.bashrc ~/.bash_profile 2>/dev/null
```

Or manually edit:

```bash
nano ~/.zshrc
nano ~/.bashrc
nano ~/.bash_profile
```

Remove any lines containing:

```bash
ohmysky
```

---

# Recommended Fonts

For the best appearance install a Nerd Font:

* MesloLGS Nerd Font
* JetBrains Mono Nerd Font
* FiraCode Nerd Font
* Hack Nerd Font

---

# Future Roadmap

Planned enhancements:

* CPU utilization
* Uptime indicator
* Current Wi-Fi SSID
* Lockdown Mode detection
* Docker container count
* Kubernetes context
* GitHub notifications
* Threat intelligence feed
* CVE ticker
* Custom themes
* Powerline separators

---

# License

MIT License

---

# Credits

Created for the security research community.

Inspired by modern shell environments while remaining lightweight, portable, and shell-native.

**OhMySky — Security Research Terminal**
