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


resource "google_monitoring_custom_service" "transparent_slis" {
  project      = var.project_id
  service_id   = "02-google-consumed-apis"
  display_name = "2 Dependency on Google APIs"
}

resource "google_monitoring_slo" "availability" {
  for_each            = var.availability
  project             = var.project_id
  service             = google_monitoring_custom_service.transparent_slis.service_id
  slo_id              = "tsli-${lower(replace(each.value.method, ".", "-"))}-availability"
  display_name        = "${lower(replace(each.value.method, ".", "-"))} availability: ${tostring(each.value.goal * 100)}% of responses over the last ${each.value.rolling_period_days} days should be served successfully"
  goal                = each.value.goal
  rolling_period_days = each.value.rolling_period_days
  request_based_sli {
    good_total_ratio {
      good_service_filter = "metric.type=\"serviceruntime.googleapis.com/api/request_count\" metric.label.response_code_class=\"2xx\" resource.labels.service=\"${each.value.service}\" resource.labels.method=\"${each.value.method}\" resource.type=\"consumed_api\" resource.label.\"project_id\"=\"${var.project_id}\""
      bad_service_filter  = "metric.type=\"serviceruntime.googleapis.com/api/request_count\" metric.label.response_code_class=\"5xx\" resource.labels.service=\"${each.value.service}\" resource.labels.method=\"${each.value.method}\" resource.type=\"consumed_api\" resource.label.\"project_id\"=\"${var.project_id}\""
    }
  }
}

resource "google_monitoring_alert_policy" "availability_fast_burn" {
  for_each     = var.availability
  project      = var.project_id
  display_name = "${lower(replace(each.value.method, ".", "-"))} availability burn rate last ${each.value.alerting_fast_burn_loopback_period} > ${each.value.alerting_fast_burn_threshold}"
  combiner     = "OR"
  conditions {
    display_name = "${lower(replace(each.value.method, ".", "-"))} availability burn rate last ${each.value.alerting_fast_burn_loopback_period} > ${each.value.alerting_fast_burn_threshold}"
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.availability[each.key].id}\", \"${each.value.alerting_fast_burn_loopback_period}\")"
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = each.value.alerting_fast_burn_threshold
      trigger {
        count = 1
      }
    }
  }
  notification_channels = var.notification_channels
}

resource "google_monitoring_alert_policy" "availability_slow_burn" {
  for_each     = var.availability
  project      = var.project_id
  display_name = "${lower(replace(each.value.method, ".", "-"))} availability burn rate last ${each.value.alerting_slow_burn_loopback_period} > ${each.value.alerting_slow_burn_threshold}"
  combiner     = "OR"
  conditions {
    display_name = "${lower(replace(each.value.method, ".", "-"))} availability burn rate last ${each.value.alerting_slow_burn_loopback_period} > ${each.value.alerting_slow_burn_threshold}"
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.availability[each.key].id}\", \"${each.value.alerting_slow_burn_loopback_period}\")"
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = each.value.alerting_slow_burn_threshold
      trigger {
        count = 1
      }
    }
  }
  notification_channels = var.notification_channels
}

