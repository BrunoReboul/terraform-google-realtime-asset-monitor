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

output "log_metric_count_critical_log_entries_id" {
  value = google_logging_metric.count_critical_log_entries.id
}

output "log_metric_count_error_log_entries_id" {
  value = google_logging_metric.count_error_log_entries.id
}

output "log_metric_count_max_request_timeout_error_id" {
  value = google_logging_metric.count_max_request_timeout_error.id
}

output "log_metric_count_memory_limit_errors_id" {
  value = google_logging_metric.count_memory_limit_errors.id
}
