batch
@echo off
title Git Repository Sync
chcp 65001 >nul
color 0A

echo ==============================================
echo   Git Repository Synchronization Script
echo        для Git Bash в Windows
echo ==============================================
echo.

:: Проверяем наличие Git Bash
if not exist "%ProgramFiles%\Git\git-bash.exe" (
    if not exist "%ProgramFiles(x86)%\Git\git-bash.exe" (
        echo [ERROR] Git Bash не найден!
        echo.
        echo Установите Git для Windows с сайта:
        echo https://git-scm.com/download/win
        echo.
        pause
        exit /b 1
    )
)

:: Запускаем скрипт в Git Bash
echo Запуск синхронизации...
echo.

"%ProgramFiles%\Git\git-bash.exe" -c "bash '/c/Users/%USERNAME%/Desktop/sync-repos.sh'"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Скрипт завершился с ошибкой!
    pause
    exit /b %errorlevel%
)