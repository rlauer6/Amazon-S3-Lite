# Amazon::S3::Lite 1.0.2 Release Notes

## Overview

A focused maintenance release replacing `XML::LibXML` with `XML::Twig`,
eliminating the `libxml2` system library dependency and simplifying CI
builds. Also includes a credential accessor compatibility fix, a
`put_object` warning fix for in-memory filehandles, and expanded test
coverage.

## Dependency Changes

- `XML::LibXML` -> `XML::Twig` - removes the `libxml2-dev` system
  library requirement. `XML::Twig` uses `libexpat` which is already
  required by other deps in the typical build environment, making
  installation significantly simpler in containers and Lambda images
- `libxml2-dev` can be removed from `build-github` and CI environments
- `Alien::Build` / `Alien::Libxml2` are no longer needed

## Bug Fixes

**`_signer` credential accessor compatibility**

The previous code used `//` to fall back between `get_aws_access_key_id`
and `aws_access_key_id` accessors, but `//` tests for definedness -
a missing method would throw rather than fall through. Fixed using
`can()` to probe for each accessor before calling it:

```perl
my $access_key_id = $creds->can('get_aws_access_key_id') && $creds->get_aws_access_key_id;
$access_key_id //= $creds->can('aws_access_key_id') && $creds->aws_access_key_id;
```

Also fixes a copy-paste bug in the original where `get_aws_secret_access_key`
was used for both key and secret.

**`put_object` warning on in-memory filehandles**

`stat` on an `IO::Scalar` or similar in-memory handle emits a
`stat() on unopened filehandle` warning because these handles have no
underlying file descriptor. Fixed by checking `fileno` first - only
real file descriptors (fd >= 0) are `stat`'d:

```perl
my $fd = eval { fileno($data) };
if ( defined $fd && $fd >= 0 ) {
  my @st = stat $data;
  $content_length = $st[7] if @st && defined $st[7];
}
```

**`_parse_list_objects_v2` `Prefix` handler**

The `'Prefix'` twig handler was firing for `<Prefix>` elements inside
`<CommonPrefixes>` nodes as well as the root-level listing prefix,
causing `$prefix` to be overwritten with the last common prefix seen.
Fixed by scoping the handler to `'ListBucketResult/Prefix'`.

## XML Parsing Refactor

All three XML parsing methods now use `XML::Twig`:

**`_parse_list_buckets`** - twig handlers for `Bucket` and `Owner`
nodes replace the XPath namespace-aware query approach.

**`_parse_copy_response`** - `XML::Twig->new->parse` replaces
`XML::LibXML->load_xml`. The 200-with-error detection uses
`$twig->root->tag` to identify the root element.

**`_parse_list_objects_v2`** - twig handlers with `$t->purge` after
each `Contents` node for memory-efficient processing of large listings.
`CommonPrefixes` handler correctly separated from root `Prefix`.

**`_croak_on_error`** - `XML::LibXML` replaced with targeted regex
extraction. More resilient to malformed error bodies:

```perl
my ($code) = $response->{content} =~ m{<Code>([^<]+)</Code>}xsm;
my ($msg)  = $response->{content} =~ m{<Message>([^<]+)</Message>}xsm;
```

`S3_NS` constant and `_xpc` helper removed entirely.

## Test Improvements

**New unit tests:**
- `error XML body extracted` - verifies `Code` and `Message` are
  extracted from XML error bodies in `_croak_on_error`
- `list_objects_v2 with common_prefixes` - exercises `CommonPrefixes`
  parsing and verifies root `Prefix` is not overwritten by nested
  `<Prefix>` elements

**Integration test improvements:**
- `test-bucket` existence verified immediately after `localstack_available`
  check - integration subtests are skipped cleanly with an informative
  message if the bucket hasn't been created rather than failing mid-suite
- `list_all_objects_v2` real pagination test added - seeds 3 objects,
  paginates with `max_keys => 2`, verifies all 3 are returned across pages
- LocalStack S3 service status check now accepts both `available` and
  `running` states

## Build & CI

- GitHub Actions workflow added (`.github/workflows/build.yml`) -
  builds on `debian:trixie` container, triggers on push to `main` and `dev`
- `build-github` script added - regenerates `cpanfile` from `requires`,
  `build-requires`, and `test-requires` before installing deps, then
  runs `make SCAN=off LINT=off`
- `build-requires` added listing CI-only dependencies
- `buildspec.yml` - `exe_files: bin` removed (no executables in this dist)

## Known Issues

- POD cold start note contains a capitalisation typo: `XML::TWig` should
  be `XML::Twig`. Will be corrected in the next patch release.
