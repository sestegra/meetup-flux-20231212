#!/usr/bin/env bash

NAMESPACE=$(yq -r '.spec.targetNamespace' git/kustomize-podinfo.yaml)

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

p "# Kubernetes already configured by Platform team"
pe "kubectl get pods -A"
pe "kubectl get ns | grep podinfo"

p "# PodInfo Git repository"
p "# https://gitlab.my.labs/labs-group/labs-project"
p "git clone git@gitlab.my.labs:labs-group/labs-project.git ../podinfo"
echo "Cloning into '../podinfo'...
remote: Enumerating objects: 431, done.
remote: Total 431 (delta 0), reused 0 (delta 0), pack-reused 431
Receiving objects: 100% (431/431), 339.92 KiB | 18.88 MiB/s, done.
Resolving deltas: 100% (96/96), done."
pe ""

p "# Open PodInfo Kustomize files"
pe "code ../podinfo/kustomize/kustomization.yaml"

p "# Create source resource for PodInfo"
pe "code git/source-podinfo.yaml"

pe "# Apply source resource"
pe "kubectl apply -f git/source-podinfo.yaml"

p "# Check source resource status"
pe "flux get sources git podinfo"

p "# Create kustomization resource for PodInfo"
pe "code git/kustomize-podinfo.yaml"

p "# Apply kustomization resource"
pe "kubectl apply -f git/kustomize-podinfo.yaml"

p "# Check kustomization resource status"
pe "flux get kustomizations podinfo"

p "# Check PodInfo deployment"
pe "kubectl get all -n $NAMESPACE"

p "# Get PodInfo URL"
pe "kubectl get ingress -n $NAMESPACE podinfo"

# Get the URL
URL=$(kubectl get ingress -n $NAMESPACE podinfo -o jsonpath='{.spec.rules[0].host}')
p "# Wait for DNS propagation"
pe "watch dig +short $URL"
p "# Open PodInfo https://$URL"

p "# Update PodInfo kustomization resource for PodInfo"
pe "code git/kustomize-podinfo.yaml"

p "# Apply kustomization resource"
pe "kubectl apply -f git/kustomize-podinfo.yaml"
p "# Check PodInfo deployment rollout"
pe "kubectl get pods -n $NAMESPACE --watch"
p "# Open PodInfo https://$URL"

echo
echo
p "# Do the same for Helm"

wait
end_demo