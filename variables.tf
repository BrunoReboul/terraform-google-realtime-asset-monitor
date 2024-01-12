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


variable "project_id" {
  description = "GCP project id where to deploy RAM for a given environment, like test or production"
}

variable "environment" {
  description = "environment name, by default terraform.workspace is used"
  default     = ""
}

variable "ram_microservice_image_tag" {
  description = "The container image tag for this microservice"
  default     = "latest"
}

variable "log_only_severity_levels" {
  description = "Which type of log entry should be logged"
  default     = "WARNING NOTICE CRITICAL"
}

variable "pubsub_allowed_regions" {
  type    = list(string)
  default = ["europe-central2", "europe-north1", "europe-west1", "europe-west3", "europe-west4", "europe-west8", "europe-west9", "europe-southwest1"]
}

variable "gcs_location" {
  description = "Cloud Storage location"
  default     = "europe-west1"
}

variable "gcs_export_bucket_object_max_age_days" {
  description = "A lifecycle rule deletes objects older than this duration"
  default     = 1
}

variable "gcs_assetjson_bucket_object_max_age_days" {
  description = "A lifecycle rule deletes objects older than this duration"
  default     = 1
}

variable "crun_region" {
  description = "cloud run region"
  default     = "europe-west1"
}

variable "dataset_location" {
  description = "Bigquery dataset location"
  default     = "EU"
}

variable "scheduler_region" {
  description = "Cloud Scheduler region"
  default     = "europe-west1"
}

variable "views_interval_days" {
  description = "The sliding windows in days the view uses to get data. Should not be less than the batch cadence to export assets"
  default     = 7
}

variable "bq_partition_expiration_ms" {
  description = "Bigquery table number of milliseconds for which to keep the storage for a partition"
  default     = 3024000000
}

variable "schedulers" {
  type = map(any)
  default = {
    prd_every_week = {
      "environment" = "prod",
      "name"        = "at_01am10_on_sunday",
      "schedule"    = "10 1 * * 0",
    },
    prd_every_3h = {
      "environment" = "prod",
      "name"        = "at_minute_0_past_every_3rd_hour",
      "schedule"    = "0 */3 * * *",
    },
    qa_every_year = {
      "environment" = "test",
      "name"        = "at_00am00_on_day_of_month_1_in_january",
      "schedule"    = "0 0 1 1 *",
    },
    qa_every_3h = {
      "environment" = "test",
      "name"        = "at_minute_0_past_every_3rd_hour",
      "schedule"    = "0 */3 * * *",
    },
  }
}

variable "export_org_ids" {
  description = "list of organization id where to grant Cloud Asset Inventory roles to allow export feature"
  type        = list(string)
}

variable "export_folder_ids" {
  description = "list of folder id where to grant Cloud Asset Inventory roles to allow export feature"
  type        = list(string)
}

variable "feed_iam_policy_orgs" {
  description = "For feed type IAM_POLICY, the map of monitored organizations and the targeted list assets for each. Can be empty"
  type        = map(list(string))
  default     = {}
}

variable "feed_resource_orgs" {
  description = "For feed type RESOURCE, the map of monitored organizations and the targeted list assets for each. Can be empty"
  type        = map(list(string))
  default     = {}
}

variable "feed_iam_policy_folders" {
  description = "For feed type IAM_POLICY, the map of monitored folders and the targeted list assets for each. Can be empty"
  type        = map(list(string))
  default     = {}
}

variable "feed_resource_folders" {
  description = "For feed type RESOURCE, the map of monitored folders and the targeted list assets for each. Can be empty"
  type        = map(list(string))
  default     = {}
}

variable "asset_feed_topic_name" {
  description = "the data on which to assess compliance"
  default     = "assetFeed"
}

variable "asset_rule_topic_name" {
  description = "each message combines the data of one asset and the code of one complicance rule's"
  default     = "assetRule"
}

variable "compliance_status_topic_name" {
  description = "compliance status may be true for compliant or false for not compliant for a given asset version and configuration rule version"
  default     = "ram-complianceStatus"
}

variable "violation_topic_name" {
  description = "violations detail why an asset is not compliant to a configuration rule"
  default     = "ram-violation"
}

