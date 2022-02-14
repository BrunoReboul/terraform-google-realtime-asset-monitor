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
  service_name = "execute"
  action_kind  = "caiexport"
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_service_account" "microservice_sa" {
  project      = var.project_id
  account_id   = "${local.service_name}${local.action_kind}"
  display_name = "RAM ${local.service_name} ${local.action_kind}"
  description  = "Solution: Real-time Asset Monitor, microservice: ${local.service_name} ${local.action_kind}"
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

resource "google_storage_bucket_iam_member" "exports_admin" {
  bucket = google_storage_bucket.exports.name
  role   = "roles/storage.admin"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudasset.iam.gserviceaccount.com"
}

resource "google_cloud_run_service" "crun_svc" {
  project  = var.project_id
  name     = "${local.service_name}${local.action_kind}"
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
        env {
          name  = "${upper(local.service_name)}_ACTION_KIND"
          value = local.action_kind
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

resource "google_service_account" "subscription_sa" {
  project      = var.project_id
  account_id   = "${local.service_name}-${local.action_kind}-sub"
  display_name = "RAM execute ${local.action_kind} trigger"
  description  = "Solution: Real-time Asset Monitor, microservice tigger: ${local.service_name}, action: ${local.action_kind}"
}
data "google_iam_policy" "binding" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:${google_service_account.subscription_sa.email}",
    ]
  }
}
resource "google_cloud_run_service_iam_policy" "trigger_invoker" {
  location = google_cloud_run_service.crun_svc.location
  project  = google_cloud_run_service.crun_svc.project
  service  = google_cloud_run_service.crun_svc.name

  policy_data = data.google_iam_policy.binding.policy_data
}

resource "google_pubsub_subscription" "subcription" {
  project              = var.project_id
  name                 = "${local.service_name}-${local.action_kind}"
  topic                = var.triggering_topic_id
  ack_deadline_seconds = var.sub_ack_deadline_seconds
  push_config {
    oidc_token {
      service_account_email = google_service_account.subscription_sa.email
    }
    #Updated endpoint to deal with WARNING in logs: failed to extract Pub/Sub topic name from the URL request path: "/", configure your subscription's push endpoint to use the following path pattern: 'projects/PROJECT_NAME/topics/TOPIC_NAME
    push_endpoint = "${google_cloud_run_service.crun_svc.status[0].url}/${var.triggering_topic_id} "
  }
  expiration_policy {
    ttl = ""
  }
  filter                     = "attributes.ce-type = \"com.gitlab.realtime-asset-monitor.${local.action_kind}\""
  message_retention_duration = var.sub_message_retention_duration
  retry_policy {
    minimum_backoff = var.sub_minimum_backoff
  }
}
