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

variable "trigger_export_topic_name" {
  description = "the message body is the key used to fetch which exports to trigger"
  default     = "exportTrigger"
}

variable "pubsub_allowed_regions" {
  type    = list(string)
  default = ["europe-west1", "europe-west3", "europe-west4", "europe-north1", "europe-central2"]
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
  }
}

variable "scheduler_region" {
  description = "Cloud Scheduler region"
  default     = "europe-west1"
}

variable "gcs_location" {
  description = "Cloud Storage location"
  default     = "europe-west1"
}

variable "export_org_ids" {
  description = "list of organization id where to grant Cloud Asset Inventory roles to allow export feature"
  type        = list(string)
}

variable "export_folder_ids" {
  description = "list of folder id where to grant Cloud Asset Inventory roles to allow export feature"
  type        = list(string)
}
