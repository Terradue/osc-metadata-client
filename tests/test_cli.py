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

from click.testing import CliRunner

from transpiler_mate.ogcapi.records.ogcapi_records_models import (
    RecordCommonProperties,
    RecordGeoJSON,
)


def make_record(record_id: str) -> RecordGeoJSON:
    return RecordGeoJSON(
        id=record_id,
        properties=RecordCommonProperties(title="Record"),
        links=[],
    )


def test_main_loads_context(monkeypatch, tmp_path, osc_modules) -> None:
    cli = osc_modules["cli"]
    runner = CliRunner()
    record = make_record("original-id")
    called = {}

    class FakeSession:
        def __init__(self):
            self.adapters = {}

        def mount(self, scheme, adapter):
            self.adapters[scheme] = adapter

    session = FakeSession()
    http_adapter = object()
    file_adapter = object()
    oci_adapter = object()

    monkeypatch.setattr(cli, "Session", lambda: session)
    monkeypatch.setattr(cli, "HTTPAdapter", lambda: http_adapter)
    monkeypatch.setattr(cli, "FileAdapter", lambda: file_adapter)
    monkeypatch.setattr(
        cli,
        "OCIAdapter",
        lambda **kwargs: called.update(oci_adapter_kwargs=kwargs) or oci_adapter,
    )

    def fake_load_record_geojson(*args):
        called["load_record_geojson_args"] = args
        return record

    monkeypatch.setattr(cli, "load_record_geojson", fake_load_record_geojson)
    monkeypatch.setattr(
        cli,
        "execute_workflow",
        lambda source,
        ogc_api_processes_endpoint,
        geobrowser_endpoint,
        record_geojson,
        project_id,
        output: (
            called.update(
                source=source,
                ogc_api_processes_endpoint=ogc_api_processes_endpoint,
                geobrowser_endpoint=geobrowser_endpoint,
                record_geojson=record_geojson,
                project_id=project_id,
                output=output,
            )
        ),
    )

    result = runner.invoke(
        cli.main,
        [
            "--id",
            "workflow-1",
            "--project-id",
            "project-1",
            "--project-name",
            "Project",
            "--ogc-api-processes-endpoint",
            "https://ogcapi.example.com/processes",
            "--geobrowser-endpoint",
            "https://geobrowser.example.com/processes",
            "--output",
            str(tmp_path),
            "--oci-hostname",
            "registry.example.com",
            "--oci-username",
            "neo",
            "--oci-password",
            "secret",
            "https://example.com/workflow.cwl",
            "workflow",
        ],
    )

    assert result.exit_code == 0
    assert called["load_record_geojson_args"] == (
        "https://example.com/workflow.cwl",
        "project-1",
        "Project",
        session,
    )
    assert session.adapters == {
        "http://": http_adapter,
        "https://": http_adapter,
        "file://": file_adapter,
        "oci://": oci_adapter,
    }
    assert called["oci_adapter_kwargs"] == {
        "hostname": "registry.example.com",
        "username": "neo",
        "password": "secret",
    }
    assert called["source"] == "https://example.com/workflow.cwl"
    assert (
        called["ogc_api_processes_endpoint"] == "https://ogcapi.example.com/processes"
    )
    assert called["geobrowser_endpoint"] == "https://geobrowser.example.com/processes"
    assert called["record_geojson"].id == "workflow-1"
    assert called["project_id"] == "project-1"
    assert called["output"] == Path(tmp_path)


