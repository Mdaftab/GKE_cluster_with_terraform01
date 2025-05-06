#!/bin/bash

# Exit on error
set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Change to the dev environment directory
cd "$(dirname "$0")/../environments/dev"

# Get cluster info from Terraform output
print_status "Retrieving cluster information..."
CLUSTER_NAME=$(terraform output -raw cluster_name)
CLUSTER_REGION=$(terraform output -raw cluster_region)
PROJECT_ID=$(terraform output -raw project_id)

echo "Connecting to GKE cluster..."
echo "Cluster: $CLUSTER_NAME"
echo "Region: $CLUSTER_REGION"
echo "Project: $PROJECT_ID"

# Configure kubectl
gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --region "$CLUSTER_REGION" \
  --project "$PROJECT_ID"

# Verify connection
print_status "Verifying cluster connection..."
kubectl cluster-info

# Print available nodes
echo -e "\nCluster nodes:"
kubectl get nodes

print_status "Connection successful! 🚀"
echo -e "You can now use kubectl to manage your cluster."
echo -e "\nTo deploy a sample application, run:"
echo -e "${GREEN}kubectl apply -f ../kubernetes/manifests/deployment.yaml${NC}"
echo -e "\nTo view the application endpoint once deployed, run:"
echo -e "${GREEN}kubectl get service demo-app${NC}"