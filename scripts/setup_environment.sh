#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print success message
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error message
error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

echo "🚀 Setting up development environment..."

# Create Python virtual environment
echo "Creating Python virtual environment..."
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
success "Python virtual environment created and dependencies installed"

# Install actionlint
echo "Installing actionlint..."
if ! command -v actionlint &> /dev/null; then
    go install github.com/rhysd/actionlint/cmd/actionlint@latest
    success "actionlint installed"
else
    success "actionlint already installed"
fi

# Install tflint
echo "Installing tflint..."
if ! command -v tflint &> /dev/null; then
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    success "tflint installed"
else
    success "tflint already installed"
fi

# Initialize pre-commit hooks if not already installed
echo "Initializing pre-commit hooks..."
if pip list | grep -q pre-commit; then
    .venv/bin/pre-commit install
    success "pre-commit hooks initialized"
else
    pip install pre-commit
    .venv/bin/pre-commit install
    success "pre-commit installed and hooks initialized"
fi

# Make scripts executable
chmod +x scripts/*.{sh,py}
success "Made scripts executable"

echo -e "\n🎉 Development environment setup complete!"
echo "Run 'source .venv/bin/activate' to activate the Python virtual environment"
echo "Run './scripts/validate_workflow.sh' to validate your project"
echo "Run './scripts/docs_generator.py' to update documentation and diagrams"
