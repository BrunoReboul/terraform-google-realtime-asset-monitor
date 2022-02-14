# RAM execute gcilistgroups microservice infra pre requisites

[admin SDK limits](https://developers.google.com/admin-sdk/directory/v1/limits)

2022-02-11 default is 3000 per 100 sec -> do not retry in less than a 105 sec

minimum_backoff = "105s"
