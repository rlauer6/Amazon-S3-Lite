# Amazon::S3::Lite 1.2.2 Release Notes

## Overview

1.2.2 improves constructor flexibility, fixes logger initialization, adds
`log_level` support throughout, implements log level filtering in the minimal
fallback logger, and fixes the notification configuration XML to correctly
omit the `<Filter>` block when no filters are specified.

---

## Changes

### new() - accepts list or hashref, region no longer required

`new()` now accepts either a hashref or a flat key/value list:

```perl
# Both are equivalent
Amazon::S3::Lite->new({ region => 'us-east-1', ... });
Amazon::S3::Lite->new( region => 'us-east-1', ... );
```

`region` is no longer required - it defaults to `us-east-1`.

The `croak 'new() requires a hashref'` and `croak 'region is required'`
guards are removed. The test for `region is required` is removed accordingly.

### _init_logger - log_level support, correct Log4perl initialization

`_init_logger` now reads `log_level` from the constructor options (defaulting
to `warn`) and stores it as `$self->{log_level}`. The `log_level` accessor is
new.

The Log4perl initialization path is fixed - `Log::Log4perl->easy_init` now
receives `{ level => uc $log_level }` rather than
`$Log::Log4perl::WARN` (which was never correctly imported and resolved to
`undef`). The `require Log::Log4perl::Level` call is removed.

When Log4perl is already initialized, `get_logger(__PACKAGE__)` is now
correctly called in the `else` branch - previously it was called
unconditionally, then `return`'d before the initialized check could branch.

A caller-supplied `logger` passed via the constructor (rather than as a
parameter to `_init_logger`) is now correctly detected using `blessed`.

### _init_credentials - refactored to read from $self

`_init_credentials` no longer takes an `$args` hashref parameter - it reads
directly from `$self`. The explicit credentials case uses `delete` to remove
`aws_access_key_id`, `aws_secret_access_key`, and `token` from the object
after reading them.

### _create_notification_configuration - optional Filter block

A new `:filters` template wraps the `<Filter>` block:

```
:filters
<Filter>
  <S3Key>
    @filter_rules@
  </S3Key>
</Filter>
```

When no filters are specified, `$filters` is set to `q{}` and `@filters@`
in the event template expands to an empty string - correctly omitting the
`<Filter>` block entirely. Previously an empty `<S3Key>` block was always
emitted, causing a 400 `MalformedXML` error from S3 when no prefix/suffix
filter was needed.

Both `lambda-event` and `sqs-event` templates updated to use `@filters@`
in place of the inline `<Filter>` block.

### Amazon::S3::Lite::Logger - log level filtering and fatal

The minimal fallback logger now implements log level filtering. A `$LEVELS`
hash maps level names to numeric priorities (TRACE=5000, DEBUG=10000,
INFO=20000, WARN=30000, ERROR=40000, FATAL=50000). Each log method checks
the configured level before printing.

`new()` accepts `log_level` (default `warn`). `_log_level()` returns the
numeric priority for the configured level. `level()` getter/setter added.
`fatal()` added - dies with the message rather than printing.

Previously `trace` and `debug` were silent no-ops; `info`, `warn`, and
`error` always printed to STDERR regardless of configured level.
