#!/usr/bin/env bash

chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

FLAG_FILE="$HOME/FLAG"
CONF_FILE="/data/data/com.termux/files/home/usr/bin/conf"

if [[ -f "$CONF_FILE" ]]; then
   . "$CONF_FILE"
else
   echo "⚠️ Конфиг не найден: $CONF_FILE"
fi

if [ ! -f "$FLAG_FILE" ]; then
   apt update && apt install -y tmux micro rsync eza fastfetch ncurses-utils git
   touch "$FLAG_FILE"
fi

# === АЛИАСЫ ===
alias blackout="bash --norc"
alias bashrc="micro -clipboard internal ~/.bashrc"
alias config='micro -clipboard internal "~/usr/bin/conf"'
alias reload="source ~/.bashrc"
alias filsync="rsync -av --progress ~/CODE/Go/compiled/ /usr/bin/fil/"
alias backup='rsync -av --delete --inplace --no-owner --no-group --exclude=".cache" --exclude="tmp" --exclude="**/node_modules" ~/ /sdcard/termux/'
alias backfrom='rsync -av --delete --inplace --no-owner --no-group --chmod=ugo=rwX /sdcard/termux/ ~/'

[[ -n "$TMUX" ]] && trap 'tmux detach' EXIT

tmux
