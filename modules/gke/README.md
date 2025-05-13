# GKE Module

This module creates a secure and hardened Google Kubernetes Engine (GKE) cluster using the official `terraform-google-modules/kubernetes-engine/google` private cluster module as a base. It incorporates several best practices for security, networking, and manageability suitable for a production-ready environment.

## Features

*   **Private Cluster:** Nodes have only private IP addresses.
*   **VPC-Native Networking:** Uses alias IP ranges for Pods and Services.
*   **Workload Identity:** Securely manage access for workloads running in the cluster.
*   **Node Auto-upgrade & Auto-repair:** Ensures nodes are running the latest secure and stable GKE versions.
*   **Shielded Nodes, Secure Boot, Integrity Monitoring:** Enhances node security against rootkits and boot-level malware.
*   **NodeLocal DNSCache:** Improves DNS performance and reduces reliance on the kube-dns service.
*   **Application-layer Secrets Encryption (Optional):** Encrypts Kubernetes Secrets using Cloud KMS.
*   **Binary Authorization (Optional):** Enforces deployment of trusted container images.
*   **Dataplane V2:** Optimized networking with Calico.
*   **Maintenance Policy:** Configures scheduled maintenance windows.
*   **Resource Labels:** Applies consistent labels for cost allocation and management.
*   **Input Validation:** Basic validation for key variables.

## Usage

This module is typically called from an environment-specific `main.tf` file (e.g., `environments/dev/main.tf`).

```terraform
module "gke" {
  source = "../../modules/gke"

  project_id             = var.project_id
  project_name           = var.project_name
  cluster_name           = "${var.project_name}-cluster"
  region                 = var.region
  zone                   = var.zone
  network_name           = module.vpc.network_name
  subnet_name            = module.vpc.subnet_name
  master_ipv4_cidr_block = var.master_ipv4_cidr_block
  service_account        = module.security.service_account_email # Example: using SA from security module
  machine_type           = var.machine_type
  min_node_count         = var.min_node_count
  max_node_count         = var.max_node_count
  initial_node_count     = var.initial_node_count
  environment            = var.environment

  # Security configurations (controlled by environment variables)
  enable_binary_authorization = var.enable_binary_authorization
  enable_database_encryption  = var.enable_database_encryption
  database_encryption_key     = var.database_encryption_key # Required if enable_database_encryption is true
  enable_boot_disk_encryption = var.enable_boot_disk_encryption
  boot_disk_kms_key           = var.boot_disk_kms_key       # Required if enable_boot_disk_encryption is true
  enable_dns_cache            = var.enable_dns_cache
  enable_pod_security_policy  = var.enable_pod_security_policy
  enable_master_authorized_networks = var.enable_master_authorized_networks
  master_authorized_cidr_blocks = var.master_authorized_cidr_blocks # Required if enable_master_authorized_networks is true
  release_channel             = var.release_channel
  node_taints                 = var.node_taints

  depends_on = [module.vpc, module.security] # Example dependencies
}
```

## Inputs

