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

resource "google_tags_tag_key" "autofix_key" {
  for_each    = toset(var.autofix_org_ids)
  parent      = "organizations/${each.key}"
  short_name  = "autofix"
  description = "Real-time Asset Monitor automatic remediation"
}

resource "google_tags_tag_value" "autofix_bqdsdelete_value" {
  for_each    = toset(var.autofix_org_ids)
  parent      = "tagKeys/${google_tags_tag_key.autofix_key[each.key].name}"
  short_name  = "bqdsdelete"
  description = "Real-time Asset Monitor delete Bigquery Dataset"
}
