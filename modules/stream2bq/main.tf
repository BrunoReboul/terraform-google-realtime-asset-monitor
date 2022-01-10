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
  service_name = "stream2bq"
}

resource "google_service_account" "microservice_sa" {
  project      = var.project_id
  account_id   = local.service_name
  display_name = "RAM monitor"
  description  = "Solution: Real-time Asset Monitor, microservice: ${local.service_name}"
}

resource "google_project_iam_member" "project_profiler_agent" {
  project = var.project_id
  role    = "roles/cloudprofiler.agent"
  member  = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_bigquery_dataset" "ram_dataset" {
  project       = var.project_id
  dataset_id    = var.dataset_name
  friendly_name = "real-time_asset_monitor"
  description   = "real-time_asset_monitor"
  location      = var.dataset_location
}

resource "google_bigquery_dataset_iam_member" "editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.ram_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_bigquery_table" "assets" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.ram_dataset.dataset_id
  table_id            = "assets"
  description         = "Real-time Asset Monitor - assets"
  deletion_protection = true

  time_partitioning {
    type = "DAY"
  }

  schema = <<EOF
[
    {
        "mode": "REQUIRED",
        "name": "timestamp",
        "type": "TIMESTAMP"
    },
    {
        "mode": "REQUIRED",
        "name": "name",
        "type": "STRING"
    },
    {
        "name": "owner",
        "type": "STRING"
    },
    {
        "name": "violationResolver",
        "type": "STRING"
    },
    {
        "name": "ancestryPathDisplayName",
        "type": "STRING"
    },
    {
        "name": "ancestryPath",
        "type": "STRING"
    },
    {
        "mode": "REPEATED",
        "name": "ancestorsDisplayName",
        "type": "STRING"
    },
    {
        "mode": "REPEATED",
        "name": "ancestors",
        "type": "STRING"
    },
    {
        "mode": "REQUIRED",
        "name": "assetType",
        "type": "STRING"
    },
    {
        "mode": "REQUIRED",
        "name": "deleted",
        "type": "BOOLEAN"
    },
    {
        "name": "projectID",
        "type": "STRING"
    }
]
EOF

}

resource "google_bigquery_table" "compliance_status" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.ram_dataset.dataset_id
  table_id            = "complianceStatus"
  description         = "Real-time Asset Monitor - complianceStatus"
  deletion_protection = true

  time_partitioning {
    type = "DAY"
  }

  schema = <<EOF
[
    {
        "mode": "REQUIRED",
        "name": "assetName",
        "type": "STRING"
    },
    {
        "description": "When the asset change was captured",
        "mode": "REQUIRED",
        "name": "assetInventoryTimeStamp",
        "type": "TIMESTAMP"
    },
    {
        "description": "Mean to capture the asset change: real-time or batch-export",
        "name": "assetInventoryOrigin",
        "type": "STRING"
    },
    {
        "mode": "REQUIRED",
        "name": "ruleName",
        "type": "STRING"
    },
    {
        "description": "When the rule was assessed",
        "mode": "REQUIRED",
        "name": "ruleDeploymentTimeStamp",
        "type": "TIMESTAMP"
    },
    {
        "mode": "REQUIRED",
        "name": "compliant",
        "type": "BOOLEAN"
    },
    {
        "mode": "REQUIRED",
        "name": "deleted",
        "type": "BOOLEAN"
    },
    {
        "description": "When the compliance rule was evaluated on the asset settings",
        "mode": "REQUIRED",
        "name": "evaluationTimeStamp",
        "type": "TIMESTAMP"
    }
]
EOF

}

resource "google_bigquery_table" "violations" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.ram_dataset.dataset_id
  table_id            = "violations"
  description         = "Real-time Asset Monitor - violations"
  deletion_protection = true

  time_partitioning {
    type = "DAY"
  }

  schema = <<EOF
