# CLI reference

## Command shape

```text
osc-metadata-client [OPTIONS] SOURCE COMMAND [ARGS]...
```

`SOURCE` is the annotated CWL document used to initialize the metadata record.
Shared options must appear before `SOURCE`; command-specific options appear after
the command.

## Shared options

| Option | Required | Description |
| --- | --- | --- |
| `--id TEXT` | yes | Process ID for `workflow`; job ID for `experiment` and `products`. |
| `--project-id TEXT` | yes | Referencing Open Science Catalog project identifier. |
| `--project-name TEXT` | yes | Human-readable project name. |
| `--ogc-api-processes-endpoint TEXT` | yes | OGC API - Processes base URL. |
| `--geobrowser-endpoint TEXT` | yes | Geobrowser base URL. |
| `--output PATH` | yes | Root directory for generated metadata. |
| `--oauth2-bearer TEXT` | no | Token for HTTP(S) source and OGC API requests; environment: `OAUTH2_BEARER`. |
| `--oci-hostname TEXT` | no | OCI registry hostname; environment: `OCI_HOSTNAME`. |
| `--oci-username TEXT` | no | OCI registry username; environment: `OCI_USERNAME`. |
| `--oci-password TEXT` | no | OCI registry password; environment: `OCI_PASSWORD`. |

Without `--oauth2-bearer`, HTTP(S) requests are unauthenticated.

## `workflow`

```text
osc-metadata-client [OPTIONS] SOURCE workflow
```

Converts CWL application metadata into an Open Science Catalog workflow OGC API
Record. It adds links to the source, `/processes/{id}`, and the Geobrowser process
page.

Output: `OUTPUT/workflows/ID/record.json`

![Workflow flow diagram](../diagrams/out/flow/workflow.svg)

![Workflow sequence diagram](../diagrams/out/sequence/workflow.svg)

## `experiment`

```text
osc-metadata-client [OPTIONS] SOURCE experiment --workflow-id TEXT
```

| Option | Required | Description |
| --- | --- | --- |
| `--workflow-id TEXT` | yes | Identifier of the workflow related to this job. |

Polls `/jobs/{id}` until the job reaches a terminal state. A successful job
produces an experiment OGC API Record and serialized inputs; any other terminal
status fails the command.

Outputs:

```text
OUTPUT/experiments/ID/record.json
OUTPUT/experiments/ID/input.yaml
```

![Experiment flow diagram](../diagrams/out/flow/experiments.svg)

![Experiment sequence diagram](../diagrams/out/sequence/experiments.svg)

## `products`

```text
osc-metadata-client [OPTIONS] SOURCE products --experiment-id TEXT
```

| Option | Required | Description |
| --- | --- | --- |
| `--experiment-id TEXT` | yes | Identifier of the experiment related to this result. |

Confirms the job succeeded, retrieves `/jobs/{id}/results`, and creates a product
STAC Collection using the OSC and Themes PySTAC extensions.

Outputs:

```text
OUTPUT/products/ID/collection.json
OUTPUT/products/ID/output.yaml
```

![Products flow diagram](../diagrams/out/flow/products.svg)

![Products sequence diagram](../diagrams/out/sequence/products.svg)
