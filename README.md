<a id="table-of-contents" class="anchor" aria-label="Permalink: Table of Contents" href="#table-of-contents"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">Table of Contents</h1>
<ul>
<li><a href="#name">NAME</a></li>
<li><a href="#synopsis">SYNOPSIS</a></li>
<li><a href="#description">DESCRIPTION</a></li>
<li>
<a href="#constructor">CONSTRUCTOR</a>
<ul>
<li><a href="#new">new</a></li>
<li><a href="#credential-resolution-order">Credential resolution order</a></li>
</ul>
</li>
<li>
<a href="#methods">METHODS</a>
<ul>
<li><a href="#list%5Cobjects%5Cv2">list_objects_v2</a></li>
<li><a href="#list%5Call%5Cobjects%5Cv2">list_all_objects_v2</a></li>
<li><a href="#get%5Cobject">get_object</a></li>
<li><a href="#head%5Cobject">head_object</a></li>
<li><a href="#put%5Cobject">put_object</a></li>
<li><a href="#copy%5Cobject">copy_object</a></li>
<li><a href="#delete%5Cobject">delete_object</a></li>
<li><a href="#list%5Cbuckets">list_buckets</a></li>
<li><a href="#create%5Cbucket">create_bucket</a></li>
<li><a href="#delete%5Cbucket">delete_bucket</a></li>
<li><a href="#put%5Cpublic%5Caccess%5Cblock">put_public_access_block</a></li>
<li><a href="#put%5Cbucket%5Cwebsite">put_bucket_website</a></li>
<li><a href="#get%5Cbucket%5Cwebsite">get_bucket_website</a></li>
<li><a href="#delete%5Cbucket%5Cwebsite">delete_bucket_website</a></li>
<li><a href="#put%5Cbucket%5Cpolicy">put_bucket_policy</a></li>
<li><a href="#get%5Cbucket%5Cpolicy">get_bucket_policy</a></li>
<li><a href="#put%5Cbucket%5Cnotification%5Cconfiguration">put_bucket_notification_configuration</a></li>
<li><a href="#get%5Cbucket%5Cnotification%5Cconfiguration">get_bucket_notification_configuration</a></li>
<li><a href="#remove%5Cbucket%5Cnotification%5Cconfiguration">remove_bucket_notification_configuration</a></li>
</ul>
</li>
<li><a href="#error-handling">ERROR HANDLING</a></li>
<li><a href="#dependencies">DEPENDENCIES</a></li>
<li><a href="#lambda-usage-notes">LAMBDA USAGE NOTES</a></li>
<li><a href="#testing">TESTING</a></li>
<li><a href="#see-also">SEE ALSO</a></li>
<li><a href="#author">AUTHOR</a></li>
<li><a href="#license">LICENSE</a></li>
</ul>
<a id="name" class="anchor" aria-label="Permalink: NAME" href="#name"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">NAME</h1>
<p>Amazon::S3::Lite - A lightweight Amazon S3 client for common
operations</p>
<a id="synopsis" class="anchor" aria-label="Permalink: SYNOPSIS" href="#synopsis"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">SYNOPSIS</h1>
<pre><code>use Amazon::S3::Lite;

# Credentials from environment or IAM role automatically
my $s3 = Amazon::S3::Lite-&gt;new({ region =&gt; 'us-east-1' });

# Explicit credentials
my $s3 = Amazon::S3::Lite-&gt;new({
  region                =&gt; 'us-east-1',
  aws_access_key_id     =&gt; $key,
  aws_secret_access_key =&gt; $secret,
  token                 =&gt; $session_token,  # optional, for STS/Lambda roles
});

# Pass any credentials object with standard getters
my $s3 = Amazon::S3::Lite-&gt;new({
  region      =&gt; 'us-east-1',
  credentials =&gt; $creds_obj,
});

# List objects in a bucket
my $result = $s3-&gt;list_objects_v2('my-bucket', prefix =&gt; 'logs/');

foreach my $obj ( @{ $result-&gt;{objects} } ) {
  printf "%s  %d bytes\n", $obj-&gt;{key}, $obj-&gt;{size};
}

# Paginate
while ( $result-&gt;{is_truncated} ) {
  $result = $s3-&gt;list_objects_v2('my-bucket',
    prefix             =&gt; 'logs/',
    continuation_token =&gt; $result-&gt;{next_continuation_token},
  );
  # ... process $result-&gt;{objects}
}

# Get an object
my $obj = $s3-&gt;get_object('my-bucket', 'path/to/key.json');
print $obj-&gt;{content};

# Head an object (existence check / metadata only)
my $meta = $s3-&gt;head_object('my-bucket', 'path/to/key.json');
if ($meta) {
  print $meta-&gt;{content_length};
}

# Put an object
$s3-&gt;put_object('my-bucket', 'path/to/key.json', $json_string,
  content_type =&gt; 'application/json',
  metadata     =&gt; { source =&gt; 'lambda' },
);

# Copy an object
$s3-&gt;copy_object(
  src_bucket =&gt; 'my-bucket', src_key =&gt; 'orig/file.json',
  dst_bucket =&gt; 'my-bucket', dst_key =&gt; 'archive/file.json',
);

