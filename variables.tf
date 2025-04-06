variable "project_id" {
  type = string
  default = "ml-dev-1"
}

variable "default_region" {
  type = string
  default = "us-central1"
}

variable "vpc_name" {
  type = string
  default = "cis-vpc-1"
}

variable "vpc_routing" {
  description = "routing mode: [GLOBAL | REGIONAL]"
  type = string
  default = "GLOBAL"
}