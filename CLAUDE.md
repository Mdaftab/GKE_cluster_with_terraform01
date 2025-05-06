# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains Terraform configuration for deploying a minimal, cost-effective Google Kubernetes Engine (GKE) cluster on Google Cloud Platform (GCP). The infrastructure is designed to be self-destructing and optimized for testing and development purposes.

## Key Features

- Private GKE cluster with custom VPC and dedicated subnets
- Cost optimization through spot instances, minimal node count, and small machine types
- Security through private cluster configuration, VPC-native networking, and shielded nodes
- Automated infrastructure deployment through Terraform and GitHub Actions
- True self-destructing capability with Cloud Scheduler jobs
- Secure authentication using Workload Identity Federation for CI/CD

## Common Commands

### Environment Setup

```bash
# Install dependencies and set up authentication
./scripts/bootstrap.sh

# Configure GCP project and enable APIs
./scripts/setup.sh

# Set up GCP Workload Identity Federation (for GitHub Actions)
export PROJECT_ID="your-project-id"
export GITHUB_REPO="your-github-username/your-repo-name"
./scripts/setup_gcp_auth.sh
```

### Python Requirements

The project uses Python scripts for documentation and validation. Make sure to install the required dependencies:

```bash
pip install -r requirements.txt
```

Required packages:
- python-hcl2: For parsing Terraform HCL files
- pyyaml: For parsing YAML manifests
- graphviz: For generating diagrams
- terraform-visual: For generating infrastructure diagrams
- pre-commit: For running pre-commit hooks on code changes

### Terraform Operations

```bash
# Initialize Terraform (navigate to an environment directory first)
cd environments/dev
terraform init

# Format Terraform files
terraform fmt -recursive

# Validate Terraform configuration
terraform validate

# Plan infrastructure changes
terraform plan -out=tfplan

# Apply infrastructure changes
terraform apply tfplan

# Destroy infrastructure
terraform destroy
```

### Connecting to the Cluster

```bash
# Configure kubectl to connect to the GKE cluster
./scripts/connect.sh
```

### Documentation Generation

```bash
# Generate infrastructure diagrams and update README
python scripts/docs_generator.py
```

### Validation

```bash
# Run comprehensive project validation
./scripts/validate_workflow.sh
```

## Project Structure

- **environments/** - Contains environment-specific Terraform configurations
  - **dev/** - Development environment configuration
- **modules/** - Reusable Terraform modules
  - **gke/** - GKE cluster module
  - **vpc/** - VPC network module
- **kubernetes/manifests/** - Kubernetes resource definitions
- **scripts/** - Automation scripts for setup and maintenance
- **docs/diagrams/** - Infrastructure diagrams

## Architecture Overview

This project follows a modular Terraform structure:

1. The root module in `environments/dev/` creates the main infrastructure
2. It references and configures the reusable modules in `modules/`:
   - `vpc` module creates the custom VPC network with subnets, secondary IP ranges, firewall rules, and Cloud NAT
   - `gke` module creates the private GKE cluster using the VPC created by the vpc module

## Workflow

1. **Local Development**:
   - Make changes to Terraform code
   - Run `terraform fmt -recursive` to format code
   - Run `terraform validate` to validate configuration
   - Run `terraform plan` to see changes
   - Commit and push changes

2. **CI/CD Pipeline** (through GitHub Actions):
   - Code Quality Checks
   - Security Analysis 
   - Terraform Format Verification
   - Infrastructure Planning
   - Infrastructure Application (on merge to main)
   - Post-Deployment Validation

## Python Dependencies

The project uses Python scripts for documentation and validation. Required packages:
- python-hcl2
- pyyaml
- graphviz

Install them with:
```bash
pip install -r requirements.txt
```

## Important Notes

- Never commit sensitive information or credentials
- Backend configuration and variable values should be configured locally
- The cluster uses Workload Identity Federation for authentication
- Follow the security notes in the README.md
- Self-destruction is controlled via the `auto_destroy_hours` variable
- Detailed documentation is available in the docs/ directory

## Project Architecture

- `modules/vpc/` - Creates custom VPC network, subnets, and NAT gateway
- `modules/gke/` - Creates GKE cluster with optimized configuration
- `modules/gke/self_destruct.tf` - Self-destruction mechanism with Cloud Scheduler
- `environments/dev/` - Dev environment configuration
- `docs/` - Detailed documentation on deployment and architecture
- `scripts/` - Automation scripts for setup and maintenance
- `.github/workflows/` - CI/CD pipeline configuration with security checks