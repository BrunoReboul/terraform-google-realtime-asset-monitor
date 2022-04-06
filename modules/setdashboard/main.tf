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

resource "google_logging_metric" "ram_latency" {
  project = var.project_id
  name    = "ram_latency"
  filter  = "resource.type=\"cloud_run_revision\" severity=\"NOTICE\" jsonPayload.message=~\"^finish\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DISTRIBUTION"
    unit        = "s"
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
  }
  value_extractor = "EXTRACT(jsonPayload.latency_seconds)"
  label_extractors = {
    "environment"       = "EXTRACT(jsonPayload.environment)"
    "microservice_name" = "EXTRACT(jsonPayload.microservice_name)"
    "origin"            = "EXTRACT(jsonPayload.assetInventoryOrigin)"
  }
  bucket_options {
    exponential_buckets {
      num_finite_buckets = 64
      growth_factor      = 1.4142135623731
      scale              = 0.01
    }
  }
}

resource "google_logging_metric" "ram_latency_e2e" {
  project = var.project_id
  name    = "ram_latency_e2e"
  filter  = "resource.type=\"cloud_run_revision\" severity=\"NOTICE\" jsonPayload.message=~\"^finish\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DISTRIBUTION"
    unit        = "s"
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
  }
  value_extractor = "EXTRACT(jsonPayload.latency_e2e_seconds)"
  label_extractors = {
    "environment"       = "EXTRACT(jsonPayload.environment)"
    "microservice_name" = "EXTRACT(jsonPayload.microservice_name)"
    "origin"            = "EXTRACT(jsonPayload.assetInventoryOrigin)"
  }
  bucket_options {
    exponential_buckets {
      num_finite_buckets = 64
      growth_factor      = 1.4142135623731
      scale              = 0.01
    }
  }
}

