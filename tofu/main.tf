resource "proxmox_virtual_environment_vm" "node" {
  for_each = var.vm_specs

  name      = each.value.name
  node_name = var.node_name
  vm_id     = each.value.vm_id

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = each.value.disk_gb
  }

  network_device {
    bridge = var.bridge
  }

  initialization {
    datastore_id = var.datastore_id

    dns {
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = each.value.address
        gateway = var.gateway
      }
    }

    user_account {
      keys     = [trimspace(var.ssh_public_key)]
      username = "devops"
    }
  }
}

