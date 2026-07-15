cwlVersion: v1.2
$namespaces:
  s: https://schema.org/

schemas:
- http://schema.org/version/9.0/schemaorg-current-http.rdf

# The software itself

s:name: OSC Client - Publish `experiment` and `product`
s:description: ESA Open Science Catalog Client
s:dateCreated: '2026-05-12'
s:license:
  '@type': s:CreativeWork
  s:identifier: Apache-2.0

# Discoverability and citation

s:keywords:
- CWL
- CWL Workflow
- Workflow
- Earth Observation
- Earth Observation application package

# Run-time environment

s:operatingSystem:
- Linux
- MacOS X
s:softwareRequirements:
- https://cwltool.readthedocs.io/en/latest/
- https://www.python.org/

# Current version of the software

s:softwareVersion: 0.1.0
s:softwareHelp:
  '@type': s:CreativeWork
  s:name: User Manual
  s:url: https://terradue.github.io/osc-metadata-client/

# Publisher

s:publisher:
  '@type': s:Organization
  s:email: info@terradue.com
  s:identifier: https://ror.org/0069cx113
  s:name: Terradue Srl

# Authors & Contributors

s:author:
- '@type': s:Role
  s:roleName: Project Manager
  s:additionalType: http://purl.org/spar/datacite/ProjectManager
  s:author:
    '@type': s:Person
    s:affiliation:
      '@type': s:Organization
      s:identifier: https://ror.org/0069cx113
      s:name: Terradue
    s:email: fabrice.brito@terradue.com
    s:familyName: Brito
    s:givenName: Fabrice
    s:identifier: https://orcid.org/0009-0000-1342-9736
- '@type': s:Role
  s:roleName: Project Leader
  s:additionalType: http://purl.org/spar/datacite/ProjectLeader
  s:author:
    '@type': s:Person
    s:affiliation:
      '@type': s:Organization
      s:identifier: https://ror.org/0069cx113
      s:name: Terradue
    s:email: simone.tripodi@terradue.com
    s:familyName: Tripodi
    s:givenName: Simone
    s:identifier: https://orcid.org/0009-0006-2063-618X

# CWL Workflow

$graph:
- id: sync_git_repository_cli
  class: CommandLineTool
  label: Clone or pull a Git repository
  doc: |
    Clones a Git repository when the target directory does not exist.
    If the target directory already contains a Git repository, checks out the
    requested branch and pulls it with `--ff-only`.

    Reads REPOSITORY_PATH, REPOSITORY_URL, BRANCH, and REMOTE from the preserved
    execution environment. BRANCH defaults to `main`; REMOTE defaults to `origin`.
  inputs: []
  outputs:
  - id: checkout_directory
    type: Directory
    outputBinding:
      loadContents: true
      glob: repository_path.txt
      outputEval: |
        ${
          return {
            "class": "Directory",
            "location": self[0].contents
          };
        }
  - id: log
    type: string
    outputBinding:
      loadContents: true
      glob: sync_git_repository_cli.log
      outputEval: $(self[0].contents)
  requirements:
  - class: NetworkAccess
    networkAccess: true
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
    - entryname: sync_git_repository_cli.sh
      entry: |-
        #!/bin/bash
        set -euo pipefail

        : "\${REPOSITORY_PATH:?REPOSITORY_PATH is required}"
        : "\${REPOSITORY_URL:?REPOSITORY_URL is required}"
        : "\${BRANCH:=main}"
        : "\${REMOTE:=origin}"

        if [ -d "$REPOSITORY_PATH/.git" ]; then
          echo "Updating existing repository at $REPOSITORY_PATH"
          git -C "$REPOSITORY_PATH" fetch "$REMOTE" "$BRANCH"
          git -C "$REPOSITORY_PATH" checkout "$BRANCH" || git -C "$REPOSITORY_PATH" checkout -b "$BRANCH" "$REMOTE/$BRANCH"
          git -C "$REPOSITORY_PATH" pull --ff-only "$REMOTE" "$BRANCH"
        else
          echo "Cloning $REPOSITORY_URL into $REPOSITORY_PATH"
          git clone --branch "$BRANCH" "$REPOSITORY_URL" "$REPOSITORY_PATH"
        fi

        printf '%s' "$REPOSITORY_PATH" > repository_path.txt
  cwlVersion: v1.2
  baseCommand: bash
  arguments:
  - sync_git_repository_cli.sh
  stdout: sync_git_repository_cli.log
