/**
 * Copyright 2023 Google LLC
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

output "ram_main_microservices" {
  value = google_monitoring_dashboard.ram_main_microservices.id
}

output "ram_gcpexport_microservices" {
  value = google_monitoring_dashboard.ram_gcpexport_microservices.id
}

output "ram_errors_in_log_entries" {
  value = google_monitoring_dashboard.ram_errors_in_log_entries.id
}

output "ram_daily_counts_top3_cost_drivers" {
  value = google_monitoring_dashboard.ram_daily_counts_top3_cost_drivers.id
}

output "ram_core_microservices_latency" {
  value = google_monitoring_dashboard.ram_core_microservices_latency.id
}

output "consumed_api_request_count" {
  value = google_monitoring_dashboard.consumed_api_request_count.id
}