| Name                            | Description                                                                 | Type                                                                 | Default     | Required |
| :------------------------------ | :-------------------------------------------------------------------------- | :------------------------------------------------------------------- | :---------- | :------- |
| `project_id`                    | The ID of the project in which the resources belong                         | `string`                                                             | n/a         | yes      |
| `project_name`                  | The name of the project (used for resource naming)                          | `string`                                                             | n/a         | yes      |
| `region`                        | The region to host the cluster in                                           | `string`                                                             | n/a         | yes      |
| `zone`                          | The zone to host the cluster in (required if is a zonal cluster)            | `string`                                                             | n/a         | yes      |
| `network_name`                  | The VPC network to host the cluster in                                      | `string`                                                             | n/a         | yes      |
| `subnet_name`                   | The subnetwork to host the cluster in                                       | `string`                                                             | n/a         | yes      |
| `master_ipv4_cidr_block`        | The IP range in CIDR notation to use for the hosted master network          | `string`                                                             | n/a         | yes      |
| `service_account`               | The service account to be used by the node VMs                              | `string`                                                             | n/a         | yes      |
| `machine_type`                  | The machine type to use for node VMs                                        | `string`                                                             | n/a         | yes      |
| `min_node_count`                | Minimum number of nodes in the NodePool                                     | `number`                                                             | n/a         | yes      |
| `max_node_count`                | Maximum number of nodes in the NodePool                                     | `number`                                                             | n/a         | yes      |
| `initial_node_count`            | Initial number of nodes in the NodePool                                     | `number`                                                             | n/a         | yes      |
| `environment`                   | The environment this cluster will run in                                    | `string`                                                             | n/a         | yes      |
| `cluster_name`                  | The name of the cluster                                                     | `string`                                                             | n/a         | yes      |
| `enable_binary_authorization`   | Enable Binary Authorization for the cluster                                 | `bool`                                                               | `false`     | no       |
| `enable_database_encryption`    | Enable application-layer secrets encryption with Cloud KMS                  | `bool`                                                               | `false`     | no       |
| `database_encryption_key`       | Cloud KMS key for database encryption (required if `enable_database_encryption` is true) | `string` | `""`        | no       |
| `enable_boot_disk_encryption`   | Enable node boot disk encryption                                            | `bool`                                                               | `false`     | no       |
| `boot_disk_kms_key`             | Cloud KMS key for boot disk encryption (required if `enable_boot_disk_encryption` is true) | `string` | `""`        | no       |
| `enable_dns_cache`              | Enable NodeLocal DNSCache                                                   | `bool`                                                               | `true`      | no       |
| `enable_pod_security_policy`    | Enable pod security policy                                                  | `bool`                                                               | `false`     | no       |
| `enable_master_authorized_networks` | Enable master authorized networks                                         | `bool`                                                               | `false`     | no       |
| `master_authorized_cidr_blocks` | List of CIDR blocks authorized to access the master (required if `enable_master_authorized_networks` is true) | `list(object({ cidr_block = string, display_name = string }))` | `[]`        | no       |
| `release_channel`               | The release channel for the GKE cluster (UNSPECIFIED, RAPID, REGULAR, STABLE) | `string` | `"STABLE"`  | no       |
| `node_taints`                   | List of taints to apply to nodes                                            | `list(object({ key = string, value = string, effect = string }))` | `[]`        | no       |

## Outputs

| Name                      | Description                                    |
| :------------------------ | :--------------------------------------------- |
| `cluster_name`            | The name of the GKE cluster                    |
| `location`                | The location (region or zone) of the cluster   |
| `endpoint`                | The IP address of the cluster master           |
| `ca_certificate`          | The cluster's certificate authority data       |
| `service_account`         | The service account used by the node pools     |
| `node_pool_names`         | List of names of the created node pools        |
| `node_pool_machine_types` | Map of node pool names to their machine types  |

## Architecture Diagram (Conceptual)

```mermaid
graph TD
    A[Environment (e.g., dev)] --> B(GKE Module)
    B --> C(GKE Cluster)
    B --> D(Node Pool)
    B --> E(Security Features)
    B --> F(Networking Configuration)
    A --> G(VPC Module)
    G --> H(VPC Network)
    G --> I(Subnets)
    A --> J(Security Module)
    J --> K(Service Accounts)
    J --> L(IAM Policies)
    C --> M(Workload Identity)
    C --> N(NodeLocal DNSCache)
    D --> O(Shielded Nodes)
    D --> P(Secure Boot)
    D --> Q(Integrity Monitoring)
    C --> R(Dataplane V2)
    C --> S(Network Policy)
    C --> T(Secrets Encryption)
    C --> U(Binary Authorization)

    subgraph Modules
        B
        G
        J
    end

    subgraph GKE Cluster Components
        C
        D
        E
        F
        M
        N
        O
        P
        Q
        R
        S
        T
        U
    end

    subgraph VPC Components
        H
        I
    end

    subgraph Security Components
        K
        L
    end

    classDef default fill:#f9f,stroke:#333,stroke-width:2px;
    classDef module fill:#ccf,stroke:#333,stroke-width:2px;
    class B,G,J module;
```

## Considerations

*   This module creates a private cluster. Ensure you have a way to access the master endpoint (e.g., via a jump host in an authorized network or Cloud Interconnect/VPN).
*   Review and configure the security features (`enable_binary_authorization`, `enable_database_encryption`, etc.) based on your environment's security requirements.
*   Adjust node pool configurations (machine type, size, disk size, spot instances) based on your workload needs and cost considerations.
*   Ensure the necessary APIs are enabled in your GCP project (e.g., Kubernetes Engine API, Compute Engine API, Cloud Key Management Service API if using secrets encryption).
