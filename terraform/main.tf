
locals {
  proj_name       = "secretshub"
  proj_id         = "secretshub1"
  proj_number     = "895441105404"
  location        = "us-central1"
#   zone            = "us-central1-b"
#   vpc_subnet_cidr = "10.8.0.0/28"
#   release         = "1"
#   tag_owner       = "guilhermeviegas"
}

provider "google" {
  project = local.proj_id
  region  = local.location
}

resource "google_project_service" "tf_enable_apis" {
  for_each = toset([
    "run.googleapis.com",
    "storage.googleapis.com",
    "cloudfunctions.googleapis.com",
    "eventarc.googleapis.com",
    "cloudscheduler.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "eventarc.googleapis.com", # although not directly used, it is needed for google_cloudfunctions2_function
    "pubsub.googleapis.com"    # although not directly used, it is needed for google_cloudfunctions2_function
  ])
  project = local.proj_id
  service = each.key
}

module "network" {
  source          = "./modules/network"
  proj_id         = local.proj_id
}

module "storage" {
  source      = "./modules/storage"
  proj_id     = local.proj_id
  proj_number = local.proj_number
  location    = local.location
}

module "compute" {
  source    = "./modules/compute"
  proj_name = local.proj_name
  proj_id   = local.proj_id
  location  = local.location
}






















