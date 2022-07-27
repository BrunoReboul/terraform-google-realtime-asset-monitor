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


output "transperent_slis_custom_service_display_name" {
  value = google_monitoring_custom_service.transperent_slis.display_name
}

output "transperent_slis_custom_service_id" {
  value = google_monitoring_custom_service.transperent_slis.id
}

output "transperent_slis_monitoring_slo_availability" {
  value = { for s in sort(keys(var.availability)) : s => google_monitoring_slo.availability[s].id }
}

output "transperent_slis_monitoring_slo_availability_fast_burn_alert" {
  value = { for s in sort(keys(var.availability)) : s => google_monitoring_alert_policy.availability_fast_burn[s].id }
}

output "transperent_slis_monitoring_slo_availability_slow_burn_alert" {
  value = { for s in sort(keys(var.availability)) : s => google_monitoring_alert_policy.availability_slow_burn[s].id }
}
