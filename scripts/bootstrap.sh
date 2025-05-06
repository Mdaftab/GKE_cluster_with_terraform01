#!/bin/bash

set -e  # Exit on any error

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
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

# Check for required tools
echo "🔍 Checking for required tools..."

# Check for gcloud
if ! command_exists gcloud; then
    print_error "Google Cloud SDK (gcloud) is not installed."
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi
print_status "Google Cloud SDK is installed"

# Check for terraform
if ! command_exists terraform; then
    print_error "Terraform is not installed."
    echo "Please install it from: https://developer.hashicorp.com/terraform/downloads"
    exit 1
fi
print_status "Terraform is installed"

# Check for kubectl
if ! command_exists kubectl; then
    print_error "kubectl is not installed."
    echo "Please install it from: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi
print_status "kubectl is installed"

# Check if user is authenticated with Google Cloud
if ! gcloud auth list --filter=status:ACTIVE --format="get(account)" 2>/dev/null | grep -q "@"; then
    print_warning "You need to authenticate with Google Cloud. Running login now..."
    gcloud auth login
    gcloud auth application-default login
else
    print_status "Already authenticated with Google Cloud"
fi

# Get current GCP project
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ -z "$CURRENT_PROJECT" ]; then
    print_warning "No GCP project is currently set."
    read -p "Enter your GCP Project ID: " PROJECT_ID
    if [ -z "$PROJECT_ID" ]; then
        print_error "Project ID is required"
        exit 1
    fi
    gcloud config set project "$PROJECT_ID"
    print_status "Project set to: $PROJECT_ID"
else
    print_status "Using GCP project: $CURRENT_PROJECT"
    read -p "Do you want to use a different project? (y/n): " CHANGE_PROJECT
    if [[ "$CHANGE_PROJECT" == "y" || "$CHANGE_PROJECT" == "Y" ]]; then
        read -p "Enter your GCP Project ID: " PROJECT_ID
        if [ -z "$PROJECT_ID" ]; then
            print_error "Project ID is required"
            exit 1
        fi
        gcloud config set project "$PROJECT_ID"
        print_status "Project changed to: $PROJECT_ID"
    else
        PROJECT_ID=$CURRENT_PROJECT
    fi
fi

# Enable required APIs
print_status "Enabling required GCP APIs..."
APIS="compute.googleapis.com container.googleapis.com cloudresourcemanager.googleapis.com iam.googleapis.com storage-api.googleapis.com"
for api in $APIS; do
    if ! gcloud services list --enabled --filter="name:$api" --format="get(name)" | grep -q "$api"; then
        gcloud services enable "$api"
        print_status "Enabled $api"
    else
        print_warning "$api already enabled"
    fi
done

# Create GCS bucket for Terraform state
BUCKET_NAME="${PROJECT_ID}-terraform-state"
if ! gsutil ls "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
    print_status "Creating GCS bucket for Terraform state..."
    BUCKET_REGION=$(gcloud config get-value compute/region 2>/dev/null)
    if [ -z "$BUCKET_REGION" ]; then
        BUCKET_REGION="us-central1"
        print_warning "No region set, using default: $BUCKET_REGION"
    fi
    
    if gsutil mb -l $BUCKET_REGION "gs://${BUCKET_NAME}"; then
        # Enable versioning
        gsutil versioning set on "gs://${BUCKET_NAME}"
        print_status "Created and configured bucket: ${BUCKET_NAME}"
    else
        print_error "Failed to create bucket"
        exit 1
    fi
else
    print_warning "Bucket ${BUCKET_NAME} already exists"
fi

# Create backend.tf
cd "$(dirname "$0")/../environments/dev"

# Create backend.tf from example
if [ ! -f backend.tf ]; then
    print_status "Creating backend.tf..."
    if [ -f backend.tf.example ]; then
        sed "s/YOUR_BUCKET_NAME/${BUCKET_NAME}/g" backend.tf.example > backend.tf
        print_status "Created backend.tf"
    else
        print_error "backend.tf.example not found"
        exit 1
    fi
else
    print_warning "backend.tf already exists, skipping..."
fi

# Create terraform.tfvars
if [ ! -f terraform.tfvars ]; then
    print_status "Creating terraform.tfvars..."
    if [ -f terraform.tfvars.example ]; then
        sed -e "s/your-project-id/$PROJECT_ID/g" \
            -e "s/your-project-name/$PROJECT_ID/g" \
            terraform.tfvars.example > terraform.tfvars
        print_status "Created terraform.tfvars"
    else
        print_error "terraform.tfvars.example not found"
        exit 1
    fi
else
    print_warning "terraform.tfvars already exists, skipping..."
fi

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Output success message
cat << EOF

🎉 Bootstrap Complete!

${YELLOW}Configuration Summary:${NC}
- Project ID: ${PROJECT_ID}
- Terraform State Bucket: ${BUCKET_NAME}
- Required APIs: Enabled
- Configuration Files: Created and initialized

${YELLOW}Next Steps:${NC}
1. Review and customize terraform.tfvars if needed. This file contains all the configuration options.
   Key security settings you may want to adjust:
   - deploy_network_policies: Enable to add Kubernetes NetworkPolicies
   - enable_monitoring: Enable for enhanced security monitoring

2. Run the deployment:
   ${GREEN}cd environments/dev
   terraform plan    # Preview changes to verify configuration
   terraform apply   # Deploy the infrastructure${NC}

3. After deployment, connect to your cluster:
   ${GREEN}./scripts/connect.sh${NC}

4. Test your cluster with the demo app:
   ${GREEN}kubectl apply -f ../../kubernetes/manifests/deployment.yaml
   kubectl get service demo-app -w${NC} # Wait for external IP

5. When finished, destroy the infrastructure to avoid ongoing charges:
   ${GREEN}cd environments/dev
   terraform destroy${NC}

All modules use Terraform best practices including:
- Modular approach with distinct network, security, and cluster modules
- Least privilege service accounts with minimal permissions
- Private cluster with secure networking
- Comprehensive security features following Google's hardening guide

For more detailed documentation, see:
- README.md for project overview
- docs/architecture.md for architecture details
EOF