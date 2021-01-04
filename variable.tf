variable "resource_group_name" {
    default = "rg-rancher2"
}
variable "location" {
    default = "southeastasia"
  
}
variable "admin_username" {
    default = "tsunomur"
}
variable "admin_password" {
    default = "Password1!"
}
variable "ssh_public_key_path" {
    default = "~/.ssh/id_rsa.pub"
}
variable "linux-controlplane-count" {
    default = 3
}
variable "linux-worker-count" {
    default = 3
}
variable "windows-worker-count" {
    default = 3
}
variable "permit-access-source-ip" {
    default = ["103.2.248.102", "52.230.98.244"]
}