# Delete an object
$s3-&gt;delete_object('my-bucket', 'path/to/key.json');

# List all buckets
my $result = $s3-&gt;list_buckets;
for my $bucket ( @{ $result-&gt;{buckets} } ) {
  print $bucket-&gt;{name}, "\n";
}

# Create a bucket
$s3-&gt;create_bucket('my-bucket');
$s3-&gt;create_bucket('my-bucket', region =&gt; 'eu-west-1');

# Configure a Lambda notification trigger
$s3-&gt;put_bucket_notification_configuration('my-bucket',
  type       =&gt; 'lambda',
  lambda_arn =&gt; $function_arn,
  events     =&gt; 's3:ObjectCreated:*',
  filters    =&gt; { prefix =&gt; 'uploads/' },
);

# Configure an SQS notification trigger
$s3-&gt;put_bucket_notification_configuration('my-bucket',
  type      =&gt; 'sqs',
  queue_arn =&gt; $queue_arn,
  events    =&gt; 's3:ObjectCreated:*',
);

# Retrieve notification configuration
my $configs = $s3-&gt;get_bucket_notification_configuration('my-bucket');
for my $cfg ( @{$configs} ) {
  printf "id=%s lambda=%s queue=%s\n",
    $cfg-&gt;{id}, $cfg-&gt;{lambda_arn} // '', $cfg-&gt;{queue_arn} // '';
}
</code></pre>
<a id="description" class="anchor" aria-label="Permalink: DESCRIPTION" href="#description"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">DESCRIPTION</h1>
<p><code>Amazon::S3::Lite</code> is a minimal Amazon S3 client covering the
operations most commonly needed in AWS Lambda functions and
lightweight scripts: listing buckets, listing objects, reading,
writing, copying, and deleting.</p>
<p>It is built on <a href="https://metacpan.org/pod/HTTP%3A%3ATiny" rel="nofollow">HTTP::Tiny</a> (core since Perl 5.14) and
<a href="https://metacpan.org/pod/Amazon%3A%3ASignature4%3A%3ALite" rel="nofollow">Amazon::Signature4::Lite</a>, with no dependency on LWP or any part of
the libwww-perl ecosystem. The dependency list is intentionally small,
making it well-suited for Lambda container images where minimizing
cold-start time and image size matters.</p>
<p>It is not a replacement for <a href="https://metacpan.org/pod/Amazon%3A%3AS3" rel="nofollow">Amazon::S3</a> or <a href="https://metacpan.org/pod/Net%3A%3AAmazon%3A%3AS3" rel="nofollow">Net::Amazon::S3</a>, which
support the full S3 API surface including multipart upload, bucket
management, ACLs, versioning, and presigned URLs. If you need those
features, use one of those distributions instead.</p>
<p><a href="https://metacpan.org/pod/Amazon%3A%3AS3%3A%3AThin" rel="nofollow">Amazon::S3::Thin</a> is another excellent lightweight S3 client with a
similar philosophy and a longer track record. It is more complete than
this module - supporting presigned URLs, bulk delete, and
virtual-hosted-style requests - and returns raw <a href="https://metacpan.org/pod/HTTP%3A%3AResponse" rel="nofollow">HTTP::Response</a>
objects so callers handle status codes and errors
themselves. <code>Amazon::S3::Lite</code> differs in three ways: it has no
dependency on LWP (<code>Amazon::S3::Thin</code> defaults to <a href="https://metacpan.org/pod/LWP%3A%3AUserAgent" rel="nofollow">LWP::UserAgent</a>),
it returns parsed hashrefs rather than raw response objects, and it
has first-class support for Lambda IAM role credential rotation. If
you need the broader feature set or prefer direct HTTP access,
<code>Amazon::S3::Thin</code> is a fine choice.</p>
<a id="constructor" class="anchor" aria-label="Permalink: CONSTRUCTOR" href="#constructor"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">CONSTRUCTOR</h1>
<a id="new" class="anchor" aria-label="Permalink: new" href="#new"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">new</h2>
<pre><code>my $s3 = Amazon::S3::Lite-&gt;new(\%options);
</code></pre>
<p>Returns a new <code>Amazon::S3::Lite</code> object. Options:</p>
<ul>
<li>
<p>region (options, default: us-east-1)</p>
<p>The AWS region for your bucket, e.g. <code>us-east-1</code>.</p>
</li>
<li>
<p>aws_access_key_id / aws_secret_access_key</p>
<p>Static credentials. <code>token</code> may also be supplied for STS temporary
credentials (as used by Lambda execution roles).</p>
<p>These are only consulted if no <code>credentials</code> object is provided.</p>
</li>
<li>
<p>token</p>
<p>Optional STS session token, used alongside static credentials for
temporary credential sets.</p>
</li>
<li>
<p>credentials</p>
<p>An object providing credential getters. The object must respond to:</p>
<pre><code>  $creds-&gt;aws_access_key_id
  $creds-&gt;aws_secret_access_key
  $creds-&gt;token            # may return undef
