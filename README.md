# GKE Test Cluster Deployment

[![Made By][made-by-shield]][made-by-url]
[![Built With][built-with-terraform]][terraform-url]
[![Built With][built-with-gcp]][gcp-url]
[![License][license-shield]][license-url]

[![HCL][hcl-shield]][shell-url]
[![Shell][shell-shield]][shell-url]

This project contains Terraform configurations to deploy a minimal Google Kubernetes Engine (GKE) cluster on Google Cloud Platform (GCP). It's designed for testing purposes and is optimized for use with GCP's free tier.

<p align="center">
  <a href="#prerequisites">Prerequisites</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#project-structure">Structure</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#security-notes">Security</a> •
  <a href="#maintenance">Maintenance</a>
</p>

## ✨ Features

<table>
<tr>
<td>

### 🚀 Infrastructure
- Regional cluster with single-zone deployment
- Custom VPC with dedicated subnets
- Cloud NAT for internet access
- Automated node pool management
- Self-destructing mechanism

### 💰 Cost Optimization
- Uses e2-micro machine type
- Leverages spot instances
- Minimal node count (1-2 nodes)
- Optimized resource requests

</td>
<td>

### 🔒 Security
- Private GKE cluster
- VPC-native networking
- Shielded nodes
- Limited OAuth scopes
- Minimal service account permissions

### 🤖 Automation
- Automated deployment
- Self-destruction capability
- Automated connection setup
- Infrastructure as Code
- CI/CD ready

</td>
</tr>
</table>

## 📋 Prerequisites

Before you begin, ensure you have:
1. A Google Cloud Platform account
2. Owner or Editor role on your GCP project
3. Git installed on your machine
4. Linux/Unix-based operating system

The bootstrap script will automatically install:
- Terraform >= 1.0
- Google Cloud SDK
- kubectl
- gke-gcloud-auth-plugin

## 🚀 Quick Start

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Mdaftab/self-destruct-infra-tf.git
   cd self-destruct-infra-tf
   ```

2. **Run Bootstrap Script**
   ```bash
   sudo ./scripts/bootstrap.sh
   ```
   The script will:
   - Install all required tools
   - Prompt for your GCP Project ID
   - Enable required GCP APIs
   - Create a GCS bucket for Terraform state
   - Configure terraform.tfvars and backend.tf automatically

3. **Authenticate with Google Cloud**
   ```bash
   gcloud auth application-default login
   ```

4. **Deploy Infrastructure**
   ```bash
   cd environments/dev
   terraform init
   terraform plan
   terraform apply
   ```

5. **Connect to Cluster**
   ```bash
   ../../scripts/connect.sh
   ```

## 🏗️ Project Structure

```
/gke-project
├── environments/dev/          # Environment-specific configurations
│   ├── main.tf               # Main Terraform configuration
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Output definitions
│   ├── terraform.tfvars      # Variable values (auto-configured)
│   └── backend.tf            # Backend configuration (auto-configured)
├── modules/                   # Reusable Terraform modules
│   ├── gke/                  # GKE cluster module
│   └── vpc/                  # VPC network module
├── kubernetes/               # Kubernetes resources
│   └── manifests/           # Kubernetes manifest files
│       ├── deployment.yaml  # Demo application deployment
│       ├── monitoring.yaml  # Monitoring stack configuration
│       └── logging.yaml     # Logging stack configuration
├── scripts/                  # Utility scripts
│   ├── bootstrap.sh         # Automated setup script
│   └── connect.sh           # Cluster connection script
└── README.md
```

## ⚙️ Configuration

### 🔧 Automated Setup
The bootstrap script automatically:
1. Installs all required tools and dependencies
2. Creates and configures GCS bucket for Terraform state
3. Enables required GCP APIs:
   - compute.googleapis.com
   - container.googleapis.com
   - cloudresourcemanager.googleapis.com
   - iam.googleapis.com
4. Sets up configuration files with your project details

### 🔒 Sensitive Files
The following files are automatically configured and should not be committed:
- `terraform.tfvars`: Contains project-specific variables
- `backend.tf`: Contains state backend configuration
- `.terraform.lock.hcl`: Contains provider version locks
- Any `*.json` credential files
- `.env` or `.envrc` files

### VPC Configuration
- Subnet CIDR: `10.0.0.0/24`
- Pod CIDR: `10.1.0.0/16`
- Service CIDR: `10.2.0.0/16`
- Master CIDR: `172.16.0.0/28`

### GKE Configuration
- Machine Type: `e2-micro`
- Node Pool Size: 1-2 nodes
- Spot Instances: Enabled
- Private Cluster: Enabled
- Regional Deployment: Yes

## 🔐 Security Notes

1. **Never commit sensitive files:**
   - Terraform state files (`*.tfstate`)
   - Variable files (`*.tfvars`)
   - Credentials (`*.json`)
   - Backend configuration (`backend.tf`)
   - Environment files (`.env`, `.envrc`)

2. Use service accounts with minimal required permissions
3. Regularly rotate service account keys
4. Keep your GKE cluster version updated
5. Monitor cluster logs and metrics

## 🛠️ Maintenance

### Updating the Cluster
```bash
# Get latest changes
git pull

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Destroying the Infrastructure
```bash
terraform destroy
```

## ⚠️ Limitations

- e2-micro instances are extremely resource-constrained
- Limited to lightweight workloads
- Requires manual resource scaling for complex applications
- Spot instances may be terminated with short notice

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

[made-by-shield]: https://img.shields.io/badge/Made%20by-Mdaftab-blue
[made-by-url]: https://github.com/Mdaftab
[built-with-terraform]: https://img.shields.io/badge/Built%20with-Terraform-purple
[terraform-url]: https://www.terraform.io/
[built-with-gcp]: https://img.shields.io/badge/Built%20with-GCP-blue
[gcp-url]: https://cloud.google.com/
[license-shield]: https://img.shields.io/badge/License-MIT-green
[license-url]: LICENSE
[hcl-shield]: https://img.shields.io/badge/Language-HCL-blue
[hcl-url]: https://github.com/hashicorp/hcl
[shell-shield]: https://img.shields.io/badge/Language-Shell-green
[shell-url]: https://www.gnu.org/software/bash/
