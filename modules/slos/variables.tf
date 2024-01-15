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
}

variable "notification_channels" {
  type = list(string)
}

variable "alerting_topic_name" {
  default = "alerting"
}

variable "pubsub_allowed_regions" {
  type = list(string)
}

variable "ram_e2e_latency" {
  type = map(any)
}

variable "log_metric_ram_execution_count_id" {
}

variable "log_metric_ram_execution_latency_e2e_id" {
}

variable "ram_availability" {
  description = "Critical User Journeys CUJs map crtical microservices"
  default = {
    microservice_list = [
      "launch",
      "execute",
      "splitexport",
      "convertfeed",
      "fetchrules",
      "monitor",
      "stream2bq",
      "publish2fs"
    ]
    goal                               = 0.999
    rolling_period_days                = 28
    alerting_fast_burn_loopback_period = "1h"
    alerting_fast_burn_threshold       = 10
    alerting_slow_burn_loopback_period = "24h"
    alerting_slow_burn_threshold       = 2
  }
}
