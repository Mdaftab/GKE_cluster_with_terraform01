# GKE Cluster Deployment with Terraform

This project provides a simple and modular example of deploying a Google Kubernetes Engine (GKE) cluster using Terraform, focusing on core networking and basic security practices. It's designed as a starting point for DevOps engineers to understand how to deploy a GKE cluster using infrastructure as code.

## Overview

This repository contains Terraform modules to deploy:
- A custom VPC network with necessary subnets for GKE.
- A private GKE cluster.
- Basic Kubernetes Network Policies for pod isolation (optional).

The goal is to demonstrate a clean, modular Terraform structure for deploying a GKE cluster.

## Prerequisites

Before you begin, ensure you have the following installed:

1.  **Google Cloud SDK:** For authenticating with GCP.
    [Install Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
2.  **Terraform (v1.0+):** For managing infrastructure as code.
    [Install Terraform](https://developer.hashicorp.com/terraform/downloads)
3.  **kubectl:** For interacting with the Kubernetes cluster.
    [Install kubectl](https://kubernetes.io/docs/tasks/tools/)

You will also need a Google Cloud Platform account with billing enabled and appropriate permissions to create VPC networks, GKE clusters, and related resources.

## Deployment Steps

Follow these steps to deploy the GKE cluster:

### 1. Clone the Repository

Start by cloning this repository to your local machine:

```bash
git clone https://github.com/yourusername/gke-terraform-demo.git
cd gke-terraform-demo
```

### 2. Configure Your Environment

Navigate to the development environment directory:

```bash
cd environments/dev
```

Copy the example variable and backend files:

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.tf.example backend.tf
```

Edit `terraform.tfvars` and replace the placeholder values with your actual GCP project ID and desired configuration:

```terraform
project_id = "YOUR_GCP_PROJECT_ID"
project_name = "gke-demo"
region = "us-central1"
zone = "us-central1-a"
subnet_cidr = "10.0.0.0/24"
pod_cidr = "10.1.0.0/16"
service_cidr = "10.2.0.0/16"
master_ipv4_cidr_block = "172.16.0.0/28"
machine_type = "e2-micro"
min_node_count = 1
max_node_count = 2
initial_node_count = 1
environment = "dev"

# Set to true to deploy Network Policies
deploy_network_policies = false
```

Edit `backend.tf` and configure your Terraform state backend. Using a remote backend like Google Cloud Storage (GCS) is highly recommended for team collaboration and state management. Replace `YOUR_GCS_BUCKET_NAME` with the name of your GCS bucket:

```terraform
terraform {
  backend "gcs" {
    bucket = "YOUR_GCS_BUCKET_NAME"
    prefix = "terraform/state/gke-demo"
  }
}
```

If the specified GCS bucket does not exist, you will need to create it manually before running `terraform init`.

### 3. Initialize Terraform

Initialize Terraform in the environment directory. This downloads the necessary providers and modules:

```bash
terraform init
```

If you are using the GCS backend, Terraform will initialize the backend and potentially prompt you to migrate your state if a local state file exists.

### 4. Review the Deployment Plan

Generate and review the execution plan. This step shows you exactly what resources Terraform will create, modify, or destroy:

```bash
terraform plan
```

Carefully examine the output to ensure the planned changes match your expectations.

### 5. Apply the Configuration

If the plan is satisfactory, apply the configuration to deploy the resources in your GCP project:

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### 6. Connect to Your Cluster

Once the deployment is complete, you can connect to your GKE cluster using `kubectl`. The `environments/dev/outputs.tf` file provides a convenient command to get the cluster credentials:

```bash
terraform output get_credentials_command
```

Execute the output command in your terminal. This will configure `kubectl` to connect to your new GKE cluster.

### 7. (Optional) Deploy a Sample Application

You can deploy a simple application to test your cluster and network policies. Navigate back to the project root directory and apply the sample deployment manifest:

```bash
cd ../..
kubectl apply -f kubernetes/manifests/deployment.yaml
```

Check the status of the deployed application and service:

```bash
kubectl get pods
kubectl get service demo-app
```

If you enabled Network Policies, you might need to adjust them to allow traffic to your application.

### 8. Clean Up

To avoid incurring unnecessary costs, remember to destroy the deployed infrastructure when you are finished:

Navigate back to the environment directory:

```bash
cd environments/dev
```

Run the destroy command:

```bash
terraform destroy
```

Type `yes` when prompted to confirm the destruction of resources.

## Detailed Architecture (Core Components)

```mermaid
graph TD
    A[GCP Project] --> B(VPC Module)
    B --> C(VPC Network)
    C --> D(Subnet)
    D --> E(Primary IP Range)
    D --> F(Secondary IP Range - Pods)
    D --> G(Secondary IP Range - Services)
    C --> H(Firewall Rules)
    B --> I(Cloud NAT)
    B --> J(VPC Flow Logs)

    A --> K(GKE Module)
    K --> L(GKE Cluster)
    L --> M(Node Pool)
    L --> N(Network Policy Module)
    N --> O(Kubernetes Network Policies)

    subgraph Infrastructure
        C
        D
        E
        F
        G
        H
        I
        J
        L
        M
        O
    end

    classDef default fill:#f9f,stroke:#333,stroke-width:2px;
    classDef module fill:#ccf,stroke:#333,stroke-width:2px;
    class B,K,N module;
```

## Terraform Best Practices Demonstrated

This project showcases the following Terraform best practices:

*   **Modularity:** Infrastructure components are organized into reusable modules (VPC, GKE, Network Policy).
*   **Input Validation:** Variables include validation rules to catch configuration errors early.
*   **Locals:** Used for consistent naming and simplifying expressions.
*   **Variables:** All configurable aspects are defined using variables.
*   **Conditional Logic:** Modules and resources can be conditionally deployed using `count`.
*   **Naming Conventions:** Consistent naming is used across resources and variables.
*   **Documentation:** Each module has a README, and the main README provides a clear overview and steps.
*   **Remote State:** Recommended configuration for using a GCS backend for state management.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE](LICENSE) file for details.
