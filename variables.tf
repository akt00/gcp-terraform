variable "project_id" {
  description = "project name"
  type = string
  default = "ml-dev-1"
}

variable "vpc_name" {
  description = "vpc name"
  type = string
  default = "cid-tf-test"
}

variable "vpc_routing" {
  description = "routing mode"
  type = string
  default = "GLOBAL"
}