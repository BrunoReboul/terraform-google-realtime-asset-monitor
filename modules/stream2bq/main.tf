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

locals {
  service_name                 = "stream2bq"
  views_interval_days_extended = var.views_interval_days + 7
}

resource "google_service_account" "microservice_sa" {
  project      = var.project_id
  account_id   = local.service_name
  display_name = "RAM ${local.service_name}"
  description  = "Solution: Real-time Asset Monitor, microservice: ${local.service_name}"
}

resource "google_project_iam_member" "project_profiler_agent" {
  project = var.project_id
  role    = "roles/cloudprofiler.agent"
  member  = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_bigquery_dataset" "ram_dataset" {
  project       = var.project_id
  dataset_id    = var.dataset_name
  friendly_name = "real-time_asset_monitor"
  description   = "real-time_asset_monitor"
  location      = var.dataset_location
}

resource "google_bigquery_dataset_iam_member" "editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.ram_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.microservice_sa.email}"
}

resource "google_bigquery_table" "assets" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.ram_dataset.dataset_id
  table_id            = "assets"
  description         = "Real-time Asset Monitor - assets"
  deletion_protection = true

  time_partitioning {
    type          = "DAY"
    expiration_ms = var.bq_partition_expiration_ms
  }

  schema = <<EOF
[
    {
        "mode": "REQUIRED",
        "name": "timestamp",
        "type": "TIMESTAMP"
    },
    {
        "mode": "REQUIRED",
        "name": "name",
        "type": "STRING"
    },
    {
        "name": "owner",
        "type": "STRING"
    },
    {
        "name": "violationResolver",
        "type": "STRING"
    },
    {
        "name": "ancestryPathDisplayName",
        "type": "STRING"
    },
    {
        "name": "ancestryPath",
        "type": "STRING"
    },
    {
        "mode": "REPEATED",
        "name": "ancestorsDisplayName",
        "type": "STRING"
    },
    {
        "mode": "REPEATED",
        "name": "ancestors",
        "type": "STRING"
    },
    {
        "mode": "REQUIRED",
        "name": "assetType",
        "type": "STRING"
    },
    {
        "mode": "REQUIRED",
        "name": "deleted",
        "type": "BOOLEAN"
    },
    {
        "name": "projectID",
        "type": "STRING"
    },
    {
        "name": "persistTimestamp",
        "type": "TIMESTAMP"
    },
    {
        "name": "scheduledRootTriggeringID",
        "type": "STRING"
    }
]
EOF

}

resource "google_bigquery_table" "compliance_status" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.ram_dataset.dataset_id
  table_id            = "complianceStatus"
  description         = "Real-time Asset Monitor - complianceStatus"
  deletion_protection = true

  time_partitioning {
    type          = "DAY"
    expiration_ms = var.bq_partition_expiration_ms
  }

  schema = <<EOF
[
    {
        "mode": "REQUIRED",
        "name": "assetName",
        "type": "STRING"
    },
    {
        "mode": "NULLABLE",
        "name": "assetType",
        "type": "STRING"
    },
    {
        "description": "When the asset change was captured",
        "mode": "REQUIRED",
        "name": "assetInventoryTimeStamp",
        "type": "TIMESTAMP"
    },
    {
        "description": "Mean to capture the asset change: real-time or batch-export",
        "name": "assetInventoryOrigin",
        "type": "STRING"
    },
    {
        "mode": "REQUIRED",
        "name": "ruleName",
        "type": "STRING"
    },
    {
        "description": "When the rule was assessed",
        "mode": "REQUIRED",
        "name": "ruleDeploymentTimeStamp",
        "type": "TIMESTAMP"
    },
    {
        "mode": "REQUIRED",
        "name": "compliant",
        "type": "BOOLEAN"
    },
    {
        "mode": "REQUIRED",
        "name": "deleted",
        "type": "BOOLEAN"
    },
    {
        "description": "When the compliance rule was evaluated on the asset settings",
        "mode": "REQUIRED",
        "name": "evaluationTimeStamp",
        "type": "TIMESTAMP"
    },
    {
        "name": "scheduledRootTriggeringID",
        "type": "STRING"
    }
]
EOF

}

