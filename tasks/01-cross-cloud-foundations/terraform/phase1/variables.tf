# Reusable values referenced throughout the Terraform files below.
# Changing a default here changes it everywhere it's used.

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "azure_location" {
  type    = string
  default = "uksouth"
}

# The AWS "building's" private address range
variable "aws_vpc_cidr" {
  type    = string
  default = "10.100.0.0/16"
}

# The Azure "building's" private address range — deliberately non-overlapping
# with the AWS range above, since overlapping ranges can't be connected by VPN
variable "azure_vnet_cidr" {
  type    = string
  default = "10.200.0.0/16"
}

variable "project_tag" {
  type    = string
  default = "multicloud-portfolio"
}
