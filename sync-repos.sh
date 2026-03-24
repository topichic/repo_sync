#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# ==============================================
# НАСТРОЙКИ - ИЗМЕНИТЕ ПУТИ НА СВОИ
# ==============================================

# Пути к репозиториям (можно использовать как Windows, так и Unix-стиль)
# Пример Windows: "C:/Users/User/Projects/source-repo"
# Пример Unix:    "/c/Users/User/Projects/source-repo"
SOURCE_REPO_DEFAULT="C:\Users\User\mfua"
TARGET_REPO_DEFAULT="C:\Users\User\database"

# Включить автоматический git push? (true/false)
ENABLE_PUSH=false

# ==============================================
# ФУНКЦИИ
# ==============================================

# Функция для вывода с цветом
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${CYAN}=== $1 ===${NC}"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Функция для конвертации Windows-пути в Unix-путь
to_unix_path() {
    local path="$1"
    
    # Если путь в формате C:\Users\...
    if [[ "$path" =~ ^[A-Za-z]:\\ ]]; then
        local drive=$(echo "$path" | cut -c1 | tr '[:upper:]' '[:lower:]')
        local rest="${path:2}"
        echo "/$drive${rest//\\//}"
    # Если путь в формате C:/Users/...
    elif [[ "$path" =~ ^[A-Za-z]:/ ]]; then
        local drive=$(echo "$path" | cut -c1 | tr '[:upper:]' '[:lower:]')
        echo "/$drive${path:2}"
    else
        echo "$path"
    fi
}

# Функция для конвертации Unix-пути в Windows-путь (для вывода)
to_win_path() {
    local path="$1"
    
    if [[ "$path" =~ ^/([a-z])/(.*) ]]; then
        local drive=$(echo "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')
        echo "${drive}:\\${BASH_REMATCH[2]//\//\\}"
    else
        echo "$path"
    fi
}

# Функция проверки Git
check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git не найден!"
        print_info "Убедитесь, что Git Bash установлен правильно"
        return 1
    fi
    
    local git_version=$(git --version)
    print_success "Git: $git_version"
    return 0
}

# Функция проверки репозитория
check_repo() {
    local repo_path="$1"
    local repo_name="$2"
    local unix_path=$(to_unix_path "$repo_path")
    local win_path=$(to_win_path "$unix_path")
    
    print_info "Проверяю: $win_path"
    
    if [ ! -d "$unix_path" ]; then
        print_error "Папка не существует: $win_path"
        return 1
    fi
    
    if [ ! -d "$unix_path/.git" ]; then
        print_error "Не является git-репозиторием: $win_path"
        return 1
    fi
    
    print_success "Найден: $win_path"
    return 0
}

# Функция для git pull
git_pull() {
    local repo_path="$1"
    local repo_name="$2"
    local unix_path=$(to_unix_path "$repo_path")
    
    print_info "Выполняю git pull в $repo_name..."
    
    cd "$unix_path" || {
        print_error "Не могу перейти в папку"
        return 1
    }
    
    # Проверяем наличие удаленного репозитория
    if ! git remote -v 2>/dev/null | grep -q "origin"; then
        print_warning "Нет удаленного репозитория 'origin'"
        return 0
    fi
    
    # Проверяем доступ к удаленному репозиторию
    print_info "Проверяю соединение..."
    if ! git ls-remote --exit-code origin &>/dev/null; then
        print_warning "Нет доступа к удаленному репозиторию"
        print_info "Возможные причины:"
        echo "  - Нет интернета"
        echo "  - Приватный репозиторий требует аутентификации"
        echo "  - Не настроены SSH-ключи"
        
        read -p "Продолжить? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Выполняем pull
    echo "----------------------------------------"
    if git pull; then
        echo "----------------------------------------"
        print_success "Pull выполнен"
        return 0
    else
        echo "----------------------------------------"
        print_error "Ошибка при pull"
        return 1
    fi
}

