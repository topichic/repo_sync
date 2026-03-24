powershell

$SCRIPT:SOURCE_REPO_DEFAULT = "C:\Users\User\mfua"
$SCRIPT:TARGET_REPO_DEFAULT = "C:\Users\YourUsername\Projects\target-repo"
$SCRIPT:ENABLE_PUSH = $false

# Показывать подробный вывод? (true/false)
$SCRIPT:VERBOSE_OUTPUT = $true
function Write-ColorInfo {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host "[INFO] $Message" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

# Функция для проверки наличия Git в системе
function Test-GitInstalled {
    try {
        $gitVersion = git --version 2>$null
        if ($gitVersion) {
            Write-Success "Git найден: $gitVersion"
            return $true
        }
    } catch {
        Write-Error "Git не найден в системе!"
        Write-ColorInfo "Скачайте и установите Git с сайта: https://git-scm.com/download/win" -Color Yellow
        Write-ColorInfo "После установки перезапустите PowerShell" -Color Yellow
        return $false
    }
}

# Функция для проверки репозитория
function Test-Repository {
    param(
        [string]$RepoPath,
        [string]$RepoName
    )
    
    Write-ColorInfo "Проверяю путь: $RepoPath" -Color Blue
    
    # Проверяем существование папки
    if (-not (Test-Path $RepoPath)) {
        Write-Error "Директория $RepoName не существует: $RepoPath"
        return $false
    }
    
    # Проверяем наличие папки .git
    $gitPath = Join-Path $RepoPath ".git"
    if (-not (Test-Path $gitPath)) {
        Write-Error "В директории $RepoName нет папки .git (это не git-репозиторий): $RepoPath"
        return $false
    }
    
    Write-Success "$RepoName найден: $RepoPath"
    return $true
}

# Функция для выполнения git pull
function Invoke-GitPull {
    param(
        [string]$RepoPath,
        [string]$RepoName
    )
    
    Write-ColorInfo "Выполняю git pull в $RepoName..." -Color Blue
    
    # Сохраняем текущую директорию
    $currentLocation = Get-Location
    
    try {
        Set-Location $RepoPath -ErrorAction Stop
        
        # Проверяем наличие удаленного репозитория
        $remotes = git remote -v 2>$null
        if ($remotes -notmatch "origin") {
            Write-Warning "В репозитории нет удаленного репозитория 'origin'. Пропускаю pull."
            return $true
        }
        
        # Проверяем подключение к удаленному репозиторию
        Write-ColorInfo "Проверяю доступ к удаленному репозиторию..." -Color Blue
        $remoteCheck = git ls-remote --exit-code origin 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Не удалось подключиться к удаленному репозиторию."
            Write-ColorInfo "Возможные причины:" -Color Yellow
            Write-ColorInfo "  - Нет интернета" -Color Yellow
            Write-ColorInfo "  - Приватный репозиторий требует аутентификации" -Color Yellow
            Write-ColorInfo "  - Не настроены SSH-ключи или Git Credentials" -Color Yellow
            
            $choice = Read-Host "Продолжить выполнение? (y/n)"
            if ($choice -ne 'y') {
                return $false
            }
        }
        
        # Выполняем git pull
        Write-ColorInfo "Загружаю изменения из удаленного репозитория..." -Color Blue
        Write-Host "------------------- git pull output -------------------"
        
        $pullOutput = git pull 2>&1
        $pullResult = $LASTEXITCODE
        
        Write-Host $pullOutput
        Write-Host "--------------------------------------------------------"
        
        if ($pullResult -eq 0) {
            Write-Success "git pull в $RepoName выполнен успешно"
            return $true
        } else {
            Write-Error "Ошибка при выполнении git pull в $RepoName"
            return $false
        }
    }
    catch {
        Write-Error "Ошибка при выполнении git pull: $_"
        return $false
    }
    finally {
        # Возвращаемся в исходную директорию
        Set-Location $currentLocation
    }
}

