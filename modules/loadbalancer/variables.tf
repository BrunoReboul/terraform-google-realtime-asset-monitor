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

variable "region" {
  description = "gcp region"
  default     = "europe-west1"
  type        = string
}

variable "dns_name" {
  description = "The DNS name used to expose RAM e.g. ram.example.com"
  type        = string
}

variable "support_email" {
  description = "iap brand support email"
  type        = string
}

variable "gcs_location" {
  description = "Cloud Storage location"
  default     = "europe-west1"
  type        = string
}

variable "static_public_bucket_name_suffix" {
  description = "suffix to the bucketname hosting public static content"
  type        = string
}
