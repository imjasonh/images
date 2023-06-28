#!/usr/bin/env bash

# monopod:tag:k8s

set -o errexit -o nounset -o errtrace -o pipefail -x

NAMESPACE=${NAMESPACE:-kube-state-metrics-${RANDOM}}
RELEASE=${RELEASE:-cg-test-${RANDOM}}

helm upgrade --install ${RELEASE} --wait \
    prometheus-community/kube-state-metrics \
    --namespace ${NAMESPACE} \
    --create-namespace \
    --set image.repository=${IMAGE_REPOSITORY} \
    --set image.registry=${IMAGE_REGISTRY} \
    --set image.sha=${IMAGE_SHA}

# Wait for helm to catch up
sleep 3

if kubectl wait --for=condition=ready pod -n ${NAMESPACE} --timeout=30s --selector app.kubernetes.io/instance=${RELEASE}; then
  kubectl port-forward -n ${NAMESPACE} svc/${RELEASE}-kube-state-metrics ${FREE_PORT}:8080 &
  pid=$!
  trap "kill $pid" EXIT
  sleep 5
  curl localhost:${FREE_PORT}/metrics | grep kube
  echo "Success"
else
  echo "Failed"
  kubectl describe pod -n ${NAMESPACE} --selector app.kubernetes.io/instance=${RELEASE}
  kubectl logs -n ${NAMESPACE} --selector app.kubernetes.io/instance=${RELEASE}
  exit 1
fi
