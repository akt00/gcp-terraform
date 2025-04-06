provider "google" {
  project = var.project_id
  region = var.default_region
}

resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = var.vpc_name
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
  name          = "subnet-1"
  ip_cidr_range = "10.1.0.0/16"
  region        = var.default_region
  network       = google_compute_network.vpc_network.id
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
  depends_on = [ google_compute_network.vpc_network ]
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
  depends_on = [ module.instance_template ]
}