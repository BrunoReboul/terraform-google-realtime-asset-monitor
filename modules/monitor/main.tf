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

resource "google_service_account" "microservice_sa" {
  project      = var.project_id
  account_id   = "monitor"
  display_name = "RAM monitor"
  description  = "Solution: Real-time Asset Monitor, microservice: monitor"
}

resource "google_pubsub_topic" "compliance_status" {
  project = var.project_id
  name    = var.compliance_status_topic_name
  message_storage_policy {
    allowed_persistence_regions = var.pubsub_allowed_regions
  }
}

resource "google_pubsub_topic_iam_member" "compliance_status_publisher" {
  project = google_pubsub_topic.compliance_status.project
  topic   = google_pubsub_topic.compliance_status.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_pubsub_topic" "violation" {
  project = var.project_id
  name    = var.violation_topic_name
  message_storage_policy {
    allowed_persistence_regions = var.pubsub_allowed_regions
  }
}

resource "google_pubsub_topic_iam_member" "violation_publisher" {
  project = google_pubsub_topic.violation.project
  topic   = google_pubsub_topic.violation.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.microservice_sa.email}"
}
