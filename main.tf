provider "google" {
  project = var.project_id
  region = var.default_region
}

module "vpc" {
    source = "terraform-google-modules/network/google"
    version = "~> 10.0"

    project_id = var.project_id
    auto_create_subnetworks = false
    network_name = var.vpc_name
    routing_mode = var.vpc_routing
    subnets = [
        {
            subnet_name = "subnet-1"
            subnet_ip = "10.1.0.0/20"
            subnet_region = "us-central1"
        }
    ]
}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = module.vpc.network_name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000"]
  }

  source_tags = ["dev"]
}