def test_main_uses_bearer_auth_adapter(monkeypatch, tmp_path, osc_modules) -> None:
    cli = osc_modules["cli"]
    runner = CliRunner()
    record = make_record("workflow-1")
    mounted = {}
    bearer_adapter = object()

    class FakeSession:
        def mount(self, scheme, adapter):
            mounted[scheme] = adapter

    monkeypatch.setattr(cli, "Session", FakeSession)
    monkeypatch.setattr(
        cli,
        "BearerAuthHTTPAdapter",
        lambda token: mounted.update(bearer_token=token) or bearer_adapter,
    )
    monkeypatch.setattr(cli, "HTTPAdapter", lambda: None)
    monkeypatch.setattr(cli, "FileAdapter", object)
    monkeypatch.setattr(cli, "OCIAdapter", lambda **kwargs: object())
    monkeypatch.setattr(cli, "load_record_geojson", lambda *args: record)
    monkeypatch.setattr(cli, "execute_workflow", lambda *args: None)

    result = runner.invoke(
        cli.main,
        [
            "--id",
            "workflow-1",
            "--project-id",
            "project-1",
            "--project-name",
            "Project",
            "--ogc-api-processes-endpoint",
            "https://ogcapi.example.com/processes",
            "--geobrowser-endpoint",
            "https://geobrowser.example.com/processes",
            "--output",
            str(tmp_path),
            "--oauth2-bearer",
            "oauth-token",
            "https://example.com/workflow.cwl",
            "workflow",
        ],
    )

    assert result.exit_code == 0
    assert mounted["bearer_token"] == "oauth-token"
    assert mounted["http://"] is bearer_adapter
    assert mounted["https://"] is bearer_adapter


def test_experiment_command_dispatches(monkeypatch, tmp_path, osc_modules) -> None:
    cli = osc_modules["cli"]
    runner = CliRunner()
    record = make_record("experiment-1")
    called = {}

    monkeypatch.setattr(cli, "load_record_geojson", lambda *args: record)
    monkeypatch.setattr(
        cli,
        "execute_experiment",
        lambda **kwargs: called.update(kwargs),
    )

    result = runner.invoke(
        cli.main,
        [
            "--id",
            "experiment-1",
            "--project-id",
            "project-1",
            "--project-name",
            "Project",
            "--ogc-api-processes-endpoint",
            "https://ogcapi.example.com/processes",
            "--geobrowser-endpoint",
            "https://geobrowser.example.com/processes",
            "--output",
            str(tmp_path),
            "--oauth2-bearer",
            "token",
            "https://example.com/workflow.cwl",
            "experiment",
            "--workflow-id",
            "workflow-1",
        ],
    )

    assert result.exit_code == 0
    assert called["project_id"] == "project-1"
    assert called["workflow_id"] == "workflow-1"
    assert (
        called["ogc_api_processes_endpoint"] == "https://ogcapi.example.com/processes"
    )
    assert called["geobrowser_endpoint"] == "https://geobrowser.example.com/processes"
    assert called["record_geojson"].id == "experiment-1"
    assert called["output"] == Path(tmp_path)
    assert called["oauth2_bearer"] == "token"


def test_products_command_dispatches(monkeypatch, tmp_path, osc_modules) -> None:
    cli = osc_modules["cli"]
    runner = CliRunner()
    record = make_record("product-1")
    called = {}

    monkeypatch.setattr(cli, "load_record_geojson", lambda *args: record)
    monkeypatch.setattr(
        cli,
        "execute_product",
        lambda *args: called.update(
            ogc_api_processes_endpoint=args[0],
            geobrowser_endpoint=args[1],
            record_geojson=args[2],
            project_id=args[3],
            experiment_id=args[4],
            output=args[5],
            oauth2_bearer=args[6],
        ),
    )

    result = runner.invoke(
        cli.main,
        [
            "--id",
            "product-1",
            "--project-id",
            "project-1",
            "--project-name",
            "Project",
            "--ogc-api-processes-endpoint",
            "https://ogcapi.example.com/processes",
            "--geobrowser-endpoint",
            "https://geobrowser.example.com/processes",
            "--output",
            str(tmp_path),
            "--oauth2-bearer",
            "token",
            "https://example.com/workflow.cwl",
            "products",
            "--experiment-id",
            "experiment-1",
        ],
    )

    assert result.exit_code == 0
    assert (
        called["ogc_api_processes_endpoint"] == "https://ogcapi.example.com/processes"
    )
    assert called["geobrowser_endpoint"] == "https://geobrowser.example.com/processes"
    assert called["record_geojson"].id == "product-1"
    assert called["project_id"] == "project-1"
    assert called["experiment_id"] == "experiment-1"
    assert called["output"] == Path(tmp_path)
    assert called["oauth2_bearer"] == "token"
