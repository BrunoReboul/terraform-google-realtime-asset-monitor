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
  description = "RAM GCP project id for a given environment, like dev or production"
}

variable "environment" {
  description = "environment name"
}

variable "asset_rule_topic_name" {
  description = "each message combines the data of one asset and the code of one complicance rule's"
  default     = "assetRule"
}

variable "pubsub_allowed_regions" {
  type = list(string)
}

variable "gcs_location" {
  description = "Cloud Storage location"
  default     = "europe-west1"
}

variable "crun_region" {
  description = "cloud run region"
  default     = "europe-west1"
}

variable "crun_cpu" {
  description = "Number of cpu in k8s quantity 1000m means 1000 millicpu aka 1"
  default     = "1000m"
}
variable "crun_concurrency" {
  description = "Number of requests a container could received at the same time"
  default     = 300
}

variable "crun_max_instances" {
  description = "Max number of instances"
  default     = 300
}

variable "crun_memory" {
  description = "Memory allocation in k8s quantity "
  default     = "256Mi"
}

variable "crun_timeout_seconds" {
  description = "Max duration for an instance for responding to a request"
  default     = 1800
}

variable "ram_container_images_registry" {
  description = "artifact registry path"
  default     = "europe-docker.pkg.dev/brunore-ram-dev-100/realtime-asset-monitor"
}
variable "ram_microservice_image_tag" {
  description = "The container image tag for this microservice"
  default     = "latest"
}

variable "rule_collection_id" {
  description = "firestore rule collection id"
  default     = "rules"
}
variable "cache_max_age_minutes" {
  description = "Duration in minutes after which the asset cache should be reloaded"
  default     = "60"
}
variable "log_only_severity_levels" {
  description = "Which type of log entry should be logged"
  default     = "WARNING NOTICE CRITICAL"
}

variable "start_profiler" {
  description = "Continuous CPU and heap profiling in Cloud Profiler"
  default     = "false"
}

variable "triggering_topic_id" {
  description = "Triggering topic e.g projects/PROJECT_ID/topics/TOPIC_NAME"
}

variable "sub_ack_deadline_seconds" {
  description = "The maximum time after a subscriber receives a message before the subscriber should acknowledge the message"
  default     = 260
}

variable "sub_message_retention_duration" {
  description = "How long to retain unacknowledged messages in the subscription's backlog,"
  default     = "86400s"
}

variable "sub_minimum_backoff" {
  description = "The minimum delay between consecutive deliveries of a given message"
  default     = "10s"
}
