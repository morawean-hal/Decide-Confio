# FIX CLI Tool

Ein praktisches Python-Kommandozeilentool zum schnellen Parsen, Vergleichen und Visualisieren von FIX-Nachrichten, CSV-/Excel-Tabellen oder HTML-Logs.  
Alle Daten werden lokal als JSON ("_fix_flatfile_db.json") gespeichert.

## Features

- Einfügen und Auswerten von `8=FIX`-Nachrichten (Paste).
- Import von CSV-/Excel-Tabellen (Copy-Paste direkt ins Tool).
- HTML-Log-Import (optional, mit `beautifulsoup4`).
- Suche nach OrderID, ClOrdID, CompIDs, Datei, etc.
- Farbtabelle & Komfort (wenn `rich` installiert ist).
- Erkennung und Vermeidung von Duplikaten.
- Delta-Vergleich für Orderflüsse (OMS/Trading-Workflows).
- Persistente lokale Datenbank (JSON).

## Voraussetzungen

- **Python 3.7 oder neuer** (empfohlen: 3.8+)
- Optional für Komfortfunktionen:  
  - [rich](https://pypi.org/project/rich/) (`pip install rich`)
  - [beautifulsoup4](https://pypi.org/project/beautifulsoup4/) (`pip install beautifulsoup4`)

## Quickstart

### 1. Voraussetzung prüfen/erfüllen

**Unter Linux / Mac / WSL:**
```sh
bash fixcli.sh
Unter Windows (Doppelklick oder cmd):

fixcli.bat
2. Alternativ direkt starten
python fixcli.py
Das Skript meldet sich mit einem interaktiven Menü.

Hinweise
Benötigte Zusatzmodule werden beim Start geprüft und Empfehlungen zur Installation gegeben.
Alle eingegebenen Daten bleiben lokal.
Beispiele
FIX-Daten oder CSV/Excel-Block einfach ins Terminal kopieren.
Bei Bedarf nach OrderID/ClOrdID/CompID suchen.
HTML-Tabellenlog? Nur mit beautifulsoup4 verfügbar.
Für Entwickler:
Erweiterungen und Bugreports gerne als Issue oder Pull Request!


---

## 2. Linux/Mac Shell-Startscript: `fixcli.sh`

```sh
#!/bin/sh

# Prüfe, ob python3 vorhanden ist
if command -v python3 >/dev/null 2>&1 ; then
    PYVER=$(python3 --version 2>&1)
    echo "Python gefunden: $PYVER"
    # Prüfen, ob mindestens Version 3.7
    MINVER=7
    THISVER=$(echo "$PYVER" | awk '{print $2}' | cut -d. -f2)
    if [ "$THISVER" -lt "$MINVER" ]; then
        echo "Python-Version zu alt. Bitte mindestens Python 3.7 oder neuer installieren."
        exit 1
    fi
    python3 fixcli.py
elif command -v python >/dev/null 2>&1 ; then
    PYVER=$(python --version 2>&1)
    echo "Python gefunden: $PYVER"
    # Prüfen, ob mindestens Version 3.7
    MINVER=7
    THISVER=$(echo "$PYVER" | awk '{print $2}' | cut -d. -f2)
    if [ "$THISVER" -lt "$MINVER" ]; then
        echo "Python-Version zu alt. Bitte mindestens Python 3.7 oder neuer installieren."
        exit 1
    fi
    python fixcli.py
else
    echo "Kein Python 3 installiert! Bitte installiere Python 3.7 oder neuer."
    exit 1
fi
3. Windows-Batchscript: fixcli.bat
@echo off
setlocal

REM Suche python3 zuerst
where python3 >nul 2>nul
if %errorlevel%==0 (
    for /f "tokens=2 delims= " %%v in ('python3 --version') do (
        set PYVER=%%v
    )
    echo Python gefunden: %PYVER%
    for /f "tokens=1,2 delims=." %%x in ("%PYVER%") do (
        set MAJ=%%x
        set MIN=%%y
    )
    if "%MAJ%"=="3" if %MIN% GEQ 7 (
        python3 fixcli.py
        exit /b
    ) else (
        echo Python-Version zu alt. Bitte mindestens Python 3.7 oder neuer installieren.
        exit /b 1
    )
)

REM Fallback: Suche python
where python >nul 2>nul
if %errorlevel%==0 (
    for /f "tokens=2 delims= " %%v in ('python --version') do (
        set PYVER=%%v
    )
    echo Python gefunden: %PYVER%
    for /f "tokens=1,2 delims=." %%x in ("%PYVER%") do (
        set MAJ=%%x
        set MIN=%%y
    )
    if "%MAJ%"=="3" if %MIN% GEQ 7 (
        python fixcli.py
        exit /b
    ) else (
        echo Python-Version zu alt. Bitte mindestens Python 3.7 oder neuer installieren.
        exit /b 1
    )
)

echo Kein Python 3 installiert! Bitte installiere Python 3.7 oder neuer.
exit /b 1
