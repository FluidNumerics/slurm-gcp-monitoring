
locals{

base_name = "${var.slurm_cluster_name}-monitor"

}

# Create the instance template for the monitor
# To do - need a startup script that installs and starts
# grafana, prometheus, go, and prometheus-slurm-exporter,
# performs configurations to enable slurmd (configless slurm),
# copies in grafana.ini and dashboard (json files). 
module "slurm_monitoring_template" {
  source = "./modules/slurm_instance_template"

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
## In this case, the grafana.ini is set up to use workspace credentials

# If a service account is provided, then we use that service account. Otherwise, we need
# to create a service account

## TO DO : Create Service Account if var.service_Account == null

## TO DO : Create local that sets service_acccount_name to the variable provided or
## the the google_service_account.myaccount.name created above

# Create a service account key
resource "google_service_account_key" "mykey" {
  service_account_id = google_service_account.myaccount.name
}

## TO DO : Edit the template grafana.ini to use the specific service account key


### Create the VM from the template, with the provided service account in the appropriate network
