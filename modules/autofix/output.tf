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

output "ram_autofix_tag_keys_id" {
  value = tomap({ for o in sort(var.autofix_org_ids) : o => google_tags_tag_key.autofix_key[o].id })
}

output "ram_autofix_bqdsdelete_tag_value_id" {
  value = tomap({ for o in sort(var.autofix_org_ids) : o => google_tags_tag_value.autofix_bqdsdelete_value[o].id })
}
