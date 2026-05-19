---

## Amazon::S3::Lite 1.1.2

**Released:** Tue May 19, 2026

### Bug Fixes

**`_parse_notification_configuration`** - the XML element names used
when parsing S3 bucket notification configurations were wrong. S3 uses
`CloudFunctionConfiguration` as the container element and
`CloudFunction` as the ARN field for Lambda targets in this context,
not `LambdaFunctionConfiguration` / `LambdaFunctionArn`. The twig
handler key and the `first_child_text` call have been corrected
accordingly. This was causing notification configurations to silently
parse as empty.

**`put_bucket_notification_configuration` /
`get_bucket_notification_configuration`** - the query string for the
notification sub-resource was built as `?notification`, which AWS
Signature V4 signing treats differently from `?notification=`. Changed
to `?notification=` in both methods so the signed URL matches what AWS
expects, preventing authentication failures on these calls.

**`_request`** - replaced postfix `if` form (`$options->{content} =
$content if ...`) with a block `if` for consistency with the rest of
the codebase style.

### Diagnostics

**`get_bucket_notification_configuration`** - the parsed response is
now logged at `DEBUG` level via `Data::Dumper`, capturing both the raw
HTTP response and the structured parse result. Aids in diagnosing
notification configuration issues without requiring code changes.
