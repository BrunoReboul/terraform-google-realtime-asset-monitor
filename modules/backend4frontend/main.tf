/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  service_name = "backend4frontend"
}

resource "google_service_account" "microservice_sa" {
  project      = var.project_id
  account_id   = local.service_name
  display_name = "RAM ${local.service_name}"
  description  = "Solution: Real-time Asset Monitor, microservice: ${local.service_name}"
}

resource "google_project_iam_member" "project_profiler_agent" {
  project = var.project_id
  role    = "roles/cloudprofiler.agent"
  member  = "serviceAccount:${google_service_account.microservice_sa.email}"
}
resource "google_cloud_run_service" "crun_svc" {
  project  = var.project_id
  name     = local.service_name
  location = var.crun_region

  template {
    spec {
      containers {
        image = "${var.ram_container_images_registry}/${local.service_name}:${var.ram_microservice_image_tag}"
        resources {
          limits = {
            cpu    = "${var.crun_cpu}"
            memory = "${var.crun_memory}"
          }
        }
        env {
          name  = "${upper(local.service_name)}_ENVIRONMENT"
          value = var.environment
        }
        env {
          name  = "${upper(local.service_name)}_LOG_ONLY_SEVERITY_LEVELS"
          value = var.log_only_severity_levels
        }
        env {
          name  = "${upper(local.service_name)}_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "${upper(local.service_name)}_START_PROFILER"
          value = var.start_profiler
        }
      }
      container_concurrency = var.crun_concurrency
      timeout_seconds       = var.crun_timeout_seconds
      service_account_name  = google_service_account.microservice_sa.email
    }
    metadata {
      annotations = {
        "run.googleapis.com/client-name"   = "terraform"
        "autoscaling.knative.dev/maxScale" = "${var.crun_max_instances}"
      }
    }
  }
  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "internal"
    }
  }
  autogenerate_revision_name = true
  traffic {
    percent         = 100
    latest_revision = true
  }
  lifecycle {
    ignore_changes = all
  }
}
