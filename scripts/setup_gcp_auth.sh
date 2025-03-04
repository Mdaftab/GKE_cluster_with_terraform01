#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

# Check if required environment variables are set
if [ -z "$PROJECT_ID" ]; then
    error "PROJECT_ID environment variable is not set"
fi

if [ -z "$GITHUB_REPO" ]; then
    error "GITHUB_REPO environment variable is not set"
fi

echo "🔒 Setting up GCP Workload Identity Federation..."

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable \
    iamcredentials.googleapis.com \
    iam.googleapis.com \
    cloudresourcemanager.googleapis.com
success "APIs enabled"

# Create Service Account
SA_NAME="github-actions-sa"
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
echo "Creating Service Account..."
gcloud iam service-accounts create "$SA_NAME" \
    --project="$PROJECT_ID" \
    --display-name="GitHub Actions Service Account" || true
success "Service Account created/verified"

# Grant necessary roles to the Service Account
echo "Granting necessary roles..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/editor" || true
success "Roles granted"

# Create Workload Identity Pool if it doesn't exist
POOL_NAME="github-actions-pool"
echo "Creating Workload Identity Pool..."
gcloud iam workload-identity-pools create "$POOL_NAME" \
    --project="$PROJECT_ID" \
    --location="global" \
    --display-name="GitHub Actions Pool" || true
success "Workload Identity Pool created/verified"

# Create Workload Identity Provider
PROVIDER_NAME="github-actions"
echo "Creating Workload Identity Provider..."
gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
    --project="$PROJECT_ID" \
    --location="global" \
    --workload-identity-pool="$POOL_NAME" \
    --display-name="GitHub Actions Provider" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,google.groups=assertion.repository" \
    --issuer-uri="https://token.actions.githubusercontent.com" || true
success "Workload Identity Provider created/verified"

# Allow authentications from the GitHub repository
echo "Setting up authentication binding..."
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
    --project="$PROJECT_ID" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/$PROJECT_ID/locations/global/workloadIdentityPools/$POOL_NAME/attribute.repository/${GITHUB_REPO}" || true
success "Authentication binding created"

# Get the Workload Identity Provider resource name
WORKLOAD_IDENTITY_PROVIDER="projects/$PROJECT_ID/locations/global/workloadIdentityPools/$POOL_NAME/providers/$PROVIDER_NAME"
success "Got Workload Identity Provider: $WORKLOAD_IDENTITY_PROVIDER"

echo -e "\n🎉 Setup Complete!"
echo "Add the following secrets to your GitHub repository:"
echo -e "\nWORKLOAD_IDENTITY_PROVIDER:"
echo "$WORKLOAD_IDENTITY_PROVIDER"
echo -e "\nSERVICE_ACCOUNT_EMAIL:"
echo "$SA_EMAIL"

# Save the values to a local file for reference
echo -e "\nSaving values to .env.gcp (DO NOT COMMIT THIS FILE)"
echo "WORKLOAD_IDENTITY_PROVIDER=\"$WORKLOAD_IDENTITY_PROVIDER\"" > .env.gcp
echo "SERVICE_ACCOUNT_EMAIL=\"$SA_EMAIL\"" >> .env.gcp
chmod 600 .env.gcp
success "Values saved to .env.gcp"
