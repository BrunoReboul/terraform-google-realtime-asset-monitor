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

data "google_secret_manager_secret_version_access" "ram_iap_client_id" {
  project = var.project_id
  secret  = "ram-iap-client-id"
}

data "google_secret_manager_secret_version_access" "ram_iap_client_secret" {
  project = var.project_id
  secret  = "ram-iap-client-secret"
}

resource "google_compute_security_policy" "cloud_armor_edge" {
  project = var.project_id
  name    = "cloud-armor-edge"
  type    = "CLOUD_ARMOR_EDGE"
}

resource "google_compute_security_policy" "cloud_armor" {
  project = var.project_id
  name    = "cloud-armor"
  type    = "CLOUD_ARMOR"
}


resource "google_storage_bucket" "static_public_web" {
  project       = var.project_id
  name          = "${var.project_id}${var.static_public_bucket_name_suffix}"
  location      = var.gcs_location
  storage_class = "COLDLINE"
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

resource "google_storage_bucket_object" "indexpage" {
  name         = "index.html"
  content      = "<html><body>Welcome to Real-time Asset Monitor, use <a href=\"https://${var.dns_name}/console\">/console</a> to get the console</body></html>"
  content_type = "text/html"
  bucket       = google_storage_bucket.static_public_web.id
}

resource "google_storage_bucket_object" "errorpage" {
  name         = "404.html"
  content      = "<html><body>404! Woops, the page your are trying to reach does not exist or you do not have access</body></html>"
  content_type = "text/html"
  bucket       = google_storage_bucket.static_public_web.id
}

resource "google_storage_bucket_object" "favicon" {
  name   = "favicon.ico"
  source = "${path.module}/favicon.ico"
  bucket = google_storage_bucket.static_public_web.id
}

resource "google_compute_backend_bucket" "static_public_content" {
  project              = var.project_id
  name                 = "static-public"
  description          = "Static public content, at least 404 not found page"
  bucket_name          = google_storage_bucket.static_public_web.name
  edge_security_policy = google_compute_security_policy.cloud_armor_edge.id
  enable_cdn           = false
}

resource "google_storage_bucket_iam_member" "public_rule" {
  bucket = google_storage_bucket.static_public_web.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_compute_region_network_endpoint_group" "results_neg" {
  project               = var.project_id
  name                  = "results-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    url_mask = "/<service>"
  }
}

resource "google_compute_backend_service" "results" {
  project = var.project_id
  name    = "results"
  log_config {
    enable      = true
    sample_rate = 1.0
  }
  backend {
    group = google_compute_region_network_endpoint_group.results_neg.id
  }
  iap {
    oauth2_client_id     = data.google_secret_manager_secret_version_access.ram_iap_client_id.secret_data
    oauth2_client_secret = data.google_secret_manager_secret_version_access.ram_iap_client_secret.secret
  }
  security_policy = google_compute_security_policy.cloud_armor.id
}

resource "google_compute_region_network_endpoint_group" "admin_neg" {
  project               = var.project_id
  name                  = "admin-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    url_mask = "/<service>"
  }
}

resource "google_compute_backend_service" "admin" {
  project = var.project_id
  name    = "admin"
  log_config {
    enable      = true
    sample_rate = 1.0
  }
  backend {
    group = google_compute_region_network_endpoint_group.admin_neg.id
  }
  iap {
    oauth2_client_id     = data.google_secret_manager_secret_version_access.ram_iap_client_id.secret_data
    oauth2_client_secret = data.google_secret_manager_secret_version_access.ram_iap_client_secret.secret_data
  }
  security_policy = google_compute_security_policy.cloud_armor.id
}

resource "google_compute_url_map" "ram_urlmap" {
  project         = var.project_id
  name            = "ram-urlmap"
  description     = "Real-time Asset Monitor URL map"
  default_service = google_compute_backend_bucket.static_public_content.id
  host_rule {
    hosts        = [var.dns_name]
    path_matcher = "ram"
  }
  path_matcher {
    name            = "ram"
    default_service = google_compute_backend_bucket.static_public_content.id
    path_rule {
      paths   = ["/console", "/console/*", "/consolebff/*", "/dashboards/*"]
      service = google_compute_backend_service.results.id
    }
    path_rule {
      paths   = ["/exemptions", "/exemptions/*", "/exemptionsbff/*"]
      service = google_compute_backend_service.admin.id
    }
  }
}

resource "google_compute_managed_ssl_certificate" "ram_ssl_certif" {
  project = var.project_id
  name    = "ram-ssl-certif"
  managed {
    domains = ["${var.dns_name}"]
  }
}

resource "google_compute_global_address" "ram_ext_ip" {
  project = var.project_id
  name    = "ram-ext-ip"
}

resource "google_compute_target_https_proxy" "ram_https_proxy" {
  project = var.project_id
  name    = "ram-https-proxy"
  url_map = google_compute_url_map.ram_urlmap.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.ram_ssl_certif.id
  ]
}

resource "google_compute_global_forwarding_rule" "ram_fwd_rule" {
  project    = var.project_id
  name       = "ram-fwd-rule"
  ip_address = google_compute_global_address.ram_ext_ip.address
  target     = google_compute_target_https_proxy.ram_https_proxy.id
  port_range = "443"
}