</code></pre>
<p>Any object that satisfies this interface is accepted -
<a href="https://metacpan.org/pod/Amazon%3A%3ACredentials" rel="nofollow">Amazon::Credentials</a>, <a href="https://metacpan.org/pod/Paws%3A%3ACredential%3A%3A%2A" rel="nofollow">Paws::Credential::*</a>, or your own. The
getters are called at request time, so objects that refresh expiring
credentials transparently are supported.</p>
</li>
<li>
<p>logger</p>
<p>An object providing the standard log methods:</p>
<pre><code>  $logger-&gt;trace(...)
  $logger-&gt;debug(...)
  $logger-&gt;info(...)
  $logger-&gt;warn(...)
  $logger-&gt;error(...)
</code></pre>
<p>If not supplied, the module looks for <a href="https://metacpan.org/pod/Log%3A%3ALog4perl" rel="nofollow">Log::Log4perl</a>. If available,
it calls <code>Log::Log4perl::easy_init</code> with the configure log level (or
WARN) and logs to STDERR.  If Log::Log4perl is not installed, a
minimal internal logger.</p>
</li>
<li>
<p>host</p>
<p>Override the S3 endpoint host. Defaults to <code>s3.amazonaws.com</code>.
Useful for S3-compatible services (MinIO, Ceph, LocalStack).</p>
</li>
<li>
<p>secure</p>
<p>Use HTTPS. Default is 1 (true). Set to 0 only for testing against
local S3-compatible endpoints.</p>
</li>
<li>
<p>timeout</p>
<p>HTTP request timeout in seconds. Default is 30.</p>
</li>
</ul>
<a id="credential-resolution-order" class="anchor" aria-label="Permalink: Credential resolution order" href="#credential-resolution-order"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Credential resolution order</h2>
<p>When no <code>credentials</code> object is passed, credentials are resolved in
this order:</p>
<ol>
<li>Constructor arguments <code>aws_access_key_id</code> and <code>aws_secret_access_key</code>.</li>
<li>Environment variables <code>AWS_ACCESS_KEY_ID</code>, <code>AWS_SECRET_ACCESS_KEY</code>,
and optionally <code>AWS_SESSION_TOKEN</code>.</li>
<li>
<a href="https://metacpan.org/pod/Amazon%3A%3ACredentials" rel="nofollow">Amazon::Credentials</a>, if installed. This covers IAM instance roles,
Lambda execution roles, ECS task roles, and <code>~/.aws/credentials</code>
profiles.</li>
<li>If none of the above yield credentials, the constructor croaks.</li>
</ol>
<a id="methods" class="anchor" aria-label="Permalink: METHODS" href="#methods"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">METHODS</h1>
<p>All methods croak on unrecoverable errors (network failure, HTTP 5xx).
HTTP 404 is not an exception - methods that can meaningfully return
<code>undef</code> for a missing resource do so.</p>
<a id="list_objects_v2" class="anchor" aria-label="Permalink: list_objects_v2" href="#list_objects_v2"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">list_objects_v2</h2>
<pre><code>my $result = $s3-&gt;list_objects_v2($bucket, %options);
</code></pre>
<p>Lists objects in <code>$bucket</code> using the S3 ListObjectsV2 API.</p>
<p>Options:</p>
<ul>
<li>
<p>prefix</p>
<p>Limit results to keys beginning with this string.</p>
</li>
<li>
<p>delimiter</p>
<p>Group keys sharing a common prefix up to this delimiter. Grouped
prefixes are returned in <code>common_prefixes</code>.</p>
</li>
<li>
<p>max_keys</p>
<p>Maximum number of objects to return per call (1-1000, default 1000).</p>
</li>
<li>
<p>continuation_token</p>
<p>Resume a truncated listing from a prior call's
<code>next_continuation_token</code>.</p>
</li>
<li>
<p>start_after</p>
<p>Return only keys lexicographically after this value.</p>
</li>
</ul>
<p>Returns a hashref:</p>
<pre><code>{
  bucket                 =&gt; 'my-bucket',
  prefix                 =&gt; 'logs/',
  is_truncated           =&gt; 0,
  next_continuation_token =&gt; undef,        # set when is_truncated is true
  key_count              =&gt; 42,
  objects                =&gt; [
    {
      key           =&gt; 'logs/2024-01-01.gz',
      size          =&gt; 102400,
      last_modified =&gt; '2024-01-01T00:00:00.000Z',
      etag          =&gt; 'abc123',
      storage_class =&gt; 'STANDARD',
    },
    ...
  ],
  common_prefixes        =&gt; [],            # populated when delimiter is set
}
</code></pre>
<a id="list_all_objects_v2" class="anchor" aria-label="Permalink: list_all_objects_v2" href="#list_all_objects_v2"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">list_all_objects_v2</h2>
<pre><code>my @objects = $s3-&gt;list_all_objects_v2($bucket, %options);
</code></pre>
<p>Convenience wrapper around <a href="#list_objects_v2">"list_objects_v2"</a> that automatically
follows continuation tokens and returns a flat list of all matching
object hashrefs in a single call.</p>
<p>Accepts the same options as <code>list_objects_v2</code> except
<code>continuation_token</code> (which is managed internally) and <code>delimiter</code>
(which is silently ignored - see below).</p>
<pre><code>my @logs = $s3-&gt;list_all_objects_v2('my-bucket', prefix =&gt; 'logs/');

