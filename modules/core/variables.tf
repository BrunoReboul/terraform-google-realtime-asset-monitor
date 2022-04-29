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


variable "project_id" {
  description = "GCP project id where to deploy RAM for a given environment, like test or production"
}

variable "ram_microservice_image_tag" {
  description = "The container image tag for this microservice"
  default     = "latest"
}

variable "log_only_severity_levels" {
  description = "Which type of log entry should be logged"
  default     = "WARNING NOTICE CRITICAL"
}

variable "pubsub_allowed_regions" {
  type    = list(string)
  default = ["europe-west1", "europe-west3", "europe-west4", "europe-north1", "europe-central2"]
}

variable "gcs_location" {
  description = "Cloud Storage location"
  default     = "europe-west1"
}

variable "crun_region" {
  description = "cloud run region"
  default     = "europe-west1"
}

variable "dataset_location" {
  description = "Bigquery dataset location"
  default     = "EU"
}

variable "views_interval_days" {
  description = "The sliding windows in days the view uses to get data. Should not be less than the batch cadence to export assets"
  default     = 28
}
