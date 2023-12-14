#!/usr/bin/env bash

flux delete -s source git podinfo
flux delete -s kustomization podinfo
flux delete -s helmrelease podinfo
flux delete -s source oci podinfo
flux delete -s source helm podinfo

kubectl delete ns podinfo-kustomize
kubectl delete ns podinfo-helm

kubectl create ns podinfo-kustomize
kubectl create ns podinfo-helm

# Delete all pods in ingress-nginx namespace
kubectl delete pod -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Create a root CA for the cluster
flux create secret tls labs-root-ca \
  --ca-crt-file=/etc/ssl/certs/labs.pem

kubectl -n flux-system create secret generic cosign-pub \
  --from-file=cosign.pub=../cosign.pub