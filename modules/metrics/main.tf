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

resource "google_logging_metric" "count_critical_log_entries" {
  project = var.project_id
  name    = "count_critical_log_entries"
  filter  = "resource.type=\"cloud_run_revision\" severity=CRITICAL"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    labels {
      key         = "type"
      value_type  = "STRING"
      description = "retry or noretry types"
    }
    labels {
      key         = "microservice"
      value_type  = "STRING"
      description = "microservice name"
    }
  }
  label_extractors = {
    "type"         = "EXTRACT(jsonPayload.message)"
    "microservice" = "EXTRACT(jsonPayload.microservice_name)"
  }
}

resource "google_logging_metric" "count_error_log_entries" {
  project = var.project_id
  name    = "count_error_log_entries"
  filter  = "resource.type=\"cloud_run_revision\" severity=ERROR"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    labels {
      key         = "error_code"
      value_type  = "INT64"
      description = "retry or noretry types"
    }
    labels {
      key         = "microservice"
      value_type  = "STRING"
      description = "microservice name"
    }
  }
  label_extractors = {
    "error_code"   = "EXTRACT(httpRequest.status)"
    "microservice" = "EXTRACT(resource.labels.service_name)"
  }
}

resource "google_logging_metric" "count_max_request_timeout_error" {
  project = var.project_id
  name    = "count_max_request_timeout_error"
  filter  = "resource.type=\"cloud_run_revision\" severity=ERROR textPayload:\"maximum request timeout\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    labels {
      key         = "microservice"
      value_type  = "STRING"
      description = "microservice name"
    }
  }
  label_extractors = {
    "microservice" = "EXTRACT(resource.labels.service_name)"
  }
}

resource "google_logging_metric" "count_memory_limit_errors" {
  project = var.project_id
  name    = "count_memory_limit_errors"
  filter  = "resource.type=\"cloud_run_revision\" severity=ERROR textPayload:\"Memory limit\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    labels {
      key         = "microservice"
      value_type  = "STRING"
      description = "microservice name"
    }
  }
  label_extractors = {
    "microservice" = "EXTRACT(resource.labels.service_name)"
  }
}

resource "google_logging_metric" "ram_execution_count" {
  project = var.project_id
  name    = "ram_execution_count"
  filter  = "resource.type=\"cloud_run_revision\" log_name:\"logs/run.googleapis.com%2Fstderr\" severity=CRITICAL OR (severity=NOTICE AND jsonPayload.message:\"finish \")"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    labels {
      key         = "asset_type"
      value_type  = "STRING"
      description = "asset type, e.g. cloudfunctions.googleapis.com/CloudFunction"
    }
    labels {
      key         = "content_type"
      value_type  = "STRING"
      description = "content type, e.g. RESOURCES or IAM_POLICY"
    }
    labels {
      key         = "environment"
      value_type  = "STRING"
      description = "qa test prod ..."
    }
    labels {
      key         = "microservice_name"
      value_type  = "STRING"
      description = "convertfeed, fetchrules monitor stream2bq ..."
    }
    labels {
      key         = "origin"
      value_type  = "STRING"
      description = "real-time, sheduled ..."
    }
    labels {
      key         = "rule_name"
      value_type  = "STRING"
      description = "rule name, e.g. GCPCloudfunctionServiceaccountConstraintV1"
    }
    labels {
      key         = "status"
      value_type  = "STRING"
      description = "retry, noretry, or the finish action"
    }
  }
  label_extractors = {
    "asset_type"        = "EXTRACT(jsonPayload.assetType)"
    "content_type"      = "EXTRACT(jsonPayload.contentType)"
    "environment"       = "EXTRACT(jsonPayload.environment)"
    "microservice_name" = "EXTRACT(jsonPayload.microservice_name)"
    "origin"            = "EXTRACT(jsonPayload.assetInventoryOrigin)"
    "rule_name"         = "EXTRACT(jsonPayload.ruleName)"
    "status"            = "EXTRACT(jsonPayload.message)"
  }
}

resource "google_logging_metric" "ram_execution_latency" {
  project = var.project_id
  name    = "ram_execution_latency"
  filter  = "resource.type=\"cloud_run_revision\" severity=\"NOTICE\" jsonPayload.message=~\"^finish\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DISTRIBUTION"
    unit        = "s"
    labels {
      key         = "asset_type"
      value_type  = "STRING"
      description = "asset type, e.g. cloudfunctions.googleapis.com/CloudFunction"
    }
    labels {
      key         = "content_type"
      value_type  = "STRING"
      description = "content type, e.g. RESOURCES or IAM_POLICY"
    }
    labels {
      key         = "environment"
      value_type  = "STRING"
      description = "qa test prod ..."
    }
    labels {
      key         = "microservice_name"
      value_type  = "STRING"
      description = "convertfeed, fetchrules monitor stream2bq ..."
    }
    labels {
      key         = "origin"
      value_type  = "STRING"
      description = "real-time, sheduled ..."
    }
    labels {
      key         = "rule_name"
      value_type  = "STRING"
      description = "rule name, e.g. GCPCloudfunctionServiceaccountConstraintV1"
    }
    labels {
      key         = "status"
      value_type  = "STRING"
      description = "retry, noretry, or the finish action"
    }
  }
  value_extractor = "EXTRACT(jsonPayload.latency_seconds)"
  label_extractors = {
    "asset_type"        = "EXTRACT(jsonPayload.assetType)"
    "content_type"      = "EXTRACT(jsonPayload.contentType)"
    "environment"       = "EXTRACT(jsonPayload.environment)"
    "microservice_name" = "EXTRACT(jsonPayload.microservice_name)"
    "origin"            = "EXTRACT(jsonPayload.assetInventoryOrigin)"
    "rule_name"         = "EXTRACT(jsonPayload.ruleName)"
    "status"            = "EXTRACT(jsonPayload.message)"
  }
  bucket_options {
    exponential_buckets {
      num_finite_buckets = 64
      growth_factor      = 1.4142135623731
      scale              = 0.01
    }
  }
}

