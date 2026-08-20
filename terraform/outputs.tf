output "server_id" {
  description = "Olusturulan Hetzner sunucusunun ID'si"
  value       = hcloud_server.gitops.id
}

output "server_ipv4" {
  description = "Olusturulan sunucunun public IPv4 adresi"
  value       = hcloud_server.gitops.ipv4_address
}

output "server_ipv6" {
  description = "Olusturulan sunucunun public IPv6 adresi"
  value       = hcloud_server.gitops.ipv6_address
}

output "server_status" {
  description = "Sunucunun mevcut durumu"
  value       = hcloud_server.gitops.status
}
