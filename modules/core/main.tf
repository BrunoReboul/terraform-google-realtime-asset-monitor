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

module "deploy" {
  source     = "../deploy"
  project_id = var.project_id
}


module "convertfeed" {
  source                     = "../convertfeed"
  project_id                 = var.project_id
  pubsub_allowed_regions     = var.pubsub_allowed_regions
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
}

module "fetchrules" {
  source                     = "../fetchrules"
  project_id                 = var.project_id
  pubsub_allowed_regions     = var.pubsub_allowed_regions
  gcs_location               = var.gcs_location
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
  eva_transport_topic_id     = module.convertfeed.asset_feed_topic_id
}

module "monitor" {
  source                     = "../monitor"
  project_id                 = var.project_id
  pubsub_allowed_regions     = var.pubsub_allowed_regions
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
  eva_transport_topic_id     = module.fetchrules.asset_rule_topic_id
}

module "stream2bq" {
  source                     = "../stream2bq"
  project_id                 = var.project_id
  views_interval_days        = var.views_interval_days
  dataset_location           = var.dataset_location
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
  asset_feed_topic_id        = module.convertfeed.asset_feed_topic_id
  compliance_status_topic_id = module.monitor.compliance_status_topic_id
  violation_topic_id         = module.monitor.violation_topic_id
}
