# Architecture Guide

This document describes the architecture and design decisions of the self-destructing GKE cluster infrastructure.

## Architecture Overview

The infrastructure is designed with modularity, cost-effectiveness, and security in mind. It creates a private GKE cluster with a customized VPC network, optimized for development and testing purposes.

![Architecture Diagram](diagrams/architecture.png)

## Components

### 1. VPC Network Module

The VPC module (`modules/vpc`) creates:

- **Custom VPC network** without auto-created subnets
- **Custom subnet** in the specified region
- **Secondary IP ranges** for pods and services
- **Cloud NAT** for outbound internet connectivity
- **Firewall rules** for GKE internal communication

Key features:
- Proper CIDR segmentation for network, pods, and services
- NAT configuration for private nodes
- Secure internal communication

### 2. GKE Cluster Module

The GKE module (`modules/gke`) creates:

- **Private GKE cluster** with private nodes
- **Node pool** with spot instances for cost savings
- **Minimal configuration** optimized for testing

Key features:
- Private nodes with public control plane
- Spot instances for cost optimization
- Network policy enabled with Calico
- Shielded nodes for enhanced security
- Cloud monitoring and logging integration
- Self-destruction capability via Cloud Scheduler

### 3. Self-Destruction Mechanism

The self-destruction feature consists of:

- **Cloud Scheduler jobs** to monitor cluster lifetime
- **Time-based triggers** for automatic destruction
- **Notification system** (optional) to alert before destruction

## Security Considerations

1. **Network Security**
   - Private GKE cluster with no nodes exposed to the internet
   - VPC-native networking with proper IP segmentation
   - Network policy for pod-to-pod traffic control

2. **Access Control**
   - Workload Identity Federation for GitHub Actions
   - Principle of least privilege for service accounts
   - Limited OAuth scopes for node service accounts

3. **Node Security**
   - Shielded nodes with secure boot
   - Container-Optimized OS for reduced attack surface
   - Auto-upgrades for security patches

## Cost Optimization

Cost minimization is achieved through:

1. **Compute Resources**
   - Small machine types (e2-micro)
   - Spot instances (up to 91% discount)
   - Minimal node count (1-2 nodes)
   - Single-zone deployment

2. **Operational Costs**
   - Self-destruction to prevent forgotten resources
   - Minimal monitoring and logging configuration
   - Efficient autoscaling configuration

## Terraform Organization

The codebase follows Terraform best practices:

1. **Modularity**
   - Reusable modules for VPC and GKE
   - Clear separation of concerns
   - Configurable interfaces via variables

2. **Environment Separation**
   - Environment-specific configurations in `environments/`
   - Consistent module usage patterns
   - Variables with sensible defaults

3. **State Management**
   - Remote state in Google Cloud Storage
   - State locking to prevent concurrent modifications
   - State versioning for recovery

## CI/CD Pipeline

The GitHub Actions workflow provides:

1. **Validation**
   - Terraform format checking
   - Terraform validation
   - Security scanning with tfsec

2. **Deployment**
   - Automated planning
   - Approval gates for production
   - Secure authentication with Workload Identity

3. **Documentation**
   - Automatic diagram generation
   - README updates
   - Module documentation

## Design Decisions

### Single-Zone vs Multi-Zone

We chose a single-zone deployment to minimize costs while maintaining adequate resilience for development and testing. Production deployments should consider multi-zone or multi-regional setups.

### Spot vs Regular Instances

Spot instances were selected for cost savings (up to 91% discount). The tradeoff is potential preemption, which is acceptable for development/testing workloads.

### Private vs Public Cluster

A private cluster design was chosen for enhanced security. Nodes are not directly accessible from the internet, reducing the attack surface.

### Self-Destruction Mechanism

The automatic self-destruction capability prevents forgotten resources and unintended billing. This approach balances convenience and cost control.