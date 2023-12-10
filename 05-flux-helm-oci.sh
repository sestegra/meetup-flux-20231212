#!/usr/bin/env bash

REGISTRY_URL="registry.my.labs"
REPOSITORY="helm/podinfo"
TAG="6.5.3"
NAMESPACE=$(yq -r '.spec.targetNamespace' oci/helmrelease-podinfo.yaml)
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

### Push Helm Chart to OCI
p "# Create OCI artifact for PodInfo Helm chart"
pe "cd ../podinfo"
pe "helm package ./charts/podinfo"
pe "helm push ./podinfo-6.5.3.tgz oci://$REGISTRY_URL/helm"
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


### Use OCI artifact
echo
echo
p "# Takeover PodInfo kustomization using OCI artifact without rolling update"
pe "cd ../flux-gitops"

p "# Create HelmRepository resource"
pe "code oci/helmrepository-podinfo.yaml"
p "# Apply HelmRepository resource"
pe "kubectl apply -f oci/helmrepository-podinfo.yaml"
p "# Check HelmRepository resource status"
pe "flux get sources helm podinfo"

p "# Update HelmRelease resource"
pe "code --diff git/helmrelease-podinfo.yaml oci/helmrelease-podinfo.yaml"
p "# Apply HelmRelease resource"
pe "kubectl apply -f oci/helmrelease-podinfo.yaml"
p "# Reconcile HelmRelease resource"
pe "flux reconcile helmrelease podinfo --with-source"
p "# Check HelmRelease resource status"
pe "flux get helmrelease podinfo"

p "# Check PodInfo deployment (no rolling update)"
pe "kubectl get pod -n $NAMESPACE"

URL=$(kubectl get ingress -n $NAMESPACE podinfo-helm-podinfo -o jsonpath='{.spec.rules[0].host}')
p "# Update PodInfo HelmRelease resource"
pe "code oci/helmrelease-podinfo.yaml"
p "# Apply HelmRelease resource"
pe "kubectl apply -f oci/helmrelease-podinfo.yaml"
p "# Check PodInfo deployment rollout"
pe "kubectl get pods -n $NAMESPACE --watch"
p "# Open PodInfo https://$URL"

echo
echo
p "# Go back to slides"

wait
end_demo