variable "notification_channels" {
  type    = list(string)
  default = []
}

variable "ram_e2e_latency" {
  type = map(any)
  default = {
    real-time = {
      origin                             = "real-time"
      suffix                             = ""
      extra_filter                       = ""
      threshold_str                      = "5.4min"
      threshold_value                    = 327.68
      goal                               = 0.95
      rolling_period_days                = 28
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    },
    batch = {
      origin                             = "scheduled"
      suffix                             = "-general"
      extra_filter                       = "metric.label.\"asset_type\"!=\"k8s.io/Pod\""
      threshold_str                      = "15.5min"
      threshold_value                    = 926.819
      goal                               = 0.99
      rolling_period_days                = 28
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    }
    batch_pods = {
      origin                             = "scheduled"
      suffix                             = "-k8s-pods"
      extra_filter                       = "metric.label.\"asset_type\"=\"k8s.io/Pod\""
      threshold_str                      = "44min"
      threshold_value                    = 2621.440
      goal                               = 0.99
      rolling_period_days                = 28
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    }
  }
}

variable "cai_latency" {
  type = map(any)
  default = {
    real-time = {
      origin                             = "real-time"
      events                             = "changes"
      microservice_name                  = "convertfeed"
      status                             = "finish enrichCAIFeedMsg"
      threshold_str                      = "5.4min"
      threshold_value                    = 327.68
      goal                               = 0.95
      rolling_period_days                = 28
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    },
    batch = {
      origin                             = "scheduled"
      events                             = "exports"
      microservice_name                  = "splitexport"
      status                             = "finish splitToLines done|finish splitToChildExports done"
      threshold_str                      = "31min"
      threshold_value                    = 1853.638
      goal                               = 0.99
      rolling_period_days                = 28
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    }
  }
}

variable "api_availability" {
  type        = map(any)
  description = "Critical User Journeys CUJs map crtical microservices"
  default = {
    pubsub_publish = {
      rolling_period_days                = 28
      service                            = "pubsub.googleapis.com"
      method                             = "google.pubsub.v1.Publisher.Publish"
      goal                               = 0.999
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    },
    bigquery_insertall = {
      rolling_period_days                = 28
      service                            = "bigquery.googleapis.com"
      method                             = "google.cloud.bigquery.v2.TableDataService.InsertAll"
      goal                               = 0.999
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    },
    firestore_commit = {
      rolling_period_days                = 28
      service                            = "firestore.googleapis.com"
      method                             = "google.firestore.v1.Firestore.Commit"
      goal                               = 0.999
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    },
  }
}

variable "api_latency" {
  type = map(any)
  default = {
    pubsub_publish = {
      rolling_period_days                = 28
      service                            = "pubsub.googleapis.com"
      method                             = "google.pubsub.v1.Publisher.Publish"
      goal                               = 0.95
      threshold_str                      = "400ms"
      threshold_value                    = 0.4
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    },
    bigquery_insertall = {
      rolling_period_days                = 28
      service                            = "bigquery.googleapis.com"
      method                             = "google.cloud.bigquery.v2.TableDataService.InsertAll"
      goal                               = 0.95
      threshold_str                      = "150ms"
      threshold_value                    = 0.15
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    },
    firestore_commit = {
      rolling_period_days                = 28
      service                            = "firestore.googleapis.com"
      method                             = "google.firestore.v1.Firestore.Commit"
      goal                               = 0.95
      threshold_str                      = "1s"
      threshold_value                    = 1
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    },
  }
}

variable "deploy_autofix_bqdsdelete" {
  type        = bool
  description = "Deploy autofix bqdsdelete when true"
  default     = false
}

variable "deploy_console" {
  type        = bool
  description = "Deploy the console frontend and its BFF backend for frontend"
  default     = false
}

variable "deploy_loadbalancer" {
  type        = bool
  description = "Deploy the load balancer for front ends and their BFF"
  default     = false
}

variable "dns_name" {
  description = "The DNS name used to expose RAM"
  default     = "ram.example.com"
}

variable "support_email" {
  description = "iap brand support email"
  default     = "support@example.com"
}

variable "static_public_bucket_name_suffix" {
  description = "suffix to the bucketname hosting public static content"
  default     = "-staticpublicweb"
}
