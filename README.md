# terraform-google-realtime-asset-monitor

## Prerequisites

To use theses terraform modules, you will need a GCP project with:  

- APIs enabled
  - Artifact Registry API `artifactregistry.googleapis.com`
  - BigQuery API `bigquery.googleapis.com` (default)
  - Cloud Asset API `cloudasset.googleapis.com`
  - Cloud Firestore API `firestore.googleapis.com`
  - Cloud Logging API `logging.googleapis.com` (default)
  - Cloud Monitoring API `monitoring.googleapis.com` (default)
  - Cloud Pub/Sub API `pubsub.googleapis.com`
  - Cloud Run Admin API `run.googleapis.com`
  - Cloud Scheduler API `cloudscheduler.googleapis.com`
  - Cloud Storage API `storage.googleapis.com` (default)
  - Cloud Trace API `cloudtrace.googleapis.com` (default)
  - Eventarc API `eventarc.googleapis.com`
  - Stackdriver Profiler API `cloudprofiler.googleapis.com` (default)

- IAM roles for the service account used to run Terraform:
  - On the project or folder hosting RAM
    - Project IAM Admin `roles/resourcemanager.projectIamAdmin`
    - Pub/sub Admin `roles/pubsub.admin`
    - Service Account Admin `roles/iam.serviceAccountAdmin`
    - Service Usage Consumer `roles/serviceusage.serviceUsageConsumer` when creating CAI feeds on org or folder level attached to the RAM project
    - Cloud Run Admin `roles/run.admin`
    - Service Account User `roles/iam.serviceAccountUser`
    - Eventarc Admin `roles/eventarc.admin`
    - Storage Admin `roles/storage.admin`
    - BigQuery Admin `roles/bigquery.admin`
    - Cloud Scheduler Admin `roles/cloudscheduler.admin`
  - On the real-time monitored assets parent orgs / folders
    - Cloud Asset Owner `roles/cloudasset.owner`
  - on batch monitored assets parent orgs
    - a custom role with
      - resourcemanager.organizations.get
      - resourcemanager.organizations.getIamPolicy
      - resourcemanager.organizations.setIamPolicy
  - on batch monitored assets parent folders
    - a custome role with
      - resourcemanager.folders.get
      - resourcemanager.folders.getIamPolicy
      - resourcemanager.folders.setIamPolicy
    - or roles/resourcemanager.organizationAdmin on the folder's parent org
  - On the monitored assets projects (aka when creating CAI feeds at project level)
    - Service Usage Consumer `roles/serviceusage.serviceUsageConsumer`

- FireStore: [select native mode](https://cloud.google.com/datastore/docs/firestore-or-datastore)
- Trigger Cloud Storage service agent service account creation [by one of theses means](https://cloud.google.com/storage/docs/getting-service-agent), for example:
  - `gsutil kms serviceaccount -p <your-project-id>`
- Provision a GCS bucket to manage Terraform state.
- Install Terraform and google provider consistent with version specifyied in `versions.tf`

## Example

See the [examples folder](./examples/README.md)
