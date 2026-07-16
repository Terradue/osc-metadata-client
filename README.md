# Open Science Catalog Client

[![PyPI - Version](https://img.shields.io/pypi/v/osc-metadata-client.svg)](https://pypi.org/project/osc-metadata-client)
[![PyPI - Python Version](https://img.shields.io/pypi/pyversions/osc-metadata-client.svg)](https://pypi.org/project/osc-metadata-client)

`osc-metadata-client` is a CLI tool that simplifies metadata production for the
[Open Science Catalog](https://github.com/ESA-EarthCODE/open-science-catalog-metadata)
starting from [CWL](https://www.commonwl.org/) workflows executed on
[OGC API - Processes](https://docs.ogc.org/is/18-062r2/18-062r2.html) instances.

It helps transform workflow descriptions and execution metadata into catalog-ready
records for Open Science Catalog resources such as workflows, experiments, and
products.

The CLI accepts CWL sources over HTTP(S), local `file://` URLs, and OCI URLs. It
can authenticate HTTP(S) requests with an OAuth2 bearer token and OCI requests
with registry credentials.

See the [CLI reference](docs/cli.md) for commands, options, environment variables,
and output paths.

## License

[![Apache License, Version 2.0](https://img.shields.io/badge/license-Apache%20License%202.0-blue)](https://www.apache.org/licenses/LICENSE-2.0)
