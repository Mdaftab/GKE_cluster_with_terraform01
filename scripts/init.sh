#!/bin/bash

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run this script with sudo"
    exit 1
fi

echo "🚀 Initializing development environment..."

# Install system dependencies
print_status "Installing system dependencies..."

# Add Google Cloud SDK repository
if [ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]; then
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
fi

# Add Hashicorp repository
if [ ! -f /etc/apt/sources.list.d/hashicorp.list ]; then
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
fi

# Update package list
sudo apt-get update

# Install packages
PACKAGES="terraform google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin kubectl"
for package in $PACKAGES; do
    if ! command_exists $package; then
        sudo apt-get install -y $package
        print_status "Installed $package"
    else
        print_warning "$package is already installed"
    fi
done

# Create Python virtual environment
print_status "Setting up Python environment..."
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
print_status "Python virtual environment created and dependencies installed"

# Install development tools
print_status "Installing development tools..."

# Install actionlint
if ! command -v actionlint &> /dev/null; then
    go install github.com/rhysd/actionlint/cmd/actionlint@latest
    print_status "actionlint installed"
else
    print_warning "actionlint already installed"
fi

# Install tflint
if ! command -v tflint &> /dev/null; then
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    print_status "tflint installed"
else
    print_warning "tflint already installed"
fi

# Initialize pre-commit hooks
print_status "Initializing pre-commit hooks..."
.venv/bin/pre-commit install
print_status "pre-commit hooks initialized"

# Make scripts executable
chmod +x scripts/*.{sh,py}
print_status "Made scripts executable"

# Verify installations
print_status "Verifying installations..."
terraform version
gcloud version
kubectl version --client

# Check if user is authenticated with Google Cloud
if ! gcloud auth list --filter=status:ACTIVE --format="get(account)" 2>/dev/null | grep -q "@"; then
    print_warning "You need to authenticate with Google Cloud. Please run:"
    echo -e "${GREEN}gcloud auth login${NC}"
    echo -e "${GREEN}gcloud auth application-default login${NC}"
    exit 1
fi

cat << EOF

🎉 Development environment setup complete!

${YELLOW}Next Steps:${NC}
1. Run ${GREEN}source .venv/bin/activate${NC} to activate the Python environment
2. Run ${GREEN}./scripts/setup.sh${NC} to configure your GCP project and Terraform
3. Run ${GREEN}./scripts/validate_workflow.sh${NC} to validate your project
4. Run ${GREEN}./scripts/docs_generator.py${NC} to update documentation

For more information, see the README.md file.
EOF
