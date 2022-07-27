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

# service                            = "firestore.googleapis.com"
# method                             = "google.firestore.v1.Firestore.Commit"

variable "project_id" {
  description = "RAM GCP project id for a given environment, like dev or production"
}

variable "notification_channels" {
  type = list(string)
}

variable "availability" {
  description = "Critical User Journeys CUJs map crtical microservices"
  default = {
    # pubsub_publish = {
    #   rolling_period_days                = 28
    #   service                            = "pubsub.googleapis.com"
    #   method                             = "google.pubsub.v1.Publisher.Publish"
    #   goal                               = 0.999
    #   alerting_fast_burn_loopback_period = "1h"
    #   alerting_fast_burn_threshold       = 10
    #   alerting_slow_burn_loopback_period = "24h"
    #   alerting_slow_burn_threshold       = 2
    # },
    pubsub_publish = {
      rolling_period_days                = 28
      service                            = "bigquery.googleapis.com"
      method                             = "google.cloud.bigquery.v2.TableDataService.InsertAll"
      goal                               = 0.999
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    },
  }
}

variable "latency" {
  default = {
    pubsub_publish = {
      rolling_period_days                = 28
      service                            = "pubsub.googleapis.com"
      method                             = "google.pubsub.v1.Publisher.Publish"
      goal                               = 0.95
      threshold_str                      = "400ms"
      threshold_value                    = 0.4
      alerting_fast_burn_loopback_period = "1h"
      alerting_fast_burn_threshold       = 10
      alerting_slow_burn_loopback_period = "24h"
      alerting_slow_burn_threshold       = 2
    },
  }
}
