provider "google" {
  project = var.project_id
  region = var.default_region
}

module "vpc" {
    source = "terraform-google-modules/network/google"
    version = "~> 10.0"

    project_id = var.project_id
    network_name = var.vpc_name

    auto_create_subnetworks = false
    routing_mode = var.vpc_routing

    subnets = [
        {
            subnet_name = "subnet-1"
            subnet_ip = "10.1.0.0/20"
            subnet_region = "us-central1"
        }
    ]
}

module "firewall_rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  project_id   = var.project_id
  network_name = module.vpc.network_name

  rules = [{
    name                    = "allow-ssh-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    destination_ranges      = ["10.0.0.0/8"]
    source_ranges           = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["22"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  },
  {
    name                    = "allow-8080-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    destination_ranges      = ["10.0.0.0/8"]
    source_ranges           = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["8080"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  },
  ]
}

module "instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  automatic_restart = true
  description = "mlflow server instance template"
  network = module.vpc.network_name
  project_id = var.project_id
  region = var.default_region
  source_image = "mlflow-image-1"
  source_image_family = ""
  subnetwork = "subnet-1"
}