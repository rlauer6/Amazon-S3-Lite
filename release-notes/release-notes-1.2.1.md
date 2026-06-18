# Amazon::S3::Lite 1.2.1 Release Notes

## Overview

1.2.1 fixes the Lambda notification XML template - `LambdaFunctionConfiguration`
and `LambdaFunctionArn` are the JSON API names; the XML wire format requires
`CloudFunctionConfiguration` and `CloudFunction`. This caused a 400
`MalformedXML` error on every `put_bucket_notification_configuration` call
targeting a Lambda function.

---

## Bug Fixes

### _create_notification_configuration - correct XML element names for Lambda

The `lambda-event` template used `LambdaFunctionConfiguration` and
`LambdaFunctionArn`, which are the REST/JSON API field names documented in
the `LambdaFunctionConfiguration` data type reference. The actual XML schema
for `PutBucketNotificationConfiguration` requires `CloudFunctionConfiguration`
as the container element and `CloudFunction` as the ARN element, as documented
in the `PutBucketNotificationConfiguration` request syntax.

Before:
```xml
<LambdaFunctionConfiguration>
  <Id>@id@</Id>
  <LambdaFunctionArn>@lambda_arn@</LambdaFunctionArn>
  ...
</LambdaFunctionConfiguration>
```

After:
```xml
<CloudFunctionConfiguration>
  <Id>@id@</Id>
  <CloudFunction>@lambda_arn@</CloudFunction>
  ...
</CloudFunctionConfiguration>
```

The `QueueConfiguration` template is unaffected - `<QueueConfiguration>` and
`<Queue>` are correct in both the JSON and XML schemas.

### _create_notification_configuration - debug output capture

`_resolve(...)` was called as a bare return expression. The resolved XML is
now captured in `$resolved_xml` before returning, allowing debug `Dumper`
output to be added without restructuring the call. No functional change.
