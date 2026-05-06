#!/bin/sh

# === ОБЩИЕ ФУНКЦИИ RUSH CLI ===

# Разделитель
sep() {
    local char="${1:-=}"
    local text="$2"
    local width=$(tput cols 2>/dev/null || echo 80)
    if [ -z "$text" ]; then
        printf "%${width}s\n" | tr " " "$char"
    else
        echo "$text" | awk -v w="$width" -v c="$char" '{
            len=length($0);
            left=int((w-len-2)/2);
            right=w-len-2-left;
            for(i=0;i<left;i++) printf c;
            printf " %s ", $0;
            for(i=0;i<right;i++) printf c;
            print ""
        }'
    fi
}

# Проверка сети
site-check() {
    local sites="google.com github.com yandex.ru"
    sep "=" "NETWORK"
    for site in $sites; do
        if ping -c 1 -W 1 "$site" >/dev/null 2>&1; then
            printf "[ \033[32mOK\033[0m ] %s\n" "$site"
        else
            printf "[ \033[31mFAIL\033[0m ] %s\n" "$site"
        fi
    done
    sep "="
}

# Погода
weather() {
    if [ -z "$1" ]; then
        echo "Ошибка: укажите город"
        return 1
    fi
    local city="$1"
    printf '\e[?1049h'
    clear
    figlet -f slant -t -c "$city" 2>/dev/null || echo "=== $city ==="
    curl -s --fail "wttr.in/$city?Tn" || echo "Ошибка получения данных"
    echo "Press any key to exit"
    read -r dummy
    printf '\e[?1049l'
}

# Работа с пакетами
pack() {
    if command -v apt >/dev/null 2>&1; then
        [ $# -gt 0 ] && sudo apt install "$@" || (sudo apt update && sudo apt upgrade)
    elif command -v dnf >/dev/null 2>&1; then
        [ $# -gt 0 ] && sudo dnf install "$@" || sudo dnf upgrade
    elif command -v pacman >/dev/null 2>&1; then
        [ $# -gt 0 ] && sudo pacman -S "$@" || sudo pacman -Syu
    fi
}

# Поиск пакетов
search() {
    if command -v apt >/dev/null 2>&1; then
        apt search "$@"
    elif command -v dnf >/dev/null 2>&1; then
        dnf search "$@"
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Ss "$@"
    fi
}

# Заметки
note() {
    mkdir -p "$NOTES_FOLDER"
    local filename="${1:-$(date +%Y-%m-%d)}.txt"
    local editor="${EDITOR:-micro}"
    command -v "$editor" >/dev/null 2>&1 || editor="nano"
    "$editor" "$NOTES_FOLDER/$filename"
}

# Проверка репозитория
repo-check() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Не в git-репозитории"
        return 2
    fi
    git fetch origin 2>/dev/null
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u} 2>/dev/null || git rev-parse origin/master)
    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "Всё актуально"
    else
        echo "Есть обновления!"
        return 1
    fi
}

# Создание алиаса
bandage() {
    local TARGET_FILE="${ALIAS_FILE:-${HOME}/usr/aliases.sh}"
    echo "╭" && sep "─" "Creating alias"
    printf "│ Alias name: " && read -r ALIAS_NAME
    printf "│ For command: " && read -r ALIAS_COMMAND
    printf "│ Some description: " && read -r ALIAS_DESCRIPTION
    echo "╰" && sep "─" ""
    local ESCAPED_COMMAND=$(printf "%q" "$ALIAS_COMMAND")
    printf "\n# %s: %s\nalias %s=\"%s\"\n" "$ALIAS_NAME" "$ALIAS_DESCRIPTION" "$ALIAS_NAME" "$ESCAPED_COMMAND" >> "$TARGET_FILE"
    [ -f "$TARGET_FILE" ] && . "$TARGET_FILE"
    echo "Алиас '$ALIAS_NAME' добавлен в $TARGET_FILE"
}

# Просмотр документации
view-docs() {
    local DOCS_DIR="${HOME}/rush-cli/site"
    [ ! -d "$DOCS_DIR" ] && echo "Документация не собрана." && return 1
    local PORT=8080
    echo "Сервер: http://localhost:$PORT"
    if command -v termux-open-url >/dev/null 2>&1; then termux-open-url "http://localhost:$PORT"
    elif command -v xdg-open >/dev/null 2>&1; then xdg-open "http://localhost:$PORT" >/dev/null 2>&1
    elif command -v open >/dev/null 2>&1; then open "http://localhost:$PORT"
    fi
    miniserve "$DOCS_DIR" -p "$PORT" --index index.html
}
