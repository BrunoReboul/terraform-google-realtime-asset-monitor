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

output "project_id" {
  value       = var.project_id
  description = "Project id"
}

output "convertfeed" {
  value = module.convertfeed
}

output "dashboards" {
  value = module.dashboards
}

output "deploy" {
  value = module.deploy
}

output "executecaiexport" {
  value = module.executecaiexport
}

output "executegfsdeleteolddocs" {
  value = module.executegfsdeleteolddocs
}

# output "feeds" {
#   value       = module.feeds
# }

output "fetchrules" {
  value = module.fetchrules
}

output "launch" {
  value = module.launch
}

output "metrics" {
  value = module.metrics
}

output "monitor" {
  value = module.monitor
}

output "publish2fs" {
  value = module.publish2fs
}

output "slos" {
  value = module.slos
}

output "slos_cai" {
  value = module.slos_cai
}

output "splitexport" {
  value = module.splitexport
}

output "stream2bq" {
  value = module.stream2bq
}

output "transparentslis" {
  value = module.transparentslis
}

output "upload2gcs" {
  value = module.upload2gcs
}

output "autofix" {
  value = module.autofix
}

output "autofixbqdsdelete" {
  value = module.autofixbqdsdelete
}