resource "google_monitoring_dashboard" "ram_main_microservices" {
  project        = var.project_id
  dashboard_json = <<EOF
{
  "category": "CUSTOM",
  "displayName": "ram_main_microservices",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "height": 4,
        "widget": {
          "title": "Instance Count for convertfeed [MAX]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MAX"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/instance_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"convertfeed\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "Instance Count for fetchrules [MAX]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MAX"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/instance_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"fetchrules\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "Instance Count for monitor [MAX]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MAX"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/instance_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"monitor\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "Request Count for convertfeed [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"convertfeed\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "Request Count for fetchrules [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"fetchrules\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "Request Count for monitor [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"monitor\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "CPU Utilization for convertfeed [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/cpu/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"convertfeed\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "CPU Utilization for fetchrules [SUM",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/cpu/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"fetchrules\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "CPU Utilization for monitor [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/cpu/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"monitor\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "CPU Utilization for stream2bq [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/cpu/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"stream2bq\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "Memory Utilization for convertfeed [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/memory/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"convertfeed\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "Memory Utilization for fetchrules [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/memory/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"fetchrules\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "Memory Utilization for monitor [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/memory/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"monitor\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "Memory Utilization for stream2bq [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/memory/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"stream2bq\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "Unacked messages for .*stream2bq.* [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MEAN"
                    },
                    "filter": "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" resource.type=\"pubsub_subscription\" resource.label.\"subscription_id\"=monitoring.regex.full_match(\".*stream2bq.*\")"
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "Max Concurrent Requests for active, convertfeed [50TH PERCENTILE]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "STACKED_AREA",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_PERCENTILE_50",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/max_request_concurrencies\" resource.type=\"cloud_run_revision\" metric.label.\"state\"=\"active\" resource.label.\"service_name\"=\"convertfeed\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "Unacked messages for .*convertfeed.* [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MEAN"
                    },
                    "filter": "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" resource.type=\"pubsub_subscription\" resource.label.\"subscription_id\"=monitoring.regex.full_match(\".*convertfeed.*\")"
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "Unacked messages for .*fetchrules.* [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MEAN"
                    },
                    "filter": "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" resource.type=\"pubsub_subscription\" resource.label.\"subscription_id\"=monitoring.regex.full_match(\".*fetchrules.*\")"
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "Max Concurrent Requests for active, fetchrules [50TH PERCENTILE]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "STACKED_AREA",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_PERCENTILE_50",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/max_request_concurrencies\" resource.type=\"cloud_run_revision\" metric.label.\"state\"=\"active\" resource.label.\"service_name\"=\"fetchrules\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "Max Concurrent Requests for active, monitor [50TH PERCENTILE]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "STACKED_AREA",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_PERCENTILE_50",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/max_request_concurrencies\" resource.type=\"cloud_run_revision\" metric.label.\"state\"=\"active\" resource.label.\"service_name\"=\"monitor\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "Unacked messages for .*monitor.* [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MEAN"
                    },
                    "filter": "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" resource.type=\"pubsub_subscription\" resource.label.\"subscription_id\"=monitoring.regex.full_match(\".*monitor.*\")"
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "Instance Count for stream2bq [MAX]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MAX"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/instance_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"stream2bq\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "Max Concurrent Requests for active, stream2bq [50TH PERCENTILE]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "STACKED_AREA",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_PERCENTILE_50",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/max_request_concurrencies\" resource.type=\"cloud_run_revision\" metric.label.\"state\"=\"active\" resource.label.\"service_name\"=\"stream2bq\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "Unacked messages for .*splitexport.* [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MEAN"
                    },
                    "filter": "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" resource.type=\"pubsub_subscription\" resource.label.\"subscription_id\"=monitoring.regex.full_match(\".*splitexport.*\")"
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "Request Count for splitexport [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"splitexport\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "Instance Count for splitexport [MAX]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MAX"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/instance_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"splitexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "Max Concurrent Requests for active, splitexport [50TH PERCENTILE]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "STACKED_AREA",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_PERCENTILE_50",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/max_request_concurrencies\" resource.type=\"cloud_run_revision\" metric.label.\"state\"=\"active\" resource.label.\"service_name\"=\"splitexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "Memory Utilization for splitexport [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/memory/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"splitexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "CPU Utilization for splitexport [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/cpu/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"splitexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "Unacked messages for .*publish2fs.* [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MEAN"
                    },
                    "filter": "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" resource.type=\"pubsub_subscription\" resource.label.\"subscription_id\"=monitoring.regex.full_match(\".*publish2fs.*\")"
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 20
      },
      {
        "height": 4,
        "widget": {
          "title": "Request Count for stream2bq [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"stream2bq\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "Request Count for publish2fs [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"publish2fs\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 20
      },
      {
        "height": 4,
        "widget": {
          "title": "Instance Count for publish2fs [MAX]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MAX"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/instance_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"publish2fs\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 20
      },
      {
        "height": 4,
        "widget": {
          "title": "Max Concurrent Requests for active, publish2fs [50TH PERCENTILE]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "STACKED_AREA",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_PERCENTILE_50",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/max_request_concurrencies\" resource.type=\"cloud_run_revision\" metric.label.\"state\"=\"active\" resource.label.\"service_name\"=\"publish2fs\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 20
      },
      {
        "height": 4,
        "widget": {
          "title": "Memory Utilization for publish2fs [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/memory/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"publish2fs\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 20
      },
      {
        "height": 4,
        "widget": {
          "title": "CPU Utilization for publish2fs [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/cpu/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"publish2fs\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 20
      }
    ]
  }
}

EOF
}

resource "google_monitoring_dashboard" "ram_gcpexport_microservices" {
  project        = var.project_id
  dashboard_json = <<EOF
{
  "category": "CUSTOM",
  "displayName": "ram_gcpexport_microservices",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "height": 4,
        "widget": {
          "title": "Instance Count for launch [MAX]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MAX"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/instance_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"launch\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "Instance Count for executecaiexport [MAX]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MAX"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/instance_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"executecaiexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "Instance Count for splitexport [MAX]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MAX"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/instance_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"splitexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "Instance Count for stream2bq [MAX]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MAX"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/instance_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"stream2bq\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "Request Count for launch [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"launch\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "Request Count for executecaiexport [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"executecaiexport\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "Request Count for splitexport [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"splitexport\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "Request Count for stream2bq [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "timeSeriesQueryLanguage": "fetch cloud_run_revision\n| metric 'run.googleapis.com/request_count'\n| filter (resource.service_name == 'stream2bq')\n| align rate(1m)\n| every 1m\n| group_by [], [value_request_count_mean: mean(value.request_count)]"
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "CPU Utilization for launch [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/cpu/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"launch\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "CPU Utilization for executecaiexport [SUM",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/cpu/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"executecaiexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "CPU Utilization for splitexport [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/cpu/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"splitexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "CPU Utilization for stream2bq [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/cpu/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"stream2bq\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "Memory Utilization for launch [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/memory/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"launch\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "Memory Utilization for executecaiexport [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/memory/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"executecaiexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "Memory Utilization for splitexport [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/memory/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"splitexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "Memory Utilization for stream2bq [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "groupByFields": [],
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/memory/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"stream2bq\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "Max Concurrent Requests for active, launch [50TH PERCENTILE]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "STACKED_AREA",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_PERCENTILE_50",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/max_request_concurrencies\" resource.type=\"cloud_run_revision\" metric.label.\"state\"=\"active\" resource.label.\"service_name\"=\"launch\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "Unacked messages for .*stream2bq.* [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MEAN"
                    },
                    "filter": "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" resource.type=\"pubsub_subscription\" resource.label.\"subscription_id\"=monitoring.regex.full_match(\".*stream2bq.*\")"
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "Unacked messages for .*splitexport.* [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MEAN"
                    },
                    "filter": "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" resource.type=\"pubsub_subscription\" resource.label.\"subscription_id\"=monitoring.regex.full_match(\".*splitexport.*\")"
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "Max Concurrent Requests for active, executecaiexport [50TH PERCENTILE]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "STACKED_AREA",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_PERCENTILE_50",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/max_request_concurrencies\" resource.type=\"cloud_run_revision\" metric.label.\"state\"=\"active\" resource.label.\"service_name\"=\"executecaiexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "Unacked messages for .*launch.* [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MEAN"
                    },
                    "filter": "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" resource.type=\"pubsub_subscription\" resource.label.\"subscription_id\"=monitoring.regex.full_match(\".*launch.*\")"
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "Unacked messages for .*caiexport.* [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MEAN"
                    },
                    "filter": "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" resource.type=\"pubsub_subscription\" resource.label.\"subscription_id\"=monitoring.regex.full_match(\".*caiexport.*\")"
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "Max Concurrent Requests for active, splitexport [50TH PERCENTILE]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "STACKED_AREA",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_PERCENTILE_50",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/max_request_concurrencies\" resource.type=\"cloud_run_revision\" metric.label.\"state\"=\"active\" resource.label.\"service_name\"=\"splitexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "Max Concurrent Requests for active, stream2bq [50TH PERCENTILE]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "STACKED_AREA",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_PERCENTILE_50",
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/max_request_concurrencies\" resource.type=\"cloud_run_revision\" metric.label.\"state\"=\"active\" resource.label.\"service_name\"=\"stream2bq\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "Unacked messages for .*executegfsdeleteolddocs.* [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MEAN"
                    },
                    "filter": "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" resource.type=\"pubsub_subscription\" resource.label.\"subscription_id\"=monitoring.regex.full_match(\".*executegfsdeleteolddocs.*\")",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    }
                  }
                }
              }
            ],
            "thresholds": [],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "Request Count for executegfsdeleteolddocs [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"executegfsdeleteolddocs\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "thresholds": [],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "Instance Count for executegfsdeleteolddocs [MAX]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_MAX"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/instance_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"executegfsdeleteolddocs\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    }
                  }
                }
              }
            ],
            "thresholds": [],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "Max Concurrent Requests for active, executegfsdeleteolddocs [50TH PERCENTILE]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "STACKED_AREA",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_PERCENTILE_50",
                      "groupByFields": [],
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/max_request_concurrencies\" resource.type=\"cloud_run_revision\" metric.label.\"state\"=\"active\" resource.label.\"service_name\"=\"executegfsdeleteolddocs\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    }
                  }
                }
              }
            ],
            "thresholds": [],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "Memory Utilization for executegfsdeleteolddocs [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "groupByFields": [],
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/memory/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"executegfsdeleteolddocs\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    }
                  }
                }
              }
            ],
            "thresholds": [],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "CPU Utilization for stream2bq [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "HEATMAP",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "groupByFields": [],
                      "perSeriesAligner": "ALIGN_DELTA"
                    },
                    "filter": "metric.type=\"run.googleapis.com/container/cpu/utilizations\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"stream2bq\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 16
      }
    ]
  }
}

