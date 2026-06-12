## Amazon::S3::Lite 1.1.5 Release Notes

**Bug Fixes**
- `_parse_notification_configuration` now also handles
  `TopicConfiguration` (SNS) entries in bucket notification
  configurations, extracting `topic_arn` from the `Topic` element —
  previously only `CloudFunctionConfiguration` and
  `QueueConfiguration` were parsed.
