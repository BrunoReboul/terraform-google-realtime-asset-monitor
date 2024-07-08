/**
 * Copyright 2024 Google LLC
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
  service_name = "fetchrules"
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

resource "google_pubsub_topic" "asset_rule" {
  project = var.project_id
  name    = var.asset_rule_topic_name
  message_storage_policy {
    allowed_persistence_regions = var.pubsub_allowed_regions
  }
}

resource "google_pubsub_topic_iam_member" "asset_rule_publisher" {
  project = google_pubsub_topic.asset_rule.project
  topic   = google_pubsub_topic.asset_rule.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_pubsub_topic_iam_member" "asset_rule_viewer" {
  project = google_pubsub_topic.asset_rule.project
  topic   = google_pubsub_topic.asset_rule.name
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_storage_bucket" "rules_repo" {
  project                     = var.project_id
  name                        = "${var.project_id}-rulesrepo"
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

resource "google_storage_bucket_iam_member" "rule_repo_reader" {
  bucket = google_storage_bucket.rules_repo.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_storage_bucket" "common_rego" {
  project                     = var.project_id
  name                        = "${var.project_id}-commonrego"
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

resource "google_storage_bucket_iam_member" "common_rego_reader" {
  bucket = google_storage_bucket.common_rego.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_storage_bucket_object" "audit_rego" {
  name   = "audit.rego"
  source = "${path.module}/audit.rego"
  bucket = google_storage_bucket.common_rego.id
}

resource "google_storage_bucket_object" "constraints_rego" {
  name   = "constraints.rego"
  source = "${path.module}/constraints.rego"
  bucket = google_storage_bucket.common_rego.id
}

resource "google_storage_bucket_object" "util_rego" {
  name   = "util.rego"
  source = "${path.module}/util.rego"
  bucket = google_storage_bucket.common_rego.id
}

# resource "google_cloud_run_service" "crun_svc" {
#   project  = var.project_id
#   name     = local.service_name
#   location = var.crun_region

#   template {
#     spec {
#       containers {
#         image = "${var.ram_container_images_registry}/${local.service_name}:${var.ram_microservice_image_tag}"
#         resources {
#           limits = {
#             cpu    = "${var.crun_cpu}"
#             memory = "${var.crun_memory}"
#           }
#         }
#         env {
#           name  = "${upper(local.service_name)}_ASSET_RULE_TOPIC_ID"
#           value = google_pubsub_topic.asset_rule.name
#         }
#         env {
#           name  = "${upper(local.service_name)}_CACHE_MAX_AGE_MINUTES"
#           value = var.cache_max_age_minutes
#         }
#         env {
#           name  = "${upper(local.service_name)}_ENVIRONMENT"
#           value = var.environment
#         }
#         env {
#           name  = "${upper(local.service_name)}_LOG_ONLY_SEVERITY_LEVELS"
#           value = var.log_only_severity_levels
#         }
#         env {
#           name  = "${upper(local.service_name)}_PROJECT_ID"
#           value = var.project_id
#         }
#         env {
#           name  = "${upper(local.service_name)}_RULE_COLLECTION_ID"
#           value = var.rule_collection_id
#         }
#         env {
#           name  = "${upper(local.service_name)}_START_PROFILER"
#           value = var.start_profiler
#         }
#       }
#       container_concurrency = var.crun_concurrency
#       timeout_seconds       = var.crun_timeout_seconds
#       service_account_name  = google_service_account.microservice_sa.email
#     }
#     metadata {
#       annotations = {
#         "run.googleapis.com/client-name"   = "terraform"
#         "autoscaling.knative.dev/maxScale" = "${var.crun_max_instances}"
#       }
#     }
#   }
#   metadata {
#     annotations = {
#       "run.googleapis.com/ingress" = "internal"
#     }
#   }
#   autogenerate_revision_name = true
#   traffic {
#     percent         = 100
#     latest_revision = true
#   }
#   lifecycle {
#     ignore_changes = all
#   }
# }

resource "google_cloud_run_v2_service" "crun_svc" {
  project  = var.project_id
  name     = local.service_name
  location = var.crun_region
  client = "terraform"
  ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  traffic {
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
  template {
    containers {
        image = "${var.ram_container_images_registry}/${local.service_name}:${var.ram_microservice_image_tag}"
        resources {
          cpu_idle = true
          limits = {
            cpu    = "${var.crun_cpu}"
            memory = "${var.crun_memory}"
          }
        }
        env {
          name  = "${upper(local.service_name)}_ASSET_RULE_TOPIC_ID"
          value = google_pubsub_topic.asset_rule.name
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
          name  = "${upper(local.service_name)}_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "${upper(local.service_name)}_RULE_COLLECTION_ID"
          value = var.rule_collection_id
        }
        env {
          name  = "${upper(local.service_name)}_START_PROFILER"
          value = var.start_profiler
        }
    }
    max_instance_request_concurrency = var.crun_concurrency
    timeout = var.crun_timeout
    service_account = google_service_account.microservice_sa.email
    scaling {
      max_instance_count = var.crun_max_instances
    }
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "google_service_account" "subscription_sa" {
  project      = var.project_id
  account_id   = "trigger-${local.service_name}"
  display_name = "RAM execute ${local.service_name} trigger"
  description  = "Solution: Real-time Asset Monitor, microservice trigger: ${local.service_name}"
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
  location = google_cloud_run_v2_service.crun_svc.location
  project  = google_cloud_run_v2_service.crun_svc.project
  service  = google_cloud_run_v2_service.crun_svc.name

  policy_data = data.google_iam_policy.binding.policy_data
}

resource "google_pubsub_subscription" "subcription" {
  project              = var.project_id
  name                 = local.service_name
  topic                = var.triggering_topic_id
  ack_deadline_seconds = var.sub_ack_deadline_seconds
  push_config {
    oidc_token {
      service_account_email = google_service_account.subscription_sa.email
    }
    #Updated endpoint to deal with WARNING in logs: failed to extract Pub/Sub topic name from the URL request path: "/", configure your subscription's push endpoint to use the following path pattern: 'projects/PROJECT_NAME/topics/TOPIC_NAME
    push_endpoint = google_cloud_run_v2_service.crun_svc.uri
  }
  expiration_policy {
    ttl = ""
  }
  message_retention_duration = var.sub_message_retention_duration
  retry_policy {
    minimum_backoff = var.sub_minimum_backoff
  }
}
