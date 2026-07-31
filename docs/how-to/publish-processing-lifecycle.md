# Publish a processing lifecycle

Use the three commands in this guide to represent an OGC API - Processes
process, job, and result as an Open Science Catalog workflow, experiment, and
product.

## Set the common values

The examples use shell variables only to keep the commands readable:

```bash
SOURCE=https://example.org/workflows/process.cwl
PROCESSES=https://processes.example.org
GEOBROWSER=https://browser.example.org
OUTPUT=./build/catalog
PROJECT_ID=my-project
PROJECT_NAME="My Project"
```

If the source or service is protected, first follow
[Configure sources and authentication](configure-sources.md).

## Convert the process to a workflow record

Use the process identifier as `--id`:

```bash
osc-metadata-client \
  --id process-001 \
  --project-id "$PROJECT_ID" \
  --project-name "$PROJECT_NAME" \
  --ogc-api-processes-endpoint "$PROCESSES" \
  --geobrowser-endpoint "$GEOBROWSER" \
  --output "$OUTPUT" \
  "$SOURCE" \
  workflow
```

This creates `workflows/process-001/record.json` and links it to
`/processes/process-001`.

## Convert a successful job to an experiment record

Use the job identifier as `--id` and identify its workflow:

```bash
osc-metadata-client \
  --id job-001 \
  --project-id "$PROJECT_ID" \
  --project-name "$PROJECT_NAME" \
  --ogc-api-processes-endpoint "$PROCESSES" \
  --geobrowser-endpoint "$GEOBROWSER" \
  --output "$OUTPUT" \
  "$SOURCE" \
  experiment \
  --workflow-id process-001
```

The client polls `/jobs/job-001` until the job reaches a terminal state. It
creates the experiment record only for a successful job and serializes the job
inputs beside it.

## Convert the result to a product collection

Use the same job identifier and identify the experiment record:

```bash
osc-metadata-client \
  --id job-001 \
  --project-id "$PROJECT_ID" \
  --project-name "$PROJECT_NAME" \
  --ogc-api-processes-endpoint "$PROCESSES" \
  --geobrowser-endpoint "$GEOBROWSER" \
  --output "$OUTPUT" \
  "$SOURCE" \
  products \
  --experiment-id job-001
```

The client retrieves `/jobs/job-001/results`, writes the output parameters, and
creates a product STAC Collection. The collection is enriched through this
project's typed PySTAC implementations of the
[OSC](https://github.com/stac-extensions/osc) and
[Themes](https://github.com/stac-extensions/themes) extensions.

Review the complete [generated-files reference](../reference/outputs.md) before
committing the files to an Open Science Catalog metadata repository.
