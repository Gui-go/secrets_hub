variable "proj_name" {
  description = "Project name"
  type        = string
}

variable "proj_id" {
  description = "Project ID identifier"
  type        = string
}

variable "location" {
  description = "Location of the resources"
  type        = string
}

# variable "zone" {
#   description = "Zone of the resources"
#   type        = string
# }

variable "tag_owner" {
  description = "Tag to describe the owner of the resources"
  type        = string
}

variable "vpc_subnet_cidr" {
  description = "CIDE subnetwork for the VPC"
  type        = string
}