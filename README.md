# Self-Destructing GKE Cluster Infrastructure

A minimal, cost-effective Google Kubernetes Engine (GKE) cluster deployment using Terraform. This project creates a self-destructing cluster optimized for testing and development purposes.

## 🎯 Features

<table>
<tr>
<td>

### 🚀 Infrastructure
- Private GKE cluster
- Custom VPC with dedicated subnets
- Cloud NAT for internet access
- Spot instances for cost savings
- Single-zone deployment

### 💰 Cost Optimization
- e2-micro machine type
- Spot instances
- Minimal node count (1-2)
- Auto-destruction capability

</td>
<td>

### 🔒 Security
- Private cluster
- VPC-native networking
- Shielded nodes
- Limited OAuth scopes
- Application default credentials

### 🤖 Automation
- Two-step deployment process
- Automated dependency setup
- Infrastructure as Code
- Terraform state management
- Required APIs auto-enabled

</td>
</tr>
</table>

## 🔑 Authentication Setup

### Local Development
1. Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
2. Authenticate with GCP:
   ```bash
   gcloud auth application-default login
   ```
3. Set your project ID:
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   ```

### GitHub Actions Authentication
This project uses Workload Identity Federation for secure authentication between GitHub Actions and Google Cloud Platform. This is the recommended approach as it:
- Eliminates the need to store long-lived credentials in GitHub
- Provides automatic key rotation
- Enables fine-grained access control
- Follows security best practices

To set up Workload Identity Federation:

1. Set required environment variables:
   ```bash
   export PROJECT_ID="your-project-id"
   export GITHUB_REPO="your-github-username/your-repo-name"
   ```

2. Run the setup script:
   ```bash
   ./scripts/setup_gcp_auth.sh
   ```

3. Add the generated secrets to your GitHub repository:
   - `WORKLOAD_IDENTITY_PROVIDER`
   - `SERVICE_ACCOUNT_EMAIL`

## 📋 Prerequisites

Before starting, ensure you have:
- A Google Cloud Platform account
- Owner or Editor role on your GCP project
- Git installed
- Linux/Unix-based operating system

## 🚀 Deployment Process

The deployment process is split into two automated scripts for better organization and security:

### 1. Bootstrap Script (`bootstrap.sh`)

This script handles all prerequisite installations and authentication:

```bash
sudo ./scripts/bootstrap.sh
```

**What it does:**
- ✓ Installs required tools:
  - Terraform
  - Google Cloud SDK
  - kubectl
  - gke-gcloud-auth-plugin
- ✓ Verifies successful installations
- ✓ Checks GCP authentication status
- ✓ Guides through GCP authentication if needed

### 2. Setup Script (`setup.sh`)

This script configures and prepares your infrastructure:

```bash
./scripts/setup.sh
```

**What it does:**
- ✓ Verifies GCP authentication
- ✓ Sets up GCP project configuration
- ✓ Enables required GCP APIs:
  - Compute Engine
  - Kubernetes Engine
  - Cloud Resource Manager
  - IAM
- ✓ Creates GCS bucket for Terraform state
- ✓ Configures backend.tf with bucket details
- ✓ Creates terraform.tfvars with your settings
- ✓ Initializes Terraform
- ✓ Generates deployment plan

### 3. Deploy Infrastructure

After the setup is complete, deploy your infrastructure:

```bash
cd environments/dev
terraform apply tfplan
```

## 🏗️ Project Structure

```
.
├── environments/
│   └── dev/                 # Development environment
│       ├── backend.tf       # Terraform backend configuration
│       ├── main.tf         # Main Terraform configuration
│       ├── variables.tf     # Variable definitions
│       └── terraform.tfvars # Variable values
├── modules/                 # Reusable Terraform modules
│   └── gke/                # GKE cluster module
└── scripts/
    ├── bootstrap.sh        # Initial setup script
    └── setup.sh           # Infrastructure setup script
    └── setup_gcp_auth.sh  # GCP authentication setup script
```

## ⚙️ Infrastructure Details

### Network Configuration
- Subnet CIDR: `10.0.0.0/24`
- Pod CIDR: `10.1.0.0/16`
- Service CIDR: `10.2.0.0/16`
- Master CIDR: `172.16.0.0/28`

### Cluster Configuration
- Machine Type: `e2-micro`
- Node Count: 1-2 nodes
- Node Type: Spot instances
- Private Cluster: Yes
- Region: `us-central1`
- Zone: `us-central1-a`

## 🔒 Security Notes

1. **Authentication:**
   - Uses application default credentials
   - No service account keys stored locally
   - Minimal required permissions

2. **Network Security:**
   - Private cluster deployment
   - Authorized networks limited to your IP
   - Secure master access configuration

3. **Never Commit:**
   - Terraform state files (`*.tfstate`)
   - Variable files (`*.tfvars`)
   - Backend configuration (`backend.tf`)

## 🔧 Maintenance

### Updating Configuration
1. Edit `terraform.tfvars` for changes
2. Run `terraform plan` to review
3. Apply with `terraform apply`

### Destroying Infrastructure
```bash
cd environments/dev
terraform destroy
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Infrastructure Diagrams

The infrastructure diagrams below are automatically generated from our Terraform code and updated on every push to main.

_Note: Diagrams will be automatically generated and inserted here by GitHub Actions_

[made-by-shield]: https://img.shields.io/badge/Made%20by-Mdaftab-blue
[made-by-url]: https://github.com/Mdaftab
[built-with-terraform]: https://img.shields.io/badge/Built%20with-Terraform-844fba
[terraform-url]: https://terraform.io
[built-with-gcp]: https://img.shields.io/badge/Built%20with-GCP-4285f4
[gcp-url]: https://cloud.google.com
[license-shield]: https://img.shields.io/badge/License-MIT-green
[license-url]: LICENSE
[hcl-shield]: https://img.shields.io/badge/HCL-38%25-blue
[shell-shield]: https://img.shields.io/badge/Shell-12%25-green
[shell-url]: scripts/

<!-- BEGIN AUTO-GENERATED -->
> ⚠️ This section is automatically generated. Do not modify manually.
> Last updated: 2025-03-05 00:52:09

## 🏗 Terraform Modules

### vpc

**Variables:**
- `project_id` (string)
- `vpc_name` (string)
- `subnet_name` (string)
- `region` (string)
- `subnet_cidr` (string)
- `pod_cidr` (string)
- `service_cidr` (string)
- `master_ipv4_cidr_block` (string)

**Outputs:**
- `network_name`
- `subnet_name`
- `network_id`
- `subnet_id`

### gke

**Variables:**
- `project_id` (string)
- `region` (string)
- `zone` (string)
- `network_name` (string)
- `subnet_name` (string)
- `master_ipv4_cidr_block` (string)
- `service_account` (string)
- `machine_type` (string)
- `min_node_count` (number)
- `max_node_count` (number)
- `initial_node_count` (number)
- `environment` (string)
- `cluster_name` (string)

**Outputs:**
- `cluster_name`
- `cluster_region`
- `project_id`
- `endpoint`
- `ca_certificate`

## 🚢 Kubernetes Resources

### logging.yaml

- `Namespace/logging`
- `HelmChart/loki-stack`
- `ConfigMap/promtail-config`

### deployment.yaml

- `Deployment/demo-app`
- `Service/demo-app`

### monitoring.yaml

- `Namespace/monitoring`
- `HelmChart/prometheus-stack`
- `ServiceMonitor/demo-app`

