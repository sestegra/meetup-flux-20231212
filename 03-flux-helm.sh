#!/usr/bin/env bash

REGISTRY_URL="registry.my.labs"
REPOSITORY="images/podinfo"
TAG="6.5.3"
PLATFORM="linux/amd64"
NAMESPACE=$(yq -r '.spec.targetNamespace' git/helmrelease-podinfo.yaml)

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

p "# Open PodInfo Helm files"
pe "code ../podinfo/charts/podinfo/Chart.yaml"

p "# Create HelmRelease resource for PodInfo"
pe "code git/helmrelease-podinfo.yaml"

p "# Apply HelmRelease resource"
pe "kubectl apply -f git/helmrelease-podinfo.yaml"

p "# Check HelmRelease resource status"
pe "flux get helmreleases podinfo"

p "# Check PodInfo deployment"
pe "kubectl get all -n $NAMESPACE"

p "# Get PodInfo URL"
pe "kubectl get ingress -n $NAMESPACE podinfo-helm-podinfo"

# Get the URL
URL=$(kubectl get ingress -n $NAMESPACE podinfo-helm-podinfo -o jsonpath='{.spec.rules[0].host}')
p "# Wait for DNS propagation"
pe "watch dig +short $URL"
p "# Open PodInfo https://$URL"

p "# Update PodInfo HelmRelease resource"
pe "code git/helmrelease-podinfo.yaml"
p "# Apply HelmRelease resource"
pe "kubectl apply -f git/helmrelease-podinfo.yaml"
p "# Check PodInfo deployment rollout"
pe "kubectl get pods -n $NAMESPACE --watch"
p "# Open PodInfo https://$URL"

echo
echo
p "# Back to slides"

wait
end_demo