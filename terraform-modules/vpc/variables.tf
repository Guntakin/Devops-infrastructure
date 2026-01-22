#------------------------------------------#
# AWS Region and AZ Values
#------------------------------------------#
variable "azs" {
  description = "List of availability zones, currently only 3 are used"
  default     = ["a", "b", "c"]
  type        = list(string)
}

variable "nat_per_az" {
  default     = true
  description = "When true, will configure a NAT gateway per AZ instead of per VPC"
}

#------------------------------------------#
# VPC Parameters
#------------------------------------------#
variable "environment-name" {
  description = "Display name for the VPC, without '-VPC'"
}

variable "vpc_display_name" {
  description = "Display name for the VPC, without '-VPC'"
  default     ="stage"
}

variable "cidr" {
  description = "CIDR for the VPC and subnet"
}

#------------------------------------------#
# VPN Connectivity
#------------------------------------------#
variable "aws_vpn_west_cidr" {
  description = "CIDR of OpenVPN source IPs in AWS us-west-2, used to allow traffic to all instances"
  default     = "10.1.32.193/32"
}

variable "aws_vpn_east_cidr" {
  description = "CIDR of OpenVPN source IPs in AWS us-east-1, used to allow traffic to all instances"
  default     = "10.4.32.122/32"
}