foreach my $obj (@logs) {
  printf "%s  %d bytes\n", $obj-&gt;{key}, $obj-&gt;{size};
}
</code></pre>
<p>Be mindful of memory when listing buckets with large numbers of
objects.  For very large listings, use <a href="#list_objects_v2">"list_objects_v2"</a> directly
and process each page as it arrives.</p>
<p><code>delimiter</code> and <code>common_prefixes</code> are not supported by this method.
The purpose of <code>list_all_objects_v2</code> is a complete flat listing of
all matching keys. Hierarchical directory-style traversal using
<code>delimiter</code> is inherently page-by-page and should use
<a href="#list_objects_v2">"list_objects_v2"</a> directly.</p>
<p>Returns a (possibly empty) list of object hashrefs, each with the same
fields as the elements of <code>objects</code> in the <code>list_objects_v2</code>
response.</p>
<ul>
<li>
<p>log_level</p>
<p>Log level for the internal logger. Accepted values: <code>trace</code>, <code>debug</code>,
<code>info</code>, <code>warn</code>, <code>error</code>, <code>fatal</code>. Default is <code>warn</code>. Only consulted
when no <code>logger</code> object is supplied and Log::Log4perl is not available
or not yet initialized.</p>
</li>
</ul>
<a id="get_object" class="anchor" aria-label="Permalink: get_object" href="#get_object"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">get_object</h2>
<pre><code>my $obj = $s3-&gt;get_object($bucket, $key);
my $obj = $s3-&gt;get_object($bucket, $key, %options);
</code></pre>
<p>Fetches the object at <code>$key</code> in <code>$bucket</code>.</p>
<p>Returns <code>undef</code> if the key does not exist (HTTP 404).</p>
<p>Returns a hashref on success:</p>
<pre><code>{
  content        =&gt; '...',          # raw bytes; absent when filename is used
  content_type   =&gt; 'application/json',
  content_length =&gt; 1024,
  etag           =&gt; 'abc123',
  last_modified  =&gt; 'Tue, 01 Jan 2024 00:00:00 GMT',
  metadata       =&gt; {               # x-amz-meta-* headers, lowercased
    source =&gt; 'lambda',
  },
}
</code></pre>
<p>Options:</p>
<ul>
<li>
<p>range</p>
<p>An HTTP Range header value, e.g. <code>bytes=0-1023</code>, for partial fetches.</p>
</li>
<li>
<p>filename</p>
<p>Path to a local file where the object body should be written. When
supplied, the response body is streamed directly to disk via
HTTP::Tiny's <code>:content_file</code> mechanism and <code>content</code> is omitted from
the returned hashref. The file is created or overwritten.</p>
<pre><code>  my $meta = $s3-&gt;get_object('my-bucket', 'data/dump.csv',
    filename =&gt; '/tmp/dump.csv',
  );
  # $meta-&gt;{content} is absent; file is on disk
</code></pre>
<p>This is the recommended approach for large objects in Lambda where
holding the full body in memory is undesirable.</p>
</li>
</ul>
<a id="head_object" class="anchor" aria-label="Permalink: head_object" href="#head_object"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">head_object</h2>
<pre><code>my $meta = $s3-&gt;head_object($bucket, $key);
</code></pre>
<p>Fetches metadata for <code>$key</code> without retrieving the object body.
Useful for existence checks and reading <code>x-amz-meta-*</code> headers
cheaply.</p>
<p>Returns <code>undef</code> if the key does not exist (HTTP 404).</p>
<p>Returns a hashref on success with the same fields as <code>get_object</code>
except <code>content</code>, which is always absent.</p>
<a id="put_object" class="anchor" aria-label="Permalink: put_object" href="#put_object"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">put_object</h2>
<pre><code>$s3-&gt;put_object($bucket, $key, $data, %options);
</code></pre>
<p>Stores <code>$data</code> at <code>$key</code> in <code>$bucket</code>. <code>$data</code> may be:</p>
<ul>
<li>A scalar string (the object body verbatim)</li>
<li>A reference to a scalar (avoids copying large strings)</li>
<li>An open filehandle or <a href="https://metacpan.org/pod/IO%3A%3AFile" rel="nofollow">IO::File</a> object (body is read to EOF)</li>
</ul>
<p>When passing a filehandle, <code>content_length</code> becomes required unless
HTTP::Tiny can determine the size from the handle (i.e. the handle is
backed by a real file). For in-memory handles (<code>IO::Scalar</code>, etc.)
you must supply <code>content_length</code> explicitly, or the method will
croak.</p>
<pre><code># Scalar
$s3-&gt;put_object('my-bucket', 'hello.txt', 'Hello, world!',
  content_type =&gt; 'text/plain',
);