EOF
}

resource "google_monitoring_dashboard" "ram_errors_in_log_entries" {
  depends_on = [
    google_logging_metric.count_critical_log_entries,
    google_logging_metric.count_error_log_entries,
    google_logging_metric.count_max_request_timeout_error,
    google_logging_metric.count_memory_limit_errors,
  ]
  project        = var.project_id
  dashboard_json = <<EOF
{
  "category": "CUSTOM",
  "displayName": "ram_errors_in_log_entries",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_critical_log_entries for noretry, convertfeed",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_critical_log_entries\" metric.label.\"type\"=\"noretry\" metric.label.\"microservice\"=\"convertfeed\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_critical_log_entries for retry, convertfeed",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_critical_log_entries\" metric.label.\"type\"=\"retry\" metric.label.\"microservice\"=\"convertfeed\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_memory_limit_errors for convertfeed",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_memory_limit_errors\" metric.label.\"microservice\"=\"convertfeed\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_max_request_timeout_error for convertfeed",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_max_request_timeout_error\" metric.label.\"microservice\"=\"convertfeed\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_error_log_entries for convertfeed by label.error_code [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "groupByFields": [
                        "metric.label.\"error_code\""
                      ],
                      "perSeriesAligner": "ALIGN_SUM"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_error_log_entries\" metric.label.\"microservice\"=\"convertfeed\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_critical_log_entries for noretry, fetchrules",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_critical_log_entries\" metric.label.\"type\"=\"noretry\" metric.label.\"microservice\"=\"fetchrules\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_memory_limit_errors for fetchrules",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_memory_limit_errors\" metric.label.\"microservice\"=\"fetchrules\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_max_request_timeout_error for fetchrules",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_max_request_timeout_error\" metric.label.\"microservice\"=\"fetchrules\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_error_log_entries for fetchrules [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "groupByFields": [
                        "metric.label.\"error_code\""
                      ],
                      "perSeriesAligner": "ALIGN_SUM"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_error_log_entries\" metric.label.\"microservice\"=\"fetchrules\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_critical_log_entries for retry, fetchrules",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_critical_log_entries\" metric.label.\"type\"=\"retry\" metric.label.\"microservice\"=\"fetchrules\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_critical_log_entries for noretry, monitor",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_critical_log_entries\" metric.label.\"type\"=\"noretry\" metric.label.\"microservice\"=\"monitor\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_memory_limit_errors for monitor",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_memory_limit_errors\" metric.label.\"microservice\"=\"monitor\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_max_request_timeout_error for monitor",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_max_request_timeout_error\" metric.label.\"microservice\"=\"monitor\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_error_log_entries for monitor [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "groupByFields": [
                        "metric.label.\"error_code\""
                      ],
                      "perSeriesAligner": "ALIGN_SUM"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_error_log_entries\" metric.label.\"microservice\"=\"monitor\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_critical_log_entries for retry, monitor",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_critical_log_entries\" metric.label.\"type\"=\"retry\" metric.label.\"microservice\"=\"monitor\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_critical_log_entries for noretry, stream2bq",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_critical_log_entries\" metric.label.\"type\"=\"noretry\" metric.label.\"microservice\"=\"stream2bq\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_memory_limit_errors for stream2bq",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_memory_limit_errors\" metric.label.\"microservice\"=\"stream2bq\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    }
                  }
                }
              }
            ],
            "thresholds": [],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_max_request_timeout_error for stream2bq",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_max_request_timeout_error\" metric.label.\"microservice\"=\"stream2bq\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_error_log_entries for stream2bq [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "groupByFields": [
                        "metric.label.\"error_code\""
                      ],
                      "perSeriesAligner": "ALIGN_SUM"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_error_log_entries\" metric.label.\"microservice\"=\"stream2bq\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_critical_log_entries for retry, stream2bq",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_critical_log_entries\" metric.label.\"type\"=\"retry\" metric.label.\"microservice\"=\"stream2bq\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "Request Count for convertfeed [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"convertfeed\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "Cloud Run Revision - Request Count for fetchrules [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"fetchrules\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "Cloud Run Revision - Request Count for monitor [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"monitor\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 12
      },
      {
        "height": 4,
        "widget": {
          "title": "Cloud Run Revision - Request Count for stream2bq [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"stream2bq\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 16
      },
      {
        "height": 4,
        "widget": {
          "title": "Cloud Run Revision - Request Count for splitexport [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"splitexport\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"response_code_class\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 0,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_critical_log_entries for noretry, splitexport",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_critical_log_entries\" metric.label.\"type\"=\"noretry\" metric.label.\"microservice\"=\"splitexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 2,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_memory_limit_errors for splitexport",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_memory_limit_errors\" metric.label.\"microservice\"=\"splitexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 4,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_max_request_timeout_error for splitexport",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_max_request_timeout_error\" metric.label.\"microservice\"=\"splitexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 6,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_error_log_entries for splitexport [SUM]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "groupByFields": [
                        "metric.label.\"error_code\""
                      ],
                      "perSeriesAligner": "ALIGN_SUM"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_error_log_entries\" metric.label.\"microservice\"=\"splitexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 8,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "title": "logging/user/count_critical_log_entries for retry, splitexport",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_NONE"
                    },
                    "filter": "metric.type=\"logging.googleapis.com/user/count_critical_log_entries\" metric.label.\"type\"=\"retry\" metric.label.\"microservice\"=\"splitexport\""
                  }
                }
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 2,
        "xPos": 10,
        "yPos": 0
      }
    ]
  }
}

