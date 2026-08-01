# Release Notes — Amazon::S3::Lite 1.3.0

**Released:** 2026-08-01  
**Author:** Rob Lauer \<rlauer\@gmail.com\>

---

## Overview

Version 1.3.0 is a feature release that significantly expands the S3
bucket management API surface. This release adds bucket deletion,
static website hosting configuration, public access block controls,
and bucket policy management. It also introduces two new supporting
modules — `Amazon::S3::Lite::Constants` and
`Amazon::S3::Lite::Policies` — and upgrades the build toolchain to the
latest `CPAN::Maker::Bootstrapper` conventions.

---

## New Features

### Bucket Management Methods

#### `delete_bucket($bucket, %options)`

Deletes an empty S3 bucket. The caller is responsible for emptying the
bucket first (e.g. using `list_all_objects_v2` and
`delete_object`). An optional `region` argument overrides the signing
region.

#### `put_public_access_block($bucket, %options)`

Sets the Block Public Access configuration on a bucket. All four
settings (`block_public_acls`, `ignore_public_acls`,
`block_public_policy`, `restrict_public_buckets`) default to `true`
when omitted, resulting in a fully locked-down bucket. Pass explicit
false values for settings that must be relaxed (e.g. to host a static
website with a bucket policy).

#### `put_bucket_website($bucket, %options)`

Configures a bucket as an S3 static website endpoint. Accepts `index`
(default: `index.html`) and an optional `error` document key.

#### `get_bucket_website($bucket)`

Returns the bucket's website configuration as a hashref containing
`index_document`, `error_document`, and (if set)
`redirect_all_requests_to`. Returns `undef` if no website
configuration exists (HTTP 404).

#### `delete_bucket_website($bucket)`

Removes the website configuration from a bucket.

#### `put_bucket_policy($bucket, $policy)`

Attaches a bucket policy. The policy may be supplied as a Perl hashref
(encoded to canonical JSON internally) or as a pre-encoded JSON
string.

#### `get_bucket_policy($bucket, %options)`

Returns the bucket's policy as a decoded hashref, or `undef` if no
policy exists (`NoSuchBucketPolicy`). Pass `raw => 1` to receive the
raw JSON string instead.

---

### New Modules

#### `Amazon::S3::Lite::Constants`

Centralises constant definitions (previously declared inline with
`Readonly` in the main module). Exports `:booleans` tag containing
`$TRUE` and `$FALSE`.

#### `Amazon::S3::Lite::Policies`

A `Role::Tiny` role consumed by `Amazon::S3::Lite`. Encapsulates policy-related behaviour.

---

### XML Template Additions (`__DATA__`)

Three new inline XML templates were added to the `__DATA__` section of
the main module:

- `:website` — `WebsiteConfiguration` document
- `:website-error` — `ErrorDocument` fragment
- `:public_access_block` — `PublicAccessBlockConfiguration` document

---

## Changes to Existing Code

- Constants (`$TRUE`, `$FALSE`) moved out of `Amazon::S3::Lite` into
  the new `Amazon::S3::Lite::Constants` module. The `Readonly`
  dependency is replaced by this module.
- `Amazon::S3::Lite` now consumes the `Amazon::S3::Lite::Policies` role via `Role::Tiny::With`.
- `JSON::PP` is now a direct `use` import rather than a deferred `require`.
- `Carp::Always` added for more helpful stack traces during development.
- POD corrected: a missing `=over 4` / `=back` pair around the `log_level` item was added, resolving the POD errors present in 1.2.3.

---

## New Test

- `t/02-put-bucket-website.t` — tests for the new website configuration methods.

---

## Dependency Changes

### `cpanfile`

| Change | Module | Version |
|--------|--------|---------|
| Added (suggests) | `Amazon::Credentials` | 1.3.0 |
| Added (suggests) | `Log::Log4perl` | 1.57 |

Optional dependencies (`Amazon::Credentials`, `Log::Log4perl`) are now
declared as `suggests` entries in the `cpanfile` rather than being
mentioned only in documentation. The `cpanfile` is now generated from
separate `requires`, `recommends`, and `suggests` tier files.

---

## Build Toolchain Updates

These changes affect the project's build infrastructure and do not
impact the installed module's runtime behaviour.

- **`Makefile`**: Updated to use `cpan-maker` (replacing
  `make-cpan-dist.pl`) and `markdown-render` (replacing
  `md-utils.pl`). The default goal is now `$(TARBALL)`
  directly. Dependency scanning now produces `.raw` intermediate files
  for `requires`, `recommends`, and `suggests` tiers
  independently. `deps.mk` now depends on `.pm.in`/`.pl.in` source
  files rather than built `.pm`/`.pl` targets, eliminating the prior
  chicken-and-egg build ordering problem. New `test`, `check`, and
  `package` convenience targets added.
- **`.includes/perl.mk`**: `podchecker` replaces `podextract` as the
  primary POD validation tool. POD checking is now integrated directly
  into the `%.pm` and `%.pl` pattern rules. `perlcritic` invocations
  now pass explicit `--theme` and `--severity` flags. A `check-syntax`
  phony target is introduced as a named alias for building all
  modules/scripts. The redundant `2>/dev/null` duplication in the tidy
  diff check is corrected.
- **`.includes/update.mk`**: `update-available` now performs a proper
  semantic version comparison and supports a `CMB_VERSION_DRIFT` drift
  check (`fail` / `warn` / `ignore`). The `update` target now handles
  an optional `builder` script and correctly sets file permissions
  after copying.
- **`.includes/git.mk`**: `NO_COMMIT=1` environment variable
  suppresses the final commit. Build output is quieted with `NO_ECHO`.
- **`.includes/release-notes.mk`**: Release note generation is now
  delegated to `cmb release-notes`.
- **`.gitignore`**: Added `**/*.checked`, `**/*.raw`, and
  `buildspec.yml.current`.
- **`deps.mk`**, **`project.mk`**, **`recommends`**, **`suggests`**:
  New project infrastructure files.

---

## Upgrade Notes

- If you subclass or monkey-patch `Amazon::S3::Lite` and reference
  `$Amazon::S3::Lite::TRUE` or `$Amazon::S3::Lite::FALSE` directly,
  update those references to import from `Amazon::S3::Lite::Constants`
  instead.
- `Role::Tiny` is now a runtime dependency (pulled in transitively by
  `Amazon::S3::Lite::Policies`). Ensure it is available in your
  environment.
- Optional dependencies `Amazon::Credentials` (≥ 1.3.0) and
  `Log::Log4perl` (≥ 1.57) are now declared in `cpanfile` as
  `suggests`. Installers that honour `suggests` entries will attempt
  to install them; installers that do not will continue to work as
  before.