# Функция для копирования содержимого репозитория
function Copy-RepositoryContents {
    param(
        [string]$SourcePath,
        [string]$TargetPath
    )
    
    Write-ColorInfo "Копирую содержимое из исходного репозитория в целевой..." -Color Blue
    Write-ColorInfo "Исходный:  $SourcePath" -Color Blue
    Write-ColorInfo "Целевой:   $TargetPath" -Color Blue
    Write-ColorInfo "Исключаю папку .git" -Color Blue
    
    # Нормализуем пути
    $SourcePath = $SourcePath.TrimEnd('\')
    $TargetPath = $TargetPath.TrimEnd('\')
    
    try {
        # Получаем список всех элементов в исходной папке (кроме .git)
        Write-ColorInfo "Сканирую исходную папку..." -Color Blue
        $sourceItems = Get-ChildItem -Path $SourcePath -Force | Where-Object { $_.Name -ne ".git" }
        
        # Копируем новые файлы из исходной папки
        Write-ColorInfo "Копирую новые файлы..." -Color Green
        
        $copiedCount = 0
        $skippedCount = 0
        
        foreach ($item in $sourceItems) {
            $sourceItemPath = $item.FullName
            $targetItemPath = Join-Path $TargetPath $item.Name
            
            try {
                if ($item.PSIsContainer) {
                    # Копируем папку рекурсивно
                    Copy-Item -Path $sourceItemPath -Destination $targetItemPath -Recurse -Force -ErrorAction Stop
                    if ($SCRIPT:VERBOSE_OUTPUT) {
                        Write-Host "  [КОПИЯ] Папка: $($item.Name)" -ForegroundColor Gray
                    }
                } else {
                    # Копируем файл
                    Copy-Item -Path $sourceItemPath -Destination $targetItemPath -Force -ErrorAction Stop
                    if ($SCRIPT:VERBOSE_OUTPUT) {
                        Write-Host "  [КОПИЯ] Файл: $($item.Name)" -ForegroundColor Gray
                    }
                }
                $copiedCount++
            }
            catch {
                Write-Warning "Не удалось скопировать $($item.Name): $($_.Exception.Message)"
                $skippedCount++
            }
        }
        
        Write-Success "Копирование завершено!"
        Write-ColorInfo "  Скопировано: $copiedCount" -Color Green
        if ($skippedCount -gt 0) {
            Write-ColorInfo "  Пропущено: $skippedCount" -Color Yellow
        }
        
        return $true
    }
    catch {
        Write-Error "Критическая ошибка при копировании: $_"
        return $false
    }
}

# Функция для выполнения git push в целевом репозитории
function Invoke-GitPush {
    param(
        [string]$RepoPath
    )
    
    Write-ColorInfo "Выполняю git push в целевом репозитории..." -Color Blue
    
    # Сохраняем текущую директорию
    $currentLocation = Get-Location
    
    try {
        Set-Location $RepoPath -ErrorAction Stop
        
        # Проверяем, есть ли изменения
        $status = git status --porcelain
        if ($status) {
            Write-ColorInfo "Есть изменения, создаю коммит..." -Color Blue
            
            # Добавляем все изменения
            git add .
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Ошибка при git add"
                return $false
            }
            
            # Создаем коммит с текущей датой
            $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            git commit -m "Auto-sync: $date"
            
            if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
                Write-Error "Ошибка при git commit"
                return $false
            }
            
            # Проверяем наличие удаленного репозитория
            $remotes = git remote -v 2>$null
            if ($remotes -match "origin") {
                Write-ColorInfo "Отправляю изменения в удаленный репозиторий..." -Color Blue
                
                $pushOutput = git push 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "git push выполнен успешно"
                } else {
                    Write-Error "Ошибка при git push"
                    Write-Host $pushOutput -ForegroundColor Red
                    return $false
                }
            } else {
                Write-Warning "Нет удаленного репозитория 'origin', пропускаю push"
            }
        } else {
            Write-ColorInfo "Нет изменений для коммита" -Color Green
        }
        
        return $true
    }
    catch {
        Write-Error "Ошибка при выполнении git push: $_"
        return $false
    }
    finally {
        Set-Location $currentLocation
    }
}