resource "google_bigquery_table" "violations" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.ram_dataset.dataset_id
  table_id            = "violations"
  description         = "Real-time Asset Monitor - violations"
  deletion_protection = true

  time_partitioning {
    type          = "DAY"
    expiration_ms = var.bq_partition_expiration_ms
  }

  schema = <<EOF
[
    {
        "description": "The violation information, aka why it is not compliant",
        "fields": [
            {
                "mode": "REQUIRED",
                "name": "message",
                "type": "STRING"
            },
            {
                "name": "metadata",
                "type": "STRING"
            },
            {
                "description": "When the compliance rule was evaluated on the asset settings",
                "mode": "REQUIRED",
                "name": "evaluationTimeStamp",
                "type": "TIMESTAMP"
            }
        ],
        "name": "nonCompliance",
        "type": "RECORD"
    },
    {
        "description": "The settings of the cloud function hosting the rule check",
        "fields": [
            {
                "mode": "REQUIRED",
                "name": "functionName",
                "type": "STRING"
            },
            {
                "mode": "REQUIRED",
                "name": "deploymentTime",
                "type": "TIMESTAMP"
            },
            {
                "name": "projectID",
                "type": "STRING"
            },
            {
                "name": "environment",
                "type": "STRING"
            }
        ],
        "name": "functionConfig",
        "type": "RECORD"
    },
    {
        "description": "The settings of the constraint used in conjonction with the rego template to assess the rule",
        "fields": [
            {
                "name": "kind",
                "type": "STRING"
            },
            {
                "fields": [
                    {
                        "name": "name",
                        "type": "STRING"
                    },
                    {
                        "name": "annotations",
                        "type": "STRING"
                    }
                ],
                "name": "metadata",
                "type": "RECORD"
            },
            {
                "fields": [
                    {
                        "name": "severity",
                        "type": "STRING"
                    },
                    {
                        "name": "match",
                        "type": "STRING"
                    },
                    {
                        "name": "parameters",
                        "type": "STRING"
                    }
                ],
                "name": "spec",
                "type": "RECORD"
            }
        ],
        "name": "constraintConfig",
        "type": "RECORD"
    },
    {
        "description": "The message from Cloud Asset Inventory in realtime or from split dump in batch",
        "fields": [
            {
                "fields": [
                    {
                        "mode": "REQUIRED",
                        "name": "name",
                        "type": "STRING"
                    },
                    {
                        "name": "owner",
                        "type": "STRING"
                    },
                    {
                        "name": "violationResolver",
                        "type": "STRING"
                    },
                    {
                        "name": "ancestryPathDisplayName",
                        "type": "STRING"
                    },
                    {
                        "name": "ancestryPath",
                        "type": "STRING"
                    },
                    {
                        "name": "ancestorsDisplayName",
                        "type": "STRING"
                    },
                    {
                        "name": "ancestors",
                        "type": "STRING"
                    },
                    {
                        "mode": "REQUIRED",
                        "name": "assetType",
                        "type": "STRING"
                    },
                    {
                        "name": "iamPolicy",
                        "type": "STRING"
                    },
                    {
                        "name": "resource",
                        "type": "STRING"
                    },
                    {
                        "name": "updateTime",
                        "type": "TIMESTAMP"
                    },
                    {
                        "name": "scheduledRootTriggeringID",
                        "type": "STRING"
                    }
                ],
                "name": "asset",
                "type": "RECORD"
            },
            {
                "fields": [
                    {
                        "mode": "REQUIRED",
                        "name": "startTime",
                        "type": "TIMESTAMP"
                    }
                ],
                "name": "window",
                "type": "RECORD"
            },
            {
                "name": "origin",
                "type": "STRING"
            }
        ],
        "name": "feedMessage",
        "type": "RECORD"
    },
    {
        "description": "The rego code, including the rule template used to assess the rule as a JSON document",
        "name": "regoModules",
        "type": "STRING"
    }
]
EOF

}