EOF
}

resource "google_monitoring_dashboard" "daily_counts_top3_cost_drivers" {
  project        = var.project_id
  dashboard_json = <<EOF
{
  "category": "CUSTOM",
  "displayName": "daily_counts_top3_cost_drivers",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "height": 4,
        "widget": {
          "title": "CLOUD RUN Billable Instance Time",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "plotType": "STACKED_BAR",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "timeSeriesQueryLanguage": "fetch cloud_run_revision\n| metric 'run.googleapis.com/container/billable_instance_time'\n| align delta(1d)\n| every 1d\n| within 1d \n| group_by [resource.service_name]\n"
                }
              }
            ],
            "thresholds": [],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 12,
        "xPos": 0,
        "yPos": 8
      },
      {
        "height": 4,
        "widget": {
          "title": "LOG bytes ingested",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "plotType": "STACKED_BAR",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "timeSeriesQueryLanguage": "fetch global\n| metric 'logging.googleapis.com/billing/bytes_ingested'\n| align delta(1d)\n| every 1d\n| within 1d \n| group_by [metric.resource_type ]"
                }
              }
            ],
            "thresholds": [],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 12,
        "xPos": 0,
        "yPos": 4
      },
      {
        "height": 4,
        "widget": {
          "title": "FIRESTORE - Document Reads",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "plotType": "STACKED_BAR",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "timeSeriesQueryLanguage": "fetch firestore_instance\n| metric 'firestore.googleapis.com/document/read_count'\n| align delta(1d)\n| every 1d\n| within 1d \n| group_by [metric.type]\n"
                }
              }
            ],
            "thresholds": [],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 12,
        "xPos": 0,
        "yPos": 0
      }
    ]
  }
}

