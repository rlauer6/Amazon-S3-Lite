# Amazon::S3::Lite 1.2.0 Release Notes

## Overview

1.2.0 adds `remove_bucket_notification_configuration` - a convenience method
that clears all S3 bucket notification configurations in a single call.
Required by `alr-helper remove-bucket-notification` in ALRB 1.2.2+
`lambda-sqs-teardown`.

---

## New Features

### remove_bucket_notification_configuration

```perl
$s3->remove_bucket_notification_configuration($bucket);
```

Clears all notification configurations from `$bucket` by PUTting an empty
`<NotificationConfiguration/>` document to the S3 notification endpoint -
the correct S3 API idiom for removing all event notifications from a bucket.
After this call S3 will no longer deliver any events for the bucket to any
Lambda function, SQS queue, or SNS topic.

Takes a single required argument - the bucket name. Croaks if the bucket name
is absent. Returns true on success, croaks on failure.
