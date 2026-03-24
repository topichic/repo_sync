# **Git Repository Synchronization Scripts**

## Комплект скриптов для синхронизации Git-репозиториев в Windows

Этот репозиторий содержит набор скриптов для автоматической синхронизации двух локальных Git-репозиториев в операционной системе Windows. Скрипты обновляют исходный репозиторий (`git pull`) и копируют его содержимое (исключая папку `.git`) в целевой репозиторий.

## 📋 Содержание

- [Возможности](#возможности)
- [Состав репозитория](#состав-репозитория)
- [Требования](#требования)
- [Быстрый старт](#быстрый-старт)
- [Детальное описание скриптов](#детальное-описание-скриптов)
  - [PowerShell скрипт](#1-powershell-скрипт-sync-gitreposps1)
  - [Git Bash скрипт](#2-git-bash-скрипт-sync-repossh)
  - [Batch файлы для запуска](#3-batch-файлы-для-запуска)
- [Настройка](#настройка)
- [Работа с приватными репозиториями](#работа-с-приватными-репозиториями)
- [Автозагрузка](#автозагрузка)
- [Устранение проблем](#устранение-проблем)
- [Примеры использования](#примеры-использования)

## 🚀 Возможности

- **Автоматическое обновление** исходного репозитория через `git pull`
- **Копирование содержимого** с исключением папки `.git`
- **Проверка путей** и валидация Git-репозиториев
- **Поддержка приватных репозиториев** через SSH или Git Credential Manager
- **Опциональный `git push`** в целевом репозитории
- **Цветной вывод** для удобного визуального контроля
- **Автозагрузка** в Windows
- **Два варианта** исполнения: PowerShell и Git Bash

## 📁 Состав репозитория

| Файл | Описание |
|------|----------|
| `Sync-GitRepos.ps1` | Основной PowerShell скрипт |
| `Sync-GitRepos.bat` | Batch-файл для запуска PowerShell скрипта |
| `sync-repos.sh` | Скрипт для Git Bash |
| `sync-repos.bat` | Batch-файл для запуска Git Bash скрипта |
| `README.md` | Документация |

## 💻 Требования

### Для PowerShell скрипта:
- Windows 7/8/10/11
- PowerShell 5.1 или выше
- [Git for Windows](https://git-scm.com/download/win) (должен быть в PATH)

### Для Git Bash скрипта:
- Windows 7/8/10/11
- [Git Bash](https://git-scm.com/download/win) (устанавливается вместе с Git for Windows)

## ⚡ Быстрый старт

### Вариант 1: PowerShell (рекомендуется для Windows)

1. **Установите Git for Windows** (если ещё не установлен)
   - Скачайте с [официального сайта](https://git-scm.com/download/win)
   - При установке выберите опцию **"Git from the command line and also from 3rd-party software"**

2. **Скачайте скрипты**
   - Сохраните `Sync-GitRepos.ps1` в удобную папку (например, `C:\Scripts\`)

3. **Настройте пути**
   - Откройте `Sync-GitRepos.ps1` в текстовом редакторе
   - Найдите и измените строки:
   ```powershell
   $SCRIPT:SOURCE_REPO_DEFAULT = "C:\Users\YourUsername\Projects\source-repo"
   $SCRIPT:TARGET_REPO_DEFAULT = "C:\Users\YourUsername\Projects\target-repo"
   ```

4. **Разрешите выполнение скриптов** (выполните в PowerShell один раз):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

5. **Запустите скрипт**:
   ```powershell
   C:\Scripts\Sync-GitRepos.ps1
   ```

### Вариант 2: Git Bash (легковесный)

1. **Установите Git Bash** (входит в Git for Windows)

2. **Скачайте скрипт** `sync-repos.sh`

3. **Настройте пути** в начале файла:
   ```bash
   SOURCE_REPO_DEFAULT="/c/Users/YourUsername/Projects/source-repo"
   TARGET_REPO_DEFAULT="/c/Users/YourUsername/Projects/target-repo"
   ```

4. **Запустите**:
   - Нажмите правой кнопкой на файл → "Open with Git Bash"

## 📚 Детальное описание скриптов

### 1. PowerShell скрипт (`Sync-GitRepos.ps1`)

Полнофункциональный скрипт с цветным выводом и интерактивным режимом.

**Особенности:**
- Подробный цветной вывод в консоль
- Проверка наличия Git в системе
- Валидация путей и Git-репозиториев
- Обработка ошибок с возможностью продолжения
- Интерактивный ввод путей
- Настройка доступа к приватным репозиториям
- Автоматическое добавление в автозагрузку

**Параметры командной строки:**
```powershell
# Обычный запуск с запросами
.\Sync-GitRepos.ps1

# Автоматический режим (для автозагрузки)
.\Sync-GitRepos.ps1 -AutoRun
```

### 2. Git Bash скрипт (`sync-repos.sh`)

Легковесный скрипт для Git Bash, использующий нативные Linux-команды.

**Особенности:**
- Быстрый и легковесный
- Поддержка различных форматов путей (Windows и Unix)
- Автоматическое использование `rsync` если доступен
- Цветной вывод
- Интерактивный режим
- Параметр `--autorun` для автозагрузки

**Поддерживаемые форматы путей:**
```bash
/c/Users/User/Projects/source-repo     # Unix-style
C:/Users/User/Projects/source-repo     # Windows with forward slashes
C:\Users\User\Projects\source-repo     # Windows with backslashes
```

**Параметры командной строки:**
```bash
# Обычный запуск
./sync-repos.sh

# Автоматический режим
./sync-repos.sh --autorun
```

### 3. Batch файлы для запуска

**`Sync-GitRepos.bat`** - запускает PowerShell скрипт:
```batch
@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Sync-GitRepos.ps1"
```

**`sync-repos.bat`** - запускает Git Bash скрипт:
```batch
@echo off
"%ProgramFiles%\Git\git-bash.exe" -c "bash '/c/путь/к/sync-repos.sh'"
```

## ⚙️ Настройка

### Изменение путей по умолчанию

**Для PowerShell:**
```powershell
# В Sync-GitRepos.ps1
$SCRIPT:SOURCE_REPO_DEFAULT = "D:\Projects\my-source-repo"
$SCRIPT:TARGET_REPO_DEFAULT = "D:\Projects\my-target-repo"
```

**Для Git Bash:**
```bash
# В sync-repos.sh
SOURCE_REPO_DEFAULT="/d/Projects/my-source-repo"
TARGET_REPO_DEFAULT="/d/Projects/my-target-repo"
```

### Включение автоматического push

**PowerShell:**
```powershell
$SCRIPT:ENABLE_PUSH = $true
```

**Git Bash:**
```bash
ENABLE_PUSH=true
```

## 🔐 Работа с приватными репозиториями

### Вариант 1: Git Credential Manager (рекомендуется)

```powershell
# В PowerShell
git config --global credential.helper manager-core

# При первом pull/push введите логин и пароль
# Они сохранятся в менеджере учетных данных Windows
```

### Вариант 2: SSH-ключи

```bash
# В Git Bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
# Нажмите Enter для всех вопросов

# Покажите публичный ключ
cat ~/.ssh/id_rsa.pub

# Добавьте ключ в настройках GitHub/GitLab

# Измените remote на SSH
git remote set-url origin git@github.com:username/repo.git
```

### Вариант 3: Сохранение пароля в Windows

```cmd
# В командной строке (cmd)
cmdkey /generic:git:https://github.com /user:your_username /pass:your_password
```

## 🔄 Автозагрузка

### Способ 1: Через скрипт (рекомендуется)

После успешной синхронизации скрипты сами предложат добавить себя в автозагрузку. Просто ответьте `y` на вопрос.

### Способ 2: Через планировщик задач

1. Нажмите `Win + R`, введите `taskschd.msc`
2. Создайте простую задачу
3. Триггер: "При запуске системы"
4. Действие: Запуск программы

**Для PowerShell:**
- Программа: `powershell.exe`
- Аргументы: `-WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Scripts\Sync-GitRepos.ps1" -AutoRun`

**Для Git Bash:**
- Программа: `C:\Program Files\Git\git-bash.exe`
- Аргументы: `-c "bash '/c/Scripts/sync-repos.sh' --autorun"`

### Способ 3: Через папку автозагрузки

1. Нажмите `Win + R`, введите `shell:startup`
2. Создайте ярлык с командой

**Для PowerShell:**
```
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Scripts\Sync-GitRepos.ps1" -AutoRun
```

**Для Git Bash:**
```
C:\Program Files\Git\git-bash.exe -c "bash '/c/Scripts/sync-repos.sh' --autorun"
```

## 🔧 Устранение проблем

### Проблема: "Git не найден"

**Решение:** Переустановите Git, выбрав опцию "Git from the command line and also from 3rd-party software"

### Проблема: "Не удается загрузить файл, так как выполнение сценариев отключено"

**Решение (PowerShell):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Проблема: "Permission denied" при pull/push

**Решение:** Настройте Git Credential Manager или SSH-ключи

### Проблема: Русские буквы отображаются некорректно

**Решение:** Убедитесь, что файл сохранен в кодировке UTF-8 with BOM

### Проблема: Скрипт закрывается сразу после запуска

**Решение:** Используйте batch-файлы для запуска или запускайте через терминал

## 📝 Примеры использования

### Пример 1: Синхронизация двух локальных репозиториев

```powershell
# Настройка
$SOURCE_REPO_DEFAULT = "C:\Projects\my-app"
$TARGET_REPO_DEFAULT = "C:\Projects\my-app-deploy"

# Запуск
.\Sync-GitRepos.ps1
```

### Пример 2: Синхронизация с автоматическим push

```powershell
# Включить push
$ENABLE_PUSH = $true

# Запуск
.\sync-repos.sh
```

### Пример 3: Настройка для работы с GitHub

```bash
# Клонируем репозитории
cd /c/Projects
git clone https://github.com/username/source-repo.git
git clone https://github.com/username/target-repo.git

# Настраиваем скрипт
SOURCE_REPO_DEFAULT="/c/Projects/source-repo"
TARGET_REPO_DEFAULT="/c/Projects/target-repo"

# Запускаем
./sync-repos.sh
```

### Пример 4: Добавление в автозагрузку

```powershell
# 1. Запустите скрипт
.\Sync-GitRepos.ps1

# 2. После успешной синхронизации ответьте 'y' на вопрос о автозагрузке

# 3. Перезагрузите компьютер для проверки
```

## 📊 Сравнение скриптов

| Характеристика | PowerShell | Git Bash |
|----------------|------------|----------|
| Скорость работы | Средняя | Высокая |
| Наглядность вывода | Отличная | Хорошая |
| Зависимости | Только Git | Git Bash |
| Работа с путями | Windows | Windows/Unix |
| Rsync поддержка | Нет | Да (если установлен) |
| Интерактивность | Полная | Полная |
| Автозагрузка | Да | Да |

## 🤝 Вклад в проект

Если вы нашли ошибку или хотите улучшить скрипты:
1. Создайте issue с описанием проблемы
2. Предложите pull request с улучшениями
3. Поделитесь своим опытом использования

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. Вы можете свободно использовать, модифицировать и распространять скрипты.

## 📞 Поддержка

Если у вас возникли вопросы или проблемы:
- Создайте issue в репозитории
- Напишите в комментариях
- Изучите раздел [Устранение проблем](#устранение-проблем)

---

## 🎯 Заключение

Данные скрипты помогут вам автоматизировать синхронизацию Git-репозиториев в Windows. Выбирайте тот вариант, который лучше подходит для ваших задач:

- **PowerShell** - если нужен максимально подробный вывод и интеграция с Windows
- **Git Bash** - если нужна скорость и легковесность

Оба скрипта полностью работоспособны и протестированы в Windows 10/11.

**Удачной синхронизации!** 🚀