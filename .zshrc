# === КАСТОМИЗАЦИЯ ===
export USRNAME="spark"
export HSTNAME="localhost"
export PS1="%F{blue}$USRNAME%f%F{white}@%f%F{yellow}$HSTNAME%f: %F{default}"

# === ПУТИ ===
export FLAG_FILE="$HOME/FLAG"
export CONF_FILE="$HOME/usr/bin/zsh/conf"
export FETCH_FILE="$HOME/usr/bin/zsh/SEARCH-FETCH-CONFIG"
export BIN_FOLDER="$HOME/usr/bin"
export NOTES_FOLDER="$HOME/.notes"
export PREFIX="${PREFIX:-$HOME}"
export BINPATH="$PREFIX/usr/bin"
export FILPATH="$PREFIX/FIL/compiled"
export SCRIPTS="$PREFIX/scripts"
export PATH="$BINPATH:$FILPATH:$SCRIPTS:$PATH"

# === УСТАНОВКА ПАКЕТОВ ===
if [ ! -f "$FLAG_FILE" ]; then
    apt update && apt install -y helix xmake rsync eza fastfetch ncurses-utils git figlet lf lua54 lazygit
    touch "$FLAG_FILE"
fi

# === SSH ПРАВА ===
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# === КОНФИГИ ===
. $CONF_FILE
. $FETCH_FILE

# === АЛИАСЫ ===
alias blackout="zsh --no-rcs"            
alias zshrc="hx ~/.zshrc"            
alias config='hx "$CONF_FILE"' 
alias reload="source ~/.zshrc && tmux clear-history"

# === БЭКАПЫ ===
alias backup='rsync -av --delete --inplace --no-owner --no-group --exclude=".cache" --exclude="tmp" --exclude="**/node_modules" ~/ /sdcard/termux/'
alias backfrom='rsync -av --delete --inplace --no-owner --no-group --chmod=ugo=rwX /sdcard/termux/ ~/'