resource "google_bigquery_table" "last_assets" {
  project     = var.project_id
  dataset_id  = google_bigquery_dataset.ram_dataset.dataset_id
  table_id    = "last_assets"
  description = "Real-time Asset Monitor - last_assets"
  view {
    use_legacy_sql = false
    query          = <<EOF
WITH scoped_assets AS (
    SELECT
        *
    FROM
        `${var.project_id}.${google_bigquery_dataset.ram_dataset.dataset_id}.${google_bigquery_table.assets.table_id}`
    WHERE
        DATE(_PARTITIONTIME) > DATE_SUB(CURRENT_DATE(), INTERVAL ${var.views_interval_days} DAY)
        OR _PARTITIONTIME IS NULL
),
old AS (
    SELECT
        scoped_assets.*,
        0 AS change
    FROM
        scoped_assets
    WHERE
        persistTimeStamp IS NULL
),
old_dedup_and_more_details AS (
    SELECT
        timestamp,
        name,
        MAX(owner) AS owner,
        MAX(violationResolver) AS violationResolver,
        ancestryPathDisplayName,
        ancestryPath,
        TO_JSON_STRING(ancestorsDisplayName) AS j_ancestorsDisplayName,
        TO_JSON_STRING(ancestors) AS j_ancestors,
        assetType,
        deleted,
        projectID,
        persistTimeStamp,
        scheduledRootTriggeringID,
        change
    FROM
        old
    GROUP BY
        timestamp,
        name,
        ancestryPathDisplayName,
        ancestryPath,
        j_ancestorsDisplayName,
        j_ancestors,
        assetType,
        deleted,
        projectID,
        persistTimeStamp,
        scheduledRootTriggeringID,
        change
),
old_most_recent AS (
    SELECT
        name,
        MAX(timestamp) AS timestamp
    FROM
        old_dedup_and_more_details
    GROUP BY
        name
    ORDER BY
        name
),
old_last_assets AS (
    SELECT
        old_dedup_and_more_details.timestamp,
        old_dedup_and_more_details.name,
        old_dedup_and_more_details.owner,
        old_dedup_and_more_details.violationResolver,
        old_dedup_and_more_details.ancestryPathDisplayName,
        old_dedup_and_more_details.ancestryPath,
        JSON_QUERY_ARRAY(
            old_dedup_and_more_details.j_ancestorsDisplayName
        ) AS ancestorsDisplayName,
        JSON_QUERY_ARRAY(old_dedup_and_more_details.j_ancestors) AS ancestors,
        old_dedup_and_more_details.assetType,
        old_dedup_and_more_details.deleted,
        old_dedup_and_more_details.projectID,
        old_dedup_and_more_details.persistTimeStamp,
        old_dedup_and_more_details.scheduledRootTriggeringID,
        old_dedup_and_more_details.change
    FROM
        old_dedup_and_more_details
        INNER JOIN old_most_recent ON old_dedup_and_more_details.name = old_most_recent.name
        AND old_dedup_and_more_details.timestamp = old_most_recent.timestamp
),
wpts AS (
    SELECT
        scoped_assets.*,
        1 AS change
    FROM
        scoped_assets
    WHERE
        persistTimeStamp IS NOT NULL
),
wpts_most_recent AS (
    SELECT
        name,
        array_agg(
            struct(timeStamp, persistTimeStamp)
            order by
                timeStamp desc,
                persistTimeStamp desc
        ) [offset(0)] as tms
    FROM
        wpts
    GROUP BY
        name
    ORDER BY
        name
),
wpts_last_assets AS (
    SELECT
        wpts.*
    FROM
        wpts
        INNER JOIN wpts_most_recent ON wpts.name = wpts_most_recent.name
        AND wpts.timestamp = wpts_most_recent.tms.timestamp
        AND wpts.persistTimeStamp = wpts_most_recent.tms.persistTimeStamp
),
old_union_new_last_assets AS (
    SELECT
        *
    FROM
        old_last_assets
    UNION
    ALL
    SELECT
        *
    FROM
        wpts_last_assets
),
prefer_new AS (
    SELECT
        name,
        MAX(change) AS change
    FROM
        old_union_new_last_assets
    GROUP BY
        name
)
SELECT
    timestamp,
    old_union_new_last_assets.name,
    owner,
    violationResolver,
    ancestryPathDisplayName,
    ancestryPath,
    ancestorsDisplayName,
    ancestors,
    assetType,
    deleted,
    projectID,
    IF(
        persistTimeStamp IS NULL,
        timeStamp,
        persistTimeStamp
    ) AS persistTimeStamp,
    scheduledRootTriggeringID
FROM
    old_union_new_last_assets
    INNER JOIN prefer_new ON prefer_new.name = old_union_new_last_assets.name
    AND prefer_new.change = old_union_new_last_assets.change
EOF
  }
}

