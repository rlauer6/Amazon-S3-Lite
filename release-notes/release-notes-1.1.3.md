# Amazon::S3::Lite Release Notes

## 1.1.3

### New Features

**SQS notification configuration support.** `put_bucket_notification_configuration`
and `_create_notification_configuration` now accept `type => 'sqs'` alongside
the existing `type => 'lambda'`. Pass `queue_arn` instead of `lambda_arn` for
SQS targets. The `sqs-event` XML template is included in `__DATA__` and
generates a `QueueConfiguration` element.

**`_parse_notification_configuration` handles both Lambda and SQS.**
A shared twig handler now processes both `CloudFunctionConfiguration` and
`QueueConfiguration` elements, returning `queue_arn` in the parsed result for
SQS configurations alongside the existing `lambda_arn`, `events`, and `filters`
fields.

**Named template hash.** The `__DATA__` section has been restructured from a
`---`-delimited positional array to named templates prefixed with `:name`.
`_fetch_templates` now populates `%TEMPLATES` (keyed by name) rather than
`@TEMPLATES` (indexed by position). Templates are looked up as
`filter-rule`, `event`, `lambda-event`, and `sqs-event` - making the set
extensible without position-sensitive indexing.

**`_resolve` - global substitution.** The template variable substitution regex
now carries the `g` flag so all occurrences of a placeholder are replaced, not
just the first.

---

### Changes

**`_create_notification_configuration` - `type` is now required.** The method
validates `lambda_arn` when `type => 'lambda'` and `queue_arn` when
`type => 'sqs'`, croaking with a clear message if the wrong ARN is absent.

---

### Cleanup

Removed unused imports: `Carp::carp`, `Digest::SHA::sha256_hex`,
`Scalar::Util::reftype`.

---

## 1.1.2

**`?notification=` signing fix, debug logging, style.**
See `release-notes/release-notes-1.1.2.md`.
