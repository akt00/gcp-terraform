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
    ingress_rules = [
        {
            name    = "allow-ssh"
            source_ranges = ["0.0.0.0/0"]  // Allow SSH from anywhere (restrict this!)
            allowed = [
                {
                    protocol = "tcp"
                    ports    = ["22"]
                }
            ]
            target_tags = ["ssh-allowed"] // Optional: Apply to instances with this tag
        },
    ]
}