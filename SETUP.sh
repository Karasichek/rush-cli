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
sudo apt update

# Установка пакетов
print_stage "Установка пакетов: tmux, helix, xmake, rsync, eza, fastfetch, ncurses-utils, git, figlet, lf, lua5.4, lazygit, miniserve..."
sudo apt install -y tmux helix xmake rsync eza fastfetch ncurses-utils git figlet lf lua5.4 miniserve

# Установка lazygit (может отсутствовать в стандартных репозиториях)
if ! command -v lazygit >/dev/null 2>&1; then
    print_warning "lazygit не найден в стандартных репозиториях, устанавливаю из официального репозитория..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    if [ -n "$LAZYGIT_VERSION" ]; then
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        rm -f lazygit lazygit.tar.gz
        print_stage "lazygit успешно установлен"
    else
        print_error "Не удалось определить версию lazygit"
    fi
fi

# Развёртывание конфигурации
print_stage "Развёртывание конфигурации из текущей директории..."
# Копируем содержимое текущей директории в $HOME (кроме .git и самого SETUP.sh)
rsync -av --exclude='.git' --exclude='SETUP.sh' ./ "$HOME/" 2>/dev/null
print_stage "Конфигурация скопирована в $HOME"

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
    if [ -d "$HOME/usr/bin" ] && ! echo "$PATH" | grep -q "$HOME/usr/bin"; then
        echo "" >> "$profile_file"
        echo "# Add rush-cli bin to PATH" >> "$profile_file"
        echo "export PATH=\"\$HOME/usr/bin:\$PATH\"" >> "$profile_file"
    fi
    
    echo "${GREEN}✓ Установлен ENV=$shrc_file для shell: $current_shell${RESET}"
    
    # Экспортируем ENV для текущей сессии
    export ENV="$HOME/.shrc"
else
    echo "${GREEN}✓ Shell ($current_shell) имеет собственную конфигурацию, .shrc не требуется${RESET}"
    
    # Для zsh/bash также добавим путь к бинарникам в PATH если нужно
    config_file=""
    if [ "$current_shell" = "zsh" ]; then
        config_file="$HOME/.zshrc"
    elif [ "$current_shell" = "bash" ]; then
        config_file="$HOME/.bashrc"
    fi
    
    if [ -n "$config_file" ]; then
        if [ -d "$HOME/usr/bin" ] && ! grep -q "usr/bin" "$config_file" 2>/dev/null; then
            echo "export PATH=\"\$HOME/usr/bin:\$PATH\"" >> "$config_file"
        fi
    fi
fi

# Установка fzf-tab для Zsh
if [ ! -d "$HOME/.fzf-tab" ]; then
    print_stage "Установка fzf-tab..."
    git clone https://github.com/Aloxaf/fzf-tab "$HOME/.fzf-tab"
fi

print_stage "Установка завершена успешно!"

# Запуск shell
print_stage "Запуск оболочки..."
if command -v zsh >/dev/null 2>&1; then
    exec zsh
elif command -v bash >/dev/null 2>&1; then
    exec bash
else
    exec sh
fi
