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

output "subscription_sa_email" {
  description = "Service account email used to trigger this type of action"
  value       = google_service_account.subscription_sa.email
}
output "subscription_id" {
  description = "PubSub subscription id to trigger this type of action"
  value       = google_pubsub_subscription.subcription.id
}
