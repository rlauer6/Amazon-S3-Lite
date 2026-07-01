# Amazon::S3::Lite 1.2.3

**Released:** Wed Jul 1, 2026
**Author:** Rob Lauer \<rclauer@gmail.com\>

---

## Overview

This is a bug fix release for `Amazon::S3::Lite`. It corrects a logger
initialisation issue introduced in earlier releases where `$self->{logger}`
was not being set when `Log::Log4perl` was configured via `easy_init`.

---

## Bug Fixes

### Logger not set when using `Log::Log4perl::easy_init` ([`_init_logger`])

In previous releases, `$self->{logger}` was only assigned when
`Log::Log4perl` had **already** been initialised by the caller. When
`_init_logger` was responsible for calling `easy_init` itself (i.e.
`Log::Log4perl` was available but not yet initialised), the logger
object was never stored on `$self`, resulting in subsequent logging
calls failing or falling through unexpectedly.

The fix unconditionally calls `Log::Log4perl->get_logger(__PACKAGE__)`
after the `easy_init` / initialisation check, ensuring `$self->{logger}`
is always populated whenever `Log::Log4perl` is available.

**Before:**
```perl
if ( !Log::Log4perl->initialized ) {
    Log::Log4perl->easy_init( { level => uc $log_level } );
}
else {
    $self->{logger} = Log::Log4perl->get_logger(__PACKAGE__);
}
```

**After:**
```perl
if ( !Log::Log4perl->initialized ) {
    Log::Log4perl->easy_init( { level => uc $log_level } );
}

$self->{logger} = Log::Log4perl->get_logger(__PACKAGE__);
```

---

## Files Changed

| File | Change |
|------|--------|
| `lib/Amazon/S3::Lite.pm.in` | Fixed `_init_logger` to always set `$self->{logger}` when `Log::Log4perl` is available |
| `VERSION` | Bumped to `1.2.3` |
| `README.md` | Regenerated from POD |
| `release-notes.md` | Updated |

---

## Upgrade Notes

This release is a drop-in replacement for `1.2.2`. No API changes were
made. Users who rely on `Log::Log4perl` for logging are encouraged to
upgrade, as previous releases may have silently fallen back to the
internal minimal logger even when `Log::Log4perl` was installed and
available.

---

## Dependencies

No changes to dependencies in this release. See the
[module documentation](https://metacpan.org/pod/Amazon::S3::Lite) for
the full dependency list.