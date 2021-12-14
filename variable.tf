#these are the variables which are used in main.tf
#path where the credentials had stored 
variable "path" {
    default="C:/Users/THLOHITH/Desktop/terraformdemo/demo1/analysis"
}
variable "vpc_network" {
    default = "vpc-net"
}
variable "vpc_subnetwork" {
    default = "vpc-subnet"
}
variable "project" {
    default = "fluted-anthem-331611"
}

