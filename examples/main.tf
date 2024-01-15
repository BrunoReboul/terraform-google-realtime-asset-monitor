
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

terraform {
  backend "gcs" {
    bucket = "<yourTFstateBucket>"
    prefix = "<yourPrefix>"
  }
}

module "realtime-asset-monitor" {
  source                  = "BrunoReboul/realtime-asset-monitor/google"
  version                 = "<x.y.z>"
  project_id                = terraform.workspace == "prod" ? var.prod_project_id : var.test_project_id
  export_org_ids            = var.export_org_ids
  export_folder_ids         = var.export_folder_ids
  feed_iam_policy_folders   = var.feed_iam_policy_folders
  feed_iam_policy_orgs      = var.feed_iam_policy_orgs
  feed_resource_folders     = var.feed_resource_folders
  feed_resource_orgs        = var.feed_resource_orgs
  log_only_severity_levels  = var.log_only_severity_levels
  pubsub_allowed_regions    = var.pubsub_allowed_regions
  gcs_location              = var.gcs_location
  crun_region               = var.crun_region
  dataset_location          = var.dataset_location
  scheduler_region          = var.scheduler_region
  views_interval_days       = var.views_interval_days
  schedulers                = var.schedulers
  notification_channels     = var.notification_channels
  deploy_autofix_bqdsdelete = false
  deploy_console            = false
  deploy_loadbalancer       = false
}