# Filehandle
open my $fh, '&lt;', '/tmp/data.csv' or die $!;
$s3-&gt;put_object('my-bucket', 'data.csv', $fh,
  content_type =&gt; 'text/csv',
);
</code></pre>
<p>Options:</p>
<ul>
<li>
<p>content_type</p>
<p>MIME type for the object. Defaults to <code>application/octet-stream</code>.</p>
</li>
<li>
<p>content_length</p>
<p>Required when <code>$data</code> is an in-memory filehandle. Optional (and
ignored) for scalar data, where length is computed automatically.</p>
</li>
<li>
<p>metadata</p>
<p>Hashref of user-defined metadata. Keys should be bare names - the
<code>x-amz-meta-</code> prefix is added automatically.</p>
<pre><code>  metadata =&gt; { source =&gt; 'lambda', job_id =&gt; '42' }
</code></pre>
</li>
<li>
<p>acl</p>
<p>Canned ACL string, e.g. <code>private</code> (default), <code>public-read</code>.</p>
</li>
</ul>
<p>Returns the ETag of the stored object on success. Croaks on failure.</p>
<a id="copy_object" class="anchor" aria-label="Permalink: copy_object" href="#copy_object"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">copy_object</h2>
<pre><code>$s3-&gt;copy_object(
  src_bucket =&gt; 'src-bucket',
  src_key    =&gt; 'original/key.json',
  dst_bucket =&gt; 'dst-bucket',
  dst_key    =&gt; 'copy/key.json',
);
</code></pre>
<p>Copies an object within or between buckets without transferring data
through the client. The copy is performed entirely server-side by S3.</p>
<p>Returns a hashref on success:</p>
<pre><code>{
  etag          =&gt; 'abc123',
  last_modified =&gt; '2024-01-01T00:00:00.000Z',
}
</code></pre>
<p>Croaks on failure.</p>
<a id="delete_object" class="anchor" aria-label="Permalink: delete_object" href="#delete_object"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">delete_object</h2>
<pre><code>$s3-&gt;delete_object($bucket, $key);
$s3-&gt;delete_object($bucket, $key, version_id =&gt; $vid);
</code></pre>
<p>Deletes the object at <code>$key</code> in <code>$bucket</code>.</p>
<p>If <code>version_id</code> is provided, that specific version is deleted.</p>
<p>Returns true on success. Note that S3 returns HTTP 204 for both
successful deletes <em>and</em> deletes of non-existent keys, so this method
does not distinguish between the two - it succeeds silently in either
case.</p>
<a id="list_buckets" class="anchor" aria-label="Permalink: list_buckets" href="#list_buckets"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">list_buckets</h2>
<pre><code>my $result = $s3-&gt;list_buckets;
</code></pre>
<p>Lists all S3 buckets owned by the authenticated account.</p>
<p>Returns a hashref:</p>
<pre><code>{
  owner_id   =&gt; 'abc123...',
  owner_name =&gt; 'myaccount',
  buckets    =&gt; [
    { name =&gt; 'my-bucket',    creation_date =&gt; '2024-01-01T00:00:00.000Z' },
    { name =&gt; 'other-bucket', creation_date =&gt; '2024-06-01T00:00:00.000Z' },
    ...
  ],
}
</code></pre>
<p>Note that this operation is always signed against <code>us-east-1</code>
regardless of the region the object was constructed with. See
<a href="#lambda-usage-notes">"LAMBDA USAGE NOTES"</a>.</p>
<a id="create_bucket" class="anchor" aria-label="Permalink: create_bucket" href="#create_bucket"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">create_bucket</h2>
<pre><code>$s3-&gt;create_bucket($bucket);
$s3-&gt;create_bucket($bucket, region =&gt; 'eu-west-1', acl =&gt; 'private');
</code></pre>
<p>Creates a new S3 bucket. Options:</p>
<ul>
<li>
<p>region</p>
<p>The region in which to create the bucket. Defaults to the region the
object was constructed with. <strong>Note:</strong> <code>us-east-1</code> is S3's implicit
default - the <code>CreateBucketConfiguration</code> body is intentionally
omitted for that region as including it causes a <code>InvalidLocationConstraint</code>
error. For all other regions the <code>LocationConstraint</code> element is
sent automatically.</p>
</li>
<li>
<p>acl</p>
<p>Canned ACL string, e.g. <code>private</code> (the S3 default), <code>public-read</code>.</p>
</li>
</ul>
<p>Returns true on success. Croaks on failure.</p>
<a id="delete_bucket" class="anchor" aria-label="Permalink: delete_bucket" href="#delete_bucket"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">delete_bucket</h2>
<pre><code>$s3-&gt;delete_bucket($bucket);
$s3-&gt;delete_bucket($bucket, region =&gt; 'us-west-2');
</code></pre>
<p>Deletes an empty bucket. Returns a true value on success. S3 refuses
to delete a bucket that still contains objects, so callers must empty
the bucket first (for example by iterating <a href="#list_all_objects_v2">"list_all_objects_v2"</a> and
calling <a href="#delete_object">"delete_object"</a> on each key).</p>
<ul>
<li>
<p>region</p>
<p>Override the region the delete is signed against. Defaults to the
region the object was constructed with.</p>
</li>
</ul>
<a id="put_public_access_block" class="anchor" aria-label="Permalink: put_public_access_block" href="#put_public_access_block"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">put_public_access_block</h2>
<pre><code>$s3-&gt;put_public_access_block($bucket);
$s3-&gt;put_public_access_block(
  $bucket,
  block_public_acls       =&gt; 1,
  ignore_public_acls      =&gt; 1,
  block_public_policy      =&gt; 0,
  restrict_public_buckets =&gt; 0,
);
</code></pre>
<p>Sets the Block Public Access configuration on a bucket. Each of the
four settings is a boolean; any setting not supplied <strong>defaults to
true</strong> (fully locked down), so an argument-less call blocks all public
access. Returns a true value on success.</p>
<ul>
<li>
<p>block_public_acls</p>
</li>
<li>
<p>ignore_public_acls</p>
</li>
<li>
<p>block_public_policy</p>
</li>
<li>
<p>restrict_public_buckets</p>
<p>Each accepts a true/false value. Omitted settings default to true.
Note that hosting content publicly (for example a static website, or
a policy-scoped private bucket that grants anonymous <code>GetObject</code> from
a VPC endpoint) requires the relevant setting to be false so the
bucket policy is not rejected.</p>
</li>
</ul>
<a id="put_bucket_website" class="anchor" aria-label="Permalink: put_bucket_website" href="#put_bucket_website"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">put_bucket_website</h2>
<pre><code>$s3-&gt;put_bucket_website($bucket);
$s3-&gt;put_bucket_website($bucket, index =&gt; 'index.html', error =&gt; 'error.html');
</code></pre>
<p>Configures the bucket as an S3 static website endpoint. Returns a true
value on success.</p>
<ul>
<li>
<p>index</p>
<p>The index document suffix. Defaults to <code>index.html</code>.</p>
</li>
<li>
<p>error</p>
<p>The error document key. Optional; when omitted, no error document is
configured.</p>
</li>
</ul>
<a id="get_bucket_website" class="anchor" aria-label="Permalink: get_bucket_website" href="#get_bucket_website"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">get_bucket_website</h2>
<pre><code>my $config = $s3-&gt;get_bucket_website($bucket);
</code></pre>
<p>Returns the bucket's website configuration as a hashref, or <code>undef</code>
if the bucket has no website configuration. The hashref contains
whichever of the following are set:</p>
<ul>
<li>
<p>index_document</p>
<p>The index document suffix.</p>
</li>
<li>
<p>error_document</p>
<p>The error document key.</p>
</li>
<li>
<p>redirect_all_requests_to</p>
<p>The hostname all requests are redirected to, if the bucket is
configured as a redirect.</p>
</li>
</ul>
<a id="delete_bucket_website" class="anchor" aria-label="Permalink: delete_bucket_website" href="#delete_bucket_website"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">delete_bucket_website</h2>
<pre><code>$s3-&gt;delete_bucket_website($bucket);
</code></pre>
<p>Removes the website configuration from a bucket. Returns a true value
on success.</p>
<a id="put_bucket_policy" class="anchor" aria-label="Permalink: put_bucket_policy" href="#put_bucket_policy"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">put_bucket_policy</h2>
<pre><code>$s3-&gt;put_bucket_policy($bucket, \%policy);
$s3-&gt;put_bucket_policy($bucket, $json_string);
</code></pre>
<p>Attaches a bucket policy. The policy may be given either as a Perl
data structure (a hashref, which is encoded to canonical JSON) or as a
pre-encoded JSON string. Returns a true value on success.</p>
<a id="get_bucket_policy" class="anchor" aria-label="Permalink: get_bucket_policy" href="#get_bucket_policy"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">get_bucket_policy</h2>
<pre><code>my $policy = $s3-&gt;get_bucket_policy($bucket);
my $json   = $s3-&gt;get_bucket_policy($bucket, raw =&gt; 1);
</code></pre>
<p>Returns the bucket's policy, or <code>undef</code> if the bucket has no policy
(S3 returns <code>NoSuchBucketPolicy</code>). By default the policy is decoded
and returned as a hashref; pass <code>raw =&gt; 1</code> to get the raw JSON
string instead.</p>
<ul>
<li>
<p>raw</p>
<p>When true, return the policy as its raw JSON string rather than a
decoded hashref.</p>
</li>
</ul>
<a id="put_bucket_notification_configuration" class="anchor" aria-label="Permalink: put_bucket_notification_configuration" href="#put_bucket_notification_configuration"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">put_bucket_notification_configuration</h2>
<pre><code># Lambda trigger
$s3-&gt;put_bucket_notification_configuration($bucket,
  type       =&gt; 'lambda',
  lambda_arn =&gt; $function_arn,
  events     =&gt; 's3:ObjectCreated:*',
);

