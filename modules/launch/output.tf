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

output "service_account_email" {
  description = "Service account email used to run this microservice"
  value       = google_service_account.microservice_sa.email
}

output "actions_repo_bucket_name" {
  description = "Cloud storage bucket to store scheduled action configurations"
  value       = google_storage_bucket.actions_repo.name
}

output "action_topic_id" {
  description = "action topic id"
  value       = google_pubsub_topic.action.id
}

output "action_trigger_topic_id" {
  description = "action trigger topic id"
  value       = google_pubsub_topic.action_trigger.id
}

output "job_ids" {
  description = "Cloud Scheduler job ids"
  value = toset([
    for job in google_cloud_scheduler_job.job : job.id
  ])
}

output "crun_service_id" {
  description = "cloud run service id"
  value       = google_cloud_run_v2_service.crun_svc.id
}
output "crun_service_url" {
  description = "cloud run service url"
  value       = google_cloud_run_v2_service.crun_svc.uri
}
output "trigger_service_account_email" {
  description = "Service account email used to trigger this microservice"
  value       = google_service_account.eva_trigger_sa.email
}
output "trigger_id" {
  description = "Eventarc trigger id"
  value       = google_eventarc_trigger.eva_trigger.id
}

output "trigger_subscription_name" {
  description = "Eventarc trigger subscription name"
  value       = google_eventarc_trigger.eva_trigger.transport[0].pubsub[0].subscription
}
