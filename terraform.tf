terraform {
  required_providers {
    google = {
        source = "hashicorp/google"
        version = ">=6.14.0"
    }
  }

  backend "gcs" {
    bucket = "cis-dev-terraform"
  }
  
  required_version = ">=1.1.0"
}