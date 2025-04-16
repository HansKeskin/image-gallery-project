locals {
  apis = [
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "storage.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudfunctions.googleapis.com",
    "iam.googleapis.com"
  ]
}

# 1) Gerekli API'leri etkinleştir
resource "google_project_service" "enable_apis" {
  for_each = toset(local.apis)
  service  = each.value
}

# 2) Cloud Build'in deploy işlemi yapacağı Service Account
resource "google_service_account" "cloudbuild" {
  account_id   = "cloudbuild-deployer"
  display_name = "Cloud Build Deployer"
}

# 3) Bu SA'ya ihtiyaç duyduğu rolleri ver
resource "google_project_iam_member" "cloudbuild_roles" {
  for_each = toset([
    "roles/cloudbuild.builds.editor",
    "roles/iam.serviceAccountUser",
    "roles/run.admin",
    "roles/storage.admin",
    "roles/artifactregistry.admin",
    "roles/cloudfunctions.developer"
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}
# 4) Artifact Registry (Docker imajlarımızı saklayacağımız repo)
resource "google_artifact_registry_repository" "api_repo" {
  provider      = google
  location      = var.region
  repository_id = "image-gallery-api"
  format        = "DOCKER"
}

# 5) Resimlerin saklanacağı Storage Bucket
resource "google_storage_bucket" "images" {
  name          = "${var.project_id}-images"
  location      = var.region
  force_destroy = true   # silme sırasında içindeki objeleri de temizler
}

# 6) Output’lar (opsiyonel, sonradan kolay erişim için)
output "artifact_registry_repo" {
  value = google_artifact_registry_repository.api_repo.id
}

output "images_bucket_name" {
  value = google_storage_bucket.images.name
}

# ----------------------------
# 7) Cloud Run Service (Image API)
# ----------------------------
resource "google_cloud_run_service" "api" {
  name     = "image-gallery-api"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/image-gallery-api/image-gallery-api:latest"
        ports {
          container_port = 8080
        }
        env {
          name  = "IMAGE_BUCKET"
          value = google_storage_bucket.images.name
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}

# ----------------------------
# 8) Herkese Açık Erişim (Test İçin)
# ----------------------------
resource "google_cloud_run_service_iam_member" "api_invoker" {
  service  = google_cloud_run_service.api.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ----------------------------
# 9) Cloud Function: Thumbnail Generator
# ----------------------------

# 9.1) Zip dosyasını bucket'a yükle
resource "google_storage_bucket_object" "fn_zip" {
  name   = "generate-thumbnail.zip"
  bucket = google_storage_bucket.images.name
  source = "${path.module}/../functions/generate-thumbnail.zip"
}

# 9.2) Fonksiyonu deploy et
resource "google_cloudfunctions_function" "thumb" {
  name        = "generate-thumbnail"
  runtime     = "nodejs18"
  entry_point = "generateThumbnail"
  region      = var.region

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.images.name
  }

  source_archive_bucket = google_storage_bucket.images.name
  source_archive_object = google_storage_bucket_object.fn_zip.name

  environment_variables = {
    IMAGE_BUCKET = google_storage_bucket.images.name
  }
}

# ----------------------------
# 10) CI/CD Trigger (Cloud Build)
# ----------------------------
resource "google_cloudbuild_trigger" "ci_cd" {
  project = var.project_id
  name    = "image-gallery-ci-cd"

  github {
    owner = "hanskeskin3820"
    name  = "image-gallery-project"
    push {
      branch = "master"
    }
  }

  # Build config dosyamız
  filename = "cloudbuild.yaml"

  # Cloudbuild.yaml içindeki substitüsyonlar için
  substitutions = {
    _REGION     = var.region
    _PROJECT_ID = var.project_id
  }
}

