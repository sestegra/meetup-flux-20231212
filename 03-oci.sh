#!/bin/bash

REGISTRY_URL="registry.my.labs"
REPOSITORY="images/podinfo"
TAG="6.5.3"
PLATFORM="linux/amd64"

# Test if DEMO_MAGIC is set
if [ -z "$DEMO_MAGIC" ]; then
  echo "DEMO_MAGIC is not set"
  exit 1
fi

# Test if in VS Code
if [ -z "$VSCODE_NONCE" ]; then
  echo "Not in VS Code"
  exit 1
fi

. $DEMO_MAGIC
export DEMO_PROMPT="flux-oci $ "
export DEMO_COMMENT_COLOR="\033[0;33m"

start_demo

p "# Get the catalog from my OCI registry: $REGISTRY_URL"
pe "crane catalog $REGISTRY_URL"

p "# List available tags in $REPOSITORY repository"
pe "crane ls $REGISTRY_URL/$REPOSITORY"

p "# Get the manifest for $REPOSITORY:$TAG"
pe "crane manifest $REGISTRY_URL/$REPOSITORY:$TAG --platform $PLATFORM | jq"

p "# Get the config for $REPOSITORY:$TAG"
pe "crane config $REGISTRY_URL/$REPOSITORY:$TAG | jq"

p "# Get the layers for $REPOSITORY:$TAG"
pe "crane blob registry.my.labs/images/podinfo:6.5.3@sha256:96526aa774ef0126ad0fe9e9a95764c5fc37f409ab9e97021e7b4775d82bf6fa | tar tvz | more"
pe "crane blob registry.my.labs/images/podinfo:6.5.3@sha256:a50a85e7a1537930b779f99aaebf2635cc856f455621f2a723783c9964d30474 | tar tvz | more"
pe "crane blob registry.my.labs/images/podinfo:6.5.3@sha256:30bbb1eccca30fbbcbdde358f8bb19acd238352a31c384ce9a09476dbfed9912 | tar tvz | more"

wait
end_demo