/**
 * Copyright 2023 Google LLC
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
  service_name = "convertfeed"
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

resource "google_storage_bucket" "attributes_repo" {
  project                     = var.project_id
  name                        = "${var.project_id}-attributesrepo"
  location                    = var.gcs_location
  force_destroy               = true
  uniform_bucket_level_access = true
  lifecycle_rule {
    condition {
      age = 36500
    }
    action {
      type          = "SetStorageClass"
      storage_class = "STANDARD"
    }
  }
}

resource "google_storage_bucket_iam_member" "attributes_repo_reader" {
  bucket = google_storage_bucket.attributes_repo.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_storage_bucket_object" "attributes_to_publish2fs_default" {
  name   = "publish2fs.yaml"
  source = "${path.module}/publish2fs.yaml"
  bucket = google_storage_bucket.attributes_repo.id
  lifecycle {
    ignore_changes = all
  }
}

resource "google_storage_bucket_object" "attributes_to_upload2gcs_default" {
  name   = "upload2gcs.yaml"
  source = "${path.module}/upload2gcs.yaml"
  bucket = google_storage_bucket.attributes_repo.id
  lifecycle {
    ignore_changes = all
  }
}

resource "google_pubsub_topic" "asset_feed" {
  project = var.project_id
  name    = var.asset_feed_topic_name
  message_storage_policy {
    allowed_persistence_regions = var.pubsub_allowed_regions
  }
}

resource "google_pubsub_topic_iam_member" "asset_feed_publisher" {
  project = google_pubsub_topic.asset_feed.project
  topic   = google_pubsub_topic.asset_feed.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_pubsub_topic_iam_member" "asset_feed_viewer" {
  project = google_pubsub_topic.asset_feed.project
  topic   = google_pubsub_topic.asset_feed.name
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_project_iam_member" "cloud_datastore_viewer" {
  project = var.project_id
  role    = "roles/datastore.viewer"
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
          name  = "${upper(local.service_name)}_ASSET_COLLECTION_ID"
          value = var.asset_collection_id
        }
        env {
          name  = "${upper(local.service_name)}_ASSET_FEED_TOPIC_ID"
          value = google_pubsub_topic.asset_feed.name
        }
        env {
          name  = "${upper(local.service_name)}_CACHE_MAX_AGE_MINUTES"
          value = var.cache_max_age_minutes
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
          name  = "${upper(local.service_name)}_OWNER_LABEL_KEY_NAME"
          value = var.owner_label_Key_name
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
          name  = "${upper(local.service_name)}_VIOLATION_RESOLVER_LABEL_KEY_NAME"
          value = var.violation_resolver_label_key_name
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

resource "google_pubsub_topic" "cai_feed" {
  project = var.project_id
  name    = var.cai_feed_topic_name
  message_storage_policy {
    allowed_persistence_regions = var.pubsub_allowed_regions
  }
}

resource "google_service_account" "eva_trigger_sa" {
  project      = var.project_id
  account_id   = "${local.service_name}-trigger"
  display_name = "RAM ${local.service_name} trigger"
  description  = "Solution: Real-time Asset Monitor, microservice trigger: ${local.service_name}"
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
      topic = google_pubsub_topic.cai_feed.id
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
