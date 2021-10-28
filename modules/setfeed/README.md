# RAM setfeeds configures the destination Pubsub topic used by the Google Cloud Asset Inventory feeds

## testing the caiFeed topic

```shell
gcloud pubsub subscriptions create testcaifeed --topic=caiFeed --project=<yourProjectID>
gcloud pubsub subscriptions pull testcaifeed --auto-ack --project=<yourProjectID>
```
