
variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}

variable "min_node_count" {
  description = "The minimum number of nodes in the default node pool."
  type        = number
}

variable "max_node_count" {
  description = "The maximum number of nodes in the default node pool."
  type        = number
}

variable "vm_size" {
  description = "The azure vm size."
  type        = string
}

variable "vm_disk_size" {
  description = "The disk size of the azure vm. Make sure the vm_size supports the disk size."
  type        = string
}
