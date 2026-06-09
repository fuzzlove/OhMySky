#!/usr/bin/env bash

set -e

echo "[*] Uninstalling OhMySky..."

# Remove installation directories

rm -rf "$HOME/.ohmysky"
rm -rf "$HOME/.cache/ohmysky"

# Remove references from shell startup files

for file in 
"$HOME/.bashrc" 
"$HOME/.bash_profile" 
"$HOME/.profile" 
"$HOME/.zshrc"
do
[ -f "$file" ] || continue

```
cp "$file" "$file.ohmysky.bak"

sed -i.bak '/\.ohmysky\/bash\.sh/d' "$file" 2>/dev/null || true
sed -i.bak '/\.ohmysky\/zsh\.zsh/d' "$file" 2>/dev/null || true
sed -i.bak '/OhMySky/d' "$file" 2>/dev/null || true

rm -f "$file.bak"
```

done

echo
echo "[+] OhMySky files removed."
echo "[+] Startup entries removed."
echo "[+] Backups created as *.ohmysky.bak"
echo
echo "Restart your terminal or run:"
echo
echo "  source ~/.zshrc"
echo "  source ~/.bashrc"
echo
echo "OhMySky has been uninstalled."
