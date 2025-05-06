# Secure GKE Cluster with Terraform

A production-ready Google Kubernetes Engine (GKE) cluster deployment using Terraform best practices. This project provides a secure, modular, and cost-effective GKE infrastructure following Google Cloud's recommendations and security hardening guidelines.

## Overview

This repository contains Terraform modules to deploy:
- Private GKE cluster with custom VPC network
- Comprehensive security controls
- Cost-optimized configurations
- Complete infrastructure as code

Perfect for:
- Development and testing environments
- Learning GKE best practices
- Starting point for production workloads
- Understanding Terraform modular design

## Features

### Infrastructure
- **Private GKE cluster** with custom VPC and dedicated subnets
- **VPC-native networking** with separate pod and service CIDRs
- **Cloud NAT** for outbound internet access
- **Spot instances** for cost efficiency (up to 91% discount)
- **Complete modularity** for easy customization

### Security
- **Private cluster** with secure networking
- **Shielded nodes** with Secure Boot
- **Workload Identity** for pod-level authentication
- **Network Policy (Calico)** for pod isolation
- **Service account** with minimal permissions
- **NodeLocal DNSCache** for secure/improved DNS
- **VPC Flow Logs** for network auditing
- **Application-layer Secrets Encryption** (optional)

### Cost Optimization
- **e2-micro** machine type (smallest available)
- **Spot instances** for significant cost reduction
- **Minimal node count** (1-2 nodes)
- **Single-zone** configuration for development

### Terraform Best Practices
- **Modular design** with clean separation of concerns
- **Remote state** with GCS backend
- **Clear variable definitions** with documentation
- **Logical resource organization**
- **Feature flags** for optional capabilities
- **Secure defaults** with override capability

## Prerequisites

Before you start, you need:

