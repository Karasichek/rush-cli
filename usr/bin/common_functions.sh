#!/bin/sh

# === ОБЩИЕ ФУНКЦИИ RUSH CLI ===

# Функция для запуска команд с повышением привилегий
run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        # Уже root
        "$@"
    else
        # Не root
        if command -v sudo >/dev/null 2>&1; then
            sudo "$@"
        elif command -v doas >/dev/null 2>&1; then
            doas "$@"
        elif command -v su >/dev/null 2>&1; then
            su -c "$*"
        else
            "$@"
        fi
    fi
}

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

# Проверка сети (расширенная)
site-check() {
    local sites="google.com github.com yandex.ru amazon.com wikipedia.org"
    sep "=" "NETWORK"
    for site in $sites; do
        if ping -c 1 -W 2 "$site" >/dev/null 2>&1; then
            local ping_ms=$(ping -c 1 -W 2 "$site" | grep -oE 'time=[0-9.]+' | cut -d= -f2)
            printf "[ \033[32mOK\033[0m ] %-15s — %s ms\n" "$site" "$ping_ms"
        else
            printf "[ \033[31mFAIL\033[0m ] %-15s\n" "$site"
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

# Работа с пакетами (с повышением привилегий)
pack() {
    if command -v apt >/dev/null 2>&1; then
        if [ $# -gt 0 ]; then
            run_as_root apt install "$@"
        else
            run_as_root apt update && run_as_root apt upgrade
        fi
    elif command -v dnf >/dev/null 2>&1; then
        if [ $# -gt 0 ]; then
            run_as_root dnf install "$@"
        else
            run_as_root dnf upgrade
        fi
    elif command -v pacman >/dev/null 2>&1; then
        if [ $# -gt 0 ]; then
            run_as_root pacman -S "$@"
        else
            run_as_root pacman -Syu
        fi
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

# Последняя сессия tmux
latest() {
    local sessions=$(tmux list-sessions -F "#{session_name} #{session_created}" 2>/dev/null)
    [ -z "$sessions" ] && return 1
    local latest_session=$(echo "$sessions" | sort -k2 -rn | head -1)
    local session_name=$(echo "$latest_session" | awk '{print $1}')
    local session_time=$(echo "$latest_session" | awk '{print $2}')
    local now=$(date +%s)
    echo "Сессия: $session_name ($(date -d "@$session_time" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "время неизвестно"))"
    [ $(( now - session_time )) -lt 43200 ] && tmux attach-session -t "$session_name" || echo "Сессия старая, создайте новую"
}

# Проверка сети (старое название для совместимости)
net() { site-check; }

# Warp (древовидный список)
warp() {
    if command -v eza >/dev/null 2>&1; then
        eza -T --git -s extension --icons --all "$@"
    else
        command tree -a "$@"
    fi
}
