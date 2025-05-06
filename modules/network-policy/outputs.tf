# modules/network-policy/outputs.tf

output "enabled_network_policies" {
  description = "List of enabled network policies"
  value = concat(
    var.enable_default_policies ? ["default-deny-ingress"] : [],
    var.enable_default_policies && var.restrict_egress ? ["default-deny-egress", "allow-dns-egress", "allow-api-egress"] : [],
    var.enable_intra_namespace_communication ? ["allow-intra-namespace"] : [],
    [for k, v in var.enabled_apps_ingress : "allow-ingress-to-${k}"],
    var.allow_external_egress && var.restrict_egress ? [for k, v in var.external_egress_cidrs : "allow-egress-to-${k}"] : []
  )
}