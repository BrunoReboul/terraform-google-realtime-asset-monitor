# terraform-google-realtime-asset-monitor

To use theses terraform modules, you will need a GCP project with:  

- APIs enabled
  - Artifact Registry API `artifactregistry.googleapis.com`
  - BigQuery API `bigquery.googleapis.com`
  - Cloud Asset API `cloudasset.googleapis.com`
  - Cloud Firestore API `firestore.googleapis.com`
  - Cloud Logging API `logging.googleapis.com`
  - Cloud Monitoring API `monitoring.googleapis.com`
  - Cloud Pub/Sub API `pubsub.googleapis.com`
  - Cloud Run Admin API `run.googleapis.com`
  - Cloud Scheduler API `cloudscheduler.googleapis.com`
  - Cloud Storage API `storage.googleapis.com`
  - Cloud Trace API `cloudtrace.googleapis.com`
  - Eventarc API `eventarc.googleapis.com`
  - Stackdriver Profiler API `cloudprofiler.googleapis.com`

- IAM roles for the service account used to run Terraform:
  - On the project or folder hosting RAM
    - Project IAM Admin `roles/resourcemanager.projectIamAdmin`
    - Pub/sub Admin `roles/pubsub.admin`
    - Service Account Admin `roles/iam.serviceAccountAdmin`
    - Service Usage Consumer `roles/serviceusage.serviceUsageConsumer` when creating CAI feeds on org or folder level attached to the RAM project
  - On the monitored assets parent orgs / folders /projects
    - Cloud Asset Owner `roles/cloudasset.owner`
  - On the monitored assets projects (aka when creating CAI feeds at project level)
    - Service Usage Consumer `roles/serviceusage.serviceUsageConsumer`

- FireStore: [select native mode](https://cloud.google.com/datastore/docs/firestore-or-datastore)
