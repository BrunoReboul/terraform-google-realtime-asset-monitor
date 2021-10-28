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

# # Retreive project setting form the projectId to get the project number
data "google_project" "project" {
  project_id = var.project_id
}

resource "google_pubsub_topic" "cai_feed" {
  project = var.project_id
  name    = var.cai_feed_topic_name
  message_storage_policy {
    allowed_persistence_regions = var.pubsub_allowed_regions
  }
}

# https://cloud.google.com/asset-inventory/docs/monitoring-asset-changes#before_you_begin
resource "google_pubsub_topic_iam_member" "cai_feed_publisher" {
  project = google_pubsub_topic.cai_feed.project
  topic   = google_pubsub_topic.cai_feed.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudasset.iam.gserviceaccount.com"
  # Wait for the fist org or folder feed to be created so the targeted Google service account is created
  depends_on = [
    google_cloud_asset_organization_feed.feed_iam_policy_org,
  ]
}

resource "google_cloud_asset_organization_feed" "feed_iam_policy_org" {
  for_each        = var.feed_iam_policy_orgs
  billing_project = var.project_id
  org_id          = each.key
  feed_id         = "ram-iam-policy"
  content_type    = "IAM_POLICY"
  asset_types     = each.value
  feed_output_config {
    pubsub_destination {
      topic = google_pubsub_topic.cai_feed.id
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
      topic = google_pubsub_topic.cai_feed.id
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
      topic = google_pubsub_topic.cai_feed.id
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
      topic = google_pubsub_topic.cai_feed.id
    }
  }
}

resource "google_cloud_asset_project_feed" "feed_iam_policy_project" {
  for_each     = var.feed_iam_policy_projects
  project      = each.key
  feed_id      = "ram-iam-policy"
  content_type = "IAM_POLICY"
  asset_types  = each.value
  feed_output_config {
    pubsub_destination {
      topic = google_pubsub_topic.cai_feed.id
    }
  }
  depends_on = [
    google_pubsub_topic_iam_member.cai_feed_publisher,
  ]
}

resource "google_cloud_asset_project_feed" "feed_resource_project" {
  for_each     = var.feed_resource_projects
  project      = each.key
  feed_id      = "ram-resource"
  content_type = "RESOURCE"
  asset_types  = each.value
  feed_output_config {
    pubsub_destination {
      topic = google_pubsub_topic.cai_feed.id
    }
  }
  depends_on = [
    google_pubsub_topic_iam_member.cai_feed_publisher,
  ]
}
