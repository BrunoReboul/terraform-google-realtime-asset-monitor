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

output "service_account_email" {
  description = "Service account email used to run this microservice"
  value       = google_service_account.microservice_sa.email
}

output "crun_service_id" {
  description = "cloud run service id"
  value       = google_cloud_run_service.crun_svc.id
}
output "crun_service_url" {
  description = "cloud run service url"
  value       = google_cloud_run_service.crun_svc.status[0].url
}
output "trigger_service_account_email" {
  description = "Service account email used to trigger this microservice"
  value       = google_service_account.eva_trigger_sa.email
}
output "trigger_id_asset_feed" {
  description = "Evenarc asset feed trigger id"
  value       = google_eventarc_trigger.eva_trigger_asset_feed.id
}

output "trigger_subscription_name_asset_feed" {
  description = "Evenarc trigger asset feed subscription name"
  value       = google_eventarc_trigger.eva_trigger_asset_feed.transport[0].pubsub[0].subscription
}
output "trigger_id_compliance_status" {
  description = "Evenarc compliance status trigger id"
  value       = google_eventarc_trigger.eva_trigger_compliance_status.id
}

output "trigger_subscription_name_compliance_status" {
  description = "Evenarc trigger compliance status subscription name"
  value       = google_eventarc_trigger.eva_trigger_compliance_status.transport[0].pubsub[0].subscription
}

output "trigger_id_violation" {
  description = "Evenarc violation trigger id"
  value       = google_eventarc_trigger.eva_trigger_violation.id
}

output "trigger_subscription_name_violation" {
  description = "Evenarc trigger violation subscription name"
  value       = google_eventarc_trigger.eva_trigger_violation.transport[0].pubsub[0].subscription
}

output "ram_dataset_id" {
  value = google_bigquery_dataset.ram_dataset.dataset_id
}
