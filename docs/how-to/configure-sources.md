# Configure sources and authentication

The CWL `SOURCE` argument accepts HTTP(S), local `file://`, and OCI URLs.

## Use an HTTP(S) source

Pass its URL directly. For a protected source or OGC API - Processes service,
provide an OAuth2 bearer token:

```bash
export OAUTH2_BEARER=replace-with-token
osc-metadata-client [OPTIONS] https://example.org/process.cwl COMMAND
```

You can instead pass `--oauth2-bearer TOKEN` before `SOURCE`. The same token is
used for HTTP(S) CWL retrieval and OGC API - Processes job and result requests.

## Use a local source

Use an absolute file URL:

```bash
osc-metadata-client [OPTIONS] file:///absolute/path/process.cwl COMMAND
```

## Use an OCI source

Configure the registry credentials and pass an `oci://` URL:

```bash
export OCI_HOSTNAME=registry.example.org
export OCI_USERNAME=my-user
export OCI_PASSWORD=replace-with-password
osc-metadata-client [OPTIONS] oci://registry.example.org/project/process:tag COMMAND
```

The equivalent CLI options are `--oci-hostname`, `--oci-username`, and
`--oci-password`. Put all of them before `SOURCE`.

Avoid embedding credentials in source URLs or committing tokens to scripts.
