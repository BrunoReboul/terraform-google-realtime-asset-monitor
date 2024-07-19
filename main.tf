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

locals {
  environment = var.environment != "" ? var.environment : terraform.workspace
}

module "deploy" {
  source     = "./modules/deploy"
  project_id = var.project_id
}

module "convertfeed" {
  source                     = "./modules/convertfeed"
  project_id                 = var.project_id
  environment                = local.environment
  pubsub_allowed_regions     = var.pubsub_allowed_regions
  gcs_location               = var.gcs_location
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
}

module "fetchrules" {
  source                     = "./modules/fetchrules"
  project_id                 = var.project_id
  environment                = local.environment
  pubsub_allowed_regions     = var.pubsub_allowed_regions
  gcs_location               = var.gcs_location
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
  triggering_topic_id        = module.convertfeed.asset_feed_topic_id
}

module "monitor" {
  source                     = "./modules/monitor"
  project_id                 = var.project_id
  environment                = local.environment
  pubsub_allowed_regions     = var.pubsub_allowed_regions
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
  triggering_topic_id        = module.fetchrules.asset_rule_topic_id
}

module "stream2bq" {
  source                     = "./modules/stream2bq"
  project_id                 = var.project_id
  environment                = local.environment
  views_interval_days        = var.views_interval_days
  bq_partition_expiration_ms = var.bq_partition_expiration_ms
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
  asset_feed_topic_id        = module.convertfeed.asset_feed_topic_id
  compliance_status_topic_id = module.monitor.compliance_status_topic_id
  violation_topic_id         = module.monitor.violation_topic_id
  bq_tables_deletion_protection = var.bq_tables_deletion_protection
}

module "launch" {
  source                     = "./modules/launch"
  project_id                 = var.project_id
  environment                = local.environment
  pubsub_allowed_regions     = var.pubsub_allowed_regions
  gcs_location               = var.gcs_location
  scheduler_region           = var.scheduler_region
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
  schedulers                 = var.schedulers
}

module "executecaiexport" {
  source                                = "./modules/executecaiexport"
  project_id                            = var.project_id
  environment                           = local.environment
  gcs_location                          = var.gcs_location
  gcs_export_bucket_object_max_age_days = var.gcs_export_bucket_object_max_age_days
  export_org_ids                        = var.export_org_ids
  export_folder_ids                     = var.export_folder_ids
  crun_region                           = var.crun_region
  ram_microservice_image_tag            = var.ram_microservice_image_tag
  log_only_severity_levels              = var.log_only_severity_levels
  triggering_topic_id                   = module.launch.action_topic_id
}

module "executegfsdeleteolddocs" {
  source                     = "./modules/executegfsdeleteolddocs"
  project_id                 = var.project_id
  environment                = local.environment
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
  triggering_topic_id        = module.launch.action_topic_id
}

module "splitexport" {
  source                     = "./modules/splitexport"
  project_id                 = var.project_id
  environment                = local.environment
  pubsub_allowed_regions     = var.pubsub_allowed_regions
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
  exports_bucket_name        = module.executecaiexport.exports_bucket_name
  cai_feed_topic_id          = module.convertfeed.cai_feed_topic_name
}

module "publish2fs" {
  source                     = "./modules/publish2fs"
  project_id                 = var.project_id
  environment                = local.environment
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
  triggering_topic_id        = module.convertfeed.asset_feed_topic_id
  deploy_fs_assets_retention_policy = var.deploy_fs_assets_retention_policy
}

module "upload2gcs" {
  source                                   = "./modules/upload2gcs"
  project_id                               = var.project_id
  environment                              = local.environment
  gcs_location                             = var.gcs_location
  crun_region                              = var.crun_region
  ram_microservice_image_tag               = var.ram_microservice_image_tag
  log_only_severity_levels                 = var.log_only_severity_levels
  triggering_topic_id                      = module.convertfeed.asset_feed_topic_id
  gcs_assetjson_bucket_object_max_age_days = var.gcs_assetjson_bucket_object_max_age_days
}

module "feeds" {
  # wait the be ready to process feeds before creating them
  depends_on = [
    module.stream2bq,
    module.splitexport,
    module.publish2fs,
    module.upload2gcs,
  ]
  source                  = "./modules/feeds"
  project_id              = var.project_id
  cai_feed_topic_id       = module.convertfeed.cai_feed_topic_id
  feed_iam_policy_folders = var.feed_iam_policy_folders
  feed_iam_policy_orgs    = var.feed_iam_policy_orgs
  feed_resource_folders   = var.feed_resource_folders
  feed_resource_orgs      = var.feed_resource_orgs
}

module "metrics" {
  # create log based metrics once the microservices are deployed 
  depends_on = [module.feeds]
  source     = "./modules/metrics"
  project_id = var.project_id
}

module "slos" {
  # Create SLOs once the log based metrics have been created
  depends_on             = [module.metrics]
  count                      = var.deploy_slos == true ? 1 : 0
  source                 = "./modules/slos"
  project_id             = var.project_id
  pubsub_allowed_regions = var.pubsub_allowed_regions
  notification_channels  = var.notification_channels
  ram_e2e_latency        = var.ram_e2e_latency
  log_metric_ram_execution_count_id = module.metrics.log_metric_ram_execution_count_id
  log_metric_ram_execution_latency_e2e_id = module.metrics.log_metric_ram_execution_latency_e2e_id
}

module "slos_cai" {
  count                      = var.deploy_slos == true ? 1 : 0
  source                = "./modules/slos_cai"
  project_id            = var.project_id
  notification_channels = module.slos[0].ram_notification_channels
  cai_latency           = var.cai_latency
  log_metric_ram_execution_latency_e2e_id = module.metrics.log_metric_ram_execution_latency_e2e_id
}

module "transparentslis" {
  count                 = var.deploy_slos == true ? 1 : 0
  source                = "./modules/transparentslis"
  project_id            = var.project_id
  notification_channels = module.slos[0].ram_notification_channels
  availability          = var.api_availability
  latency               = var.api_latency
}

module "dashboards" {
  # Create dashboards once the log based metrics have been created
  count      = var.deploy_slos == true ? 1 : 0
  depends_on = [module.metrics]
  source     = "./modules/dashboards"
  project_id = var.project_id
  log_metric_ram_execution_latency_id = module.metrics.log_metric_ram_execution_latency_id
}

module "autofixbqdsdelete" {
  count                      = var.deploy_autofix_bqdsdelete == true ? 1 : 0
  source                     = "./modules/autofixbqdsdelete"
  project_id                 = var.project_id
  environment                = local.environment
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
  triggering_topic_id        = module.monitor.violation_topic_id
}

module "console" {
  count                      = var.deploy_console == true ? 1 : 0
  source                     = "./modules/console"
  project_id                 = var.project_id
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  dns_name                   = var.dns_name
}

module "consolebff" {
  count                      = var.deploy_console == true ? 1 : 0
  source                     = "./modules/consolebff"
  project_id                 = var.project_id
  bigquery_dataset_id        = module.stream2bq.ram_dataset_id
  environment                = local.environment
  crun_region                = var.crun_region
  ram_microservice_image_tag = var.ram_microservice_image_tag
  log_only_severity_levels   = var.log_only_severity_levels
}

module "loadbalancer" {
  count                            = var.deploy_loadbalancer == true ? 1 : 0
  source                           = "./modules/loadbalancer"
  project_id                       = var.project_id
  region                           = var.crun_region
  dns_name                         = var.dns_name
  support_email                    = var.support_email
  static_public_bucket_name_suffix = var.static_public_bucket_name_suffix
}
