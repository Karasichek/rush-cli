#!/bin/sh

# Установка цветового вывода (если доступно)
if command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RESET=$(tput sgr0)
else
    RED=""; GREEN=""; YELLOW=""; RESET=""
fi

print_stage() {
    echo "${GREEN}[STAGE] - $1${RESET}"
}

print_error() {
    echo "${RED}[ERROR] - $1${RESET}"
}

print_warning() {
    echo "${YELLOW}[WARNING] - $1${RESET}"
}

# Проверка наличия apt
if ! command -v apt >/dev/null 2>&1; then
    print_error "apt не найден"
    exit 1
fi

# Обновление списка пакетов
print_stage "Обновление списка пакетов..."
apt update

# Установка пакетов
print_stage "Установка пакетов: tmux, helix, xmake, rsync, eza, fastfetch, ncurses-utils, git, figlet, lf, lua5.4, lazygit..."
apt install -y tmux helix xmake rsync eza fastfetch ncurses-utils git figlet lf lua54

# Установка lazygit (может отсутствовать в стандартных репозиториях)
if ! command -v lazygit >/dev/null 2>&1; then
    print_warning "lazygit не найден в стандартных репозиториях, устанавливаю из официального репозитория..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    if [ -n "$LAZYGIT_VERSION" ]; then
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        install lazygit /usr/local/bin
        rm -f lazygit lazygit.tar.gz
        print_stage "lazygit успешно установлен"
    else
        print_error "Не удалось определить версию lazygit"
    fi
fi

# Копирование репозитория rush-cli
print_stage "Клонирование и копирование репозитория Karasichek/rush-cli..."
TEMP_DIR=$(mktemp -d)
if git clone --depth 1 https://github.com/Karasichek/rush-cli.git "$TEMP_DIR/rush-cli" 2>/dev/null; then
    # Копируем всё кроме .git
    cd "$TEMP_DIR/rush-cli" || exit 1
    # Используем rsync для копирования с исключением .git
    rsync -av --exclude='.git' ./ "$HOME/" 2>/dev/null
    cd - >/dev/null || exit 1
    rm -rf "$TEMP_DIR"
    print_stage "Репозиторий скопирован в $HOME"
else
    print_error "Не удалось клонировать репозиторий"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Настройка ENV для login shell
print_stage "Настройка окружения login shell..."

# Получаем имя текущей login shell
current_shell=$(basename "$SHELL")

# Список shell'ов, которые НЕ нуждаются в .shrc
exclude_shells="bash zsh ksh"

# Функция проверки, входит ли shell в список исключений
is_excluded() {
    case " $exclude_shells " in
        *" $1 "*) return 0 ;;
        *) return 1 ;;
    esac
}

# Если текущий shell НЕ в списке исключений
if ! is_excluded "$current_shell"; then
    # Путь к файлу .shrc в домашней директории
    shrc_file="$HOME/.shrc"
    
    # Создаём .shrc, если его нет
    if [ ! -f "$shrc_file" ]; then
        echo "# Auto-generated config for $current_shell" > "$shrc_file"
        echo "# Add your aliases and functions here" >> "$shrc_file"
        echo "" >> "$shrc_file"
        echo "# Example: alias ll='ls -la'" >> "$shrc_file"
        echo "" >> "$shrc_file"
        echo "# rush-cli aliases (if any)" >> "$shrc_file"
        if [ -f "$HOME/.aliases" ]; then
            echo "# Source rush-cli aliases" >> "$shrc_file"
            echo "[ -f \"\$HOME/.aliases\" ] && . \"\$HOME/.aliases\"" >> "$shrc_file"
        fi
    fi
    
    # Устанавливаем ENV в .profile, если ещё не установлена
    profile_file="$HOME/.profile"
    
    if [ -f "$profile_file" ] && ! grep -q "^ENV=" "$profile_file"; then
        echo "" >> "$profile_file"
        echo "# Set ENV for $current_shell" >> "$profile_file"
        echo "ENV=\"$shrc_file\"" >> "$profile_file"
        echo "export ENV" >> "$profile_file"
    elif [ ! -f "$profile_file" ]; then
        echo "# ENV configuration for $current_shell" > "$profile_file"
        echo "ENV=\"$shrc_file\"" >> "$profile_file"
        echo "export ENV" >> "$profile_file"
    fi
    
    # Добавляем rush-cli в PATH если нужно
    if [ -d "$HOME/.local/bin" ] && ! grep -q "PATH.*\.local/bin" "$profile_file"; then
        echo "" >> "$profile_file"
        echo "# Add local bin to PATH" >> "$profile_file"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$profile_file"
    fi
    
    echo "${GREEN}✓ Установлен ENV=$shrc_file для shell: $current_shell${RESET}"
    
    # Экспортируем ENV для текущей сессии
    export ENV="$HOME/.shrc"
else
    echo "${GREEN}✓ Shell ($current_shell) имеет собственную конфигурацию, .shrc не требуется${RESET}"
fi

print_stage "Установка завершена успешно!"

# Запуск login shell снова
print_stage "Запуск login shell..."

# Очистка и перезапуск shell
exec "$SHELL" -l