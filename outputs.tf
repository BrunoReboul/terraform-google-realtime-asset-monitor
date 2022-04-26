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

output "monitor_subscription_sa_email" {
  description = "Service account email used to trigger this type of action"
  value       = module.monitor.subscription_sa_email
}
output "monitor_subscription_id" {
  description = "PubSub subscription id to trigger this type of action"
  value       = module.monitor.subscription_id
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

output "stream2bq_subscription_sa_email" {
  description = "Service account email used to trigger this type of action"
  value       = module.stream2bq.subscription_sa_email
}
output "stream2bq_subscription_id_asset_feed" {
  description = "PubSub subscription id asset feed"
  value       = module.stream2bq.subscription_id_asset_feed
}
output "stream2bq_subscription_id_compliance_status" {
  description = "PubSub subscription id compliance status"
  value       = module.stream2bq.subscription_id_compliance_status
}
output "stream2bq_subscription_id_violation" {
  description = "PubSub subscription id violation"
  value       = module.stream2bq.subscription_id_violation
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

# executecaiexport
output "executecaiexport_service_account_email" {
  description = "Service account email used to run this microservice"
  value       = module.executecaiexport.service_account_email
}

output "executecaiexport_exports_bucket_name" {
  description = "Cloud storage bucket where to output Cloud Asset Inventory exports"
  value       = module.executecaiexport.exports_bucket_name
}

output "executecaiexport_crun_service_id" {
  description = "cloud run service id"
  value       = module.executecaiexport.crun_service_id
}
output "executecaiexport_crun_service_url" {
  description = "cloud run service url"
  value       = module.executecaiexport.crun_service_url
}

output "executecaiexport_subscription_sa_email" {
  description = "Service account email used to trigger this type of action"
  value       = module.executecaiexport.subscription_sa_email
}
output "executecaiexport_subscription_id" {
  description = "PubSub subscription id to trigger this type of action"
  value       = module.executecaiexport.subscription_id
}

# executegfsdeleteolddocs
output "executegfsdeleteolddocs_service_account_email" {
  description = "Service account email used to run this microservice"
  value       = module.executegfsdeleteolddocs.service_account_email
}

output "executegfsdeleteolddocs_crun_service_id" {
  description = "cloud run service id"
  value       = module.executegfsdeleteolddocs.crun_service_id
}
output "executegfsdeleteolddocs_crun_service_url" {
  description = "cloud run service url"
  value       = module.executegfsdeleteolddocs.crun_service_url
}

output "executegfsdeleteolddocs_subscription_sa_email" {
  description = "Service account email used to trigger this type of action"
  value       = module.executegfsdeleteolddocs.subscription_sa_email
}
output "executegfsdeleteolddocs_subscription_id" {
  description = "PubSub subscription id to trigger this type of action"
  value       = module.executegfsdeleteolddocs.subscription_id
}

#splitexport
output "splitexport_service_account_email" {
  description = "Service account email used to run this microservice"
  value       = module.splitexport.service_account_email
}

output "splitexport_crun_service_id" {
  description = "cloud run service id"
  value       = module.splitexport.crun_service_id
}
output "splitexport_crun_service_url" {
  description = "cloud run service url"
  value       = module.splitexport.crun_service_url
}

output "splitexport_subscription_sa_email" {
  description = "Service account email used to trigger this type of action"
  value       = module.splitexport.subscription_sa_email
}
output "splitexport_subscription_id" {
  description = "PubSub subscription id to trigger this type of action"
  value       = module.splitexport.subscription_id
}

# publish2fs
output "publish2fs_service_account_email" {
  description = "Service account email used to run this microservice"
  value       = module.publish2fs.service_account_email
}

output "publish2fs_crun_service_id" {
  description = "cloud run service id"
  value       = module.publish2fs.crun_service_id
}
output "publish2fs_crun_service_url" {
  description = "cloud run service url"
  value       = module.publish2fs.crun_service_url
}

output "publish2fs_subscription_sa_email" {
  description = "Service account email used to trigger this type of action"
  value       = module.publish2fs.subscription_sa_email
}
output "publish2fs_subscription_id" {
  description = "PubSub subscription id to trigger this type of action"
  value       = module.publish2fs.subscription_id
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

#dashboard
output "dashboard_log_metric_count_critical_log_entries_id" {
  value = module.setdashboard.log_metric_count_critical_log_entries_id
}

output "dashboard_log_metric_count_error_log_entries_id" {
  value = module.setdashboard.log_metric_count_error_log_entries_id
}

output "dashboard_log_metric_count_max_request_timeout_error_id" {
  value = module.setdashboard.log_metric_count_max_request_timeout_error_id
}

output "log_metric_count_memory_limit_errors_id" {
  value = module.setdashboard.log_metric_count_memory_limit_errors_id
}
