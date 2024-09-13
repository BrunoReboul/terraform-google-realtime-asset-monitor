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

variable "project_id" {
  description = "RAM GCP project id for a given environment, like dev or production"
  type        = string
}

variable "environment" {
  description = "environment name"
  type        = string
}

variable "bigquery_dataset_id" {
  description = "RAM Bigquery dataset id"
  type        = string
}

variable "crun_region" {
  description = "cloud run region"
  default     = "europe-west1"
  type        = string
}

variable "crun_cpu" {
  description = "Number of cpu in k8s quantity 1000m means 1000 millicpu aka 1"
  default     = "1000m"
  type        = string
}
variable "crun_concurrency" {
  description = "Number of requests a container could received at the same time"
  default     = 80
  type        = number
}

variable "crun_max_instances" {
  description = "Max number of instances"
  default     = 10
  type        = string
}

variable "crun_memory" {
  description = "Memory allocation in k8s quantity "
  default     = "128Mi"
  type        = string
}

variable "crun_timeout" {
  description = "Max duration for an instance for responding to a request"
  default     = "60s"
  type        = string
}

variable "ram_container_images_registry" {
  description = "artifact registry path"
  default     = "europe-docker.pkg.dev/brunore-ram-dev-100/realtime-asset-monitor"
  type        = string
}
variable "ram_microservice_image_tag" {
  description = "The container image tag for this microservice"
  default     = "latest"
  type        = string
}
variable "log_only_severity_levels" {
  description = "Which type of log entry should be logged"
  default     = "WARNING NOTICE CRITICAL"
  type        = string
}

variable "start_profiler" {
  description = "Continuous CPU and heap profiling in Cloud Profiler"
  default     = "false"
  type        = string
}

variable "audience_admin" {
  description = "the back end id is used by IAP as the audience string enabling to validate claims"
  type        = string
}

variable "audience_results" {
  description = "the back end id is used by IAP as the audience string enabling to validate claims"
  type        = string
}

variable "gcs_location" {
  description = "Cloud Storage location"
  default     = "europe-west1"
}