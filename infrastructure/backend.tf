terraform {
  backend "gcs" {
    bucket = "image-gallery-project-456914-state"
    prefix = "terraform/state"
  }
}