# Функция для настройки Git Credential Manager (для приватных репозиториев)
function Set-GitCredentials {
    Write-Step "Настройка доступа к приватным репозиториям"
    
    Write-ColorInfo "Выберите способ аутентификации для приватных репозиториев:" -Color Cyan
    Write-Host "1. Git Credential Manager (рекомендуется) - сохраняет пароль в Windows"
    Write-Host "2. SSH-ключи - требуется настройка ключей"
    Write-Host "3. Пропустить настройку"
    
    $choice = Read-Host "Ваш выбор (1-3)"
    
    switch ($choice) {
        '1' {
            Write-ColorInfo "Настраиваю Git Credential Manager..." -Color Blue
            git config --global credential.helper manager-core
            Write-Success "Git Credential Manager настроен"
            Write-ColorInfo "При первом pull/push введите логин и пароль, они сохранятся" -Color Yellow
        }
        '2' {
            Write-ColorInfo "Информация по настройке SSH-ключей:" -Color Blue
            Write-Host "1. Откройте Git Bash"
            Write-Host "2. Выполните: ssh-keygen -t rsa -b 4096"
            Write-Host "3. Добавьте публичный ключ в настройках GitHub/GitLab"
            Write-Host "4. Настройте remote: git remote set-url origin git@github.com:user/repo.git"
        }
        '3' {
            Write-ColorInfo "Настройка пропущена" -Color Yellow
        }
    }
}

