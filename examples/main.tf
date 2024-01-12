
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

terraform {
  backend "gcs" {
    bucket = "<yourTFstateBucket>"
    prefix = "<yourPrefix>"
  }
}

module "realtime-asset-monitor" {
  source                  = "BrunoReboul/realtime-asset-monitor/google"
  version                 = "<x.y.z>"
  project_id              = terraform.workspace == "prd" ? var.prd_project_id : var.qa_project_id
  feed_iam_policy_folders = var.feed_iam_policy_folders
  feed_iam_policy_orgs    = var.feed_iam_policy_orgs
  feed_resource_folders   = var.feed_resource_folders
  feed_resource_orgs      = var.feed_resource_orgs
}
