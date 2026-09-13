output "nodes" {
  description = "Configured VM names and addresses."
  value = {
    for role, vm in var.vm_specs : role => {
      name    = vm.name
      address = split("/", vm.address)[0]
      vm_id   = vm.vm_id
    }
  }
}

