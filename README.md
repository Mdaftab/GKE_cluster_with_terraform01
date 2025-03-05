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

## 📝 Recent Updates

### March 2025
1. **Infrastructure Improvements**
   - Updated GKE module configuration
   - Removed authorized_ip references
   - Added cluster_name variable
   - Optimized node pool settings

2. **Security Enhancements**
   - Implemented Workload Identity Federation
   - Added approval requirement for infrastructure changes
   - Enhanced VPC security configuration

3. **Automation Updates**
   - Added comprehensive validation workflow
   - Improved documentation generation
   - Fixed Python scripts for HCL parsing
   - Added infrastructure diagrams

4. **Documentation**
   - Added auto-generated infrastructure diagrams
   - Updated module documentation
   - Added security best practices
   - Enhanced deployment instructions

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

## 🔒 Security Notes

1. **Authentication:**
   - Uses Workload Identity Federation
   - No service account keys stored in GitHub
   - Minimal required permissions

2. **Network Security:**
   - Private cluster deployment
   - Secure master access configuration
   - VPC-native networking

3. **Change Management:**
   - Required approvals for infrastructure changes
   - Automated security scanning
   - Comprehensive validation checks

4. **Never Commit:**
   - Terraform state files (`*.tfstate`)
   - Variable files (`*.tfvars`)
   - Backend configuration (`backend.tf`)
   - Service account keys or credentials

## 🚀 Deployment Process

### 1. Initial Setup
```bash
# Install dependencies and setup authentication
./scripts/bootstrap.sh

# Configure project and enable APIs
./scripts/setup.sh
```

### 2. Infrastructure Deployment
1. Create a Pull Request with your changes
2. Wait for automated validation and planning
3. Get approval from required reviewers
4. Merge to trigger deployment
5. Approve the deployment in GitHub environments

## 🏗️ Project Structure

```
.
├── environments/
│   └── dev/                 # Development environment
│       ├── backend.tf       # Terraform backend configuration
│       ├── main.tf         # Main Terraform configuration
│       ├── variables.tf     # Variable definitions
│       └── terraform.tfvars # Variable values
├── modules/
│   ├── gke/                # GKE cluster module
│   └── vpc/                # VPC network module
├── kubernetes/
│   └── manifests/          # Kubernetes resource definitions
├── scripts/                # Automation scripts
└── docs/
    └── diagrams/          # Infrastructure diagrams
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
