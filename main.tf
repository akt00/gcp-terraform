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
    {
      name          = "default-allow-internal" # The name of the rule
      description   = "Allow internal traffic on the default network" # Provided description
      direction     = "INGRESS"     # Provided direction
      priority      = 65534         # Provided priority

      # --- IMPORTANT NOTE ON SOURCE RANGES ---
      # The range "10.128.0.0/9" is the typical default for Google's *actual* 'default' network.
      # If your VPC module creates a network with a *different* name (e.g., "my-vpc-network"),
      # this rule should likely use the IP ranges of the subnets *within that specific VPC*.
      # For your example subnet "10.1.0.0/20", you might want:
      # source_ranges = ["10.1.0.0/20"] 
      # Or if you have multiple internal subnets, list them all:
      # source_ranges = ["10.1.0.0/20", "10.2.0.0/20"] 
      # Using "10.128.0.0/9" here assumes your var.vpc_name is actually "default" or 
      # you specifically want that wide range for some reason. Please VERIFY this range
      # is appropriate for the network named module.vpc.network_name.
      source_ranges = ["10.1.0.0/20"] # Provided source IP range - VERIFY IF CORRECT FOR YOUR NETWORK

      # Target tags are not specified in the policy, so we omit target_tags

      # Specify allowed protocols and ports
      allow = [
        {
          protocol = "tcp"
          ports    = ["0-65535"] # All TCP ports
        },
        {
          protocol = "udp"
          ports    = ["0-65535"] # All UDP ports
        },
        {
          protocol = "icmp" # ICMP protocol (no ports needed)
        }
      ]

      # Logs are Off, so we omit the log_config block
      # disabled = false # Rule is enabled by default, omit 'disabled' or set to false
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