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

  rules = [
    {
      name                    = "allow-ssh-ingress"
      direction               = "INGRESS"
      source_ranges           = ["0.0.0.0/0"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name                    = "allow-8080-ingress"
      direction               = "INGRESS"
      source_ranges           = ["0.0.0.0/0"]
      allow = [{
        protocol = "tcp"
        ports    = ["8080"]
      }]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
  ]
  depends_on = [ module.vpc ]
}

module "instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  automatic_restart = true
  machine_type = "e2-small"
  description = "mlflow server instance template"
  name_prefix = "mlflow-instance-template"
  network = module.vpc.network_name
  project_id = var.project_id
  region = var.default_region
  source_image = "mlflow-image-2"
  source_image_family = "mlflow"
  source_image_project = var.project_id
  subnetwork = module.vpc.subnets["us-central1/subnet-1"].self_link
  depends_on = [ module.vpc ]
}

module "compute_instance" {
  source  = "terraform-google-modules/vm/google//modules/compute_instance"
  hostname = "mlflow"
  instance_template = module.instance_template.self_link_unique
  region = var.default_region
  network = module.vpc.network_name
  subnetwork = module.vpc.subnets["us-central1/subnet-1"].self_link
  subnetwork_project = var.project_id
  zone = "us-central1-c"
  depends_on = [ module.vpc, module.instance_template ]
}