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
  description = "GCP project id where to deploy RAM for a given environment, like test or production"
}

variable "compliance_status_topic_name" {
  description = "compliance status may be true for compliant or false for not compliant for a given asset version and configuration rule version"
  default     = "ram-complianceStatus"
}

variable "violation_topic_name" {
  description = "violations detail why an asset is not compliant to a configuration rule"
  default     = "ram-violation"
}

variable "asset_rule_topic_name" {
  description = "each message combines the data of one asset and the code of one complicance rule's"
  default     = "assetRule"
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
  default     = null
}

variable "feed_resource_orgs" {
  description = "For feed type RESOURCE, the map of monitored organizations and the targeted list assets for each. Can be empty"
  type        = map(list(string))
  default     = null
}

variable "feed_iam_policy_folders" {
  description = "For feed type IAM_POLICY, the map of monitored folders and the targeted list assets for each. Can be empty"
  type        = map(list(string))
  default     = null
}

variable "feed_resource_folders" {
  description = "For feed type RESOURCE, the map of monitored folders and the targeted list assets for each. Can be empty"
  type        = map(list(string))
  default     = null
}

variable "feed_iam_policy_projects" {
  description = "For feed type IAM_POLICY, the map of monitored projects and the targeted list assets for each. Can be empty"
  type        = map(list(string))
  default     = null
}

variable "feed_resource_projects" {
  description = "For feed type RESOURCE, the map of monitored projects and the targeted list assets for each. Can be empty"
  type        = map(list(string))
  default     = null
}

