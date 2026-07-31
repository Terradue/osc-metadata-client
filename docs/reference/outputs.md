# Generated files reference

The output directory follows the Open Science Catalog resource layout.

| Command | Primary record | Companion data |
| --- | --- | --- |
| `workflow` | `workflows/ID/record.json` | none |
| `experiment` | `experiments/ID/record.json` | `experiments/ID/input.yaml` |
| `products` | `products/ID/collection.json` | `products/ID/output.yaml` |

The client also creates or updates the resource-level `catalog.json` associated
with the generated record.

## Workflow record

The workflow is an OGC API Record derived from Schema.org metadata in the CWL
source. It has `osc:type: workflow`, identifies its OSC project, and links to the
CWL application, OGC process, Geobrowser process page, project, and catalog.

## Experiment record

The experiment is an OGC API Record for an OGC job. It records the workflow and
project relationships, execution start/end provenance, a `/jobs/{id}` link, and
an `input` link to `input.yaml`.

The record also contains an `environment` link to `environment.yaml`. The client
does not create that environment file; a surrounding publication workflow may
supply it.

## Product collection

The product is a STAC Collection for a successful job result. It links to the
project, experiment, theme, `/jobs/{id}/results`, Geobrowser job page, and
`output.yaml`.

The collection declares the versioned OSC and Themes schema URIs in
`stac_extensions`, and stores their fields through the corresponding typed
PySTAC implementations.
