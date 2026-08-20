variable "server_name" {
  description = "Hetzner Cloud sunucusunun adi"
  type        = string
  default     = "gitops-server"
}

variable "server_type" {
  description = "Hetzner Cloud sunucu tipi"
  type        = string
}

variable "location" {
  description = "Sunucunun olusturulacagi Hetzner lokasyonu"
  type        = string
}

variable "image" {
  description = "Sunucuda kullanilacak isletim sistemi image'i"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Sunucuya eklenecek SSH public key dosyasinin yolu"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "SSH baglantisina izin verilecek IP/CIDR"
  type        = string
}