# SQS trigger
$s3-&gt;put_bucket_notification_configuration($bucket,
  type      =&gt; 'sqs',
  queue_arn =&gt; $queue_arn,
  events    =&gt; [qw(s3:ObjectCreated:* s3:ObjectRemoved:*)],
  filters   =&gt; { prefix =&gt; 'uploads/', suffix =&gt; '.csv' },
);
</code></pre>
<p>Sets the bucket notification configuration for <code>$bucket</code>, routing
S3 events to a Lambda function or SQS queue.</p>
<p>Options:</p>
<ul>
<li>
<p>type (required)</p>
<p>The notification target type. Must be <code>lambda</code> or <code>sqs</code>.</p>
</li>
<li>
<p>lambda_arn (required when type is <code>lambda</code>)</p>
<p>The ARN of the Lambda function to invoke.</p>
</li>
<li>
<p>queue_arn (required when type is <code>sqs</code>)</p>
<p>The ARN of the SQS queue to deliver messages to.</p>
</li>
<li>
<p>events (required)</p>
<p>A scalar event name or an arrayref of event names.
Common values: <code>s3:ObjectCreated:*</code>, <code>s3:ObjectRemoved:*</code>.</p>
</li>
<li>
<p>filters</p>
<p>A hashref of S3 key filter rules. Supported keys are <code>prefix</code>
and <code>suffix</code>.</p>
</li>
<li>
<p>id</p>
<p>An identifier for the configuration entry. Defaults to <code>notification-1</code>.</p>
</li>
</ul>
<p>Returns true on success. Croaks on failure.</p>
<a id="get_bucket_notification_configuration" class="anchor" aria-label="Permalink: get_bucket_notification_configuration" href="#get_bucket_notification_configuration"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">get_bucket_notification_configuration</h2>
<pre><code>my $configs = $s3-&gt;get_bucket_notification_configuration($bucket);

