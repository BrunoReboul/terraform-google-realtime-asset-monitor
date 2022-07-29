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

variable "project_id" {
  description = "RAM GCP project id for a given environment, like dev or production"
}

variable "notification_channels" {
  type = list(string)
}

variable "cai_latency" {
  default = {
    real-time = {
      origin                             = "real-time"
      events                             = "changes"
      microservice_name                  = "convertfeed"
      status                             = "finish enrichCAIFeedMsg"
      threshold_str                      = "5.4min"
      threshold_value                    = 327.68
      goal                               = 0.95
      rolling_period_days                = 28
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    },
    batch = {
      origin                             = "scheduled"
      events                             = "exports"
      microservice_name                  = "splitexport"
      status                             = "finish splitToLines done|finish splitToChildExports done"
      threshold_str                      = "31min"
      threshold_value                    = 1853.638
      goal                               = 0.99
      rolling_period_days                = 28
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    }
  }
}