# Функция для копирования (используем rsync если есть, иначе cp)
copy_files() {
    local source_path="$1"
    local target_path="$2"
    local source_unix=$(to_unix_path "$source_path")
    local target_unix=$(to_unix_path "$target_path")
    local source_win=$(to_win_path "$source_unix")
    local target_win=$(to_win_path "$target_unix")
    
    print_info "Копирую из: $source_win"
    print_info "Копирую в:  $target_win"
    print_info "Исключаю папку .git"
    
    # Пробуем использовать rsync (он часто есть в Git Bash)
    if command -v rsync &> /dev/null; then
        print_info "Использую rsync для копирования..."
        rsync -av --delete --exclude='.git' "$source_unix/" "$target_unix/"
        local result=$?
        
        if [ $result -eq 0 ]; then
            print_success "Копирование через rsync завершено"
            return 0
        else
            print_error "Ошибка при rsync"
            return 1
        fi
    else
        # Используем cp если rsync недоступен
        print_info "rsync не найден, использую cp..."
        
        # Удаляем старые файлы в целевой папке (кроме .git)
        print_info "Очищаю целевую папку..."
        
        # Безопасное удаление через find
        find "$target_unix" -mindepth 1 -not -path "$target_unix/.git*" -exec rm -rf {} \; 2>/dev/null
        
        # Копируем новые файлы
        print_info "Копирую файлы..."
        
        # Включаем поддержку скрытых файлов
        shopt -s dotglob
        
        # Копируем все кроме .git
        for item in "$source_unix"/* "$source_unix"/.[!.]* "$source_unix"/..?*; do
            if [ -e "$item" ]; then
                base=$(basename "$item")
                if [ "$base" != ".git" ]; then
                    cp -r "$item" "$target_unix/" 2>/dev/null
                fi
            fi
        done
        
        # Выключаем поддержку скрытых файлов
        shopt -u dotglob
        
        print_success "Копирование через cp завершено"
        return 0
    fi
}

# Функция для git push
git_push() {
    local repo_path="$1"
    local unix_path=$(to_unix_path "$repo_path")
    local win_path=$(to_win_path "$unix_path")
    
    print_info "Выполняю git push в $win_path..."
    
    cd "$unix_path" || {
        print_error "Не могу перейти в папку"
        return 1
    }
    
    # Проверяем изменения
    if git status --porcelain | grep -q .; then
        print_info "Есть изменения, создаю коммит..."
        
        git add .
        if [ $? -ne 0 ]; then
            print_error "Ошибка при git add"
            return 1
        fi
        
        # Коммит с датой
        local date=$(date '+%Y-%m-%d %H:%M:%S')
        git commit -m "Auto-sync: $date"
        
        if [ $? -ne 0 ] && [ $? -ne 1 ]; then
            print_error "Ошибка при git commit"
            return 1
        fi
        
        # Push если есть remote
        if git remote -v 2>/dev/null | grep -q "origin"; then
            print_info "Отправляю изменения..."
            
            if git push; then
                print_success "Push выполнен"
            else
                print_error "Ошибка при push"
                return 1
            fi
        else
            print_warning "Нет удаленного репозитория"
        fi
    else
        print_info "Нет изменений для коммита"
    fi
    
    return 0
}

# Функция для настройки Git Credential Manager
setup_git_credentials() {
    print_step "НАСТРОЙКА ДОСТУПА"
    
    echo "Выберите способ аутентификации:"
    echo "1) Git Credential Manager (сохраняет пароль в Windows)"
    echo "2) SSH-ключи"
    echo "3) Пропустить"
    
    read -p "Ваш выбор (1-3): " choice
    
    case $choice in
        1)
            print_info "Настраиваю Git Credential Manager..."
            git config --global credential.helper manager-core
            print_success "Готово! При первом pull/push введите логин/пароль"
            ;;
        2)
            print_info "Настройка SSH-ключей:"
            echo "  1. Запустите: ssh-keygen -t rsa -b 4096"
            echo "  2. Добавьте ключ в GitHub/GitLab"
            echo "  3. Настройте remote: git remote set-url origin git@github.com:user/repo.git"
            ;;
        3)
            print_info "Пропускаю настройку"
            ;;
    esac
}

# Функция для добавления в автозагрузку Windows
add_to_startup() {
    local script_path=$(realpath "$0")
    local win_script_path=$(to_win_path "$script_path")
    local startup_path="$APPDATA/Microsoft/Windows/Start Menu/Programs/Startup"
    local shortcut_name="GitRepoSync.lnk"
    
    print_step "ДОБАВЛЕНИЕ В АВТОЗАГРУЗКУ"
    
    # Создаем временный VBS скрипт для создания ярлыка
    local vbs_script=$(mktemp).vbs
    
    cat > "$vbs_script" << EOF
Set WshShell = WScript.CreateObject("WScript.Shell")
Set Shortcut = WshShell.CreateShortcut("$startup_path/$shortcut_name")
Shortcut.TargetPath = "$PROGRAMFILES\\Git\\git-bash.exe"
Shortcut.Arguments = "--cd=\"$(pwd)\" -c \"bash '$script_path' --autorun\""
Shortcut.WorkingDirectory = "$(pwd)"
Shortcut.Description = "Git Repository Auto-Sync"
Shortcut.Save()
EOF
    
    # Запускаем VBS скрипт
    cscript //nologo "$vbs_script"
    rm -f "$vbs_script"
    
    print_success "Скрипт добавлен в автозагрузку"
    print_info "Путь: $startup_path/$shortcut_name"
}

# ==============================================
# ОСНОВНАЯ ПРОГРАММА
# ==============================================

# Очищаем экран
clear

# Заголовок
print_header "=============================================="
print_header "   Git Repository Synchronization Script"
print_header "           для Git Bash в Windows"
print_header "=============================================="
echo ""

# Проверяем Git
print_step "ПРОВЕРКА СИСТЕМЫ"
if ! check_git; then
    echo ""
    read -p "Нажмите Enter для выхода..."
    exit 1
fi

# Обработка параметров командной строки
AUTORUN=false
for arg in "$@"; do
    if [ "$arg" = "--autorun" ]; then
        AUTORUN=true
    fi
done

# Получаем пути к репозиториям
if [ "$AUTORUN" = true ]; then
    # Автоматический режим - используем пути по умолчанию
    SOURCE_REPO="$SOURCE_REPO_DEFAULT"
    TARGET_REPO="$TARGET_REPO_DEFAULT"
    print_info "Автоматический запуск"
    print_info "Source: $(to_win_path $(to_unix_path "$SOURCE_REPO"))"
    print_info "Target: $(to_win_path $(to_unix_path "$TARGET_REPO"))"
else
    # Интерактивный режим
    print_step "ВВОД ПУТЕЙ"
    
    echo "Примеры путей:"
    echo "  /c/Users/User/Projects/source-repo"
    echo "  C:/Users/User/Projects/source-repo"
    echo "  C:\\Users\\User\\Projects\\source-repo"
    echo ""
    
    # Исходный репозиторий
    read -p "Исходный репозиторий [$SOURCE_REPO_DEFAULT]: " SOURCE_REPO_INPUT
    SOURCE_REPO="${SOURCE_REPO_INPUT:-$SOURCE_REPO_DEFAULT}"
    
    # Целевой репозиторий
    read -p "Целевой репозиторий [$TARGET_REPO_DEFAULT]: " TARGET_REPO_INPUT
    TARGET_REPO="${TARGET_REPO_INPUT:-$TARGET_REPO_DEFAULT}"
fi

echo ""

# Проверяем исходный репозиторий
print_step "ПРОВЕРКА ИСХОДНОГО РЕПОЗИТОРИЯ"
if ! check_repo "$SOURCE_REPO" "Source"; then
    echo ""
    read -p "Нажмите Enter для выхода..."
    exit 1
fi

echo ""

# Проверяем целевой репозиторий
print_step "ПРОВЕРКА ЦЕЛЕВОГО РЕПОЗИТОРИЯ"
if ! check_repo "$TARGET_REPO" "Target"; then
    echo ""
    read -p "Нажмите Enter для выхода..."
    exit 1
fi

echo ""

# Настройка доступа для приватных репозиториев (только в интерактивном режиме)
if [ "$AUTORUN" = false ]; then
    print_step "ПРИВАТНЫЕ РЕПОЗИТОРИИ"
    read -p "Настроить доступ к приватным репозиториям? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_git_credentials
    fi
    echo ""
fi

# Подтверждение запуска (только в интерактивном режиме)
if [ "$AUTORUN" = false ]; then
    print_step "ПОДТВЕРЖДЕНИЕ"
    echo "Будет выполнено:"
    echo "  1. git pull в исходном репозитории"
    echo "  2. Копирование всех файлов (кроме .git) в целевой репозиторий"
    if [ "$ENABLE_PUSH" = true ]; then
        echo "  3. git push в целевом репозитории"
    fi
    echo ""
    
    read -p "Продолжить? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Синхронизация отменена"
        read -p "Нажмите Enter для выхода..."
        exit 0
    fi
    echo ""
fi

# Шаг 1: Git pull
print_step "ШАГ 1: ОБНОВЛЕНИЕ ИСХОДНОГО РЕПОЗИТОРИЯ"
if ! git_pull "$SOURCE_REPO" "исходном"; then
    print_warning "Продолжаем, несмотря на ошибку"
fi
echo ""

# Шаг 2: Копирование
print_step "ШАГ 2: КОПИРОВАНИЕ В ЦЕЛЕВОЙ РЕПОЗИТОРИЙ"
if ! copy_files "$SOURCE_REPO" "$TARGET_REPO"; then
    print_error "Ошибка при копировании"
    read -p "Нажмите Enter для выхода..."
    exit 1
fi
echo ""

# Шаг 3: Опциональный push
if [ "$ENABLE_PUSH" = true ]; then
    print_step "ШАГ 3: ОТПРАВКА ИЗМЕНЕНИЙ"
    if ! git_push "$TARGET_REPO"; then
        print_warning "Ошибка при push"
    fi
    echo ""
fi

# Завершение
print_step "ГОТОВО"
print_success "СИНХРОНИЗАЦИЯ ЗАВЕРШЕНА!"
print_header "=============================================="

# Добавление в автозагрузку (только в интерактивном режиме)
if [ "$AUTORUN" = false ]; then
    echo ""
    read -p "Добавить скрипт в автозагрузку Windows? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        add_to_startup
    fi
fi

# Ожидание нажатия клавиши если запущено не из терминала
if [ "$AUTORUN" = false ] && [ -t 0 ]; then
    echo ""
    read -p "Нажмите Enter для выхода..."
fi

exit 0