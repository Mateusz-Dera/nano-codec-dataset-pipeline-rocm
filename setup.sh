#!/bin/bash

# Nano Codec Data Pipeline - Setup Script
# This script installs all dependencies and sets up the environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Clear screen for a clean start
clear

# Print the NINENINESIX logo with colors
echo -e "${CYAN}${BOLD}"
echo "==============================================="
echo "          N I N E N I N E S I X  😼"
echo "==============================================="
echo ""
echo -e "${MAGENTA}"
echo "          /\\_/\\  "
echo "         ( -.- )───┐"
echo "          > ^ <    │"
echo -e "${CYAN}"
echo "==============================================="
echo -e "${NC}"
echo ""
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   Nano Codec Data Pipeline - Setup Script                  ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# 1. Check for uv
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Checking for uv"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! command -v uv &> /dev/null; then
    print_error "uv is not installed!"
    echo ""
    echo -e "${YELLOW}Please install uv first:${NC}"
    echo -e "  ${GREEN}curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
    echo ""
    echo -e "${YELLOW}Or visit:${NC} https://docs.astral.sh/uv/getting-started/installation/"
    echo ""
    exit 1
else
    UV_VERSION=$(uv --version | awk '{print $2}')
    print_success "uv is installed (version $UV_VERSION)"
fi

# 2. Install libsndfile1
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Installing libsndfile1 (audio library)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if dpkg -l | grep -q libsndfile1; then
    print_success "libsndfile1 is already installed"
else
    print_info "Installing libsndfile1..."
    sudo apt-get update
    sudo apt-get install -y libsndfile1

    if dpkg -l | grep -q libsndfile1; then
        print_success "libsndfile1 installed successfully"
    else
        print_error "Failed to install libsndfile1"
        exit 1
    fi
fi

# 3. Create virtual environment with uv
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Creating virtual environment with Python 3.12"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

VENV_DIR="venv"

if [ -d "$VENV_DIR" ]; then
    print_info "Virtual environment already exists at ./$VENV_DIR"
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing existing virtual environment..."
        rm -rf "$VENV_DIR"
        print_info "Creating new virtual environment with Python 3.12..."
        uv venv "$VENV_DIR" --python 3.12
        print_success "Virtual environment recreated with Python 3.12"
    else
        print_info "Using existing virtual environment"
    fi
else
    print_info "Creating virtual environment with Python 3.12 at ./$VENV_DIR..."
    uv venv "$VENV_DIR" --python 3.12
    print_success "Virtual environment created with Python 3.12"
fi

# 4. Install Python packages
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Installing Python dependencies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_info "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Ask user to choose between CUDA and ROCm
echo ""
print_info "Choose PyTorch backend:"
echo -e "  ${YELLOW}1.${NC} CUDA (NVIDIA)"
echo -e "  ${YELLOW}2.${NC} ROCm (AMD)"
echo ""
read -p "Select option (1 or 2): " -n 1 -r
echo ""

EXTRA_INDEX_URL=""
if [[ $REPLY == "2" ]]; then
    print_info "Selected: ROCm (AMD)"
    EXTRA_INDEX_URL="--index-url https://pypi.org/simple --extra-index-url https://download.pytorch.org/whl/rocm6.4 --index-strategy unsafe-best-match"
else
    print_info "Selected: CUDA (NVIDIA)"
fi

print_info "Installing requirements from requirements.txt with uv..."
print_info "This may take several minutes..."
uv pip install -r requirements.txt $EXTRA_INDEX_URL

if [ $? -eq 0 ]; then
    print_success "All Python packages installed successfully"
else
    print_error "Failed to install some packages"
    exit 1
fi

# 5. Optional: HuggingFace authentication
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: HuggingFace Authentication (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_info "To download and upload datasets, you need to login to HuggingFace."
echo ""
read -p "Do you want to login to HuggingFace now? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Configuring git credential storage..."
    git config --global credential.helper store

    print_info "Launching HuggingFace login..."
    print_info "You'll need your HuggingFace token from: https://huggingface.co/settings/tokens"
    echo ""

    hf auth login

    if [ $? -eq 0 ]; then
        print_success "Successfully logged in to HuggingFace!"
    else
        print_error "HuggingFace login failed. You can run 'huggingface-cli login' manually later."
    fi
else
    print_info "Skipped HuggingFace login. You can login later with:"
    echo -e "     ${GREEN}git config --global credential.helper store${NC}"
    echo -e "     ${GREEN}hf auth login${NC}"
fi

# Final summary
echo ""
echo ""
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║                  Setup Complete! 🎉                        ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
print_success "All dependencies installed successfully!"
echo ""

# Print logo again at the end
echo -e "${CYAN}${BOLD}"
echo "==============================================="
echo "          N I N E N I N E S I X  😼"
echo "==============================================="
echo -e "${NC}"
echo ""

echo -e "${BOLD}Next steps:${NC}"
echo ""
echo -e "  ${YELLOW}1.${NC} Activate the virtual environment:"
echo -e "     ${GREEN}source venv/bin/activate${NC}"
echo ""
echo -e "  ${YELLOW}2.${NC} Login to HuggingFace (if you skipped it):"
echo -e "     ${GREEN}git config --global credential.helper store${NC}"
echo -e "     ${GREEN}hf auth login${NC}"
echo ""
echo -e "  ${YELLOW}3.${NC} Configure your pipeline:"
echo -e "     ${GREEN}nano config.yaml${NC}"
echo ""
echo -e "  ${YELLOW}4.${NC} Run the pipeline:"
echo -e "     ${GREEN}uv run main.py${NC}"
echo ""
print_info "Documentation: See README.md for usage guide"
print_info "              See CLAUDE.md for technical details"
echo ""
