# CLI Reference

`osc-metadata-client` generates Open Science Catalog metadata from
[CWL](https://www.commonwl.org/) workflows and executions exposed through
[OGC API - Processes](https://docs.ogc.org/is/18-062r2/18-062r2.html).

The CLI provides three subcommands:

- `workflow`
- `experiment`
- `products`

## Base command

```text
osc-metadata-client [OPTIONS] SOURCE COMMAND [ARGS]...
```

`SOURCE` identifies the CWL document used to bootstrap the metadata record. The
configured request session supports HTTP(S), `file://`, and OCI sources.

All shared options must appear before `SOURCE`. Subcommand-specific options appear
after the subcommand name.

## Shared options

The following options are required for every subcommand:

| Option | Description |
| --- | --- |
| `--id TEXT` | Identifier assigned to the generated workflow, experiment, or product record. |
| `--project-id TEXT` | Referencing Open Science Catalog project identifier. |
| `--project-name TEXT` | Human-readable project name. |
| `--ogc-api-processes-endpoint TEXT` | Base URL used to construct OGC API - Processes links and retrieve job information. |
| `--geobrowser-endpoint TEXT` | Base URL used to construct human-readable Geobrowser links. |
| `--output PATH` | Root directory for generated metadata. |

The following shared authentication options are optional:

| Option | Environment variable | Description |
| --- | --- | --- |
| `--oauth2-bearer TEXT` | `OAUTH2_BEARER` | Bearer token used for HTTP(S) source retrieval and authenticated OGC API - Processes requests. |
| `--oci-hostname TEXT` | `OCI_HOSTNAME` | OCI registry hostname. |
| `--oci-username TEXT` | `OCI_USERNAME` | OCI registry username. |
| `--oci-password TEXT` | `OCI_PASSWORD` | OCI registry password. |

When `--oauth2-bearer` is omitted, the client uses the standard unauthenticated
HTTP adapter. Authentication is configured once on the base command; the
`experiment` and `products` subcommands do not accept a separate authorization
option.

## `workflow`

The `workflow` command transpiles metadata from the CWL source and enriches it as
an Open Science Catalog workflow record.

### Syntax

```bash
osc-metadata-client \
  --id workflow-001 \
  --project-id my-project \
  --project-name "My Project" \
  --ogc-api-processes-endpoint https://processes.example.org \
  --geobrowser-endpoint https://browser.example.org \
  --output ./build/catalog \
  https://example.org/workflows/process.cwl \
  workflow
```

The generated record includes links to the source CWL application, its OGC API -
Processes process page, and its Geobrowser process page.

### Output

```text
OUTPUT/workflows/ID/record.json
```

### Diagrams

![Workflow flow diagram](diagrams/out/flow/workflow.svg)

![Workflow sequence diagram](diagrams/out/sequence/workflow.svg)

## `experiment`

The `experiment` command retrieves job status and input information, links the
execution to its workflow, and enriches the metadata with provenance fields.

### Syntax

```bash
osc-metadata-client \
  --id job-001 \
  --project-id my-project \
  --project-name "My Project" \
  --ogc-api-processes-endpoint https://processes.example.org \
  --geobrowser-endpoint https://browser.example.org \
  --output ./build/catalog \
  --oauth2-bearer "$OAUTH2_BEARER" \
  https://example.org/workflows/process.cwl \
  experiment \
  --workflow-id workflow-001
```

`--workflow-id` is required and identifies the workflow record related to the
experiment.

The command polls the job until it reaches a terminal state. A successful job
produces the experiment record and its serialized inputs; an unsuccessful status
causes the command to fail.

### Output

```text
OUTPUT/experiments/ID/record.json
OUTPUT/experiments/ID/input.yaml
```

### Diagrams

![Experiment flow diagram](diagrams/out/flow/experiments.svg)

![Experiment sequence diagram](diagrams/out/sequence/experiments.svg)

## `products`

The `products` command retrieves a successful job result and creates a STAC
Collection enriched with the Open Science Catalog and themes extensions.

### Syntax

```bash
osc-metadata-client \
  --id job-001 \
  --project-id my-project \
  --project-name "My Project" \
  --ogc-api-processes-endpoint https://processes.example.org \
  --geobrowser-endpoint https://browser.example.org \
  --output ./build/catalog \
  --oauth2-bearer "$OAUTH2_BEARER" \
  https://example.org/workflows/process.cwl \
  products \
  --experiment-id experiment-001
```

`--experiment-id` is required and identifies the experiment related to the
generated product collection.

The collection includes links to the OGC API - Processes result, the Geobrowser
result page, the experiment, and the serialized output parameters.

### Output

```text
OUTPUT/products/ID/collection.json
OUTPUT/products/ID/output.yaml
```

### Diagrams

![Products flow diagram](diagrams/out/flow/products.svg)

![Products sequence diagram](diagrams/out/sequence/products.svg)
