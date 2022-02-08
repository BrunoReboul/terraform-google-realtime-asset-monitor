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

output "project_id" {
  value       = var.project_id
  description = "Project id"
}

output "deploy_service_account_email" {
  description = "Service account email used to deploy RAM"
  value       = module.deploy.service_account_email
}

# feed
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

# convertfeed
output "convertfeed_service_account_email" {
  description = "Service account email used to run this microservice"
  value       = module.convertfeed.service_account_email
}

output "convertfeed_crun_service_id" {
  description = "cloud run service id"
  value       = module.convertfeed.crun_service_id
}
output "convertfeed_crun_service_url" {
  description = "cloud run service url"
  value       = module.convertfeed.crun_service_url
}

output "convertfeed_trigger_service_account_email" {
  description = "Service account email used to trigger this microservice"
  value       = module.convertfeed.trigger_service_account_email
}
output "convertfeed_trigger_id" {
  description = "Eventarc trigger id"
  value       = module.convertfeed.trigger_id
}

output "convertfeed_trigger_subscription_name" {
  value = module.convertfeed.trigger_subscription_name
}

output "convertfeed_cai_feed_topic_id" {
  description = "cai feed topic id"
  value       = module.convertfeed.cai_feed_topic_id
}

output "asset_feed_topic_id" {
  description = "asset rule topic id"
  value       = module.convertfeed.asset_feed_topic_id
}

# fetchrules
output "fetchrules_service_account_email" {
  description = "Service account email used to run this microservice"
  value       = module.fetchrules.service_account_email
}

output "fetchrules_rules_repo_bucket_name" {
  description = "GCS bucket containing the compliance rules"
  value       = module.fetchrules.rules_repo_bucket_name
}

output "fetchrules_crun_service_id" {
  description = "cloud run service id"
  value       = module.fetchrules.crun_service_id
}
output "fetchrules_crun_service_url" {
  description = "cloud run service url"
  value       = module.fetchrules.crun_service_url
}

output "fetchrules_trigger_service_account_email" {
  description = "Service account email used to trigger this microservice"
  value       = module.fetchrules.trigger_service_account_email
}
output "fetchrules_trigger_id" {
  description = "Eventarc trigger id"
  value       = module.fetchrules.trigger_id
}

output "fetchrules_trigger_subscription_name" {
  value = module.fetchrules.trigger_subscription_name
}

output "asset_rule_topic_id" {
  description = "asset rule topic id"
  value       = module.fetchrules.asset_rule_topic_id
}

# monitor
output "monitor_service_account_email" {
  description = "Service account email used to run this microservice"
  value       = module.monitor.service_account_email
}

output "monitor_crun_service_id" {
  description = "cloud run service id"
  value       = module.monitor.crun_service_id
}
output "monitor_crun_service_url" {
  description = "cloud run service url"
  value       = module.monitor.crun_service_url
}

output "monitor_trigger_service_account_email" {
  description = "Service account email used to trigger this microservice"
  value       = module.monitor.trigger_service_account_email
}
output "monitor_trigger_id" {
  description = "Eventarc trigger id"
  value       = module.monitor.trigger_id
}

output "monitor_trigger_subscription_name" {
  value = module.monitor.trigger_subscription_name
}

output "compliance_status_topic_id" {
  description = "compliance status topic id"
  value       = module.monitor.compliance_status_topic_id
}

output "violation_topic_id" {
  description = "violation topic id"
  value       = module.monitor.violation_topic_id
}

# stream2bq

output "stream2bq_service_account_email" {
  description = "Service account email used to run this microservice"
  value       = module.stream2bq.service_account_email
}

output "stream2bq_crun_service_id" {
  description = "cloud run service id"
  value       = module.stream2bq.crun_service_id
}
output "stream2bq_crun_service_url" {
  description = "cloud run service url"
  value       = module.stream2bq.crun_service_url
}

output "stream2bq_trigger_service_account_email" {
  description = "Service account email used to trigger this microservice"
  value       = module.stream2bq.trigger_service_account_email
}
output "stream2bq_trigger_id_asset_feed" {
  description = "Eventarc trigger id"
  value       = module.stream2bq.trigger_id_asset_feed
}

output "stream2bq_trigger_subscription_name_asset_feed" {
  value = module.stream2bq.trigger_subscription_name_asset_feed
}

output "stream2bq_trigger_id_compliance_status" {
  description = "Eventarc trigger id"
  value       = module.stream2bq.trigger_id_compliance_status
}

output "stream2bq_trigger_subscription_name_compliance_status" {
  value = module.stream2bq.trigger_subscription_name_compliance_status
}

output "stream2bq_trigger_id_violation" {
  description = "Eventarc trigger id"
  value       = module.stream2bq.trigger_id_violation
}

output "stream2bq_trigger_subscription_name_violation" {
  value = module.stream2bq.trigger_subscription_name_violation
}

# launch
output "launch_service_account_email" {
  description = "Service account email used to run this microservice"
  value       = module.launch.service_account_email
}

output "launch_actions_repo_bucket_name" {
  description = "Cloud storage bucket to store scheduled action configurations"
  value       = module.launch.actions_repo_bucket_name
}

output "launch_crun_service_id" {
  description = "cloud run service id"
  value       = module.launch.crun_service_id
}
output "launch_crun_service_url" {
  description = "cloud run service url"
  value       = module.launch.crun_service_url
}

output "launch_trigger_service_account_email" {
  description = "Service account email used to trigger this microservice"
  value       = module.launch.trigger_service_account_email
}
output "launch_trigger_id" {
  description = "Eventarc trigger id"
  value       = module.launch.trigger_id
}

output "launch_trigger_subscription_name" {
  value = module.launch.trigger_subscription_name
}

output "action_trigger_topic_id" {
  description = "action trigger topic id"
  value       = module.launch.action_trigger_topic_id
}

# execute
output "execute_service_account_email" {
  description = "Service account email used to run this microservice"
  value       = module.execute.service_account_email
}

output "execute_exports_bucket_name" {
  description = "Cloud storage bucket where to output Cloud Asset Inventory exports"
  value       = module.execute.exports_bucket_name
}

output "execute_crun_service_id" {
  description = "cloud run service id"
  value       = module.execute.crun_service_id
}
output "execute_crun_service_url" {
  description = "cloud run service url"
  value       = module.execute.crun_service_url
}

output "execute_trigger_service_account_email" {
  description = "Service account email used to trigger this microservice"
  value       = module.execute.trigger_service_account_email
}
output "execute_trigger_id" {
  description = "Eventarc trigger id"
  value       = module.execute.trigger_id
}

output "execute_trigger_subscription_name" {
  value = module.execute.trigger_subscription_name
}

