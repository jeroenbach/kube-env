
variable "snapshot_id" {
  description = "If provided we restore a snapshot as the disk, otherwise we create an empty disk."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "The resource group name to restore the snapshot to"
  type        = string
}

variable "location" {
  description = "The location to restore the snapshot to"
  type        = string
}

variable "pv_name" {
  description = "The name of the persistent volume"
  type        = string
}

variable "pvc_name" {
  description = "The name of the persistent volume claim"
  type        = string
}

variable "pvc_namespace" {
  description = "The namespace of the persistent volume claim"
  type        = string
}

variable "disk_size_gb" {
  description = "The size of the persistent volume"
  type        = number
}