for my $cfg ( @{$configs} ) {
  if ( $cfg-&gt;{lambda_arn} ) {
    printf "Lambda: id=%s arn=%s\n", $cfg-&gt;{id}, $cfg-&gt;{lambda_arn};
  }
  elsif ( $cfg-&gt;{queue_arn} ) {
    printf "SQS:    id=%s arn=%s\n", $cfg-&gt;{id}, $cfg-&gt;{queue_arn};
  }
  print "  events: ", join(', ', @{ $cfg-&gt;{events} }), "\n";
}
</code></pre>
<p>Retrieves the current notification configuration for <code>$bucket</code>.
Handles both Lambda (<code>CloudFunctionConfiguration</code>) and SQS
(<code>QueueConfiguration</code>) entries, which are the XML element names
the S3 API returns regardless of how the configuration was created.</p>
<p>Returns an arrayref of configuration hashrefs, each containing:</p>
<ul>
<li>
<p>id</p>
<p>The configuration entry identifier.</p>
</li>
<li>
<p>lambda_arn</p>
<p>The Lambda function ARN. Present for Lambda notification entries;
<code>undef</code> for SQS entries.</p>
</li>
<li>
<p>queue_arn</p>
<p>The SQS queue ARN. Present for SQS notification entries;
<code>undef</code> for Lambda entries.</p>
</li>
<li>
<p>events</p>
<p>Arrayref of event type strings.</p>
</li>
<li>
<p>filters</p>
<p>Arrayref of hashrefs, each with <code>name</code> (<code>prefix</code> or <code>suffix</code>)
and <code>value</code>.</p>
</li>
</ul>
<p>Returns an empty arrayref if no notification configuration is set.
Croaks on failure.</p>
<a id="remove_bucket_notification_configuration" class="anchor" aria-label="Permalink: remove_bucket_notification_configuration" href="#remove_bucket_notification_configuration"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">remove_bucket_notification_configuration</h2>
<pre><code>$s3-&gt;remove_bucket_notification_configuration($bucket);
</code></pre>
<p>Removes all notification configurations from <code>$bucket</code> by sending an
empty <code>NotificationConfiguration</code> document to S3. After this call S3
will no longer deliver any events for the bucket.</p>
<p>Returns true on success. Croaks on failure.</p>
<a id="error-handling" class="anchor" aria-label="Permalink: ERROR HANDLING" href="#error-handling"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">ERROR HANDLING</h1>
<p>Methods croak on:</p>
<ul>
<li>Network-level failures (connection refused, timeout, DNS failure)</li>
<li>HTTP 5xx responses from S3</li>
<li>Unexpected HTTP 3xx responses that could not be resolved</li>
</ul>
<p>Methods return <code>undef</code> on:</p>
<ul>
<li>HTTP 404 (key or bucket not found), where the return type allows it</li>
</ul>
<p>All other HTTP error codes (400, 403, 409, etc.) cause a croak with a
message containing the HTTP status line and the S3 error body where
available.</p>
<a id="dependencies" class="anchor" aria-label="Permalink: DEPENDENCIES" href="#dependencies"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">DEPENDENCIES</h1>
<ul>
<li>
<a href="https://metacpan.org/pod/HTTP%3A%3ATiny" rel="nofollow">HTTP::Tiny</a> (core since Perl 5.14)</li>
<li><a href="https://metacpan.org/pod/Amazon%3A%3ASignature4%3A%3ALite" rel="nofollow">Amazon::Signature4::Lite</a></li>
<li>
<a href="https://metacpan.org/pod/XML%3A%3ATwig" rel="nofollow">XML::Twig</a> (for parsing list and copy responses)</li>
<li>
<a href="https://metacpan.org/pod/Digest%3A%3AMD5" rel="nofollow">Digest::MD5</a> (core, for Content-MD5 headers)</li>
<li>
<a href="https://metacpan.org/pod/MIME%3A%3ABase64" rel="nofollow">MIME::Base64</a> (core)</li>
<li><a href="https://metacpan.org/pod/URI%3A%3AEscape" rel="nofollow">URI::Escape</a></li>
<li>
<a href="https://metacpan.org/pod/Carp" rel="nofollow">Carp</a> (core)</li>
</ul>
<p>Optional:</p>
<ul>
<li>
<a href="https://metacpan.org/pod/Amazon%3A%3ACredentials" rel="nofollow">Amazon::Credentials</a> - automatic credential discovery from IAM
roles, ECS task roles, ~/.aws/credentials, and environment.</li>
<li>
<a href="https://metacpan.org/pod/Log%3A%3ALog4perl" rel="nofollow">Log::Log4perl</a> - structured logging; if present, used in
preference to the built-in minimal logger.</li>
</ul>
<a id="lambda-usage-notes" class="anchor" aria-label="Permalink: LAMBDA USAGE NOTES" href="#lambda-usage-notes"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">LAMBDA USAGE NOTES</h1>
<p>In a Lambda container, credentials come from the execution role via
the ECS credential provider endpoint (indicated by
<code>AWS_CONTAINER_CREDENTIALS_RELATIVE_URI</code> in the environment).
<a href="https://metacpan.org/pod/Amazon%3A%3ACredentials" rel="nofollow">Amazon::Credentials</a> handles this automatically when installed and
is the recommended approach. If you prefer not to take that
dependency, the Lambda runtime also populates <code>AWS_ACCESS_KEY_ID</code>,
<code>AWS_SECRET_ACCESS_KEY</code>, and <code>AWS_SESSION_TOKEN</code> directly, which
this module picks up automatically from the environment.</p>
<p><strong>Region note:</strong> The <code>list_buckets</code> method is a global S3 operation
and is always signed against <code>us-east-1</code>, regardless of the region
supplied to the constructor. This is an S3 requirement, not a
limitation of this module, and is handled transparently - your
object's region is not changed.</p>
<p><strong>Cold start:</strong> Because this module depends only on <a href="https://metacpan.org/pod/HTTP%3A%3ATiny" rel="nofollow">HTTP::Tiny</a> (Perl
core), <a href="https://metacpan.org/pod/XML%3A%3ATwig" rel="nofollow">XML::Twig</a>, <a href="https://metacpan.org/pod/AWS%3A%3ASignature4" rel="nofollow">AWS::Signature4</a>, and <a href="https://metacpan.org/pod/URI%3A%3AEscape" rel="nofollow">URI::Escape</a>, it adds
minimal overhead to Lambda container image builds compared to
LWP-based S3 clients.</p>
<a id="testing" class="anchor" aria-label="Permalink: TESTING" href="#testing"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">TESTING</h1>
<p>When testing against LocalStack, be aware that LocalStack is more
lenient than real S3 regarding SigV4 requirements. In particular,
LocalStack may accept requests where the <code>x-amz-content-sha256</code>
header is missing or where session token handling is incorrect. Tests
that pass against LocalStack should always be verified against real S3
before release.</p>
<a id="see-also" class="anchor" aria-label="Permalink: SEE ALSO" href="#see-also"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">SEE ALSO</h1>
<p><a href="https://metacpan.org/pod/Amazon%3A%3AS3" rel="nofollow">Amazon::S3</a> - the full-featured S3 client this module draws from</p>
<p><a href="https://metacpan.org/pod/Amazon%3A%3AS3%3A%3AThin" rel="nofollow">Amazon::S3::Thin</a> - another excellent lightweight S3 client with a
similar philosophy, broader feature coverage, and a longer track
record. Uses LWP by default and returns raw <a href="https://metacpan.org/pod/HTTP%3A%3AResponse" rel="nofollow">HTTP::Response</a>
objects. See <a href="#description">"DESCRIPTION"</a> for a detailed comparison.</p>
<p><a href="https://metacpan.org/pod/Net%3A%3AAmazon%3A%3AS3" rel="nofollow">Net::Amazon::S3</a> - a Moose-based full-featured alternative</p>
<p><a href="https://metacpan.org/pod/Amazon%3A%3ASignature4%3A%3ALite" rel="nofollow">Amazon::Signature4::Lite</a> - the signing module used internally</p>
<p><a href="https://metacpan.org/pod/Amazon%3A%3ACredentials" rel="nofollow">Amazon::Credentials</a> - credential provider with IAM role and profile
support</p>
<a id="author" class="anchor" aria-label="Permalink: AUTHOR" href="#author"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">AUTHOR</h1>
<p>Rob Lauer <a href="mailto:rlauer@treasurersbriefcase.com">rlauer@treasurersbriefcase.com</a></p>
<a id="license" class="anchor" aria-label="Permalink: LICENSE" href="#license"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">LICENSE</h1>
<p>This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.</p>
