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

output "crun_service_id" {
  description = "cloud run service id"
  value       = google_cloud_run_v2_service.crun_svc.id
}
output "crun_service_url" {
  description = "cloud run service url"
  value       = google_cloud_run_v2_service.crun_svc.uri
}
output "subscription_sa_email" {
  description = "Service account email used to trigger this type of action"
  value       = google_service_account.subscription_sa.email
}
output "subscription_id_asset_feed" {
  description = "PubSub subscription id for asset feed"
  value       = google_pubsub_subscription.subcription_asset_feed.id
}
output "subscription_id_compliance_status" {
  description = "PubSub subscription id for compliance status"
  value       = google_pubsub_subscription.subcription_compliance_status.id
}
output "subscription_id_violation" {
  description = "PubSub subscription id for violation"
  value       = google_pubsub_subscription.subcription_violation.id
}

output "ram_dataset_id" {
  value = google_bigquery_dataset.ram_dataset.dataset_id
}

output "view_last_assets" {
  value = google_bigquery_table.last_assets.table_id
}

output "view_last_compliance_status" {
  value = google_bigquery_table.last_compliance_status.table_id
}

output "view_last_active_violations" {
  value = google_bigquery_table.active_violations.table_id
}