EOF
}

resource "google_monitoring_dashboard" "slo_freshness_gcp_batch" {
  depends_on = [
    google_logging_metric.ram_latency_e2e,
  ]
  project        = var.project_id
  dashboard_json = <<EOF
{
    "category": "CUSTOM",
    "displayName": "SLO freshness GCP batch",
    "mosaicLayout": {
      "columns": 12,
      "tiles": [
        {
          "height": 2,
          "widget": {
            "text": {
              "content": "**Freshness**: 99% of GCP configurations from batch flow over the last 28 days should be analyzed in less than 15 minutes.",
              "format": "MARKDOWN"
            },
            "title": "GCP batch 99% < 15 minutes"
          },
          "width": 4,
          "xPos": 0,
          "yPos": 0
        },
        {
          "height": 2,
          "widget": {
            "scorecard": {
              "gaugeView": {
                "lowerBound": 0.9,
                "upperBound": 1
              },
              "thresholds": [
                {
                  "color": "RED",
                  "direction": "BELOW",
                  "label": "",
                  "value": 0.99
                }
              ],
              "timeSeriesQuery": {
                "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n| filter metric.microservice_name == 'stream2bq'\n| filter metric.origin == 'scheduled'\n| align delta(28d)\n| every 28d\n| within 28d\n| group_by [metric.microservice_name]\n| fraction_less_than_from 900"
              }
            },
            "title": "SLI vs SLO"
          },
          "width": 3,
          "xPos": 4,
          "yPos": 0
        },
        {
          "height": 2,
          "widget": {
            "scorecard": {
              "thresholds": [
                {
                  "color": "YELLOW",
                  "direction": "BELOW",
                  "label": "",
                  "value": 0.1
                }
              ],
              "timeSeriesQuery": {
                "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n| filter metric.microservice_name == 'stream2bq'\n| filter metric.origin == 'scheduled'\n| align delta(28d)\n| every 28d\n| within 28d\n| group_by [metric.microservice_name]\n| fraction_less_than_from 900\n| neg\n| add 1\n| div 0.01\n| neg\n| add 1"
              }
            },
            "title": "Remaining ERROR BUDGET"
          },
          "width": 3,
          "xPos": 7,
          "yPos": 0
        },
        {
          "height": 2,
          "widget": {
            "scorecard": {
              "sparkChartView": {
                "sparkChartType": "SPARK_LINE"
              },
              "timeSeriesQuery": {
                "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n| filter metric.microservice_name == 'stream2bq'\n| filter metric.origin == 'scheduled'\n| align delta(28d)\n| every 28d\n| within 28d\n| group_by [metric.microservice_name]\n| count_from"
              }
            },
            "title": "Configurations analyzed in 28 days"
          },
          "width": 2,
          "xPos": 10,
          "yPos": 0
        },
        {
          "height": 9,
          "widget": {
            "title": "Last 28days heatmap",
            "xyChart": {
              "chartOptions": {
                "mode": "COLOR"
              },
              "dataSets": [
                {
                  "plotType": "HEATMAP",
                  "targetAxis": "Y1",
                  "timeSeriesQuery": {
                    "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n| filter (metric.microservice_name == 'stream2bq')\n| filter metric.origin == 'scheduled'\n| align delta(28d)\n| every 28d\n| within 28d\n| group_by [metric.microservice_name]\n| graph_period 28d"
                  }
                }
              ],
              "timeshiftDuration": "0s",
              "yAxis": {
                "label": "y1Axis",
                "scale": "LINEAR"
              }
            }
          },
          "width": 3,
          "xPos": 9,
          "yPos": 2
        },
        {
          "height": 3,
          "widget": {
            "title": "Error budget burnrate on 7d sliding windows - Email when > 1.5",
            "xyChart": {
              "chartOptions": {
                "mode": "COLOR"
              },
              "dataSets": [
                {
                  "plotType": "LINE",
                  "targetAxis": "Y1",
                  "timeSeriesQuery": {
                    "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n|filter metric.microservice_name == 'stream2bq'\n| filter metric.origin == 'scheduled'\n| align delta(1m)\n| every 1m\n| group_by [metric.microservice_name], sliding(7d)\n| fraction_less_than_from 900\n| neg\n| add 1\n| div 0.01\n| cast_units \"1\""
                  }
                }
              ],
              "thresholds": [
                {
                  "label": "",
                  "targetAxis": "Y1",
                  "value": 1.5
                }
              ],
              "timeshiftDuration": "0s",
              "yAxis": {
                "label": "y1Axis",
                "scale": "LINEAR"
              }
            }
          },
          "width": 9,
          "xPos": 0,
          "yPos": 2
        },
        {
          "height": 3,
          "widget": {
            "title": "Error budget burnrate on 12h sliding windows - Alert when > 3",
            "xyChart": {
              "chartOptions": {
                "mode": "COLOR"
              },
              "dataSets": [
                {
                  "plotType": "LINE",
                  "targetAxis": "Y1",
                  "timeSeriesQuery": {
                    "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n|filter metric.microservice_name == 'stream2bq'\n| filter metric.origin == 'scheduled'\n| align delta(1m)\n| every 1m\n| group_by [metric.microservice_name], sliding(12h)\n| fraction_less_than_from 900\n| neg\n| add 1\n| div 0.01\n| cast_units \"1\""
                  }
                }
              ],
              "thresholds": [
                {
                  "label": "",
                  "targetAxis": "Y1",
                  "value": 3
                }
              ],
              "timeshiftDuration": "0s",
              "yAxis": {
                "label": "y1Axis",
                "scale": "LINEAR"
              }
            }
          },
          "width": 9,
          "xPos": 0,
          "yPos": 5
        },
        {
          "height": 3,
          "widget": {
            "title": "Error budget burnrate on 1h sliding windows - Alert when > 9",
            "xyChart": {
              "chartOptions": {
                "mode": "COLOR"
              },
              "dataSets": [
                {
                  "plotType": "LINE",
                  "targetAxis": "Y1",
                  "timeSeriesQuery": {
                    "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n|filter metric.microservice_name == 'stream2bq'\n| filter metric.origin == 'scheduled'\n| align delta(1m)\n| every 1m\n| group_by [metric.microservice_name], sliding(1h)\n| fraction_less_than_from 900\n| neg\n| add 1\n| div 0.01\n| cast_units \"1\""
                  }
                }
              ],
              "thresholds": [
                {
                  "label": "",
                  "targetAxis": "Y1",
                  "value": 9
                }
              ],
              "timeshiftDuration": "0s",
              "yAxis": {
                "label": "y1Axis",
                "scale": "LINEAR"
              }
            }
          },
          "width": 9,
          "xPos": 0,
          "yPos": 8
        }
      ]
    }
}

EOF
}

