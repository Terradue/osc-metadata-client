# PySTAC extensions reference

This package contains proper PySTAC implementations for the upstream
[Open Science Catalog](https://github.com/stac-extensions/osc) and
[Themes](https://github.com/stac-extensions/themes) STAC specifications. They
provide typed accessors, schema registration, object-type checks, serialization,
and extension hooks.

They are implementations of the published specifications within this client;
they do not redefine or replace those specifications.

## OSC extension

Import from `osc_metadata_client.osc_extension`.

| API | Purpose |
| --- | --- |
| `OscExtension.ext(obj, add_if_missing=False)` | Access OSC fields on a PySTAC `Collection` or `Item`. |
| `apply_project(...)` | Set the mutually exclusive OSC project shape. |
| `apply_product(...)` | Set the mutually exclusive OSC product shape. |
| `OscType` | `project` and `product` values. |
| `OscStatus` | `planned`, `ongoing`, and `completed` values. |
| `SCHEMA_URI` | `https://stac-extensions.github.io/osc/v1.0.0/schema.json` |

Supported properties are `osc:type`, `osc:status`, `osc:workflows`,
`osc:project`, `osc:region`, `osc:variables`, `osc:missions`, and
`osc:experiment`.

```python
from osc_metadata_client.osc_extension import OscExtension, OscStatus

osc = OscExtension.ext(collection, add_if_missing=True)
osc.apply_product(
    status=OscStatus.COMPLETED,
    project="project-001",
    experiment="experiment-001",
)
```

## Themes extension

Import from `osc_metadata_client.themes_extension`.

| API | Purpose |
| --- | --- |
| `ThemesExtension.ext(obj, add_if_missing=False)` | Access themes on a PySTAC `Catalog`, `Collection`, or `Item`. |
| `ThemesExtension.summaries(collection, ...)` | Access themes in Collection summaries. |
| `Theme` | A controlled vocabulary scheme and its concepts. |
| `ThemeConcept` | A concept identifier with optional title, description, and URL. |
| `SCHEMA_URI` | `https://stac-extensions.github.io/themes/v1.0.0/schema.json` |

```python
from osc_metadata_client.themes_extension import (
    Theme,
    ThemeConcept,
    ThemesExtension,
)

themes = ThemesExtension.ext(collection, add_if_missing=True)
themes.apply([
    Theme(
        scheme="https://github.com/stac-extensions/osc#theme",
        concepts=[ThemeConcept(id="land")],
    )
])
```

Passing `add_if_missing=True` adds the correct schema URI to
`stac_extensions`. Without it, accessing an undeclared extension raises
PySTAC's `ExtensionNotImplemented`. Unsupported PySTAC object types raise
`ExtensionTypeError`.
