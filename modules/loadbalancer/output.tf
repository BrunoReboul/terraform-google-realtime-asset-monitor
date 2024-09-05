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

output "external_ip_address" {
  description = "The external global IP address of the global external https load balancer "
  value       = google_compute_global_address.ram_ext_ip.address
}

output "audience_admin" {
  value = "/projects/${data.google_project.project.number}/global/backendServices/${google_compute_backend_service.admin.generated_id}"
}

output "audience_results" {
  value = "/projects/${data.google_project.project.number}/global/backendServices/${google_compute_backend_service.results.generated_id}"
}


output "admin_backend_name" {
  value = google_compute_backend_service.admin.name
}

output "results_backend_name" {
  value = google_compute_backend_service.results.name
}

# output "urlmap" {
#   value = google_compute_url_map.ram_urlmap
# }
