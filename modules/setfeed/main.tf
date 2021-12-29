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


resource "google_cloud_asset_organization_feed" "feed_iam_policy_org" {
  for_each        = var.feed_iam_policy_orgs
  billing_project = var.project_id
  org_id          = each.key
  feed_id         = "ram-iam-policy"
  content_type    = "IAM_POLICY"
  asset_types     = each.value
  feed_output_config {
    pubsub_destination {
      topic = var.cai_feed_topic_id
    }
  }
}

resource "google_cloud_asset_organization_feed" "feed_resource_org" {
  for_each        = var.feed_resource_orgs
  billing_project = var.project_id
  org_id          = each.key
  feed_id         = "ram-resource"
  content_type    = "RESOURCE"
  asset_types     = each.value
  feed_output_config {
    pubsub_destination {
      topic = var.cai_feed_topic_id
    }
  }
}

resource "google_cloud_asset_folder_feed" "feed_iam_policy_folder" {
  for_each        = var.feed_iam_policy_folders
  billing_project = var.project_id
  folder          = each.key
  feed_id         = "ram-iam-policy"
  content_type    = "IAM_POLICY"
  asset_types     = each.value
  feed_output_config {
    pubsub_destination {
      topic = var.cai_feed_topic_id
    }
  }
}

resource "google_cloud_asset_folder_feed" "feed_resource_folder" {
  for_each        = var.feed_resource_folders
  billing_project = var.project_id
  folder          = each.key
  feed_id         = "ram-resource"
  content_type    = "RESOURCE"
  asset_types     = each.value
  feed_output_config {
    pubsub_destination {
      topic = var.cai_feed_topic_id
    }
  }
}