resource "google_monitoring_dashboard" "slo_freshness_gcp_realtime" {
  depends_on = [
    google_logging_metric.ram_latency_e2e,
  ]
  project        = var.project_id
  dashboard_json = <<EOF
{
    "category": "CUSTOM",
    "displayName": "SLO freshness GCP real-time",
    "mosaicLayout": {
      "columns": 12,
      "tiles": [
        {
          "height": 2,
          "widget": {
            "text": {
              "content": "**Freshness**: 97% of GCP configurations from real-time flow over the last 28 days should be analyzed in less than 20 seconds.",
              "format": "MARKDOWN"
            },
            "title": "GCP real-time 97% < 20 seconds"
          },
          "width": 4,
          "xPos": 0,
          "yPos": 0
        },
        {
          "height": 2,
          "widget": {
            "scorecard": {
              "gaugeView": {
                "lowerBound": 0.9,
                "upperBound": 1
              },
              "thresholds": [
                {
                  "color": "RED",
                  "direction": "BELOW",
                  "label": "",
                  "value": 0.97
                }
              ],
              "timeSeriesQuery": {
                "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n| filter metric.microservice_name == 'stream2bq'\n| filter metric.origin == 'real-time'\n| align delta(28d)\n| every 28d\n| within 28d\n| group_by [metric.microservice_name]\n| fraction_less_than_from 20"
              }
            },
            "title": "SLI vs SLO"
          },
          "width": 3,
          "xPos": 4,
          "yPos": 0
        },
        {
          "height": 2,
          "widget": {
            "scorecard": {
              "thresholds": [
                {
                  "color": "YELLOW",
                  "direction": "BELOW",
                  "label": "",
                  "value": 0.1
                }
              ],
              "timeSeriesQuery": {
                "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n| filter metric.microservice_name == 'stream2bq'\n| filter metric.origin == 'real-time'\n| align delta(28d)\n| every 28d\n| within 28d\n| group_by [metric.microservice_name]\n| fraction_less_than_from 20\n| neg\n| add 1\n| div 0.03\n| neg\n| add 1"
              }
            },
            "title": "Remaining ERROR BUDGET"
          },
          "width": 3,
          "xPos": 7,
          "yPos": 0
        },
        {
          "height": 2,
          "widget": {
            "scorecard": {
              "sparkChartView": {
                "sparkChartType": "SPARK_LINE"
              },
              "timeSeriesQuery": {
                "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n| filter metric.microservice_name == 'stream2bq'\n| filter metric.origin == 'real-time'\n| align delta(28d)\n| every 28d\n| within 28d\n| group_by [metric.microservice_name]\n| count_from"
              }
            },
            "title": "Configurations analyzed in 28 days"
          },
          "width": 2,
          "xPos": 10,
          "yPos": 0
        },
        {
          "height": 9,
          "widget": {
            "title": "Last 28days heatmap",
            "xyChart": {
              "chartOptions": {
                "mode": "COLOR"
              },
              "dataSets": [
                {
                  "plotType": "HEATMAP",
                  "targetAxis": "Y1",
                  "timeSeriesQuery": {
                    "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n| filter (metric.microservice_name == 'stream2bq')\n| filter metric.origin == 'real-time'\n| align delta(28d)\n| every 28d\n| within 28d\n| group_by [metric.microservice_name]\n| graph_period 28d"
                  }
                }
              ],
              "timeshiftDuration": "0s",
              "yAxis": {
                "label": "y1Axis",
                "scale": "LINEAR"
              }
            }
          },
          "width": 3,
          "xPos": 9,
          "yPos": 2
        },
        {
          "height": 3,
          "widget": {
            "title": "Error budget burnrate on 7d sliding windows - Email when > 1.5",
            "xyChart": {
              "chartOptions": {
                "mode": "COLOR"
              },
              "dataSets": [
                {
                  "plotType": "LINE",
                  "targetAxis": "Y1",
                  "timeSeriesQuery": {
                    "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n|filter metric.microservice_name == 'stream2bq'\n| filter metric.origin == 'real-time'\n| align delta(1m)\n| every 1m\n| group_by [metric.microservice_name], sliding(7d)\n| fraction_less_than_from 20\n| neg\n| add 1\n| div 0.03\n| cast_units \"1\""
                  }
                }
              ],
              "thresholds": [
                {
                  "label": "",
                  "targetAxis": "Y1",
                  "value": 1.5
                }
              ],
              "timeshiftDuration": "0s",
              "yAxis": {
                "label": "y1Axis",
                "scale": "LINEAR"
              }
            }
          },
          "width": 9,
          "xPos": 0,
          "yPos": 2
        },
        {
          "height": 3,
          "widget": {
            "title": "Error budget burnrate on 12h sliding windows - Alert when > 3",
            "xyChart": {
              "chartOptions": {
                "mode": "COLOR"
              },
              "dataSets": [
                {
                  "plotType": "LINE",
                  "targetAxis": "Y1",
                  "timeSeriesQuery": {
                    "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n|filter metric.microservice_name == 'stream2bq'\n| filter metric.origin == 'real-time'\n| align delta(1m)\n| every 1m\n| group_by [metric.microservice_name], sliding(12h)\n| fraction_less_than_from 20\n| neg\n| add 1\n| div 0.03\n| cast_units \"1\""
                  }
                }
              ],
              "thresholds": [
                {
                  "label": "",
                  "targetAxis": "Y1",
                  "value": 3
                }
              ],
              "timeshiftDuration": "0s",
              "yAxis": {
                "label": "y1Axis",
                "scale": "LINEAR"
              }
            }
          },
          "width": 9,
          "xPos": 0,
          "yPos": 5
        },
        {
          "height": 3,
          "widget": {
            "title": "Error budget burnrate on 1h sliding windows - Alert when > 9",
            "xyChart": {
              "chartOptions": {
                "mode": "COLOR"
              },
              "dataSets": [
                {
                  "plotType": "LINE",
                  "targetAxis": "Y1",
                  "timeSeriesQuery": {
                    "timeSeriesQueryLanguage": "fetch cloud_run_revision::logging.googleapis.com/user/ram_latency_e2e\n|filter metric.microservice_name == 'stream2bq'\n| filter metric.origin == 'real-time'\n| align delta(1m)\n| every 1m\n| group_by [metric.microservice_name], sliding(1h)\n| fraction_less_than_from 20\n| neg\n| add 1\n| div 0.03\n| cast_units \"1\""
                  }
                }
              ],
              "thresholds": [
                {
                  "label": "",
                  "targetAxis": "Y1",
                  "value": 9
                }
              ],
              "timeshiftDuration": "0s",
              "yAxis": {
                "label": "y1Axis",
                "scale": "LINEAR"
              }
            }
          },
          "width": 9,
          "xPos": 0,
          "yPos": 8
        }
      ]
    }
}

EOF
}
