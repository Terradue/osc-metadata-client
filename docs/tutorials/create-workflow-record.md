# Create your first workflow record

In this tutorial you will convert the metadata in an annotated CWL document into
an Open Science Catalog workflow record. The result is a local JSON file ready
to be added to an Open Science Catalog metadata tree.

## Before you begin

You need Python 3.10 or newer and a CWL workflow containing
Schema.org `SoftwareApplication` metadata. You also need the public URLs of the
OGC API - Processes service and its Geobrowser. The command records these URLs as
links; it does not deploy the process.

Install the client:

```bash
python -m pip install osc-metadata-client
```

Check that the command is available:

```bash
osc-metadata-client --help
```

## Generate the record

Choose an identifier that matches the deployed process identifier. Then run:

```bash
osc-metadata-client \
  --id my-process \
  --project-id my-project \
  --project-name "My Project" \
  --ogc-api-processes-endpoint https://processes.example.org \
  --geobrowser-endpoint https://browser.example.org \
  --output ./build/catalog \
  file:///absolute/path/to/my-process.cwl \
  workflow
```

All shared options appear before the CWL source. The `workflow` subcommand comes
last.

## Inspect the result

Open the generated file:

```text
build/catalog/workflows/my-process/record.json
```

The record contains metadata extracted from the CWL document plus:

- `osc:type` set to `workflow` and the associated project identifier;
- a link to the source CWL document;
- a link to `/processes/my-process` on the OGC API - Processes service;
- a link to the matching Geobrowser page.

The CWL metadata extraction and base OGC API Record are provided by Terradue's
[transpiler-mate](https://terradue.github.io/transpiler-mate/) API. This client
adds the catalog-specific fields and relationships.

You have now completed the process-to-workflow part of the conversion. Continue
with the [processing lifecycle how-to guide](../how-to/publish-processing-lifecycle.md)
to create experiment and product metadata from a job and its results.
