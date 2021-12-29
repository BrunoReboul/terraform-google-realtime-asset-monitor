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
  description  = "Solution: Real-time Asset Monitor, microservice: fetchrules"
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