[
    {
        "description": "The violation information, aka why it is not compliant",
        "fields": [
            {
                "mode": "REQUIRED",
                "name": "message",
                "type": "STRING"
            },
            {
                "name": "metadata",
                "type": "STRING"
            },
            {
                "description": "When the compliance rule was evaluated on the asset settings",
                "mode": "REQUIRED",
                "name": "evaluationTimeStamp",
                "type": "TIMESTAMP"
            }
        ],
        "name": "nonCompliance",
        "type": "RECORD"
    },
    {
        "description": "The settings of the cloud function hosting the rule check",
        "fields": [
            {
                "mode": "REQUIRED",
                "name": "functionName",
                "type": "STRING"
            },
            {
                "mode": "REQUIRED",
                "name": "deploymentTime",
                "type": "TIMESTAMP"
            },
            {
                "name": "projectID",
                "type": "STRING"
            },
            {
                "name": "environment",
                "type": "STRING"
            }
        ],
        "name": "functionConfig",
        "type": "RECORD"
    },
    {
        "description": "The settings of the constraint used in conjonction with the rego template to assess the rule",
        "fields": [
            {
                "name": "kind",
                "type": "STRING"
            },
            {
                "fields": [
                    {
                        "name": "name",
                        "type": "STRING"
                    },
                    {
                        "name": "annotation",
                        "type": "STRING"
                    }
                ],
                "name": "metadata",
                "type": "RECORD"
            },
            {
                "fields": [
                    {
                        "name": "severity",
                        "type": "STRING"
                    },
                    {
                        "name": "match",
                        "type": "STRING"
                    },
                    {
                        "name": "parameters",
                        "type": "STRING"
                    }
                ],
                "name": "spec",
                "type": "RECORD"
            }
        ],
        "name": "constraintConfig",
        "type": "RECORD"
    },
    {
        "description": "The message from Cloud Asset Inventory in realtime or from split dump in batch",
        "fields": [
            {
                "fields": [
                    {
                        "mode": "REQUIRED",
                        "name": "name",
                        "type": "STRING"
                    },
                    {
                        "name": "owner",
                        "type": "STRING"
                    },
                    {
                        "name": "violationResolver",
                        "type": "STRING"
                    },
                    {
                        "name": "ancestryPathDisplayName",
                        "type": "STRING"
                    },
                    {
                        "name": "ancestryPath",
                        "type": "STRING"
                    },
                    {
                        "name": "ancestorsDisplayName",
                        "type": "STRING"
                    },
                    {
                        "name": "ancestors",
                        "type": "STRING"
                    },
                    {
                        "mode": "REQUIRED",
                        "name": "assetType",
                        "type": "STRING"
                    },
                    {
                        "name": "iamPolicy",
                        "type": "STRING"
                    },
                    {
                        "name": "resource",
                        "type": "STRING"
                    }
                ],
                "name": "asset",
                "type": "RECORD"
            },
            {
                "fields": [
                    {
                        "mode": "REQUIRED",
                        "name": "startTime",
                        "type": "TIMESTAMP"
                    }
                ],
                "name": "window",
                "type": "RECORD"
            },
            {
                "name": "origin",
                "type": "STRING"
            }
        ],
        "name": "feedMessage",
        "type": "RECORD"
    },
    {
        "description": "The rego code, including the rule template used to assess the rule as a JSON document",
        "name": "regoModules",
        "type": "STRING"
    }
]
EOF

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
          name  = "STREAM2BQ_ENVIRONMENT"
          value = terraform.workspace
        }
        env {
          name  = "STREAM2BQ_LOG_ONLY_SEVERITY_LEVELS"
          value = var.log_only_severity_levels
        }
        env {
          name  = "STREAM2BQ_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "STREAM2BQ_START_PROFILER"
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
  display_name = "RAM monitor trigger"
  description  = "Solution: Real-time Asset Monitor, microservice tigger: monitor"
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

resource "google_eventarc_trigger" "eva_trigger_asset_feed" {
  name            = "${local.service_name}-asset-feed"
  location        = google_cloud_run_service.crun_svc.location
  project         = google_cloud_run_service.crun_svc.project
  service_account = google_service_account.eva_trigger_sa.email
  transport {
    pubsub {
      topic = var.asset_feed_topic_id
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

resource "google_eventarc_trigger" "eva_trigger_compliance_status" {
  name            = "${local.service_name}-compliance-status"
  location        = google_cloud_run_service.crun_svc.location
  project         = google_cloud_run_service.crun_svc.project
  service_account = google_service_account.eva_trigger_sa.email
  transport {
    pubsub {
      topic = var.compliance_status_topic_id
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

resource "google_eventarc_trigger" "eva_trigger_violation" {
  name            = "${local.service_name}-violation"
  location        = google_cloud_run_service.crun_svc.location
  project         = google_cloud_run_service.crun_svc.project
  service_account = google_service_account.eva_trigger_sa.email
  transport {
    pubsub {
      topic = var.violation_topic_id
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
