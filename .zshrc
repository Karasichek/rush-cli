FLAG_FILE="$HOME/FLAG"
CONF_FILE="/data/data/com.termux/files/home/usr/bin/zsh/conf"

chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

tmux
. $HOME/usr/bin/zsh/SEARCH-FETCH-CONFIG

if [[ -f "$CONF_FILE" ]]; then
    . "$CONF_FILE"
else
    echo "Конфиг не найден: $CONF_FILE"
fi

if [ ! -f "$FLAG_FILE" ]; then
    apt update && apt install -y tmux hx xmake rsync eza fastfetch ncurses-utils git figlet
    touch "$FLAG_FILE"
fi

# === АЛИАСЫ ===
alias blackout="zsh --no-rcs"            
alias zshrc="hx ~/.zshrc"            
alias config='hx "$HOME/usr/bin/zsh/conf"' 
alias reload="source ~/.zshrc && tmux clear-history"        
alias filsync="rsync -av --progress ~/CODE/Go/compiled/ /usr/bin/fil/"
alias backup='rsync -av --delete --inplace --no-owner --no-group --exclude=".cache" --exclude="tmp" --exclude="**/node_modules" ~/ /sdcard/termux/'
alias backfrom='rsync -av --delete --inplace --no-owner --no-group --chmod=ugo=rwX /sdcard/termux/ ~/'
alias bin='/data/data/com.termux/files/usr/usr/bin/bin'
