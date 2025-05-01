resource "google_compute_network" "tf_vpc_net" {
  project                 = var.proj_id
  name                    = "${var.proj_id}-net"
  auto_create_subnetworks = false
}