resource "google_logging_metric" "ram_execution_latency_e2e" {
  project = var.project_id
  name    = "ram_execution_latency_e2e"
  filter  = "resource.type=\"cloud_run_revision\" severity=\"NOTICE\" jsonPayload.message=~\"^finish\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DISTRIBUTION"
    unit        = "s"
    labels {
      key         = "asset_type"
      value_type  = "STRING"
      description = "asset type, e.g. cloudfunctions.googleapis.com/CloudFunction"
    }
    labels {
      key         = "content_type"
      value_type  = "STRING"
      description = "content type, e.g. RESOURCES or IAM_POLICY"
    }
    labels {
      key         = "environment"
      value_type  = "STRING"
      description = "qa test prod ..."
    }
    labels {
      key         = "microservice_name"
      value_type  = "STRING"
      description = "convertfeed, fetchrules monitor stream2bq ..."
    }
    labels {
      key         = "origin"
      value_type  = "STRING"
      description = "real-time, sheduled ..."
    }
    labels {
      key         = "rule_name"
      value_type  = "STRING"
      description = "rule name, e.g. GCPCloudfunctionServiceaccountConstraintV1"
    }
    labels {
      key         = "status"
      value_type  = "STRING"
      description = "retry, noretry, or the finish action"
    }
  }
  value_extractor = "EXTRACT(jsonPayload.latency_e2e_seconds)"
  label_extractors = {
    "asset_type"        = "EXTRACT(jsonPayload.assetType)"
    "content_type"      = "EXTRACT(jsonPayload.contentType)"
    "environment"       = "EXTRACT(jsonPayload.environment)"
    "microservice_name" = "EXTRACT(jsonPayload.microservice_name)"
    "origin"            = "EXTRACT(jsonPayload.assetInventoryOrigin)"
    "rule_name"         = "EXTRACT(jsonPayload.ruleName)"
    "status"            = "EXTRACT(jsonPayload.message)"
  }
  bucket_options {
    exponential_buckets {
      num_finite_buckets = 64
      growth_factor      = 1.4142135623731
      scale              = 0.01
    }
  }
}

resource "google_logging_metric" "ram_execution_latency_t2s" {
  project = var.project_id
  name    = "ram_execution_latency_t2s"
  filter  = "resource.type=\"cloud_run_revision\" severity=\"NOTICE\" jsonPayload.message=~\"^finish\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DISTRIBUTION"
    unit        = "s"
    labels {
      key         = "asset_type"
      value_type  = "STRING"
      description = "asset type, e.g. cloudfunctions.googleapis.com/CloudFunction"
    }
    labels {
      key         = "content_type"
      value_type  = "STRING"
      description = "content type, e.g. RESOURCES or IAM_POLICY"
    }
    labels {
      key         = "environment"
      value_type  = "STRING"
      description = "qa test prod ..."
    }
    labels {
      key         = "microservice_name"
      value_type  = "STRING"
      description = "convertfeed, fetchrules monitor stream2bq ..."
    }
    labels {
      key         = "origin"
      value_type  = "STRING"
      description = "real-time, sheduled ..."
    }
    labels {
      key         = "rule_name"
      value_type  = "STRING"
      description = "rule name, e.g. GCPCloudfunctionServiceaccountConstraintV1"
    }
    labels {
      key         = "status"
      value_type  = "STRING"
      description = "retry, noretry, or the finish action"
    }
    labels {
      key         = "step_stack_length"
      value_type  = "INT64"
      description = "step stack length"
    }
  }
  value_extractor = "EXTRACT(jsonPayload.latency_t2s_seconds)"
  label_extractors = {
    "asset_type"        = "EXTRACT(jsonPayload.assetType)"
    "content_type"      = "EXTRACT(jsonPayload.contentType)"
    "environment"       = "EXTRACT(jsonPayload.environment)"
    "microservice_name" = "EXTRACT(jsonPayload.microservice_name)"
    "origin"            = "EXTRACT(jsonPayload.assetInventoryOrigin)"
    "rule_name"         = "EXTRACT(jsonPayload.ruleName)"
    "status"            = "EXTRACT(jsonPayload.message)"
    "step_stack_length" = "EXTRACT(jsonPayload.step_stack_length)"
  }
  bucket_options {
    exponential_buckets {
      num_finite_buckets = 64
      growth_factor      = 1.4142135623731
      scale              = 0.01
    }
  }
}
