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

variable "project_id" {
  description = "RAM GCP project id for a given environment, like dev or production"
}

variable "cai_feed_topic_name" {
  description = "google cloud asset inventory feed messages"
  default     = "caiFeed"
}

variable "pubsub_allowed_regions" {
  type    = list(string)
  default = ["europe-west1", "europe-west3", "europe-west4", "europe-north1", "europe-central2"]
}

variable "feed_iam_policy_orgs" {
  description = "For feed type IAM_POLICY, the map of monitored organizations and the targeted list assets for each. Can be empty"
  type        = map(list(string))
  default     = {}
}

variable "feed_resource_orgs" {
  description = "For feed type RESOURCE, the map of monitored organizations and the targeted list assets for each. Can be empty"
  type        = map(list(string))
  default     = {}
}

variable "feed_iam_policy_folders" {
  description = "For feed type IAM_POLICY, the map of monitored folders and the targeted list assets for each. Can be empty"
  type        = map(list(string))
  default     = {}
}

variable "feed_resource_folders" {
  description = "For feed type RESOURCE, the map of monitored folders and the targeted list assets for each. Can be empty"
  type        = map(list(string))
  default     = {}
}
