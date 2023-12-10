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