resource "google_monitoring_dashboard" "availability_dashboard" {
  for_each       = var.availability
  project        = var.project_id
  dashboard_json = <<EOF
{
    "displayName": "slo_2_dependency_${lower(replace(each.value.method, ".", "-"))}-availability",
    "mosaicLayout": {
        "columns": 12,
        "tiles": [
            {
                "height": 20,
                "width": 12,
                "widget": {
                    "collapsibleGroup": {},
                    "title": "${tostring(each.value.goal * 100)}% of request over the last ${each.value.rolling_period_days} days should be served successfully"
                }
            },
            {
                "height": 4,
                "width": 12,
                "widget": {
                    "title": "How much of errbdg, as a fraction from - infinity to 1, remains at this time?",
                    "xyChart": {
                        "chartOptions": {
                            "mode": "COLOR"
                        },
                        "dataSets": [
                            {
                                "plotType": "LINE",
                                "targetAxis": "Y1",
                                "timeSeriesQuery": {
                                    "timeSeriesFilter": {
                                        "aggregation": {
                                            "perSeriesAligner": "ALIGN_NEXT_OLDER"
                                        },
                                        "filter": "select_slo_budget_fraction(\"${google_monitoring_slo.availability[each.key].id}\")"
                                    },
                                    "unitOverride": "10^2.%"
                                }
                            }
                        ],
                        "thresholds": [
                            {
                                "targetAxis": "Y1",
                                "value": 1,
                                "label": "100% means ErrBdg not used: Innovation at risk"
                            },
                            {
                                "targetAxis": "Y1",
                                "label": "0% means ErrBdg gone: Reliability at risk"
                            }                        ]
                    }
                }
            },
            {
                "height": 4,
                "width": 12,
                "yPos": 4,
                "widget": {
                    "title": "Error budget: number of bad events remaining vs target over the last ${each.value.rolling_period_days} days",
                    "xyChart": {
                        "chartOptions": {
                            "mode": "COLOR"
                        },
                        "dataSets": [
                            {
                                "minAlignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s",
                                "plotType": "LINE",
                                "legendTemplate": "Remaining bad events budget",
                                "targetAxis": "Y1",
                                "timeSeriesQuery": {
                                    "timeSeriesFilter": {
                                        "aggregation": {
                                            "alignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s"
                                        },
                                        "filter": "select_slo_budget(\"${google_monitoring_slo.availability[each.key].id}\")"
                                    }
                                }
                            },
                            {
                                "minAlignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s",
                                "plotType": "STACKED_AREA",
                                "legendTemplate": "Allowed bad events budget",
                                "targetAxis": "Y1",
                                "timeSeriesQuery": {
                                    "timeSeriesFilter": {
                                        "aggregation": {
                                            "alignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s"
                                        },
                                        "filter": "select_slo_budget_total(\"${google_monitoring_slo.availability[each.key].id}\")"
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
                }
            },
            {
                "height": 4,
                "width": 12,
                "yPos": 8,
                "widget": {
                    "title": "SLO vs SLI - Ratio of good events to good + bad events on the last ${each.value.rolling_period_days} days",
                    "xyChart": {
                        "chartOptions": {
                            "mode": "COLOR"
                        },
                        "dataSets": [
                            {
                                "plotType": "LINE",
                                "targetAxis": "Y1",
                                "timeSeriesQuery": {
                                    "timeSeriesFilter": {
                                        "aggregation": {
                                            "perSeriesAligner": "ALIGN_NEXT_OLDER"
                                        },
                                        "filter": "select_slo_compliance(\"${google_monitoring_slo.availability[each.key].id}\")"
                                    },
                                    "unitOverride": "10^2.%"
                                }
                            }
                        ],
                        "thresholds": [
                            {
                                "targetAxis": "Y1",
                                "value": ${each.value.goal}
                            }
                        ]
                    }
                }
            },
            {
                "height": 4,
                "width": 12,
                "yPos": 12,
                "widget": {
                    "title": "SLO vs SLI Ratio of good events to good + bad events on a short window",
                    "xyChart": {
                        "chartOptions": {
                            "mode": "COLOR"
                        },
                        "dataSets": [
                            {
                                "plotType": "LINE",
                                "targetAxis": "Y1",
                                "timeSeriesQuery": {
                                    "timeSeriesFilter": {
                                        "aggregation": {
                                            "perSeriesAligner": "ALIGN_MEAN"
                                        },
                                        "filter": "select_slo_health(\"${google_monitoring_slo.availability[each.key].id}\")"
                                    },
                                    "unitOverride": "10^2.%"
                                }
                            }
                        ],
                        "thresholds": [
                            {
                                "targetAxis": "Y1",
                                "value": ${each.value.goal}
                            }
                        ]
                    }
                }
            },
            {
                "height": 4,
                "width": 12,
                "yPos": 16,
                "widget": {
                    "title": "Count of good and bad events over the last ${each.value.rolling_period_days} days",
                    "xyChart": {
                        "chartOptions": {
                            "mode": "COLOR"
                        },
                        "dataSets": [
                            {
                                "minAlignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s",
                                "plotType": "LINE",
                                "targetAxis": "Y1",
                                "timeSeriesQuery": {
                                    "timeSeriesFilter": {
                                        "aggregation": {
                                            "alignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s",
                                            "perSeriesAligner": "ALIGN_SUM"
                                        },
                                        "filter": "select_slo_counts(\"${google_monitoring_slo.availability[each.key].id}\")"
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
                }
            }
        ]
    }
}
EOF
}

resource "google_monitoring_slo" "latency" {
  for_each            = var.latency
  project             = var.project_id
  service             = google_monitoring_custom_service.transparent_slis.service_id
  slo_id              = "tsli-${lower(replace(each.value.method, ".", "-"))}-latency"
  display_name        = "${lower(replace(each.value.method, ".", "-"))} latency: ${tostring(each.value.goal * 100)}% of responses over the last ${each.value.rolling_period_days} days should be served faster than ${each.value.threshold_str}"
  goal                = each.value.goal
  rolling_period_days = each.value.rolling_period_days
  request_based_sli {
    distribution_cut {
      distribution_filter = "metric.type=\"serviceruntime.googleapis.com/api/request_latencies\" resource.labels.service=\"${each.value.service}\" resource.labels.method=\"${each.value.method}\" resource.type=\"consumed_api\" resource.label.\"project_id\"=\"${var.project_id}\""
      range {
        max = each.value.threshold_value
      }
    }
  }
}

resource "google_monitoring_alert_policy" "latency_fast_burn" {
  for_each     = var.latency
  project      = var.project_id
  display_name = "${lower(replace(each.value.method, ".", "-"))} latency ${each.value.threshold_str} burn rate last ${each.value.alerting_fast_burn_loopback_period} > ${each.value.alerting_fast_burn_threshold}"
  combiner     = "OR"
  conditions {
    display_name = "${lower(replace(each.value.method, ".", "-"))} latency ${each.value.threshold_str} burn rate last ${each.value.alerting_fast_burn_loopback_period} > ${each.value.alerting_fast_burn_threshold}"
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.latency[each.key].id}\", \"${each.value.alerting_fast_burn_loopback_period}\")"
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = each.value.alerting_fast_burn_threshold
      trigger {
        count = 1
      }
    }
  }
  notification_channels = var.notification_channels
}

resource "google_monitoring_alert_policy" "latency_slow_burn" {
  for_each     = var.latency
  project      = var.project_id
  display_name = "${lower(replace(each.value.method, ".", "-"))} latency ${each.value.threshold_str} burn rate last ${each.value.alerting_slow_burn_loopback_period} > ${each.value.alerting_slow_burn_threshold}"
  combiner     = "OR"
  conditions {
    display_name = "${lower(replace(each.value.method, ".", "-"))} latency ${each.value.threshold_str} burn rate last ${each.value.alerting_slow_burn_loopback_period} > ${each.value.alerting_slow_burn_threshold}"
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.latency[each.key].id}\", \"${each.value.alerting_slow_burn_loopback_period}\")"
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = each.value.alerting_slow_burn_threshold
      trigger {
        count = 1
      }
    }
  }
  notification_channels = var.notification_channels
}

resource "google_monitoring_dashboard" "latency_dashboard" {
  for_each       = var.latency
  project        = var.project_id
  dashboard_json = <<EOF
{
    "displayName": "slo_2_dependency_${lower(replace(each.value.method, ".", "-"))}-latency ${each.value.threshold_str}",
    "mosaicLayout": {
        "columns": 12,
        "tiles": [
            {
                "height": 20,
                "width": 12,
                "widget": {
                    "collapsibleGroup": {},
                    "title": "${tostring(each.value.goal * 100)}% of request over the last ${each.value.rolling_period_days} days should be served faster than ${each.value.threshold_str}"
                }
            },
            {
                "height": 4,
                "width": 12,
                "widget": {
                    "title": "How much of errbdg, as a fraction from - infinity to 1, remains at this time?",
                    "xyChart": {
                        "chartOptions": {
                            "mode": "COLOR"
                        },
                        "dataSets": [
                            {
                                "plotType": "LINE",
                                "targetAxis": "Y1",
                                "timeSeriesQuery": {
                                    "timeSeriesFilter": {
                                        "aggregation": {
                                            "perSeriesAligner": "ALIGN_NEXT_OLDER"
                                        },
                                        "filter": "select_slo_budget_fraction(\"${google_monitoring_slo.latency[each.key].id}\")"
                                    },
                                    "unitOverride": "10^2.%"
                                }
                            }
                        ],
                        "thresholds": [
                            {
                                "targetAxis": "Y1",
                                "value": 1,
                                "label": "100% means ErrBdg not used: Innovation at risk"
                            },
                            {
                                "targetAxis": "Y1",
                                "label": "0% means ErrBdg gone: Reliability at risk"
                            }                        ]
                    }
                }
            },
            {
                "height": 4,
                "width": 12,
                "yPos": 4,
                "widget": {
                    "title": "Error budget: number of bad events remaining vs target over the last ${each.value.rolling_period_days} days",
                    "xyChart": {
                        "chartOptions": {
                            "mode": "COLOR"
                        },
                        "dataSets": [
                            {
                                "minAlignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s",
                                "plotType": "LINE",
                                "legendTemplate": "Remaining bad events budget",
                                "targetAxis": "Y1",
                                "timeSeriesQuery": {
                                    "timeSeriesFilter": {
                                        "aggregation": {
                                            "alignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s"
                                        },
                                        "filter": "select_slo_budget(\"${google_monitoring_slo.latency[each.key].id}\")"
                                    }
                                }
                            },
                            {
                                "minAlignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s",
                                "plotType": "STACKED_AREA",
                                "legendTemplate": "Allowed bad events budget",
                                "targetAxis": "Y1",
                                "timeSeriesQuery": {
                                    "timeSeriesFilter": {
                                        "aggregation": {
                                            "alignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s"
                                        },
                                        "filter": "select_slo_budget_total(\"${google_monitoring_slo.latency[each.key].id}\")"
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
                }
            },
            {
                "height": 4,
                "width": 12,
                "yPos": 8,
                "widget": {
                    "title": "SLO vs SLI - Ratio of good events to good + bad events on the last ${each.value.rolling_period_days} days",
                    "xyChart": {
                        "chartOptions": {
                            "mode": "COLOR"
                        },
                        "dataSets": [
                            {
                                "plotType": "LINE",
                                "targetAxis": "Y1",
                                "timeSeriesQuery": {
                                    "timeSeriesFilter": {
                                        "aggregation": {
                                            "perSeriesAligner": "ALIGN_NEXT_OLDER"
                                        },
                                        "filter": "select_slo_compliance(\"${google_monitoring_slo.latency[each.key].id}\")"
                                    },
                                    "unitOverride": "10^2.%"
                                }
                            }
                        ],
                        "thresholds": [
                            {
                                "targetAxis": "Y1",
                                "value": ${each.value.goal}
                            }
                        ]
                    }
                }
            },
            {
                "height": 4,
                "width": 12,
                "yPos": 12,
                "widget": {
                    "title": "SLO vs SLI Ratio of good events to good + bad events on a short window",
                    "xyChart": {
                        "chartOptions": {
                            "mode": "COLOR"
                        },
                        "dataSets": [
                            {
                                "plotType": "LINE",
                                "targetAxis": "Y1",
                                "timeSeriesQuery": {
                                    "timeSeriesFilter": {
                                        "aggregation": {
                                            "perSeriesAligner": "ALIGN_MEAN"
                                        },
                                        "filter": "select_slo_health(\"${google_monitoring_slo.latency[each.key].id}\")"
                                    },
                                    "unitOverride": "10^2.%"
                                }
                            }
                        ],
                        "thresholds": [
                            {
                                "targetAxis": "Y1",
                                "value": ${each.value.goal}
                            }
                        ]
                    }
                }
            },
            {
                "height": 4,
                "width": 12,
                "yPos": 16,
                "widget": {
                    "title": "Count of good and bad events over the last ${each.value.rolling_period_days} days",
                    "xyChart": {
                        "chartOptions": {
                            "mode": "COLOR"
                        },
                        "dataSets": [
                            {
                                "minAlignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s",
                                "plotType": "LINE",
                                "targetAxis": "Y1",
                                "timeSeriesQuery": {
                                    "timeSeriesFilter": {
                                        "aggregation": {
                                            "alignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s",
                                            "perSeriesAligner": "ALIGN_SUM"
                                        },
                                        "filter": "select_slo_counts(\"${google_monitoring_slo.latency[each.key].id}\")"
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
                }
            },
            {
                "height": 7,
                "width": 12,
                "yPos": 20,
                "widget": {
                    "title": "latency over the last ${each.value.rolling_period_days} days 50th 95th 99th",
                    "xyChart": {
                        "chartOptions": {
                            "mode": "COLOR"
                        },
                        "dataSets": [
                            {
                                "minAlignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s",
                                "plotType": "HEATMAP",
                                "targetAxis": "Y1",
                                "timeSeriesQuery": {
                                    "timeSeriesFilter": {
                                        "aggregation": {
                                            "alignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s",
                                            "crossSeriesReducer": "REDUCE_SUM",
                                            "perSeriesAligner": "ALIGN_DELTA"
                                        },
                                        "filter": "metric.type=\"serviceruntime.googleapis.com/api/request_latencies\" resource.labels.service=\"${each.value.service}\" resource.labels.method=\"${each.value.method}\" resource.type=\"consumed_api\" resource.label.\"project_id\"=\"${var.project_id}\"",
                                        "secondaryAggregation": {
                                            "alignmentPeriod": "${tostring(each.value.rolling_period_days * 24 * 60 * 60)}s"
                                        }
                                    }
                                }
                            }
                        ],
                        "timeshiftDuration": "0s",
                        "yAxis": {
                            "label": "y1Axis",
                            "scale": "LOG10"
                        }
                    }
                }
            }
        ]
    }
}
EOF
}
