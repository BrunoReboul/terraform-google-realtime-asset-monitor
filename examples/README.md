# Example to be adapted to your environment

## main.tf adapt

- bucket
- prefix
- version

## terraform.tfvars adapt

- qa_project_id
- prd_project_id
- yourFirstOrgID and complement the map if multiple orgs to analyse
- yourFirstFolderID and complement the map if multiple folders to analyse
- Remove uneeded variables
  - if only analyzing at organization level then remove `feed_iam_policy_folders` and `feed_resource_folders`
  - if only analyzing at folder level then remove `feed_iam_policy_orgs` and `feed_resource_orgs`
