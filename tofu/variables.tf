variable "proxmox_endpoint" {
  description = "Proxmox API URL, for example https://pve.lab.local:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token. Prefer the PROXMOX_VE_API_TOKEN environment variable."
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Allow a self-signed Proxmox certificate during bootstrap."
  type        = bool
  default     = true
}

variable "proxmox_ssh_user" {
  type    = string
  default = "root"
}

variable "node_name" {
  type = string
}

variable "template_vm_id" {
  description = "VM ID of the cloud-init template to clone."
  type        = number
}

variable "datastore_id" {
  type    = string
  default = "local-lvm"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "gateway" {
  type = string
}

variable "dns_servers" {
  type    = list(string)
  default = ["1.1.1.1"]
}

variable "ssh_public_key" {
  type = string
}

variable "vm_specs" {
  description = "VM definitions keyed by logical role."
  type = map(object({
    vm_id     = number
    name      = string
    address   = string
    cores     = number
    memory_mb = number
    disk_gb   = number
  }))
}

