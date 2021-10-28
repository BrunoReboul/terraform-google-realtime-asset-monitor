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

module "monitor" {
  source                       = "./modules/monitor"
  project_id                   = var.project_id
  compliance_status_topic_name = var.compliance_status_topic_name
  violation_topic_name         = var.violation_topic_name
  pubsub_allowed_regions       = var.pubsub_allowed_regions
}

module "fetchrules" {
  source                 = "./modules/fetchrules"
  project_id             = var.project_id
  asset_rule_topic_name  = var.asset_rule_topic_name
  pubsub_allowed_regions = var.pubsub_allowed_regions
}

module "setfeed" {
  source                  = "./modules/setfeed"
  project_id              = var.project_id
  cai_feed_topic_name     = var.cai_feed_topic_name
  pubsub_allowed_regions  = var.pubsub_allowed_regions
  feed_iam_policy_folders = var.feed_iam_policy_folders
  feed_iam_policy_orgs    = var.feed_iam_policy_orgs
  feed_resource_folders   = var.feed_resource_folders
  feed_resource_orgs      = var.feed_resource_orgs
}
