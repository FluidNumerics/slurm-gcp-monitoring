
locals{

base_name = "${var.slurm_cluster_name}-monitor"

}

# Create the instance template for the monitor
# To do - need a startup script that installs and starts
# grafana, prometheus, go, and prometheus-slurm-exporter,
# performs configurations to enable slurmd (configless slurm),
# copies in grafana.ini and dashboard (json files). 
module "slurm_monitoring_instance_template" {
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

## For managed instance group deployment ###
## MIG deployment is necessary when you want to use a load balancer and identity aware proxy
## This also requires a grafana.ini file that receives credentials from IAP
# Create the health check for grafana on api/health:3000
resource "google_compute_health_check" "grafana" {
  name                = "${local.base_name}-grafana-health-check"
  check_interval_sec  = 30
  timeout_sec         = 10
  healthy_threshold   = 3
  unhealthy_threshold = 4

  http_health_check {
    request_path = "/api/health"
    port         = "3000"
  }
}

resource "google_compute_instance_group_manager" "slurm_monitor" {
  name = "${local.base_name}-monitor"

  base_instance_name = local.base_name
  zone               = var.zone

  version {
    instance_template  = module.slurm_monitoring_template.self_link
  }

  all_instances_config {
    metadata = {
      metadata_key = "metadata_value"
    }
    labels = {
      label_key = "label_value"
    }
  }

  target_pools = [google_compute_target_pool.appserver.id]
  target_size  = 1

  named_port {
    name = "grafana"
    port = 3000
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}

