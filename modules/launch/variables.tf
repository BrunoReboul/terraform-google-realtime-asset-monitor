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

variable "action_topic_name" {
  description = "the message body is the action to be executed"
  default     = "action"
  type        = string
}

variable "action_trigger_topic_name" {
  description = "the message body is the key used to fetch which actions to trigger"
  default     = "actionTrigger"
  type        = string
}

variable "pubsub_allowed_regions" {
  type = list(string)
}

variable "schedulers" {
  type = map(any)
  default = {
    prd_every_week = {
      "environment" = "prd",
      "name"        = "at_01am10_on_sunday",
      "schedule"    = "10 1 * * 0",
    },
    prd_every_3h = {
      "environment" = "prd",
      "name"        = "at_minute_0_past_every_3rd_hour",
      "schedule"    = "0 */3 * * *",
    },
    qa_every_year = {
      "environment" = "qa",
      "name"        = "at_00am00_on_day_of_month_1_in_january",
      "schedule"    = "0 0 1 1 *",
    },
    qa_every_3h = {
      "environment" = "qa",
      "name"        = "at_minute_0_past_every_3rd_hour",
      "schedule"    = "0 */3 * * *",
    },
  }
}

variable "scheduler_region" {
  description = "Cloud Scheduler region"
  default     = "europe-west1"
  type        = string
}

variable "gcs_location" {
  description = "Cloud Storage location"
  default     = "europe-west1"
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
  type        = number
}

variable "crun_memory" {
  description = "Memory allocation in k8s quantity "
  default     = "128Mi"
  type        = string
}

variable "crun_timeout" {
  description = "Max duration for an instance for responding to a request"
  default     = "180s"
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