- id: commit_and_push_cli
  class: CommandLineTool
  label: Commit changes and push
  doc: |
    Stages all repository changes with `git add --all`, commits them with the
    provided message, and pushes the selected branch.

    Requires `git` to be installed and authenticated in the execution
    environment when pushing to a remote repository.

    Reads REPOSITORY_PATH, BRANCH, and REMOTE from the preserved execution
    environment. REMOTE defaults to `origin`.
  inputs:
  - id: commit_message
    doc: Commit message.
    type: string
    inputBinding:
      position: 1
  outputs:
  - id: changes_pushed
    type: string
    outputBinding:
      loadContents: true
      glob: changes_pushed.txt
      outputEval: $(self[0].contents)
  requirements:
  - class: NetworkAccess
    networkAccess: true
  - class: InitialWorkDirRequirement
    listing:
    - entryname: commit_and_push_cli.sh
      entry: |-
        #!/bin/bash
        set -euo pipefail

        : "\${REPOSITORY_PATH:?REPOSITORY_PATH is required}"
        : "\${BRANCH:?BRANCH is required}"
        : "\${REMOTE:=origin}"

        commit_message="$1"
        printf '%s' "$BRANCH" > pushed_branch.txt

        if [ ! -d "$REPOSITORY_PATH/.git" ]; then
          echo "Path is not a Git repository: $REPOSITORY_PATH" >&2
          exit 1
        fi

        git -C "$REPOSITORY_PATH" fetch "$REMOTE" "$BRANCH" || true

        current_branch="\$(git -C "$REPOSITORY_PATH" rev-parse --abbrev-ref HEAD)"

        if [ "$current_branch" != "$BRANCH" ]; then
          if git -C "$REPOSITORY_PATH" show-ref --verify --quiet "refs/heads/$BRANCH"; then
            git -C "$REPOSITORY_PATH" checkout "$BRANCH"
          elif git -C "$REPOSITORY_PATH" show-ref --verify --quiet "refs/remotes/$REMOTE/$BRANCH"; then
            git -C "$REPOSITORY_PATH" checkout -b "$BRANCH" "$REMOTE/$BRANCH"
          else
            git -C "$REPOSITORY_PATH" checkout -b "$BRANCH"
          fi
        fi

        if git -C "$REPOSITORY_PATH" show-ref --verify --quiet "refs/remotes/$REMOTE/$BRANCH"; then
          git -C "$REPOSITORY_PATH" pull --ff-only "$REMOTE" "$BRANCH"
        fi

        git -C "$REPOSITORY_PATH" add --all

        if git -C "$REPOSITORY_PATH" diff --cached --quiet; then
          echo "No changes to commit; skipping push."
          printf 'false' > changes_pushed.txt
          exit 0
        fi

        git -C "$REPOSITORY_PATH" commit -m "$commit_message"
        git -C "$REPOSITORY_PATH" push --set-upstream "$REMOTE" "$BRANCH"
        printf 'true' > changes_pushed.txt
  cwlVersion: v1.2
  baseCommand: bash
  arguments:
  - commit_and_push_cli.sh
  stdout: commit_and_push_cli.log
