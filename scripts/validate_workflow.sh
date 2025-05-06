#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Function to print warning message
warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

echo "🔍 Starting comprehensive project validation..."

# Phase 1: Directory Structure Validation
echo -e "\n📁 Validating project structure..."
required_dirs=(
    "environments/dev"
    "modules"
    "modules/gke"
    "modules/vpc"
    "kubernetes/manifests"
    "docs/diagrams"
    ".github/workflows"
    "scripts"
)

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        error "Missing required directory: $dir"
    fi
    success "Found directory: $dir"
done

# Phase 2: Required Files Validation
echo -e "\n📄 Checking required files..."
required_files=(
    ".github/workflows/terraform.yml"
    ".tflint.hcl"
    "README.md"
    ".pre-commit-config.yaml"
    "environments/dev/terraform.tfvars.example"
    "modules/gke/main.tf"
    "modules/vpc/main.tf"
    "kubernetes/manifests/monitoring.yaml"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        error "Missing required file: $file"
    fi
    success "Found file: $file"
done

# Phase 3: Terraform Validation
echo -e "\n🔧 Validating Terraform configuration..."

# Check terraform is installed
if ! command -v terraform &> /dev/null; then
    error "Terraform is not installed"
fi
success "Terraform is installed"

# Format check
echo "Checking Terraform formatting..."
if ! terraform fmt -check -recursive > /dev/null; then
    error "Terraform files need formatting. Run 'terraform fmt -recursive' to fix"
fi
success "Terraform formatting is correct"

# Initialize Terraform
echo "Initializing Terraform..."
cd environments/dev
if ! terraform init -backend=false > /dev/null; then
    error "Terraform initialization failed"
fi
success "Terraform initialized successfully"

# Validate Terraform configuration
if ! terraform validate > /dev/null; then
    error "Terraform validation failed"
fi
success "Terraform validation passed"
cd ../..

# Phase 4: GitHub Actions Workflow Validation
echo -e "\n🔄 Validating GitHub Actions workflow..."

# Install actionlint if not present
if ! command -v actionlint &> /dev/null; then
    echo "Installing actionlint..."
    go install github.com/rhysd/actionlint/cmd/actionlint@latest
fi

if command -v actionlint &> /dev/null; then
    if ! actionlint .github/workflows/terraform.yml; then
        error "GitHub Actions workflow validation failed"
    fi
    success "GitHub Actions workflow is valid"
else
    warning "actionlint not installed, skipping workflow syntax validation"
fi

# Phase 5: Security Checks
echo -e "\n🔒 Performing security checks..."

# Check for sensitive information
echo "Checking for sensitive information in files..."
sensitive_patterns=(
    "password"
    "secret"
    "token"
    "key"
    "credential"
)

for pattern in "${sensitive_patterns[@]}"; do
    results=$(grep -r -i -l "$pattern" --exclude-dir=.git --exclude-dir=.terraform --exclude=validate_workflow.sh . || true)
    if [ ! -z "$results" ]; then
        warning "Found potential sensitive information with pattern '$pattern' in:"
        echo "$results"
    fi
done

# Phase 6: Dependencies Check
echo -e "\n📦 Checking required dependencies..."

# Check Python for diagram generation
if ! command -v python3 &> /dev/null; then
    error "Python3 is required for diagram generation"
fi
success "Python3 is installed"

# Check for required Python packages
required_packages=(
    "terraform-visual"
    "graphviz"
)

for package in "${required_packages[@]}"; do
    if ! pip list | grep -q "^$package "; then
        warning "$package is not installed. Install with: pip install $package"
    else
        success "$package is installed"
    fi
done

# Phase 7: Documentation Check
echo -e "\n📚 Checking documentation..."

# Run documentation generator
if [ -f scripts/docs_generator.py ]; then
    echo "Updating documentation..."
    python3 scripts/docs_generator.py
    success "Documentation updated"
else
    warning "Documentation generator script not found"
fi

# Check README.md content
if ! grep -q "# GKE Cluster with Terraform" README.md; then
    warning "README.md might be missing project title"
fi

if ! grep -q "## Infrastructure Diagrams" README.md; then
    warning "README.md might be missing infrastructure diagrams section"
fi

success "Documentation checks completed"

# Final Summary
echo -e "\n✨ Validation Summary:"
echo "------------------------"
echo "✅ Project structure validated"
echo "✅ Required files checked"
echo "✅ Terraform configuration validated"
echo "✅ GitHub Actions workflow checked"
echo "✅ Security scan completed"
echo "✅ Dependencies verified"
echo "✅ Documentation reviewed"

echo -e "\n🎉 All validation checks completed successfully!"
