resource "google_logging_metric" "job-requeue-bc-failure" {
  name   = "slurm-gcp/job-requeue-bc-failure"
  filter = <<-EOT
logName="projects/${var.project_id}/logs/slurmctld"
--Show similar entries
jsonPayload.message=~"requeue job JobId=[^ =\t\n\r\f\"\(\)\[\]\|']+\(((?:\d[,.]?)*\d)\) due to failure of node [^ =\t\n\r\f\"\(\)\[\]\|']+"
--End of show similar entries
EOT
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
  description = "Counter metric for job requeues that are caused by node failures"
  project = var.project_id
}

resource "google_logging_metric" "node-group-downed" {
  name   = "slurm-gcp/node-group-downed"
  filter = <<-EOT
logName="projects/${var.project_id}/logs/slurm_resume"
--Show similar entries
jsonPayload.message=~"/usr/local/bin/scontrol update nodename=[^ =\t\n\r\f\"\(\)\[\]\|']+ state=down reason='OPERATION_CANCELED_BY_USER"
--End of show similar entries
EOT
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
  description = "This metric keeps track of the number of times that scontrol is called to down a group of nodes that failed to be provisioned"
  project = var.project_id
}

resource "google_logging_metric" "gcp-error-cancelled-by-user" {
  name   = "slurm-gcp/gcp-error-cancelled-by-user"
  filter = <<-EOT
logName="projects/${var.project_id}/logs/slurmctld"
--Show similar entries
jsonPayload.message=~"update_node: node [^ =\t\n\r\f\"\(\)\[\]\|'] reason set to: GCP Error: OPERATION_CANCELED_BY_USER: Operation was canceled by user \."
--End of show similar entries
EOT
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
  description = "This metric keeps track of the number of times that a node fails to be provisioned due to a GCP error."
  project = var.project_id
}

resource "google_logging_metric" "resource-exhaustion-error" {
  name   = "compute-engine-api/resource-exhaustion-error"
  filter = <<-EOT
severity=ERROR
--Show similar entries
protoPayload.methodName="v1.compute.regionInstances.bulkInsert"
protoPayload.status.message="VM_MIN_COUNT_NOT_REACHED,ZONE_RESOURCE_POOL_EXHAUSTED"
--End of show similar entries
EOT
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
  description = "This metric keeps track of the number of times that a resource exhaustion error is encountered."
  project = var.project_id
}

resource "google_logging_metric" "resume-timeout" {
  name   = "slurm-gcp/resume-timeout"
  filter = <<-EOT
logName="projects/${var.project_id}/logs/slurmctld"
--Show similar entries
jsonPayload.message=~"node [^ =\t\n\r\f\"\(\)\[\]\|']+ not resumed by ResumeTimeout\(((?:\d[,.]?)*\d)\) - marking down and power_save"
--End of show similar entries
EOT
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
  description = "Counts the number of times a node is marked as down and power-saved due to a resume script timeout."
  project = var.project_id
}

resource "google_logging_metric" "slurmd-node-configuration-differs" {
  name   = "slurm-gcp/slurmd-node-configuration-differs"
  filter = <<-EOT
logName="projects/${var.project_id}/logs/slurmd"
--Show similar entries
jsonPayload.message=~"error: Node configuration differs from hardware: CPUs=((\d{2}):(\d{2})(?::(\d{2}(?:\.\d*)?))?(?:([+-](?:\d{2}):?(?:\d{2})?|Z)?))\(hw\) Boards=1:1\(hw\) SocketsPerBoard=1:2\(hw\) CoresPerSocket=((\d{2}):(\d{2})(?::(\d{2}(?:\.\d*)?))?(?:([+-](?:\d{2}):?(?:\d{2})?|Z)?))\(hw\) ThreadsPerCore=1:2\(hw"
--End of show similar entries
EOT
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
  description = "Counts the number of times slurmd on compute noes reports a node configuration differing from hardware."
  project = var.project_id
}

resource "google_logging_metric" "vm-min-count-not-reached" {
  name   = "slurm-gcp/vm-min-count-not-reached"
  filter = <<-EOT
logName="projects/${var.project_id}/logs/slurm_resume"
--Show similar entries
jsonPayload.message=~"bulkInsert operation errors: VM_MIN_COUNT_NOT_REACHED name=[^ =\t\n\r\f\"\(\)\[\]\|']+ operationGroupId=([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}) nodes=[^ =\t\n\r\f\"\(\)\[\]\|']+"
--End of show similar entries
EOT
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
  description = "This metric counts when node resume fails due to insufficient nodes being available."
  project = var.project_id
}