resource "google_bigquery_table" "last_compliance_status" {
  project     = var.project_id
  dataset_id  = google_bigquery_dataset.ram_dataset.dataset_id
  table_id    = "last_compliancestatus"
  description = "Real-time Asset Monitor - last_compliancestatus"
  view {
    use_legacy_sql = false
    query          = <<EOF
WITH last_x_days_complianceStatus AS (
    SELECT
        *
    FROM
        `${var.project_id}.${google_bigquery_dataset.ram_dataset.dataset_id}.${google_bigquery_table.compliance_status.table_id}`
    WHERE
        DATE(_PARTITIONTIME) > DATE_SUB(CURRENT_DATE(), INTERVAL ${var.views_interval_days} DAY)
        OR _PARTITIONTIME IS NULL
),
assets AS (
    SELECT
        timestamp,
        name,
        owner,
        violationResolver,
        ancestryPathDisplayName,
        ancestryPath,
        ancestorsDisplayName,
        ancestors,
        assetType,
        projectID,
        persistTimeStamp,
        scheduledRootTriggeringID
    FROM
        `${var.project_id}.${google_bigquery_dataset.ram_dataset.dataset_id}.${google_bigquery_table.last_assets.table_id}`
),
latest_asset_inventory_per_rule AS (
    SELECT
        assetName,
        ruleName,
        array_agg(
            struct(assetInventoryTimeStamp, evaluationTimeStamp)
            order by
                assetInventoryTimeStamp desc,
                evaluationTimeStamp desc
        ) [offset(0)] as tms
    FROM
        `${var.project_id}.${google_bigquery_dataset.ram_dataset.dataset_id}.${google_bigquery_table.compliance_status.table_id}`
    WHERE
        DATE(_PARTITIONTIME) > DATE_SUB(CURRENT_DATE(), INTERVAL ${local.views_interval_days_extended} DAY)
        OR _PARTITIONTIME IS NULL
    GROUP BY
        assetName,
        ruleName
    ORDER BY
        assetName,
        ruleName
),
latest_rules AS (
    SELECT
        ruleName,
        MAX(ruleDeploymentTimeStamp) AS ruleDeploymentTimeStamp
    FROM
        last_x_days_complianceStatus
    GROUP BY
        ruleName
    ORDER BY
        ruleName
),
status_for_latest_rules AS (
    SELECT
        last_x_days_complianceStatus.*
    FROM
        latest_rules
        INNER JOIN last_x_days_complianceStatus ON last_x_days_complianceStatus.ruleName = latest_rules.ruleName
        AND last_x_days_complianceStatus.ruleDeploymentTimeStamp = latest_rules.ruleDeploymentTimeStamp
),
lastrule_lastasset_compliancestatus AS (
    SELECT
        status_for_latest_rules.evaluationTimeStamp,
        status_for_latest_rules.ruleName,
        REPLACE(
            SPLIT(
                REPLACE(status_for_latest_rules.assetName, "//", ""),
                "/"
            ) [SAFE_OFFSET(0)],
            ".googleapis.com",
            ""
        ) AS serviceName,
        status_for_latest_rules.ruleDeploymentTimeStamp,
        status_for_latest_rules.compliant,
        status_for_latest_rules.assetName,
        status_for_latest_rules.assetInventoryTimeStamp,
        status_for_latest_rules.scheduledRootTriggeringID,
        IF(
            SPLIT(status_for_latest_rules.assetName, "/") [SAFE_OFFSET(2)] = "directories",
            CONCAT(
                SPLIT(status_for_latest_rules.assetName, "/") [SAFE_OFFSET(2)],
                "/",
                SPLIT(status_for_latest_rules.assetName, "/") [SAFE_OFFSET(3)]
            ),
            NULL
        ) AS directoryPath,
        IF(
            SPLIT(status_for_latest_rules.assetName, "/") [SAFE_OFFSET(2)] = "directories",
            CASE
                SPLIT(status_for_latest_rules.assetName, "/") [SAFE_OFFSET(6)]
                WHEN "members" THEN "www.googleapis.com/admin/directory/members"
                WHEN "groupSettings" THEN "groupssettings.googleapis.com/groupSettings"
                ELSE NULL
            END,
            NULL
        ) AS directoryAssetType,
    FROM
        latest_asset_inventory_per_rule
        INNER JOIN status_for_latest_rules ON status_for_latest_rules.assetName = latest_asset_inventory_per_rule.assetName
        AND status_for_latest_rules.ruleName = latest_asset_inventory_per_rule.ruleName
        AND status_for_latest_rules.evaluationTimeStamp = latest_asset_inventory_per_rule.tms.evaluationTimeStamp
    WHERE
        status_for_latest_rules.deleted = FALSE
),
enriched_compliancestatus AS (
    SELECT
        lastrule_lastasset_compliancestatus.ruleName,
        lastrule_lastasset_compliancestatus.serviceName,
        REPLACE(
            REPLACE(
                REPLACE(
                    lastrule_lastasset_compliancestatus.ruleName,
                    "ConstraintV1",
                    ""
                ),
                "GCP",
                ""
            ),
            "CI",
            ""
        ) AS ruleNameShort,
        lastrule_lastasset_compliancestatus.ruleDeploymentTimeStamp,
        lastrule_lastasset_compliancestatus.compliant,
        NOT lastrule_lastasset_compliancestatus.compliant AS notCompliant,
        lastrule_lastasset_compliancestatus.assetName,
        lastrule_lastasset_compliancestatus.assetInventoryTimeStamp,
        lastrule_lastasset_compliancestatus.evaluationTimeStamp,
        lastrule_lastasset_compliancestatus.scheduledRootTriggeringID,
        assets.owner,
        assets.violationResolver,
        IFNULL(
            assets.ancestryPath,
            lastrule_lastasset_compliancestatus.directoryPath
        ) AS ancestryPath,
        IFNULL(
            assets.ancestryPathDisplayName,
            IFNULL(
                assets.ancestryPath,
                lastrule_lastasset_compliancestatus.directoryPath
            )
        ) AS ancestryPathDisplayName,
        IF(
            ARRAY_LENGTH(assets.ancestorsDisplayName) > 0,
            assets.ancestorsDisplayName,
            assets.ancestors
        ) AS ancestorsDisplayName,
        assets.ancestors,
        IFNULL(
            assets.assetType,
            lastrule_lastasset_compliancestatus.directoryAssetType
        ) AS assetType,
        assets.projectID,
    FROM
        lastrule_lastasset_compliancestatus
        LEFT JOIN assets ON lastrule_lastasset_compliancestatus.assetName = assets.name
)
SELECT
    enriched_compliancestatus.*,
    SPLIT(
        enriched_compliancestatus.ancestryPathDisplayName,
        "/"
    ) [SAFE_OFFSET(0)] AS level0,
    SPLIT(
        enriched_compliancestatus.ancestryPathDisplayName,
        "/"
    ) [SAFE_OFFSET(1)] AS level1,
    SPLIT(
        enriched_compliancestatus.ancestryPathDisplayName,
        "/"
    ) [SAFE_OFFSET(2)] AS level2,
    SPLIT(
        enriched_compliancestatus.ancestryPathDisplayName,
        "/"
    ) [SAFE_OFFSET(3)] AS level3,
    SPLIT(
        enriched_compliancestatus.ancestryPathDisplayName,
        "/"
    ) [SAFE_OFFSET(4)] AS level4,
    SPLIT(
        enriched_compliancestatus.ancestryPathDisplayName,
        "/"
    ) [SAFE_OFFSET(5)] AS level5,
    SPLIT(
        enriched_compliancestatus.ancestryPathDisplayName,
        "/"
    ) [SAFE_OFFSET(6)] AS level6,
    SPLIT(
        enriched_compliancestatus.ancestryPathDisplayName,
        "/"
    ) [SAFE_OFFSET(7)] AS level7,
    SPLIT(
        enriched_compliancestatus.ancestryPathDisplayName,
        "/"
    ) [SAFE_OFFSET(8)] AS level8,
    SPLIT(
        enriched_compliancestatus.ancestryPathDisplayName,
        "/"
    ) [SAFE_OFFSET(9)] AS level9
FROM
    enriched_compliancestatus
ORDER BY
    enriched_compliancestatus.ruleName,
    enriched_compliancestatus.ruleDeploymentTimeStamp,
    enriched_compliancestatus.compliant,
    enriched_compliancestatus.assetName,
    enriched_compliancestatus.assetInventoryTimeStamp
EOF
  }
}

