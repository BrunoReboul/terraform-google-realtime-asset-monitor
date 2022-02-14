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
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_service_account" "microservice_sa" {
  project      = var.project_id
  account_id   = local.service_name
  display_name = "RAM execute"
  description  = "Solution: Real-time Asset Monitor, microservice: execute"
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
          name  = "EXECUTE_ENVIRONMENT"
          value = terraform.workspace
        }
        env {
          name  = "EXECUTE_LOG_ONLY_SEVERITY_LEVELS"
          value = var.log_only_severity_levels
        }
        env {
          name  = "EXECUTE_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "EXECUTE_START_PROFILER"
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

resource "google_service_account" "execute_caiexport_sub_sa" {
  project      = var.project_id
  account_id   = "${local.service_name}-caiexport-sub"
  display_name = "RAM execute caiexport trigger"
  description  = "Solution: Real-time Asset Monitor, microservice tigger: execute, action: caiexport"
}
resource "google_service_account" "execute_gcilistgroups_sub_sa" {
  project      = var.project_id
  account_id   = "${local.service_name}-gcilistgroups-sub"
  display_name = "RAM execute caiexport trigger"
  description  = "Solution: Real-time Asset Monitor, microservice tigger: execute, action: caiexport"
}
data "google_iam_policy" "binding" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:${google_service_account.execute_caiexport_sub_sa.email}",
      "serviceAccount:${google_service_account.execute_gcilistgroups_sub_sa.email}",
    ]
  }
}
resource "google_cloud_run_service_iam_policy" "trigger_invoker" {
  location = google_cloud_run_service.crun_svc.location
  project  = google_cloud_run_service.crun_svc.project
  service  = google_cloud_run_service.crun_svc.name

  policy_data = data.google_iam_policy.binding.policy_data
}

resource "google_pubsub_subscription" "execute_caiexport_sub" {
  project              = var.project_id
  name                 = "${local.service_name}-caiexport"
  topic                = var.triggering_topic_id
  ack_deadline_seconds = 10
  push_config {
    oidc_token {
      service_account_email = google_service_account.execute_caiexport_sub_sa.email
    }
    push_endpoint = google_cloud_run_service.crun_svc.status[0].url
  }
  # no expiration policy means never expires
  filter                     = "attributes.ce-type = \"com.gitlab.realtime-asset-monitor.caiexport\""
  message_retention_duration = "86400s"
  retry_policy {
    # https://cloud.google.com/asset-inventory/docs/quota
    # 2022-02-11 ExportAsset quota is 60 per MINUTE -> do not retry in less than a minute
    minimum_backoff = "65s"
  }
}
resource "google_pubsub_subscription" "execute_gcilistgroups_sub" {
  project              = var.project_id
  name                 = "${local.service_name}-gcilistgroups"
  topic                = var.triggering_topic_id
  ack_deadline_seconds = 10
  push_config {
    oidc_token {
      service_account_email = google_service_account.execute_gcilistgroups_sub_sa.email
    }
    push_endpoint = google_cloud_run_service.crun_svc.status[0].url
  }
  # no expiration policy means never expires
  filter                     = "attributes.ce-type = \"com.gitlab.realtime-asset-monitor.gcilistgroups\""
  message_retention_duration = "86400s"
  retry_policy {
    # https://developers.google.com/admin-sdk/directory/v1/limits
    # 2022-02-11 default is 3000 per 100 sec -> do not retry in less than a 105 sec
    minimum_backoff = "105s"
  }
}
