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

output "project_id" {
  value       = var.project_id
  description = "Project id"
}

output "deploy_service_account_email" {
  description = "Service account email used to deploy RAM"
  value       = module.deploy.service_account_email
}

output "monitor_service_account_email" {
  description = "Service account email used to run this microservice"
  value       = module.monitor.service_account_email
}

output "compliance_status_topic_id" {
  description = "compliance status topic id"
  value       = module.monitor.compliance_status_topic_id
}

output "violation_topic_id" {
  description = "violation topic id"
  value       = module.monitor.violation_topic_id
}

output "asset_rule_topic_id" {
  description = "asset rule topic id"
  value       = module.fetchrules.asset_rule_topic_id
}

output "cai_feed_topic_id" {
  description = "cai feed topic id"
  value       = module.setfeed.cai_feed_topic_id
}

output "feed_iam_policy_org" {
  description = "cai feed for iam policies at organizations level"
  value       = module.setfeed.feed_iam_policy_org
}

output "feed_resource_org" {
  description = "cai feed for resource at organizations level"
  value       = module.setfeed.feed_resource_org
}

output "feed_iam_policy_folder" {
  description = "cai feed for iam policies at folders level"
  value       = module.setfeed.feed_iam_policy_folder
}

output "feed_resource_folder" {
  description = "cai feed for resource at folders level"
  value       = module.setfeed.feed_resource_folder
}

output "feed_iam_policy_project" {
  description = "cai feed for iam policies at projects level"
  value       = module.setfeed.feed_iam_policy_project
}

output "feed_resource_project" {
  description = "cai feed for resource at projects level"
  value       = module.setfeed.feed_resource_project
}
