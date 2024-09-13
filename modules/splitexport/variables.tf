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

variable "exports_bucket_name" {
  description = "Cloud storage bucket where to output Cloud Asset Inventory exports"
  type        = string
}

variable "gcs_notif_export_topic_name" {
  description = "google cloud storage notification messages"
  default     = "gcsNotifExport"
  type        = string
}

variable "pubsub_allowed_regions" {
  type = list(string)
}

variable "sub_ack_deadline_seconds" {
  description = "The maximum time after a subscriber receives a message before the subscriber should acknowledge the message"
  default     = 600
  type        = number
}

variable "sub_message_retention_duration" {
  description = "How long to retain unacknowledged messages in the subscription's backlog,"
  default     = "86400s"
  type        = string
}

variable "sub_minimum_backoff" {
  description = "The minimum delay between consecutive deliveries of a given message"
  default     = "20s"
  type        = string
}

variable "cai_feed_topic_id" {
  description = "google cloud asset inventory feed messages"
  default     = "caiFeed"
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
  default     = 60
  type        = number
}

variable "crun_max_instances" {
  description = "Max number of instances"
  default     = 1000
  type        = number
}

variable "crun_memory" {
  description = "Memory allocation in k8s quantity "
  default     = "1Gi"
  type        = string
}

variable "crun_timeout" {
  description = "Max duration for an instance for responding to a request"
  default     = "3600s"
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
