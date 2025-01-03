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
  service_name = "consolebff"
}

data "google_project" "project" {
  project_id = var.project_id
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

resource "google_project_iam_member" "project_bigquery_jobuser" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_bigquery_dataset_iam_member" "editor" {
  project    = var.project_id
  dataset_id = var.bigquery_dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_storage_bucket" "usersrole_repo" {
  project                     = var.project_id
  name                        = "${var.project_id}-usersrolerepo"
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

resource "google_storage_bucket_iam_member" "usersrole_repo_reader" {
  bucket = google_storage_bucket.usersrole_repo.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.microservice_sa.email}"
}


resource "google_cloud_run_v2_service" "crun_svc" {
  project  = var.project_id
  name     = local.service_name
  location = var.crun_region
  client = "terraform"
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
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
        env {
          name  = "${upper(local.service_name)}_AUDIENCE_ADMIN"
          value = var.audience_admin
        }
        env {
          name  = "${upper(local.service_name)}_AUDIENCE_RESULTS"
          value = var.audience_results
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
data "google_iam_policy" "binding" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:service-${data.google_project.project.number}@gcp-sa-iap.iam.gserviceaccount.com",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_v2_service.crun_svc.location
  project  = google_cloud_run_v2_service.crun_svc.project
  service  = google_cloud_run_v2_service.crun_svc.name

  policy_data = data.google_iam_policy.binding.policy_data
}

resource "google_logging_metric" "ram_consolebff_response_count" {
  project = var.project_id
  name    = "ram_consolebff_response_count"
  filter  = "resource.type=\"cloud_run_revision\" resource.labels.service_name=\"consolebff\" log_name=~\"projects/.*/logs/run.googleapis.com%2Frequests\" httpRequest.requestUrl=~\"^https:.*consolebff.*v.*\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    labels {
      key         = "status"
      value_type  = "STRING"
      description = "HTTP response status code"
    }
    labels {
      key         = "resource_name"
      value_type  = "STRING"
      description = "Extracted from the request URL"
    }
  }
  label_extractors = {
    "resource_name" = "REGEXP_EXTRACT(httpRequest.requestUrl, \"^https:\\\\/\\\\/.*\\\\/consolebff\\\\/v\\\\d+\\\\/([a-z]+)\")"
    "status"        = "EXTRACT(httpRequest.status)"
  }
}

resource "google_logging_metric" "ram_consolebff_response_latency" {
  project = var.project_id
  name    = "ram_consolebff_response_latency"
  filter  = "resource.type=\"cloud_run_revision\" resource.labels.service_name=\"consolebff\" log_name=~\"projects/.*/logs/run.googleapis.com%2Frequests\" httpRequest.requestUrl=~\"^https:.*consolebff.*v.*\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DISTRIBUTION"
    unit        = "s"
    labels {
      key         = "status"
      value_type  = "STRING"
      description = "HTTP response status code"
    }
    labels {
      key         = "resource_name"
      value_type  = "STRING"
      description = "Extracted from the request URL"
    }
  }
  value_extractor = "REGEXP_EXTRACT(httpRequest.latency, \"(\\\\d+\\\\.?\\\\d*)s\")"
  label_extractors = {
    "resource_name" = "REGEXP_EXTRACT(httpRequest.requestUrl, \"^https:\\\\/\\\\/.*\\\\/consolebff\\\\/v\\\\d+\\\\/([a-z]+)\")"
    "status"        = "EXTRACT(httpRequest.status)"
  }
  bucket_options {
    exponential_buckets {
      num_finite_buckets = 80
      growth_factor      = 1.15478198468946
      scale              = 0.001
    }
  }
}
