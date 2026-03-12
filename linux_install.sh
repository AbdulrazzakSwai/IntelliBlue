#!/usr/bin/env bash

set -e

echo ""
echo "  ============================================================"
echo "       IntelliBlue - Automated Installer for Linux"
echo "  ============================================================"
echo ""

# -------------------------------------------
# 1. Check / Install Python 3
# -------------------------------------------
echo "  [1/5] Checking for Python 3..."
if command -v python3 &>/dev/null; then
    PYVER=$(python3 --version 2>&1 | awk '{print $2}')
    echo "        Found Python $PYVER"
else
    echo "        Python 3 not found. Installing..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y python3 python3-pip python3-venv
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y python3 python3-pip
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm python python-pip
    else
        echo "  [X] Could not detect package manager."
        echo "      Please install Python 3.10+ manually and re-run this script."
        exit 1
    fi
    echo "        Python 3 installed successfully."
fi

echo ""

# -------------------------------------------
# 2. Check / Install Ollama
# -------------------------------------------
echo "  [2/5] Checking for Ollama..."
if command -v ollama &>/dev/null; then
    echo "        Found Ollama."
else
    echo "        Ollama not found. Installing via official script..."
    curl -fsSL https://ollama.com/install.sh | sh
    if [ $? -ne 0 ]; then
        echo "  [X] Ollama installation failed."
        echo "      Please install it manually from https://ollama.com"
        exit 1
    fi
    echo "        Ollama installed successfully."
fi

echo ""

# -------------------------------------------
# 3. Install libpcap (required for Scapy)
# -------------------------------------------
echo "  [3/5] Checking for libpcap (required for PCAP analysis)..."
if dpkg -s libpcap-dev &>/dev/null 2>&1; then
    echo "        Found libpcap-dev."
elif rpm -q libpcap-devel &>/dev/null 2>&1; then
    echo "        Found libpcap-devel."
else
    echo "        Installing libpcap..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y libpcap-dev
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y libpcap-devel
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm libpcap
    else
        echo "  [!] Could not install libpcap automatically."
        echo "      PCAP analysis may not work. Install libpcap manually if needed."
    fi
fi

echo ""

# -------------------------------------------
# 4. Set up virtual environment & install deps
# -------------------------------------------
echo "  [4/5] Setting up Python virtual environment and installing dependencies..."

if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "        Created virtual environment (venv/)."
fi

source venv/bin/activate

pip install --upgrade pip --quiet
pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "  [X] Failed to install Python dependencies."
    exit 1
fi
echo "        Dependencies installed successfully."

echo ""

# -------------------------------------------
# 5. Pull Llama 3 model (if not already installed)
# -------------------------------------------
echo "  [5/5] Checking for Llama 3 model..."

# Start Ollama service if not running
if ! pgrep -x "ollama" &>/dev/null; then
    echo "        Starting Ollama service..."
    ollama serve &>/dev/null &
    sleep 3
fi

if ollama list 2>/dev/null | grep -qi "llama3"; then
    echo "        Llama 3 model already installed."
else
    echo "        Llama 3 not found. Pulling model via Ollama..."
    echo "        (This is a one-time download of ~4.7 GB. Please be patient.)"
    echo ""
    ollama pull llama3
    if [ $? -ne 0 ]; then
        echo ""
        echo "  [!] Failed to pull Llama 3 model."
        echo "      Make sure Ollama is running and try:  ollama pull llama3"
    else
        echo ""
        echo "        Llama 3 model ready."
    fi
fi

echo ""
echo "  ============================================================"
echo "           Installation Complete!"
echo "  ============================================================"
echo ""
echo "  To start IntelliBlue:"
echo ""
echo "      source venv/bin/activate"
echo "      python3 app.py"
echo ""
echo "  The application will be available at http://localhost:5000"
echo "  ============================================================"
echo ""
