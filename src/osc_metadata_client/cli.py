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

from osc_metadata_client import load_record_geojson
from osc_metadata_client.experiment import execute as execute_experiment
from osc_metadata_client.product import execute as execute_product
from osc_metadata_client.workflow import execute as execute_workflow
from loguru import logger
from pathlib import Path
from requests import Session
from requests.adapters import BaseAdapter, HTTPAdapter
from session_adapters.bearer_auth_http_adapter import BearerAuthHTTPAdapter
from session_adapters.file_adapter import FileAdapter
from session_adapters.oci_adapter import OCIAdapter
from transpiler_mate.cli.cli import _track
from transpiler_mate.ogcapi.records.ogcapi_records_models import RecordGeoJSON

import click


@click.group()
@click.argument("source", type=click.STRING, required=True)
@click.option(
    "--id", type=click.STRING, required=True, help="The OGC API Processes Job ID."
)
@click.option(
    "--project-id",
    type=click.STRING,
    required=True,
    help="The referencing Open Science Catalog project ID.",
)
@click.option(
    "--project-name",
    type=click.STRING,
    required=True,
    help="The referencing Open Science Catalog project Name.",
)
@click.option(
    "--ogc-api-processes-endpoint",
    type=click.STRING,
    required=True,
    help="The referencing OGC API Processes service URL.",
)
@click.option(
    "--geobrowser-endpoint",
    type=click.STRING,
    required=True,
    help="The referencing Geobrowser service URL.",
)
@click.option(
    "--output",
    type=click.Path(path_type=Path),
    required=True,
    help="The output directory path",
)
@click.option("--oci-hostname", envvar="OCI_HOSTNAME", show_envvar=True)
@click.option("--oci-username", envvar="OCI_USERNAME", show_envvar=True)
@click.option("--oci-password", envvar="OCI_PASSWORD", show_envvar=True)
@click.option("--oauth2-bearer", envvar="OAUTH2_BEARER", show_envvar=True)
@click.pass_context
def main(
    ctx,
    source: str,
    id: str,
    project_id: str,
    project_name: str,
    ogc_api_processes_endpoint: str,
    geobrowser_endpoint: str,
    output: Path,
    oci_hostname: str | None,
    oci_username: str | None,
    oci_password: str | None,
    oauth2_bearer: str | None,
):
    ctx.ensure_object(dict)
    ctx.obj["source"] = source

    session = Session()

    def mount_session(scheme: str, adapter: BaseAdapter) -> None:
        logger.debug(f"Mounting '{scheme}' scheme to '{type(adapter).__name__}'...")
        session.mount(scheme, adapter)
        logger.debug(
            f"Scheme '{scheme}' successfully mount to '{type(adapter).__name__}'"
        )

    http_adapter = (
        BearerAuthHTTPAdapter(oauth2_bearer) if oauth2_bearer else HTTPAdapter()
    )
    mount_session("http://", http_adapter)
    mount_session("https://", http_adapter)
    mount_session("file://", FileAdapter())
    mount_session(
        "oci://",
        OCIAdapter(hostname=oci_hostname, username=oci_username, password=oci_password),
    )

    record_geojson: RecordGeoJSON = load_record_geojson(
        source, project_id, project_name, session
    )
    record_geojson.id = id
    ctx.obj["record_geojson"] = record_geojson

    ctx.obj["ogc-api-processes-endpoint"] = ogc_api_processes_endpoint
    ctx.obj["geobrowser_endpoint"] = geobrowser_endpoint
    ctx.obj["project-id"] = project_id
    ctx.obj["output"] = output
    ctx.obj["oauth2_bearer"] = oauth2_bearer


@main.command(context_settings={"show_default": True})
@click.pass_context
def workflow(ctx):
    source: str = ctx.obj["source"]
    ogc_api_processes_endpoint = ctx.obj["ogc-api-processes-endpoint"]
    geobrowser_endpoint = ctx.obj["geobrowser_endpoint"]
    record_geojson: RecordGeoJSON = ctx.obj["record_geojson"]
    project_id: str = ctx.obj["project-id"]
    output: Path = ctx.obj["output"]
    execute_workflow(
        source,
        ogc_api_processes_endpoint,
        geobrowser_endpoint,
        record_geojson,
        project_id,
        output,
    )


@main.command(context_settings={"show_default": True})
@click.pass_context
@click.option(
    "--workflow-id",
    type=click.STRING,
    required=True,
    help="The referencing OGC API Records workflow URL.",
)
def experiment(
    ctx,
    workflow_id: str,
):
    ogc_api_processes_endpoint = ctx.obj["ogc-api-processes-endpoint"]
    geobrowser_endpoint = ctx.obj["geobrowser_endpoint"]
    record_geojson: RecordGeoJSON = ctx.obj["record_geojson"]
    project_id: str = ctx.obj["project-id"]
    output: Path = ctx.obj["output"]
    oauth2_bearer = ctx.obj["oauth2_bearer"]

    execute_experiment(
        project_id=project_id,
        workflow_id=workflow_id,
        record_geojson=record_geojson,
        ogc_api_processes_endpoint=ogc_api_processes_endpoint,
        geobrowser_endpoint=geobrowser_endpoint,
        output=output,
        oauth2_bearer=oauth2_bearer,
    )


@main.command(context_settings={"show_default": True})
@click.pass_context
@click.option(
    "--experiment-id",
    type=click.STRING,
    required=True,
    help="The referencing OGC API Records workflow ID.",
)
def products(
    ctx,
    experiment_id: str,
):
    ogc_api_processes_endpoint = ctx.obj["ogc-api-processes-endpoint"]
    geobrowser_endpoint = ctx.obj["geobrowser_endpoint"]
    record_geojson: RecordGeoJSON = ctx.obj["record_geojson"]
    project_id: str = ctx.obj["project-id"]
    output: Path = ctx.obj["output"]
    oauth2_bearer = ctx.obj["oauth2_bearer"]

    execute_product(
        ogc_api_processes_endpoint,
        geobrowser_endpoint,
        record_geojson,
        project_id,
        experiment_id,
        output,
        oauth2_bearer,
    )


for command in [workflow, experiment, products]:
    command.callback = _track(command.callback)
