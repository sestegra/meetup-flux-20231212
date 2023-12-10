#!/usr/bin/env bash

REGISTRY_URL="registry.my.labs"
REPOSITORY="gitops/podinfo"
TAG="6.5.3"
NAMESPACE=$(yq -r '.spec.targetNamespace' oci/kustomize-podinfo.yaml)
export COSIGN_PASSWORD=""

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

### Push Kustomization to OCI
p "# Create OCI artifact for PodInfo kustomization"
pe "cd ../podinfo"
pe "flux push artifact \\
  oci://$REGISTRY_URL/$REPOSITORY:$TAG \\
  --source=\"\$(git config --get remote.origin.url)\" \\
  --revision=\"\$(git branch --show-current)@sha1:\$(git rev-parse HEAD)\" \\
  --path=\"./kustomize\""
DIGEST_URL=$(crane digest $REGISTRY_URL/$REPOSITORY:$TAG)
p "# Sign OCI artifact"
pe "cosign sign --key=../cosign.key $REGISTRY_URL/$REPOSITORY:$TAG@$DIGEST_URL -y"

p "# Get the catalog from my OCI registry: $REGISTRY_URL"
pe "crane catalog $REGISTRY_URL"
p "# Get the manifest"
pe "crane manifest $REGISTRY_URL/$REPOSITORY:$TAG | jq ."

DIGEST_URL=$(crane manifest $REGISTRY_URL/$REPOSITORY:$TAG | jq -r .layers[0].digest)
p "# Get the layer"
pe "crane blob $REGISTRY_URL/$REPOSITORY:$TAG@$DIGEST_URL | tar tvz"

p "# Get diff between Git and OCI"
pe "flux diff artifact \\
  oci://$REGISTRY_URL/$REPOSITORY:$TAG \\
  --path ./kustomize"


### Use OCI artifact
echo
echo
p "# Takeover PodInfo kustomization using OCI artifact without rolling update"
pe "cd ../flux-gitops"
p "# Delete last GitRepository resource"
pe "flux delete source git podinfo"

p "# Create source resource for PodInfo"
pe "code oci/source-podinfo.yaml"
p "# Apply source resource"
pe "kubectl apply -f oci/source-podinfo.yaml"
p "# Check source resource status"
pe "flux get sources oci podinfo"

p "# Update kustomization resource for PodInfo"
pe "code --diff git/kustomize-podinfo.yaml oci/kustomize-podinfo.yaml"
p "# Apply kustomization resource"
pe "kubectl apply -f oci/kustomize-podinfo.yaml"
p "# Check kustomization resource status"
pe "flux get kustomizations podinfo"

p "# Check PodInfo deployment (no rolling update)"
pe "kubectl get pod -n $NAMESPACE"

URL=$(kubectl get ingress -n $NAMESPACE podinfo -o jsonpath='{.spec.rules[0].host}')
p "# Update PodInfo kustomization resource for PodInfo"
pe "code oci/kustomize-podinfo.yaml"
p "# Apply kustomization resource"
pe "kubectl apply -f oci/kustomize-podinfo.yaml"
p "# Check PodInfo deployment rollout"
pe "kubectl get pods -n $NAMESPACE --watch"
p "# Open PodInfo https://$URL"

echo
echo
p "# Do the same for Helm"

wait
end_demo