resource "google_bigquery_table" "active_violations" {
  project     = var.project_id
  dataset_id  = google_bigquery_dataset.ram_dataset.dataset_id
  table_id    = "active_violations"
  description = "Real-time Asset Monitor - active_violations"
  view {
    use_legacy_sql = false
    query          = <<EOF
SELECT
    violations.*,
    compliancestatus.serviceName,
    compliancestatus.ruleNameShort,
    compliancestatus.level0,
    compliancestatus.level1,
    compliancestatus.level2,
    compliancestatus.level3,
    compliancestatus.level4,
    compliancestatus.level5,
    compliancestatus.level6,
    compliancestatus.level7,
    compliancestatus.level8,
    compliancestatus.level9,
    compliancestatus.projectID
FROM
    `${var.project_id}.${google_bigquery_dataset.ram_dataset.dataset_id}.${google_bigquery_table.last_compliance_status.table_id}` AS compliancestatus
    INNER JOIN (
        SELECT
            *
        FROM
          `${var.project_id}.${google_bigquery_dataset.ram_dataset.dataset_id}.${google_bigquery_table.violations.table_id}`
        WHERE
            DATE(_PARTITIONTIME) > DATE_SUB(CURRENT_DATE(), INTERVAL ${var.views_interval_days} DAY)
            OR _PARTITIONTIME IS NULL
    ) AS violations ON violations.functionConfig.functionName = compliancestatus.ruleName
    AND violations.functionConfig.deploymentTime = compliancestatus.ruleDeploymentTimeStamp
    AND violations.feedMessage.asset.name = compliancestatus.assetName
    AND IF(
        violations.feedMessage.origin = "real-time",
        violations.feedMessage.window.startTime,
        IF(
            violations.feedMessage.asset.updateTime IS NULL,
            violations.feedMessage.window.startTime,
            violations.feedMessage.asset.updateTime
        )
    ) = compliancestatus.assetInventoryTimeStamp
    AND violations.nonCompliance.evaluationTimeStamp = compliancestatus.evaluationTimeStamp
EOF
  }
}