1. **Google Cloud Platform account** with billing enabled
2. **Local tools** installed:
   - [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
   - [Terraform](https://developer.hashicorp.com/terraform/downloads) (v1.0+)
   - [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/secure-gke-terraform.git
cd secure-gke-terraform
```

### 2. Run the Bootstrap Script

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

This script will:
- Verify required tools
- Authenticate with Google Cloud
- Enable necessary APIs
- Create a GCS bucket for Terraform state
- Generate backend.tf from the template
- Generate terraform.tfvars from the template
- Initialize Terraform

### 3. Deploy the Infrastructure

```bash
cd environments/dev
terraform plan    # Preview changes
terraform apply   # Deploy the infrastructure
```

### 4. Connect to Your Cluster

```bash
chmod +x ../../scripts/connect.sh
../../scripts/connect.sh
```

### 5. Test with a Sample Application

```bash
kubectl apply -f ../../kubernetes/manifests/deployment.yaml
kubectl get service demo-app  # Get the external IP
```

### 6. Clean Up When Finished

```bash
cd environments/dev
terraform destroy
```

## Detailed Architecture

### Modular Structure

The project is organized into the following modules:

1. **VPC Network Module**
   - Custom VPC with private Google access
   - Subnet with secondary IP ranges
   - Firewall rules with least privilege
   - Cloud NAT for egress traffic
   - VPC Flow Logs for security monitoring

2. **Security Module**
   - Custom service account with minimal permissions
   - Binary Authorization for image validation (optional)
   - Cloud Armor security policies (optional)
   - Secret Manager for sensitive configuration (optional)

3. **GKE Cluster Module**
   - Private cluster with private nodes
   - Spot instances for cost savings
   - Shielded nodes with secure boot
   - Workload Identity for pod authentication
   - Network Policy (Calico) for pod security
   - NodeLocal DNSCache for better DNS security

4. **Network Policy Module**
   - Default deny base policy
   - Granular allow rules by namespace/label
   - DNS access for pods
   - Optional egress restrictions

5. **Monitoring Module**
   - Custom GKE dashboards
   - Security-focused alert policies
   - Log-based security metrics
   - Optional log export for compliance

### Network Architecture

- **VPC Network**: Dedicated network for the cluster
- **Primary Subnet**: 10.0.0.0/24 for GKE nodes
- **Pod CIDR**: 10.1.0.0/16 for Kubernetes pods
- **Service CIDR**: 10.2.0.0/16 for Kubernetes services
- **Master CIDR**: 172.16.0.0/28 for GKE control plane

For a detailed visual representation, see the [architecture diagram](docs/architecture.md).

## Directory Structure

```
.
├── environments/
│   └── dev/                 # Development environment
│       ├── backend.tf.example  # Template for Terraform backend
│       ├── main.tf         # Main Terraform configuration
│       ├── outputs.tf      # Output definitions
│       ├── terraform.tfvars.example # Template for variables
│       └── variables.tf    # Input variable definitions
│
├── kubernetes/
│   └── manifests/          # Kubernetes manifests
│       └── deployment.yaml # Sample application
│
├── modules/
│   ├── gke/                # GKE cluster module
│   │   ├── main.tf         # GKE resource definitions
│   │   ├── outputs.tf      # Module outputs
│   │   └── variables.tf    # Module variables
│   │
│   ├── monitoring/         # Monitoring and alerting module
│   │   ├── main.tf         # Monitoring resources
│   │   ├── outputs.tf      # Module outputs
│   │   └── variables.tf    # Module variables
│   │
│   ├── network-policy/     # Kubernetes NetworkPolicy module
│   │   ├── main.tf         # NetworkPolicy resources
│   │   ├── outputs.tf      # Module outputs
│   │   └── variables.tf    # Module variables
│   │
│   ├── security/           # Security module
│   │   ├── main.tf         # Security resources
│   │   ├── outputs.tf      # Module outputs
│   │   └── variables.tf    # Module variables
│   │
│   └── vpc/                # VPC network module
│       ├── main.tf         # VPC resource definitions
│       ├── outputs.tf      # Module outputs
│       └── variables.tf    # Module variables
│
├── scripts/
│   ├── bootstrap.sh        # Setup script
│   └── connect.sh          # Cluster connection script
│
└── docs/
    └── architecture.md     # Architecture documentation
```

## Configuration Options

Key variables that can be customized in `terraform.tfvars`:

### Project Configuration
- `project_id` - Your GCP project ID
- `project_name` - Name used for resource naming
- `region` - GCP region (default: us-central1)
- `zone` - GCP zone (default: us-central1-a)

### Network Configuration
- `subnet_cidr` - Primary subnet CIDR (default: 10.0.0.0/24)
- `pod_cidr` - Pod IP range (default: 10.1.0.0/16)
- `service_cidr` - Service IP range (default: 10.2.0.0/16)
- `master_ipv4_cidr_block` - Master IP range (default: 172.16.0.0/28)

### GKE Configuration
- `machine_type` - Node VM type (default: e2-micro)
- `min_node_count` - Minimum nodes (default: 1)
- `max_node_count` - Maximum nodes (default: 2)

### Security Options
- `deploy_network_policies` - Enable NetworkPolicies (default: false)
- `enable_monitoring` - Enable enhanced monitoring (default: true)

## Advanced Usage

### Enabling Network Policies

Set `deploy_network_policies = true` in your terraform.tfvars file to enable Kubernetes NetworkPolicies that restrict pod-to-pod communication.

### Enhanced Monitoring

Keep `enable_monitoring = true` (default) to deploy custom dashboards, alerts, and security metrics.

### Private GKE Master

For additional security, you can restrict access to the GKE API server by setting:
```
enable_master_authorized_networks = true
master_authorized_cidr_blocks = [
  {
    cidr_block   = "192.168.1.0/24"
    display_name = "Corporate Office"
  }
]
```

## Security Considerations

This project implements a multi-layered security approach:

1. **Network Security**
   - Private GKE cluster with private nodes
   - VPC-native networking with separate pod/service CIDRs
   - Firewall rules with least privilege
   - Default deny with explicit allows

2. **Identity & Access**
   - Custom service account with minimal permissions
   - Workload Identity for pod authentication
   - RBAC for Kubernetes authorization

3. **Node Security**
   - Shielded nodes with Secure Boot
   - Node auto-upgrading
   - Container-Optimized OS
   - Optional disk encryption

4. **Workload Security**
   - Network Policy for pod isolation
   - Optional Binary Authorization
   - Optional Pod Security Policy

See the [architecture document](docs/architecture.md) for more details.

## Terraform Best Practices

This project demonstrates several Terraform best practices:

1. **Modular Design**
   - Clean separation of concerns
   - Reusable modules with well-defined interfaces
   - Logical resource organization

2. **State Management**
   - Remote state in GCS bucket
   - State locking for concurrent operations
   - State versioning for recovery

3. **Variable Management**
   - Clear definitions with types
   - Descriptive documentation
   - Sensible defaults

4. **Dynamic Configuration**
   - Feature flags for optional components
   - Environment-specific configurations
   - Override capability

5. **Security Hardening**
   - Secure defaults
   - Principle of least privilege
   - Defense in depth

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.