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
  service_name = "fetchexports"
}
resource "google_service_account" "microservice_sa" {
  project      = var.project_id
  account_id   = local.service_name
  display_name = "RAM fetchrule"
  description  = "Solution: Real-time Asset Monitor, microservice: fetchexports"
}

resource "google_project_iam_member" "project_profiler_agent" {
  project = var.project_id
  role    = "roles/cloudprofiler.agent"
  member  = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_organization_iam_member" "org_cloudasset_owner" {
  count  = length(var.export_org_ids)
  org_id = var.export_org_ids[count.index]
  role   = "roles/cloudasset.owner"
  member = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_folder_iam_member" "folder_cloudasset_owner" {
  count  = length(var.export_folder_ids)
  folder = "folders/${var.export_folder_ids[count.index]}"
  role   = "roles/cloudasset.owner"
  member = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_storage_bucket" "exports" {
  project                     = var.project_id
  name                        = "${var.project_id}-exports"
  location                    = var.gcs_location
  force_destroy               = true
  uniform_bucket_level_access = true
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_pubsub_topic" "export_trigger" {
  project = var.project_id
  name    = var.trigger_export_topic_name
  message_storage_policy {
    allowed_persistence_regions = var.pubsub_allowed_regions
  }
}

resource "google_cloud_scheduler_job" "job" {
  for_each = {
    for name, s in var.schedulers : name => s
    if s.environment == terraform.workspace
  }
  project     = var.project_id
  name        = each.value.name
  description = "Real-time Asset Monitor ${each.value.name}"
  schedule    = each.value.schedule
  region      = var.scheduler_region

  pubsub_target {
    topic_name = google_pubsub_topic.export_trigger.id
    data       = base64encode(each.value.name)
  }
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
          name  = "FETCHEXPORTS_ENVIRONMENT"
          value = terraform.workspace
        }
        env {
          name  = "FETCHEXPORTS_LOG_ONLY_SEVERITY_LEVELS"
          value = var.log_only_severity_levels
        }
        env {
          name  = "FETCHEXPORTS_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "FETCHEXPORTS_START_PROFILER"
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
  display_name = "RAM fetchexports trigger"
  description  = "Solution: Real-time Asset Monitor, microservice tigger: fetchexports"
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
  transport {
    pubsub {
      topic = google_pubsub_topic.export_trigger.id
    }
  }
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  destination {
    cloud_run_service {
      service = google_cloud_run_service.crun_svc.name
      region  = google_cloud_run_service.crun_svc.location
    }
  }
}

