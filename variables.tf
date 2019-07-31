
variable "server_name" {
  default = "web-server"
}

variable "locations" {
  type    = "map"
  default = {
    location1 = "eastus"
    location2 = "eastus2"
  }
}

variable "subnets" {
  type    = "list"
  default = ["10.0.1.10","10.0.1.11"]
}

variable "live" {
  type    = "string"
  default = false
}