resource "google_cloud_run_service" "crun_svc" {
  project  = var.project_id
  name     = local.service_name
  location = var.crun_region

  template {
    spec {
      containers {
        image = "${var.ram_container_images_registry}/${local.service_name}:${var.ram_microservice_image_tag}"
        resources {
          limits = {
            cpu    = "${var.crun_cpu}"
            memory = "${var.crun_memory}"
          }
        }
        env {
          name  = "${upper(local.service_name)}_ENVIRONMENT"
          value = var.environment
        }
        env {
          name  = "${upper(local.service_name)}_LOG_ONLY_SEVERITY_LEVELS"
          value = var.log_only_severity_levels
        }
        env {
          name  = "${upper(local.service_name)}_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "${upper(local.service_name)}_START_PROFILER"
          value = var.start_profiler
        }
      }
      container_concurrency = var.crun_concurrency
      timeout_seconds       = var.crun_timeout_seconds
      service_account_name  = google_service_account.microservice_sa.email
    }
    metadata {
      annotations = {
        "run.googleapis.com/client-name"   = "terraform"
        "autoscaling.knative.dev/maxScale" = "${var.crun_max_instances}"
      }
    }
  }
  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "internal"
    }
  }
  autogenerate_revision_name = true
  traffic {
    percent         = 100
    latest_revision = true
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "google_service_account" "subscription_sa" {
  project      = var.project_id
  account_id   = "trigger-${local.service_name}"
  display_name = "RAM execute ${local.service_name} trigger"
  description  = "Solution: Real-time Asset Monitor, microservice trigger: ${local.service_name}"
}
data "google_iam_policy" "binding" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:${google_service_account.subscription_sa.email}",
    ]
  }
}
resource "google_cloud_run_service_iam_policy" "trigger_invoker" {
  location = google_cloud_run_service.crun_svc.location
  project  = google_cloud_run_service.crun_svc.project
  service  = google_cloud_run_service.crun_svc.name

  policy_data = data.google_iam_policy.binding.policy_data
}

