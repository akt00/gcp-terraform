variable "project_id" {
  description = "project name"
  type = string
  default = "ml-dev-1"
}

variable "default_region" {
  description = "defualt region"
  type = string
  default = "us-central1"
}

variable "vpc_name" {
  description = "vpc name"
  type = string
  default = "cis-vpc-1"
}

variable "vpc_routing" {
  description = "routing mode"
  type = string
  default = "GLOBAL"
}