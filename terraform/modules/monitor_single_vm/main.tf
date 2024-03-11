
locals{

base_name = "${var.slurm_cluster_name}-monitor"

}

# Create the instance template for the monitor
module "slurm_monitoring_template" {
  source = "./modules/slurm_monitoring_instance_template"

  disk_auto_delete         = var.disk_auto_delete
  disk_labels              = var.disk_labels
  disk_size_gb             = var.disk_size_gb
  disk_type                = var.disk_type
  enable_confidential_vm   = var.enable_confidential_vm
  enable_oslogin           = var.enable_oslogin
  enable_shielded_vm       = var.enable_shielded_vm
  labels                   = var.labels
  machine_type             = var.machine_type
  metadata                 = var.metadata
  name_prefix              = var.group_name
  on_host_maintenance      = var.on_host_maintenance
  preemptible              = var.preemptible
  project_id               = var.project_id
  region                   = var.region
  service_account          = var.service_account
  shielded_instance_config = var.shielded_instance_config
  slurm_cluster_name       = var.slurm_cluster_name
  slurm_instance_role      = "login"
  source_image_family      = var.source_image_family
  source_image_project     = var.source_image_project
  source_image             = var.source_image
  spot                     = var.spot
  subnetwork_project       = var.subnetwork_project
  subnetwork               = var.subnetwork
  tags                     = concat([var.slurm_cluster_name], var.tags)
  termination_action       = var.termination_action
}


## For single server deployment, only need a VM
## This is useful when you are ok either exposing the external IP address to the outside
## world or using a VPN to reach the service. 

locals {
  scripts_dir = abspath("${path.module}/../../scripts")
  hostname      = var.hostname == "" ? "default" : var.hostname
  num_instances = length(var.static_ips) == 0 ? var.num_instances : length(var.static_ips)

  # local.static_ips is the same as var.static_ips with a dummy element appended
  # at the end of the list to work around "list does not have any elements so cannot
  # determine type" error when var.static_ips is empty
  static_ips = concat(var.static_ips, ["NOT_AN_IP"])
}

data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
}

data "google_compute_instance_template" "base" {
  project = var.project_id
  name    = module.slurm_monitoring_template.instance_template
}

data "local_file" "startup" {
  filename = abspath("${local.scripts_dir}/startup.sh")
}

resource "google_compute_instance_from_template" "slurm-gcp-monitor" {
  count   = local.num_instances
  name    = format("%s%s%s", local.hostname, "-", format("%03d", count.index + 1))
  project = var.project_id
  zone    = var.zone == null ? data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)] : var.zone

  allow_stopping_for_update = true

  network_interface {
    network            = var.network
    subnetwork         = var.subnetwork
    subnetwork_project = var.subnetwork_project
    network_ip         = length(var.static_ips) == 0 ? "" : element(local.static_ips, count.index)
    dynamic "access_config" {
      for_each = var.access_config
      content {
        nat_ip       = access_config.value.nat_ip
        network_tier = access_config.value.network_tier
      }
    }
  }

  source_instance_template = data.google_compute_instance_template.base.self_link

  # Slurm
  labels = merge(
    data.google_compute_instance_template.base.labels,
    {
      slurm_cluster_name  = var.slurm_cluster_name
      slurm_instance_role = "login"
    },
  )
  metadata = merge(
    data.google_compute_instance_template.base.metadata,
    var.metadata,
    {
      slurm_cluster_name  = var.slurm_cluster_name
      slurm_instance_role = "login"
      startup-script      = data.local_file.startup.content
      VmDnsSetting        = "GlobalOnly"
    },
  )
}