- id: publish_experiment_cli
  class: CommandLineTool
  label: Open Science Catalog `experiment` publication
  doc: |
    Publishes a `job` execution to the the [Open Science Catalog](https://opensciencedata.esa.int/) as a `experiment`.

    For more information, see [Experiments](https://opensciencedata.esa.int/experiments/catalog).
  inputs:
  - id: job_id
    type: string
    inputBinding:
      position: 1
      prefix: --id
  - id: project_id
    type: string
    inputBinding:
      position: 2
      prefix: --project-id
  - id: project_name
    type: string
    inputBinding:
      position: 3
      prefix: --project-name
  - id: ogc_api_processes_endpoint
    type: 
      https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
    inputBinding:
      position: 4
      prefix: --ogc-api-processes-endpoint
      valueFrom: $(self.value)
  - id: osc_location
    type: Directory
    inputBinding:
      position: 5
      prefix: --output
  - id: cwl_workflow_location
    type: 
      https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
    inputBinding:
      position: 6
      valueFrom: $(self.value)
  - id: workflow_id
    type: string
    inputBinding:
      position: 8
      prefix: --workflow-id
  - id: authorization_token
    type: string
    inputBinding:
      position: 9
      prefix: --authorization-token
  outputs:
  - id: log
    type: string
    outputBinding:
      loadContents: true
      glob: publish_experiment_cli.log
      outputEval: $(self[0].contents)
  requirements:
  - class: DockerRequirement
    dockerPull: docker.io/library/osc-metadata-client:latest
  - class: NetworkAccess
    networkAccess: true
  - class: SchemaDefRequirement
    types:
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Date
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Date/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Duration
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Duration/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Email
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Email/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Hostname
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Hostname/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IDNEmail
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IDNEmail/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IDNHostname
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IDNHostname/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IPv4
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IPv4/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IPv6
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IPv6/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IRI
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IRI/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IRIReference
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IRIReference/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#JsonPointer
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#JsonPointer/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Password
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Password/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#RelativeJsonPointer
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#RelativeJsonPointer/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#UUID
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#UUID/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URIReference
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URIReference/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URITemplate
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URITemplate/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Time
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Time/value
        type: string
      type: record
  cwlVersion: v1.2
  baseCommand:
  - osc-metadata-client
  arguments:
  - position: 7
    valueFrom: experiment
  stdout: publish_experiment_cli.log
- id: publish_product_cli
  class: CommandLineTool
  label: Open Science Catalog `product` publication
  doc: |
    Publishes a `job` to the the [Open Science Catalog](https://opensciencedata.esa.int/) as a `product`.

    For more information, see [Products](https://opensciencedata.esa.int/products/catalog).
  inputs:
  - id: job_id
    type: string
    inputBinding:
      position: 1
      prefix: --id
  - id: project_id
    type: string
    inputBinding:
      position: 2
      prefix: --project-id
  - id: project_name
    type: string
    inputBinding:
      position: 3
      prefix: --project-name
  - id: ogc_api_processes_endpoint
    type: 
      https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
    inputBinding:
      position: 4
      prefix: --ogc-api-processes-endpoint
      valueFrom: $(self.value)
  - id: osc_location
    type: Directory
    inputBinding:
      position: 5
      prefix: --output
  - id: cwl_workflow_location
    type: 
      https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
    inputBinding:
      position: 6
      valueFrom: $(self.value)
  - id: experiment_id
    type: string
    inputBinding:
      position: 8
      prefix: --experiment-id
  - id: authorization_token
    type: string
    inputBinding:
      position: 9
      prefix: --authorization-token
  outputs:
  - id: log
    type: string
    outputBinding:
      loadContents: true
      glob: publish_product_cli.log
      outputEval: $(self[0].contents)
  requirements:
  - class: DockerRequirement
    dockerPull: docker.io/library/osc-metadata-client:latest
  - class: NetworkAccess
    networkAccess: true
  - class: SchemaDefRequirement
    types:
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Date
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Date/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Duration
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Duration/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Email
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Email/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Hostname
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Hostname/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IDNEmail
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IDNEmail/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IDNHostname
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IDNHostname/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IPv4
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IPv4/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IPv6
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IPv6/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IRI
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IRI/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IRIReference
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IRIReference/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#JsonPointer
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#JsonPointer/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Password
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Password/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#RelativeJsonPointer
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#RelativeJsonPointer/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#UUID
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#UUID/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URIReference
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URIReference/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URITemplate
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URITemplate/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Time
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Time/value
        type: string
      type: record
  cwlVersion: v1.2
  baseCommand:
  - osc-metadata-client
  arguments:
  - position: 7
    valueFrom: products
  stdout: publish_product_cli.log
- id: publish_experiment_products
  class: Workflow
  label: Open Science Catalog `experiment` and `product` publication
  doc: |
    Publishes a `job` execution to the [Open Science Catalog](https://opensciencedata.esa.int/) as an `experiment` and its `product`.

    For more information, see [Experiments](https://opensciencedata.esa.int/experiments/catalog) and [Products](https://opensciencedata.esa.int/products/catalog).
  inputs:
  - id: job_id
    type: string
  - id: project_id
    type: string
  - id: project_name
    type: string
  - id: ogc_api_processes_endpoint
    type: 
      https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
  - id: cwl_workflow_location
    type: 
      https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
  - id: workflow_id
    type: string
  - id: authorization_token
    type: string
  outputs:
  - id: publish_experiment_log
    outputSource: publish_experiment/log
    type: string
  - id: publish_product_log
    outputSource: publish_product/log
    type: string
  requirements:
  - class: MultipleInputFeatureRequirement
  - class: SchemaDefRequirement
    types:
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Date
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Date/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Duration
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Duration/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Email
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Email/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Hostname
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Hostname/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IDNEmail
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IDNEmail/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IDNHostname
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IDNHostname/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IPv4
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IPv4/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IPv6
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IPv6/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IRI
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IRI/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IRIReference
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#IRIReference/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#JsonPointer
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#JsonPointer/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Password
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Password/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#RelativeJsonPointer
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#RelativeJsonPointer/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#UUID
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#UUID/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URIReference
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URIReference/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URITemplate
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URITemplate/value
        type: string
      type: record
    - name: 
        https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Time
      fields:
      - name: 
          https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#Time/value
        type: string
      type: record
  - class: StepInputExpressionRequirement
  cwlVersion: v1.2
  steps:
  - id: sync_git_repository
    in: []
    out:
    - checkout_directory
    run: '#sync_git_repository_cli'
  - id: publish_product
    in:
    - id: job_id
      source: job_id
    - id: project_id
      source: project_id
    - id: project_name
      source: project_name
    - id: ogc_api_processes_endpoint
      source: ogc_api_processes_endpoint
    - id: osc_location
      source: sync_git_repository/checkout_directory
    - id: cwl_workflow_location
      source: cwl_workflow_location
    - id: experiment_id
      source: job_id
    - id: authorization_token
      source: authorization_token
    out:
    - log
    run: '#publish_product_cli'
  - id: publish_experiment
    in:
    - id: job_id
      source: job_id
    - id: project_id
      source: project_id
    - id: project_name
      source: project_name
    - id: ogc_api_processes_endpoint
      source: ogc_api_processes_endpoint
    - id: osc_location
      source: sync_git_repository/checkout_directory
    - id: cwl_workflow_location
      source: cwl_workflow_location
    - id: workflow_id
      source: workflow_id
    - id: authorization_token
      source: authorization_token
    out:
    - log
    run: '#publish_experiment_cli'
  - id: commit_and_push
    in:
    - id: commit_message
      source:
      - job_id
      - workflow_id
      - project_name
      - project_id
      - publish_experiment/log
      - publish_product/log
      linkMerge: merge_nested
      valueFrom: Publish experiment and result job_id for $(self[0]) workflow 
        $(self[1]) for project $(self[2]) ($(self[3]))
    out:
    - changes_pushed
    run: '#commit_and_push_cli'
