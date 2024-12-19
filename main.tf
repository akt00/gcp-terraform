provider "google" {
  project = var.project_id
  region = "us-central1"
  zone = "us-central1-a"
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
            subnet_name = "tf-test"
            subnet_ip = "10.1.0.0/20"
            subnet_region = "us-central1"
        }
    ]
}