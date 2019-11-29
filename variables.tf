variable "server_name" {
  default = "web-server"
}

variable "locations" {
  type = map(string)
  default = {
    location1 = "eastus"
    location2 = "eastus2"
  }
}

variable "subnets" {
  type    = list(string)
  default = ["10.0.1.10", "10.0.1.11"]
}

variable "live" {
  type    = string
  default = false
}

