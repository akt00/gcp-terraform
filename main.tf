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

resource "google_compute_subnetwork" "subnetwork-1" {
  name          = "subnet-1"
  ip_cidr_range = "10.1.0.0/16"
  region        = var.default_region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "allow-health-check-v4" {
  name    = "allow-health-check"
  network = google_compute_network.vpc_network.name
  priority = 1000
  target_tags = ["lb-health-check"]
  allow {
    protocol = "tcp"
  }
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
}

resource "google_compute_firewall" "allow-health-check-v6" {
  name  = "allow-health-check-ipv6"
  network = google_compute_network.vpc_network.name
  priority = 1000
  target_tags = ["lb-health-check"]
  allow {
    protocol = "tcp"
  }
  source_ranges = ["2600:1901:8001::/48", "2600:2d00:1:b029::/64"]
}

resource "google_compute_firewall" "allow-internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc_network.name
  priority = 65534
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports = ["0-65535"]
  }
  source_ranges = ["10.1.0.0/16"]
}

resource "google_compute_firewall" "allow-ssh" {
  name = "allow-ssh"
  network = google_compute_network.vpc_network.name
  priority = 65534
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
}

module "instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  automatic_restart = true
  machine_type = "e2-small"
  description = "mlflow server instance template"
  name_prefix = "mlflow-instance-template"
  network = google_compute_network.vpc_network.name
  project_id = var.project_id
  region = var.default_region
  source_image = "mlflow-image-2"
  source_image_family = "mlflow"
  source_image_project = var.project_id
  subnetwork = google_compute_subnetwork.subnetwork-1.self_link
  depends_on = [ google_compute_network.vpc_network ]
}

module "compute_instance" {
  source  = "terraform-google-modules/vm/google//modules/compute_instance"
  hostname = "mlflow"
  instance_template = module.instance_template.self_link_unique
  region = var.default_region
  network = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.subnetwork-1.self_link
  subnetwork_project = var.project_id
  zone = "us-central1-c"
  depends_on = [ module.instance_template ]
}