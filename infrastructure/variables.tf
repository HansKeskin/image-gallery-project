variable "project_id" {
  description = "GCP Proje ID"
  type        = string
}

variable "region" {
  description = "GCP Bölgesi"
  type        = string
  default     = "us-central1"
}

variable "state_bucket" {
  description = "Terraform state bucket adı"
  type        = string
}
