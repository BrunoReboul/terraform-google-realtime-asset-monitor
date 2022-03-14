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
  service_name = "splitexport"
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_iam_member" "project_pubusb_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
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

resource "google_storage_bucket_iam_member" "exports_admin" {
  bucket = var.exports_bucket_name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_pubsub_topic_iam_member" "cai_feed_publisher" {
  project = var.project_id
  topic   = var.cai_feed_topic_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_pubsub_topic_iam_member" "cai_feed_viewer" {
  project = var.project_id
  topic   = var.cai_feed_topic_id
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_project_iam_member" "cloud_datastore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
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
          name  = "${upper(local.service_name)}_CAI_FEED_TOPIC_ID"
          value = var.cai_feed_topic_id
        }
        env {
          name  = "${upper(local.service_name)}_ENVIRONMENT"
          value = terraform.workspace
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

resource "google_service_account" "eva_trigger_sa" {
  project      = var.project_id
  account_id   = "${local.service_name}-trigger"
  display_name = "RAM ${local.service_name} trigger"
  description  = "Solution: Real-time Asset Monitor, microservice tigger: ${local.service_name}"
}
data "google_iam_policy" "binding" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:${google_service_account.eva_trigger_sa.email}",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "trigger_invoker" {
  location = google_cloud_run_service.crun_svc.location
  project  = google_cloud_run_service.crun_svc.project
  service  = google_cloud_run_service.crun_svc.name

  policy_data = data.google_iam_policy.binding.policy_data
}

resource "google_eventarc_trigger" "eva_trigger" {
  name            = local.service_name
  location        = google_cloud_run_service.crun_svc.location
  project         = google_cloud_run_service.crun_svc.project
  service_account = google_service_account.eva_trigger_sa.email
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = var.exports_bucket_name
  }
  destination {
    cloud_run_service {
      service = google_cloud_run_service.crun_svc.name
      region  = google_cloud_run_service.crun_svc.location
    }
  }
  depends_on = [google_project_iam_member.project_pubusb_publisher]
}
