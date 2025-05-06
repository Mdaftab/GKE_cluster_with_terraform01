# Deployment Guide

This guide provides detailed instructions for deploying the self-destructing GKE cluster infrastructure using Terraform. Follow these steps for a successful deployment.

## Prerequisites

- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (version >= 1.0)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- A Google Cloud Platform account with billing enabled
- Python 3.7+ (for documentation generation)

## Local Environment Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-username/GKE_cluster_with_terraform01.git
   cd GKE_cluster_with_terraform01
   ```

2. **Install Python dependencies**

   ```bash
   pip install -r requirements.txt
   ```

3. **Run the bootstrap script** to install required tools

   ```bash
   ./scripts/bootstrap.sh
   ```

4. **Authenticate with Google Cloud**

   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

5. **Set your project ID**

   ```bash
   gcloud config set project YOUR_PROJECT_ID
   ```

## Configuration

1. **Run the setup script** to configure your environment

   ```bash
   ./scripts/setup.sh
   ```

   This script will:
   - Create a Google Cloud Storage bucket for Terraform state
   - Enable necessary APIs
   - Create backend.tf and terraform.tfvars files from templates
   - Initialize Terraform

2. **Customize your deployment** by editing the terraform.tfvars file

   ```bash
   nano environments/dev/terraform.tfvars
   ```

   Key settings to consider:
   - `project_id` and `project_name`: Your GCP project details
   - `region` and `zone`: Where your infrastructure will be deployed
   - `machine_type`: VM size for your nodes (default: e2-micro for minimal cost)
   - `auto_destroy_hours`: Set how many hours until automatic destruction (0 to disable)

## Deployment

### Option 1: Manual Deployment

1. **Initialize Terraform**

   ```bash
   cd environments/dev
   terraform init
   ```

2. **Validate your configuration**

   ```bash
   terraform validate
   ```

3. **Plan your deployment**

   ```bash
   terraform plan -out=tfplan
   ```

4. **Apply the changes**

   ```bash
   terraform apply tfplan
   ```

### Option 2: CI/CD Deployment

1. **Configure GitHub Secrets**

   If using the GitHub Actions workflow, add these secrets to your repository:
   - `WORKLOAD_IDENTITY_PROVIDER`: From the setup_gcp_auth.sh script
   - `SERVICE_ACCOUNT_EMAIL`: From the setup_gcp_auth.sh script

2. **Push your changes**

   Make changes, create a pull request, and merge to main to trigger deployment.

## Connecting to the Cluster

After deployment, connect to your cluster:

```bash
./scripts/connect.sh
```

This script will:
- Get cluster credentials from Terraform outputs
- Configure kubectl to use the cluster
- Display available nodes

## Self-Destruction Mechanism

This infrastructure includes an automatic self-destruction feature to prevent forgotten resources and control costs.

1. **How it works**
   - A Cloud Scheduler job monitors the lifetime of the cluster
   - When the specified time is reached, resources are destroyed
   - Optional email notification is sent before destruction

2. **Configuration**
   - `auto_destroy_hours`: Number of hours before destruction (0 to disable)
   - `auto_destroy_notification_email`: Email for notifications

3. **Checking status**
   - View the destruction schedule in GCP Console under Cloud Scheduler
   - Check cluster labels for "self-destruct-time"

## Manual Teardown

To manually destroy all resources:

```bash
cd environments/dev
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Permissions Issues**
   - Ensure your account has the necessary IAM roles
   - Verify service account permissions

2. **Quota Limits**
   - Check for quota errors in the GCP console
   - Request quota increases if needed

3. **Network Connectivity**
   - Ensure your IP is allowed to access the GKE control plane

### Getting Help

If you encounter issues, check:
- GCP console for error messages
- Terraform logs (set TF_LOG=DEBUG for verbose output)
- GitHub Actions logs (if using CI/CD)