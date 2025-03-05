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

# Function to get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local value

    read -p "$prompt [$default]: " value
    echo "${value:-$default}"
}

echo "🚀 Setting up GCP and Terraform configuration..."

# Get project ID from gcloud config
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID=$(get_input "Enter your GCP Project ID" "")
    if [ -z "$PROJECT_ID" ]; then
        print_error "Project ID is required"
        exit 1
    fi
fi

# Verify project exists and set it as default
if ! gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1; then
    print_error "Project $PROJECT_ID does not exist or you don't have access to it"
    exit 1
fi

gcloud config set project "$PROJECT_ID"
print_status "Using project: $PROJECT_ID"

# Enable required APIs
print_status "Enabling required APIs..."
APIS="compute.googleapis.com container.googleapis.com cloudresourcemanager.googleapis.com iam.googleapis.com"
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
    if gsutil mb -l us-central1 "gs://${BUCKET_NAME}"; then
        # Enable versioning
        gsutil versioning set on "gs://${BUCKET_NAME}"
        # Set lifecycle policy
        cat > /tmp/lifecycle.json << EOL
{
  "rule": [
    {
      "action": {"type": "Delete"},
      "condition": {
        "numNewerVersions": 10,
        "isLive": false
      }
    }
  ]
}
EOL
        gsutil lifecycle set /tmp/lifecycle.json "gs://${BUCKET_NAME}"
        rm /tmp/lifecycle.json
        print_status "Created and configured bucket: ${BUCKET_NAME}"
    else
        print_error "Failed to create bucket"
        exit 1
    fi
else
    print_warning "Bucket ${BUCKET_NAME} already exists"
fi

# Get current IP address for authorized networks
CURRENT_IP=$(curl -s ifconfig.me)
if [ -z "$CURRENT_IP" ]; then
    print_error "Could not determine your IP address"
    exit 1
fi

print_status "Your IP address: $CURRENT_IP"

# Create and configure Terraform files
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

# Create terraform.tfvars from example
if [ ! -f terraform.tfvars ]; then
    print_status "Creating terraform.tfvars..."
    if [ -f terraform.tfvars.example ]; then
        sed -e "s/your-project-id/$PROJECT_ID/g" \
            -e "s/your-project-name/$PROJECT_ID/g" \
            -e "s/YOUR_IP_ADDRESS/$CURRENT_IP/g" \
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

# Run Terraform plan
print_status "Running Terraform plan..."
terraform plan -out=tfplan

cat << EOF

🎉 Setup Complete!

${YELLOW}Configuration Summary:${NC}
- Project ID: ${PROJECT_ID}
- Terraform State Bucket: ${BUCKET_NAME}
- Your IP Address: ${CURRENT_IP}
- Required APIs: Enabled
- Configuration Files: Created and configured

${YELLOW}Next Steps:${NC}
1. Review the Terraform plan output above
2. To deploy the infrastructure, run:
   ${GREEN}cd environments/dev
   terraform apply tfplan${NC}
3. After deployment, run:
   ${GREEN}./scripts/connect.sh${NC} to configure kubectl

For more information, see the README.md file.
EOF
