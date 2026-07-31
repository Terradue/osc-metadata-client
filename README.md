# Open Science Catalog Client

[![PyPI - Version](https://img.shields.io/pypi/v/osc-metadata-client.svg)](https://pypi.org/project/osc-metadata-client)
[![PyPI - Python Version](https://img.shields.io/pypi/pyversions/osc-metadata-client.svg)](https://pypi.org/project/osc-metadata-client)

`osc-metadata-client` is a small, purpose-built connector for the ESA
[Open Science Catalog](https://opensciencedata.esa.int/). It converts metadata
associated with OGC API - Processes processes, jobs, and results into the
catalog's workflow, experiment, and product records.

The client delegates CWL metadata extraction and OGC API Records conversion to
Terradue's [transpiler-mate](https://terradue.github.io/transpiler-mate/) API. It
then adds the Open Science Catalog relationships and execution context.

For product metadata, this project also provides proper PySTAC extension
implementations for the upstream
[STAC Themes extension](https://github.com/stac-extensions/themes) and
[STAC Open Science Catalog extension](https://github.com/stac-extensions/osc).
These typed implementations register extension hooks, manage schema URIs, and
read and write extension fields on PySTAC objects.

The CLI accepts CWL sources over HTTP(S), local `file://` URLs, and OCI URLs. It
can authenticate HTTP(S) requests with an OAuth2 bearer token and OCI requests
with registry credentials.

The documentation follows the [Diátaxis](https://diataxis.fr/) structure:

- [Tutorial](docs/tutorials/create-workflow-record.md)
- [How-to guide](docs/how-to/publish-processing-lifecycle.md)
- [CLI reference](docs/reference/cli.md)
- [Architecture explanation](docs/explanation/architecture.md)

## License

[![Apache License, Version 2.0](https://img.shields.io/badge/license-Apache%20License%202.0-blue)](https://www.apache.org/licenses/LICENSE-2.0)
