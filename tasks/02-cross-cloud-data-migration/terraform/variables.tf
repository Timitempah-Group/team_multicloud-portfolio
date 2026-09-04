variable "my_ip" {
  description = "Local public IP in CIDR form, for temporary seeding access to both databases"
  type        = string
  default     = "92.207.10.233/32"
}
