@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Zuerst nach python3 suchen
where python3 >nul 2>nul
if %errorlevel%==0 (
    for /f "tokens=2 delims= " %%v in ('python3 --version') do set PYVER=%%v
    echo Python gefunden: %PYVER%
    for /f "tokens=1,2 delims=." %%a in ("%PYVER%") do (
        set MAJ=%%a
        set MIN=%%b
    )
    if "!MAJ!" == "3" if !MIN! GEQ 7 (
        python3 fixcli.py
        exit /b
    ) else (
        echo Python-Version zu alt: !MAJ!.!MIN!. Bitte mindestens Python 3.7 oder neuer installieren.
        exit /b 1
    )
)

REM Dann nach python suchen
where python >nul 2>nul
if %errorlevel%==0 (
    for /f "tokens=2 delims= " %%v in ('python --version') do set PYVER=%%v
    echo Python gefunden: %PYVER%
    for /f "tokens=1,2 delims=." %%a in ("%PYVER%") do (
        set MAJ=%%a
        set MIN=%%b
    )
    if "!MAJ!" == "3" if !MIN! GEQ 7 (
        python fixcli.py
        exit /b
    ) else (
        echo Python-Version zu alt: !MAJ!.!MIN!. Bitte mindestens Python 3.7 oder neuer installieren.
        exit /b 1
    )
)

echo Kein Python 3 installiert! Bitte installiere Python 3.7 oder neuer.
exit /b 1