resource "google_pubsub_subscription" "subcription_asset_feed" {
  project              = var.project_id
  name                 = "${local.service_name}-asset-feed"
  topic                = var.asset_feed_topic_id
  ack_deadline_seconds = var.sub_ack_deadline_seconds
  push_config {
    oidc_token {
      service_account_email = google_service_account.subscription_sa.email
    }
    #Updated endpoint to deal with WARNING in logs: failed to extract Pub/Sub topic name from the URL request path: "/", configure your subscription's push endpoint to use the following path pattern: 'projects/PROJECT_NAME/topics/TOPIC_NAME
    push_endpoint = "${google_cloud_run_service.crun_svc.status[0].url}/${var.asset_feed_topic_id} "
  }
  expiration_policy {
    ttl = ""
  }
  message_retention_duration = var.sub_message_retention_duration
  retry_policy {
    minimum_backoff = var.sub_minimum_backoff
  }
}

resource "google_pubsub_subscription" "subcription_compliance_status" {
  project              = var.project_id
  name                 = "${local.service_name}-compliance-status"
  topic                = var.compliance_status_topic_id
  ack_deadline_seconds = var.sub_ack_deadline_seconds
  push_config {
    oidc_token {
      service_account_email = google_service_account.subscription_sa.email
    }
    #Updated endpoint to deal with WARNING in logs: failed to extract Pub/Sub topic name from the URL request path: "/", configure your subscription's push endpoint to use the following path pattern: 'projects/PROJECT_NAME/topics/TOPIC_NAME
    push_endpoint = "${google_cloud_run_service.crun_svc.status[0].url}/${var.compliance_status_topic_id} "
  }
  expiration_policy {
    ttl = ""
  }
  message_retention_duration = var.sub_message_retention_duration
  retry_policy {
    minimum_backoff = var.sub_minimum_backoff
  }
}

resource "google_pubsub_subscription" "subcription_violation" {
  project              = var.project_id
  name                 = "${local.service_name}-violation"
  topic                = var.violation_topic_id
  ack_deadline_seconds = var.sub_ack_deadline_seconds
  push_config {
    oidc_token {
      service_account_email = google_service_account.subscription_sa.email
    }
    #Updated endpoint to deal with WARNING in logs: failed to extract Pub/Sub topic name from the URL request path: "/", configure your subscription's push endpoint to use the following path pattern: 'projects/PROJECT_NAME/topics/TOPIC_NAME
    push_endpoint = "${google_cloud_run_service.crun_svc.status[0].url}/${var.violation_topic_id} "
  }
  expiration_policy {
    ttl = ""
  }
  message_retention_duration = var.sub_message_retention_duration
  retry_policy {
    minimum_backoff = var.sub_minimum_backoff
  }
}
