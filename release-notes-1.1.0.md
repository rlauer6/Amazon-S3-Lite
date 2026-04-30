# Amazon::S3::Lite 1.1.0 Release Notes

## Overview

This release completes the elimination of LWP from the dependency
chain by replacing `AWS::Signature4` and `HTTP::Request` with
`Amazon::Signature4::Lite` - a purpose-built, LWP-free SigV4
implementation. `Amazon::S3::Lite` now has zero dependency on the
libwww-perl ecosystem.

## Dependency Changes

- `AWS::Signature4` removed
- `HTTP::Request` removed
- `Amazon::Signature4::Lite 1.0.0` added

`AWS::Signature4` listed `LWP` as a hard prerequisite, meaning every
install of `Amazon::S3::Lite` pulled in the full LWP stack regardless
of whether it was used. That chain is now completely gone.

## Architecture

**`_signer` refactored** - now accepts `$region` as an argument and
returns an `Amazon::Signature4::Lite` instance rather than
`AWS::Signature4`. Region is passed at construction time rather than
at signing time, which is a cleaner interface:

```perl
my $signer = Amazon::Signature4::Lite->new(
  access_key    => $access_key,
  secret_key    => $secret_key,
  session_token => $token,       # resolved from credentials object
  region        => $region,
  service       => 's3',
);
```

**`_request` simplified** - the `HTTP::Request` construction, signing,
and header extraction round-trip is replaced by a direct call to
`$signer->sign(...)` which returns a hashref of signed headers ready
for `HTTP::Tiny`. Session token and `x-amz-content-sha256` handling
that was previously manual in `_request` now lives inside
`Amazon::Signature4::Lite::sign`:

```perl
my $signed = $self->_signer($region)->sign(
  method  => $method,
  url     => $url,
  headers => $headers,
  payload => $content_is_coderef ? q{} : $content,
);
delete $signed->{host};  # HTTP::Tiny sets this itself
```

## POD & README

- All references to `AWS::Signature4` updated to `Amazon::Signature4::Lite`
- Cold start note corrected
- SEE ALSO updated
- Author email updated
- Line wrapping normalized throughout

## Upgrade Notes

No API changes. Drop-in replacement for 1.0.2. The only observable
difference is that `AWS::Signature4`, `HTTP::Request`, and `LWP` are
no longer installed as dependencies.