# Функция для добавления в автозагрузку Windows
function Add-ToStartup {
    param(
        [string]$ScriptPath
    )
    
    Write-Step "Добавление в автозагрузку Windows"
    
    $startupFolder = [Environment]::GetFolderPath("Startup")
    $shortcutPath = Join-Path $startupFolder "GitRepoSync.lnk"
    
    try {
        $WScriptShell = New-Object -ComObject WScript.Shell
        $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`" -AutoRun"
        $shortcut.Description = "Git Repository Auto-Sync"
        $shortcut.WorkingDirectory = Split-Path $ScriptPath -Parent
        $shortcut.Save()
        
        Write-Success "Скрипт добавлен в автозагрузку"
        Write-ColorInfo "Ярлык создан: $shortcutPath" -Color Blue
    }
    catch {
        Write-Error "Не удалось добавить в автозагрузку: $_"
    }
}

# ==============================================
# ОСНОВНАЯ ЛОГИКА
# ==============================================

# Очищаем экран
Clear-Host

# Заголовок
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "   Git Repository Synchronization Script" -ForegroundColor Cyan
Write-Host "           для Windows PowerShell" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Проверяем наличие Git
if (-not (Test-GitInstalled)) {
    Write-Host ""
    Write-Host "Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Получаем параметры командной строки
param(
    [switch]$AutoRun
)

# Если это автоматический запуск, используем пути по умолчанию без запросов
if ($AutoRun) {
    $SOURCE_REPO = $SCRIPT:SOURCE_REPO_DEFAULT
    $TARGET_REPO = $SCRIPT:TARGET_REPO_DEFAULT
    Write-ColorInfo "Автоматический запуск. Использую пути по умолчанию:" -Color Blue
    Write-ColorInfo "  Source: $SOURCE_REPO" -Color Blue
    Write-ColorInfo "  Target: $TARGET_REPO" -Color Blue
} else {
    # Интерактивный режим - запрашиваем пути
    Write-Host "----------------------------------------------" -ForegroundColor Cyan
    Write-ColorInfo "Укажите пути к репозиториям" -Color Cyan
    Write-Host "----------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    
    # Исходный репозиторий
    $SOURCE_REPO = Read-Host "Исходный репозиторий (откуда копировать) [$($SCRIPT:SOURCE_REPO_DEFAULT)]"
    if ([string]::IsNullOrWhiteSpace($SOURCE_REPO)) {
        $SOURCE_REPO = $SCRIPT:SOURCE_REPO_DEFAULT
    }
    
    # Целевой репозиторий
    $TARGET_REPO = Read-Host "Целевой репозиторий (куда копировать) [$($SCRIPT:TARGET_REPO_DEFAULT)]"
    if ([string]::IsNullOrWhiteSpace($TARGET_REPO)) {
        $TARGET_REPO = $SCRIPT:TARGET_REPO_DEFAULT
    }
}

Write-Host ""

# Проверяем исходный репозиторий
Write-Step "ПРОВЕРКА ИСХОДНОГО РЕПОЗИТОРИЯ"
if (-not (Test-Repository -RepoPath $SOURCE_REPO -RepoName "Исходный репозиторий")) {
    Write-Host ""
    Write-Host "Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""

# Проверяем целевой репозиторий
Write-Step "ПРОВЕРКА ЦЕЛЕВОГО РЕПОЗИТОРИЯ"
if (-not (Test-Repository -RepoPath $TARGET_REPO -RepoName "Целевой репозиторий")) {
    Write-Host ""
    Write-Host "Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""

# Спрашиваем про приватные репозитории (только в интерактивном режиме)
if (-not $AutoRun) {
    Write-Step "ПРИВАТНЫЕ РЕПОЗИТОРИИ"
    Write-ColorInfo "Если используете приватные репозитории, убедитесь в наличии доступа" -Color Yellow
    $setupCredentials = Read-Host "Настроить доступ к приватным репозиториям? (y/n)"
    if ($setupCredentials -eq 'y') {
        Set-GitCredentials
    }
    Write-Host ""
}

# Подтверждение запуска (только в интерактивном режиме)
if (-not $AutoRun) {
    Write-Step "ПОДТВЕРЖДЕНИЕ"
    Write-ColorInfo "Будет выполнено:" -Color Cyan
    Write-ColorInfo "  1. git pull в исходном репозитории" -Color Cyan
    Write-ColorInfo "  2. Копирование всех файлов (кроме .git) в целевой репозиторий" -Color Cyan
    if ($SCRIPT:ENABLE_PUSH) {
        Write-ColorInfo "  3. git push в целевом репозитории" -Color Cyan
    }
    Write-Host ""
    
    $confirm = Read-Host "Продолжить синхронизацию? (y/n)"
    if ($confirm -ne 'y') {
        Write-ColorInfo "Синхронизация отменена" -Color Yellow
        Write-Host ""
        Write-Host "Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
}

Write-Host ""

# Шаг 1: Git pull в исходном репозитории
Write-Step "ШАГ 1: ОБНОВЛЕНИЕ ИСХОДНОГО РЕПОЗИТОРИЯ"
$pullResult = Invoke-GitPull -RepoPath $SOURCE_REPO -RepoName "исходном репозитории"
if (-not $pullResult) {
    Write-Warning "Продолжаем выполнение, несмотря на ошибку pull"
}

Write-Host ""

# Шаг 2: Копирование в целевой репозиторий
Write-Step "ШАГ 2: КОПИРОВАНИЕ В ЦЕЛЕВОЙ РЕПОЗИТОРИЙ"
$copyResult = Copy-RepositoryContents -SourcePath $SOURCE_REPO -TargetPath $TARGET_REPO
if (-not $copyResult) {
    Write-Error "Критическая ошибка при копировании"
    Write-Host ""
    Write-Host "Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""

# Шаг 3: Опциональный git push
if ($SCRIPT:ENABLE_PUSH) {
    Write-Step "ШАГ 3: ОТПРАВКА В УДАЛЕННЫЙ РЕПОЗИТОРИЙ"
    $pushResult = Invoke-GitPush -RepoPath $TARGET_REPO
    if (-not $pushResult) {
        Write-Warning "Ошибка при выполнении git push"
    }
    Write-Host ""
}

# Успешное завершение
Write-Step "ГОТОВО"
Write-Success "СИНХРОНИЗАЦИЯ УСПЕШНО ЗАВЕРШЕНА!"
Write-Host "==============================================" -ForegroundColor Cyan

# Предложение добавить в автозагрузку (только в интерактивном режиме)
if (-not $AutoRun) {
    Write-Host ""
    $addToStartup = Read-Host "Добавить скрипт в автозагрузку Windows? (y/n)"
    if ($addToStartup -eq 'y') {
        Add-ToStartup -ScriptPath $MyInvocation.MyCommand.Path
    }
}

# Ждем нажатия клавиши, если запущено не из консоли или в интерактивном режиме
if (-not $AutoRun -or $host.Name -like "*ISE*") {
    Write-Host ""
    Write-Host "Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

exit 0