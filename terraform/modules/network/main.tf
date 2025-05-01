resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnet" {
  name            = var.vpc_subnetwork_name
  ip_cidr_range   = var.vpc_subnetwork_cidr
  network         = google_compute_network.vpc_network.id
  region          = var.region
  private_ip_google_access = true
}
