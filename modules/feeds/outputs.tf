/**
 * Copyright 2023 Google LLC
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

output "feed_iam_policy_org" {
  description = "cai feed for iam policies at organizations level"
  value       = google_cloud_asset_organization_feed.feed_iam_policy_org
}

output "feed_resource_org" {
  description = "cai feed for resource at organizations level"
  value       = google_cloud_asset_organization_feed.feed_resource_org
}

output "feed_iam_policy_folder" {
  description = "cai feed for iam policies at folders level"
  value       = google_cloud_asset_folder_feed.feed_iam_policy_folder
}

output "feed_resource_folder" {
  description = "cai feed for resource at folders level"
  value       = google_cloud_asset_folder_feed.feed_resource_folder
}


