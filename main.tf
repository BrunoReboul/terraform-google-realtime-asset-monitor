/**
 * Copyright 2021 Google LLC
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
  source     = "./modules/deploy"
  project_id = var.project_id
}


module "convertfeed" {
  source                 = "./modules/convertfeed"
  project_id             = var.project_id
  pubsub_allowed_regions = var.pubsub_allowed_regions
  crun_region            = var.crun_region
}

module "fetchrules" {
  source                 = "./modules/fetchrules"
  project_id             = var.project_id
  pubsub_allowed_regions = var.pubsub_allowed_regions
  gcs_location           = var.gcs_location
  crun_region            = var.crun_region
  eva_transport_topic_id = module.convertfeed.asset_feed_topic_id
}

module "monitor" {
  source                 = "./modules/monitor"
  project_id             = var.project_id
  pubsub_allowed_regions = var.pubsub_allowed_regions
  crun_region            = var.crun_region
  eva_transport_topic_id = module.fetchrules.asset_rule_topic_id
}

module "stream2bq" {
  source                     = "./modules/stream2bq"
  project_id                 = var.project_id
  crun_region                = var.crun_region
  asset_feed_topic_id        = module.convertfeed.asset_feed_topic_id
  compliance_status_topic_id = module.monitor.compliance_status_topic_id
  violation_topic_id         = module.monitor.violation_topic_id
}

module "setfeed" {
  depends_on = [
    module.stream2bq.trigger_id_violation
  ]
  source                  = "./modules/setfeed"
  project_id              = var.project_id
  pubsub_allowed_regions  = var.pubsub_allowed_regions
  cai_feed_topic_id       = module.convertfeed.cai_feed_topic_id
  feed_iam_policy_folders = var.feed_iam_policy_folders
  feed_iam_policy_orgs    = var.feed_iam_policy_orgs
  feed_resource_folders   = var.feed_resource_folders
  feed_resource_orgs      = var.feed_resource_orgs
}
