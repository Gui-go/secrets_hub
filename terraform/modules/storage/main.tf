
# Backup Bucket ------------------------------------------------
resource "google_storage_bucket" "tf_backup_bucket" {
  project  = var.proj_id
  name     = "${var.proj_id}-backup-bucket"
  location = var.location
  versioning { enabled = true }
  uniform_bucket_level_access = true
}

resource "google_service_account" "tf_backup_sa" {
  project      = var.proj_id
  account_id   = "${var.proj_id}-backup-sa"
  display_name = "Vaultwarden Backup Cloud Function SA"
}

resource "google_storage_bucket_iam_member" "tf_backup_access" {
  bucket = google_storage_bucket.tf_backup_bucket.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.tf_backup_sa.email}"
}

resource "google_storage_bucket_object" "tf_func_src" {
  name = "func"
  bucket = google_storage_bucket.tf_backup_bucket.name
  source = "index.zip"
}


# VaultWarden Bucket ------------------------------------------
resource "google_storage_bucket" "tf_vaultwarden_bucket" {
  project  = var.proj_id
  name     = "${var.proj_id}-vault-bucket"
  location = var.location
  versioning { enabled = true }
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "eventarc_access" {
  bucket = google_storage_bucket.tf_vaultwarden_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:service-${var.proj_number}@gcp-sa-eventarc.iam.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "tf_source_access" {
  bucket = google_storage_bucket.tf_vaultwarden_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.tf_backup_sa.email}"
}


