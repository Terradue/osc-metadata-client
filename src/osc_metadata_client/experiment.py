# Copyright 2026 Terradue
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from __future__ import annotations

from pathlib import Path

from loguru import logger
from ogc_api_processes_client.models.status_info import StatusInfo  # noqa: TC002
from transpiler_mate.ogcapi.records.ogcapi_records_models import Link, RecordGeoJSON

from osc_metadata_client import (
    cast_model,
    create_client,
    dump_data,
    retrieve_status_info,
    serialize_yaml,
)
from osc_metadata_client.models import ExperimentProperties


def execute(
    project_id: str,
    workflow_id: str,
    record_geojson: RecordGeoJSON,
    ogc_api_processes_endpoint: str,
    geobrowser_endpoint: str,
    output: Path,
    oauth2_bearer: str,
) -> Path:
    logger.debug("Enriching OGCP API Records...")

    record_geojson.links.append(
        Link(
            rel="parent",
            href="../catalog.json",
            type="application/json",
            title="Experiments",
            hreflang="en-US",
            created=None,
            updated=None,
        )
    )
    record_geojson.links.append(
        Link(
            href=f"{ogc_api_processes_endpoint}/jobs/{record_geojson.id}",
            hreflang="en-US",
            rel="via",
            type="application/json",
            title=f"OGC API Processes - Job: {record_geojson.id}",
            created=None,
            updated=None,
        )
    )
    record_geojson.links.append(
        Link(
            href=f"{geobrowser_endpoint}/jobs/{record_geojson.id}",
            hreflang="en-US",
            rel="alternate",
            type="text/html",
            title=f"GEP Geobrowser - Job: {record_geojson.id}",
            created=None,
            updated=None,
        )
    )

    logger.debug("Reassembling OGC API Records 'Experiment' inputs...")

    status_info: StatusInfo = retrieve_status_info(
        create_client(ogc_api_processes_endpoint, oauth2_bearer),
        record_geojson.id,
    )

    logger.debug(status_info.properties)

    target_file = Path(output, f"experiments/{record_geojson.id}/record.json")
    input_files: Path = Path(target_file.parent, "input.yaml")

    serialize_yaml(status_info.inputs, input_files)

    record_geojson.links.append(
        Link(
            href=f"./{input_files.name}",
            hreflang="en-US",
            rel="input",
            type="application/yaml",
            title="Input parameters",
            created=status_info.started,
            updated=status_info.started,
        )
    )
    record_geojson.links.append(
        Link(
            href="./environment.yaml",
            hreflang="en-US",
            rel="environment",
            type="application/yaml",
            title="Execution environment",
            created=status_info.started,
            updated=status_info.started,
        )
    )
    record_geojson.links.append(
        Link(
            href=f"../../workflows/{workflow_id}/record.json",
            hreflang="en-US",
            rel="related",
            type="application/json",
            title=f"Workflow: {record_geojson.properties.title}",
            created=status_info.started,
            updated=status_info.started,
        )
    )

    logger.success(
        f"OGC API Records 'Experiment' inputs saved to {input_files.absolute()}"
    )

    record_geojson.properties.type = "experiment"
    experiment_properties: ExperimentProperties = cast_model(
        record_geojson.properties,
        ExperimentProperties,
    )
    experiment_properties.osc_project = project_id
    experiment_properties.osc_workflow = workflow_id
    experiment_properties.osc_prov_described_by_workflow = workflow_id
    # experiment_properties.osc_prov_generated = "TODO"
    experiment_properties.osc_prov_generated_by = "osc-client"
    experiment_properties.osc_prov_started_at_time = status_info.started
    experiment_properties.osc_prov_ended_at_time = status_info.finished

    record_geojson.properties = experiment_properties

    logger.success("OGCP API Records enriched")

    dump_data(
        record_geojson.model_dump(
            by_alias=True, exclude_none=True, serialize_as_any=True
        ),
        target_file,
    )

    return target_file
