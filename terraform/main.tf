
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

module "network" {
  source          = "./modules/network"
  proj_name       = local.proj_name
  proj_id         = local.proj_id
  location        = local.location
  tag_owner       = local.tag_owner
#   vpc_subnet_cidr = local.vpc_subnet_cidr
}

module "datalake" {
  source    = "./modules/datalake"
  proj_name = local.proj_name
  proj_id   = local.proj_id
  location  = "US" # NOT local.location
  tag_owner = local.tag_owner
  tag_env   = local.tag_env
}

