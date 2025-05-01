
# VaultWarden Run -------------------------------------------------------------
resource "google_cloud_run_v2_service" "tf_run_vaultwarden" {
  project  = var.proj_id
  name     = "${var.proj_name}-run-vaultwarden"
  location = var.location
  ingress  = "INGRESS_TRAFFIC_ALL"
  template {
    containers {
      image = "vaultwarden/server:latest"
      env {
        name  = "WEBSOCKET_ENABLED"
        value = "true"
      }
      env {
        name  = "SIGNUPS_ALLOWED"
        value = "false" # Disable if signup is needed          
      }
      ports {container_port = 80}
      resources {
        limits = {
          cpu    = "1"
          memory = "2Gi"
        }
      }
      volume_mounts {
        name       = "vaultwarden-data"
        mount_path = "/data"
      }
    }
    volumes {
      name = "vaultwarden-data"
      gcs {
        bucket    = google_storage_bucket.tf_vaultwarden_bucket.name
        read_only = false
      }
    }
    scaling {
      max_instance_count = 1
      min_instance_count = 0
    }
    timeout = "120s"
  }
  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

resource "google_cloud_run_service_iam_member" "tf_vaultwarden_public_access" {
  project  = var.proj_id
  service  = google_cloud_run_v2_service.tf_run_vaultwarden.name
  location = var.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}



# BackUp Function -----------------------------------------------------------------------
resource "google_cloudfunctions2_function" "tf_functions_backup" {
  name     = "${var.proj_name}-func-backup"
  project  = var.proj_id
  location = var.location
  build_config {
    runtime     = "python310"
    entry_point = "fct_backup_vaultwarden"
    source {
      storage_source {
        bucket = google_storage_bucket.tf_backup_bucket.name
        object = google_storage_bucket_object.tf_func_src.name
      }
    }
  }
  service_config {
    available_memory = "256M"
    timeout_seconds  = 60
    service_account_email = google_service_account.backup_sa.email
    environment_variables = {
      BACKUP_BUCKET = google_storage_bucket.tf_backup_bucket.name
    }
  }
  event_trigger {
    event_type = "google.cloud.storage.object.v1.finalized"
    trigger_region = var.location
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.tf_vaultwarden_bucket.name
    }
  }
  depends_on = [google_storage_bucket_object.tf_func_src]
}


resource "google_project_iam_member" "gcs_pubsub_publisher" {
  project = data.google_project.project.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
}
