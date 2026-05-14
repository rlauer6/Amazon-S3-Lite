# Amazon::S3::Lite Release Notes

## 1.1.1

### Bug Fixes

**`list_buckets` signature fix.** The endpoint URL `https://s3.amazonaws.com`
has no path component. SigV4 requires the canonical URI to be at minimum `/`,
but the URL parser was producing an empty path, resulting in a signature that
real AWS rejected with `SignatureDoesNotMatch`. LocalStack does not enforce
this requirement, so the bug was not caught during local testing. Fixed by
appending a trailing slash: `$self->_endpoint . q{/}`.

The test suite has been updated to assert the correct URL
`https://s3.amazonaws.com/`.

---

### New Features

**`create_bucket`**

Creates a new S3 bucket. Handles the `us-east-1` special case automatically -
S3 returns `InvalidLocationConstraint` if a `CreateBucketConfiguration` body
is sent for the default region, so it is intentionally omitted. All other
regions receive the required `LocationConstraint` element. Supports `region`
and `acl` options.

```perl
$s3->create_bucket('my-bucket');
$s3->create_bucket('my-bucket', region => 'eu-west-1', acl => 'private');
```

**`put_bucket_notification_configuration`**

Configures Lambda event notifications on a bucket. Accepts one or more event
types and optional key prefix/suffix filters. The notification XML is built
from templates stored in the module's `__DATA__` section using a lightweight
`@key@` substitution engine, keeping the XML structure readable and separate
from code.

```perl
$s3->put_bucket_notification_configuration($bucket,
  lambda_arn => $arn,
  events     => [qw(s3:ObjectCreated:* s3:ObjectRemoved:*)],
  filters    => { prefix => 'uploads/' },
);
```

**`get_bucket_notification_configuration`**

Retrieves the current notification configuration for a bucket. Returns an
arrayref of configuration hashrefs whose structure mirrors the input accepted
by `put_bucket_notification_configuration`, making round-trip fetch-modify-put
workflows straightforward.

```perl
my $configs = $s3->get_bucket_notification_configuration($bucket);
for my $cfg ( @{$configs} ) {
  printf "id=%s arn=%s\n", $cfg->{id}, $cfg->{lambda_arn};
}
```

---

### Internal Changes

**Template engine.** Three private methods support the notification
configuration feature: `_create_notification_configuration`,
`_parse_notification_configuration`, `_fetch_templates`, and `_resolve`.
Templates are stored in `__DATA__` (replacing `__END__`) and cached in a
package-level variable on first use so the filehandle is only consumed once.

**`_croak_on_error` refactored.** Status and reason extracted via hash slice
rather than separate assignments.

**`list_all_objects_v2` style.** `while (1)` replaced with `while ($TRUE)`.

---

### Dependencies

`List::Util` (core) added to `requires` and `cpanfile` for `pairs`.
`Readonly` and `English` added to module imports.

---

### Build System

**`update-available` target.** Checks whether a newer version of
`CPAN::Maker::Bootstrapper` is available and prints a notice.
Runs automatically as part of the `all` target.

**`workflow` target.** Installs the GitHub Actions workflow file and
`build-requires` from the bootstrapper's share directory into the project.

**`build-ci` target.** Runs a local Docker-based CI build, mirroring
the GitHub Actions environment without pushing to the repository.

**Defensive fixes.** `find-files` macro now guards against non-existent
directories. Template recipes (`test.t.tmpl`, `buildspec.yml.tmpl`,
`buildspec.yml.tmpl`) use safer error handling with explicit `if/else`
rather than shell `&&`/`||` chains.

**`YAML` => `YAML::Tiny`** in the `scan-deps` macro.

**`buildspec.yml` key renames.** `pm_module` => `pm-module`,
`test_requires` => `test-requires`, `pm_module` path key => `pm-module`
for consistency with hyphenated naming throughout.

**Release notes reorganised** into `release-notes/` subdirectory.
`release-notes.md` is now a symlink to the current release.
