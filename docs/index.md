# Open Science Catalog Client

`osc-metadata-client` is a small connector that converts the metadata around
[OGC API - Processes](https://docs.ogc.org/is/18-062r2/18-062r2.html)
processes, jobs, and results into records for the ESA
[Open Science Catalog](https://opensciencedata.esa.int/).

It has one deliberately narrow responsibility:

| OGC API - Processes resource | Open Science Catalog representation |
| --- | --- |
| Process and its annotated CWL source | Workflow OGC API Record |
| Job and its inputs/status | Experiment OGC API Record |
| Successful job result | Product STAC Collection |

The client is not a workflow engine, an OGC API - Processes server, or a catalog
publisher. It prepares catalog-ready files that another publication workflow can
commit or publish.

## Built on Terradue's metadata API

The initial CWL-to-OGC API Records conversion is performed by Terradue's
[transpiler-mate](https://terradue.github.io/transpiler-mate/) Python API. This
client builds on that conversion by adding Open Science Catalog resource types,
relationships, provenance, OGC API - Processes links, and result metadata.

## Native PySTAC extension support

The project includes proper, typed PySTAC implementations for both the
[STAC Themes extension](https://github.com/stac-extensions/themes) and the
[STAC Open Science Catalog extension](https://github.com/stac-extensions/osc).
They use PySTAC's extension interfaces and hooks rather than inserting untyped
JSON fields directly. See the [PySTAC extensions reference](reference/pystac-extensions.md).

## Choose the documentation you need

This documentation follows [Diátaxis](https://diataxis.fr/):

- **Tutorial:** [create your first workflow record](tutorials/create-workflow-record.md)
- **How-to guides:** [publish a processing lifecycle](how-to/publish-processing-lifecycle.md)
  or [configure authentication and sources](how-to/configure-sources.md)
- **Reference:** consult the [CLI](reference/cli.md),
  [generated files](reference/outputs.md), or
  [PySTAC extension API](reference/pystac-extensions.md)
- **Explanation:** understand the [architecture and design boundaries](explanation/architecture.md)

## License

This software is released under the
[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0) license.
