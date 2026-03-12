@echo off
setlocal EnableDelayedExpansion

echo.
echo  ============================================================
echo          IntelliBlue - Automated Installer for Windows
echo  ============================================================
echo.

:: -------------------------------------------
:: Check for Administrator privileges
:: -------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!] This installer requires Administrator privileges.
    echo      Right-click this file and select "Run as Administrator".
    echo.
    pause
    exit /b 1
)

:: -------------------------------------------
:: 1. Check / Install Python
:: -------------------------------------------
echo  [1/5] Checking for Python...
where python >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2 delims= " %%v in ('python --version 2^>^&1') do set PYVER=%%v
    echo        Found Python !PYVER!
) else (
    echo        Python not found. Downloading Python installer...
    echo.
    powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe' -OutFile '%TEMP%\python_installer.exe'"
    if not exist "%TEMP%\python_installer.exe" (
        echo  [X] Failed to download Python. Please install Python 3.10+ manually from https://www.python.org
        pause
        exit /b 1
    )
    echo        Installing Python 3.12.3 (this may take a minute)...
    "%TEMP%\python_installer.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1
    if %errorlevel% neq 0 (
        echo  [X] Python installation failed. Please install Python 3.10+ manually.
        pause
        exit /b 1
    )
    del "%TEMP%\python_installer.exe" >nul 2>&1
    echo        Python installed successfully.
    echo        NOTE: You may need to restart this script for PATH changes to take effect.
)

echo.

:: -------------------------------------------
:: 2. Check / Install Ollama
:: -------------------------------------------
echo  [2/5] Checking for Ollama...
where ollama >nul 2>&1
if %errorlevel% equ 0 (
    echo        Found Ollama.
) else (
    echo        Ollama not found. Downloading Ollama installer...
    echo.
    powershell -Command "Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile '%TEMP%\OllamaSetup.exe'"
    if not exist "%TEMP%\OllamaSetup.exe" (
        echo  [X] Failed to download Ollama. Please install it manually from https://ollama.com
        pause
        exit /b 1
    )
    echo        Installing Ollama...
    "%TEMP%\OllamaSetup.exe" /VERYSILENT /NORESTART
    if %errorlevel% neq 0 (
        echo  [X] Ollama installation failed. Please install it manually from https://ollama.com
        pause
        exit /b 1
    )
    del "%TEMP%\OllamaSetup.exe" >nul 2>&1
    echo        Ollama installed successfully.
)

echo.

:: -------------------------------------------
:: 3. Check / Install Npcap
:: -------------------------------------------
echo  [3/5] Checking for Npcap...
if exist "C:\Program Files\Npcap\NPFInstall.exe" (
    echo        Found Npcap.
) else if exist "C:\Windows\System32\Npcap\NPFInstall.exe" (
    echo        Found Npcap.
) else (
    echo        Npcap not found. Downloading Npcap installer...
    echo        (Npcap is required for PCAP file analysis)
    echo.
    powershell -Command "Invoke-WebRequest -Uri 'https://npcap.com/dist/npcap-1.80.exe' -OutFile '%TEMP%\npcap_installer.exe'"
    if not exist "%TEMP%\npcap_installer.exe" (
        echo  [!] Failed to download Npcap automatically.
        echo      Please install it manually from https://npcap.com
        echo      (Skipping - you can still use IntelliBlue without PCAP support)
    ) else (
        echo        Installing Npcap (a dialog may appear)...
        "%TEMP%\npcap_installer.exe"
        del "%TEMP%\npcap_installer.exe" >nul 2>&1
        echo        Npcap installation completed.
    )
)

echo.

:: -------------------------------------------
:: 4. Install Python dependencies in venv
:: -------------------------------------------
echo  [4/5] Setting up virtual environment and installing dependencies...
if not exist "venv" (
    python -m venv venv
    echo        Created virtual environment (venv/).
)
call venv\Scripts\activate.bat
python -m pip install --upgrade pip >nul 2>&1
python -m pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo  [X] Failed to install Python dependencies.
    echo      Make sure Python is in your PATH and try again.
    pause
    exit /b 1
)
echo        Dependencies installed successfully.

echo.

:: -------------------------------------------
:: 5. Pull Llama 3 model (if not already installed)
:: -------------------------------------------
echo  [5/5] Checking for Llama 3 model...
ollama list 2>nul | findstr /i "llama3" >nul 2>&1
if %errorlevel% equ 0 (
    echo        Llama 3 model already installed.
) else (
    echo        Llama 3 not found. Pulling model via Ollama...
    echo        (This is a one-time download of ~4.7 GB. Please be patient.)
    echo.
    ollama pull llama3
    if %errorlevel% neq 0 (
        echo.
        echo  [!] Failed to pull Llama 3 model.
        echo      Make sure Ollama is running and try:  ollama pull llama3
    ) else (
        echo.
        echo        Llama 3 model ready.
    )
)

echo.
echo  ============================================================
echo           Installation Complete!
echo  ============================================================
echo.
echo  To start IntelliBlue, make sure Ollama is running, then run:
echo.
echo      venv\Scripts\activate.bat
echo      python app.py
echo.
echo  The application will be available at http://localhost:5000
echo  ============================================================
echo.
pause
