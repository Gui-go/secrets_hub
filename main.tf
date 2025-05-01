

locals {
  proj_name       = "secretshub"
  proj_id         = "secretshub1"
  location        = "us-central1"
  zone            = "us-central1-b"
  vpc_subnet_cidr = "10.8.0.0/28"
  release         = "1"
  tag_owner       = "guilhermeviegas"
}

provider "google" {
  project = local.proj_id
  region  = local.location
}

resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "storage.googleapis.com",
    "cloudfunctions.googleapis.com",
    "eventarc.googleapis.com",
    "cloudscheduler.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "eventarc.googleapis.com", # although not used, it is needed for google_cloudfunctions2_function
    "pubsub.googleapis.com"    # although not used, it is needed for google_cloudfunctions2_function
  ])
  project = local.proj_id
  service = each.key
}

resource "google_storage_bucket" "tf_vaultwarden_bucket" {
  project  = local.proj_id
  name     = "${local.proj_id}-vault-bucket"
  location = local.location
  versioning {
    enabled = true
  }
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "tf_backup_bucket" {
  project  = local.proj_id
  name     = "${local.proj_id}-backup-bucket"
  location = local.location
  versioning {
    enabled = true
  }
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "tf_func_src" {
  name = "func"
  bucket = google_storage_bucket.tf_backup_bucket.name
  source = "index.zip"
}



# resource "google_secret_manager_secret" "vaultwarden_admin_token" {
#   project   = local.proj_id
#   secret_id = "vaultwarden-admin-token"
#   replication {
#     auto {}
#   }
# }

resource "google_cloud_run_v2_service" "tf_run_vaultwarden" {
  project  = local.proj_id
  name     = "${local.proj_name}-run-vaultwarden"
  location = local.location
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
  project  = local.proj_id
  service  = google_cloud_run_v2_service.tf_run_vaultwarden.name
  location = google_cloud_run_v2_service.tf_run_vaultwarden.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_storage_bucket_iam_member" "eventarc_access" {
  bucket = google_storage_bucket.tf_vaultwarden_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-eventarc.iam.gserviceaccount.com"
}

data "google_project" "project" {
  project_id = local.proj_id
}




resource "google_service_account" "backup_sa" {
  project      = local.proj_id
  account_id   = "vaultwarden-backup-sa"
  display_name = "Vaultwarden Backup Cloud Function SA"
}

resource "google_storage_bucket_iam_member" "source_access" {
  bucket = google_storage_bucket.tf_vaultwarden_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.backup_sa.email}"
}

resource "google_storage_bucket_iam_member" "backup_access" {
  bucket = google_storage_bucket.tf_backup_bucket.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.backup_sa.email}"
}

resource "google_project_iam_member" "gcs_pubsub_publisher" {
  project = data.google_project.project.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_cloudfunctions2_function" "tf_functions_backup" {
  name     = "${local.proj_name}-func-backup"
  project  = local.proj_id
  location = local.location
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
    trigger_region = local.location
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.tf_vaultwarden_bucket.name
    }
  }
  depends_on = [google_storage_bucket_object.tf_func_src]
}









# resource "google_cloudfunctions_function" "tf_functions_backup" {
#   project               = local.proj_id
#   name                  = "vaultwarden-backup"
#   region                = local.location
#   runtime               = "python39"
#   description           = "Backup Vaultwarden files on bucket update"
#   available_memory_mb   = 128
#   source_archive_bucket = google_storage_bucket.tf_vaultwarden_bucket.name
#   source_archive_object = google_storage_bucket_object.func_src.name
#   entry_point           = "backup_vaultwarden"
#   service_account_email = google_service_account.backup_sa.email
#   event_trigger {
#     event_type = "google.storage.object.finalize"
#     resource   = google_storage_bucket.tf_vaultwarden_bucket.name
#   }
#   environment_variables = {
#     BACKUP_BUCKET = google_storage_bucket.tf_backup_bucket.name
#   }
#   depends_on = [google_storage_bucket_object.func_src]
# }























# resource "google_eventarc_trigger" "vaultwarden_bucket_trigger" {
#   project  = local.proj_id
#   name     = "vaultwarden-bucket-trigger"
#   location = local.location
#   matching_criteria {
#     attribute = "type"
#     value     = "google.cloud.storage.object.v1.finalized"
#   }
#   matching_criteria {
#     attribute = "bucket"
#     value     = google_storage_bucket.tf_vaultwarden_bucket.name
#   }
#   destination {
#     cloud_function = google_cloudfunctions_function.tf_functions_backup.name
#   }
#   service_account = google_service_account.backup_sa.email
# }

























# resource "google_cloud_scheduler_job" "tf_scheduler_backup" {
#   name        = "${local.proj_name}-scheduler-backup"
#   schedule    = "0 0 * * *"  # Daily at midnight
#   description = "Backup Vaultwarden data"
#   http_target {
#     uri         = google_cloudfunctions_function.backup_function.http_trigger_url
#     http_method = "POST"
#   }
# }

# resource "google_service_account" "tf_sa_backup" {
#   account_id   = "sa-${local.proj_name}-backup"
#   display_name = "sa-${local.proj_name}-backup"
# }

# resource "google_storage_bucket_iam_member" "backup_sa_source" {
#   bucket = google_storage_bucket.tf_vaultwarden_bucket.name
#   role   = "roles/storage.admin"
#   member = "serviceAccount:${google_service_account.tf_sa_backup.email}"
# }

# resource "google_cloudfunctions_function" "backup_function" {
#   name        = "vaultwarden-backup-function"
#   description = "Backs up Vaultwarden data from source to backup bucket"
#   runtime     = "python39"
#   region      = local.location
#   available_memory_mb   = 256
#   source_archive_bucket = google_storage_bucket.function_code.name
#   source_archive_object = google_storage_bucket_object.backup_function_code.name
#   trigger_http          = true
#   entry_point           = "backup_handler"
#   service_account_email = google_service_account.backup_sa.email
# }

# # IAM for Cloud Function to allow invocation
# resource "google_cloudfunctions_function_iam_member" "invoker" {
#   project        = google_cloudfunctions_function.backup_function.project
#   region         = google_cloudfunctions_function.backup_function.region
#   cloud_function = google_cloudfunctions_function.backup_function.name
#   role           = "roles/cloudfunctions.invoker"
#   member         = "serviceAccount:${google_service_account.backup_sa.email}"
# }


















