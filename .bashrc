export RUSH_VERS="1.4.0"

# === КАСТОМИЗАЦИЯ ===
export USRNAME="spark"
export HSTNAME="localhost"
export PS1="\[\e[34m\]$USRNAME\[\e[0m\]@\[\e[33m\]$HSTNAME\[\e[0m\]: "

# === ПУТИ ===
export FLAG_FILE="$HOME/FLAG"
export CONF_FILE="$HOME/usr/bin/conf"
export FETCH_FILE="$HOME/usr/bin/SEARCH-FETCH-CONFIG"
export ALIAS_FILE="$HOME/usr/aliases.sh"
export BIN_FOLDER="$HOME/usr/bin"
export NOTES_FOLDER="$HOME/.notes"

export PREFIX="${PREFIX:-$HOME}"
export BINPATH="$PREFIX/usr/bin"
export FILPATH="$PREFIX/FIL/compiled"
export SCRIPTS="$PREFIX/scripts"
export PATH="$BINPATH:$FILPATH:$SCRIPTS:$PATH"
export BACKUP_FOLDER="/sdcard/termux/"

# === PATH ===
export LUA_PATH="$HOME/usr/lua/?.lua;;"
export LUA_CPATH="$HOME/usr/lua/?.so;;"

# === УСТАНОВКА ПАКЕТОВ ===
if [ ! -f "$FLAG_FILE" ]; then
    apt update && apt install -y micro xmake rsync eza fastfetch ncurses-utils git figlet lua54 lazygit fzf lf tgpt
    touch "$FLAG_FILE"
fi

# === SSH ПРАВА ===
chmod 700 ~/.ssh 2>/dev/null
chmod 600 ~/.ssh/id_ed25519 2>/dev/null
chmod 644 ~/.ssh/id_ed25519.pub 2>/dev/null

# === КОНФИГИ ===
[ -f "$CONF_FILE" ] && . "$CONF_FILE"
[ -f "$FETCH_FILE" ] && . "$FETCH_FILE"
[ -f "$ALIAS_FILE" ] && . "$ALIAS_FILE"

# === АЛИАСЫ ===
alias blackout="bash --norc"
alias bashrc="micro ~/.bashrc"
alias config='micro "$CONF_FILE"'
alias reload="source ~/.bashrc"
alias aliases="micro $ALIAS_FILE"

# === БЭКАПЫ ===
alias backup='rsync -av -q --delete --inplace --no-owner --no-group --exclude=".cache" --exclude=".npm" --exclude="**/node_modules" ~/ $BACKUP_FOLDER'
alias backfrom='rsync -av -q --delete --inplace --no-owner --no-group --chmod=ugo=rwX $BACKUP_FOLDER ~/'
