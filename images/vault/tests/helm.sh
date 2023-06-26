#!/usr/bin/env bash

# monopod:tag:k8s

set -o errexit -o nounset -o errtrace -o pipefail -x

helm repo add hashicorp https://helm.releases.hashicorp.com

# Note testing with local version of vault and stable version of vault-k8s image
helm install vault-${FREE_PORT} hashicorp/vault \
	--namespace vault-${FREE_PORT} \
	--create-namespace \
	--set injector.image.repository=cgr.dev/chainguard/vault-k8s \
	--set injector.image.tag=latest \
	--set injector.agentImage.repository=${IMAGE_REPOSITORY} \
	--set injector.agentImage.tag=${IMAGE_TAG} \
	--set server.image.repository=${IMAGE_REPOSITORY} \
	--set server.image.tag=${IMAGE_TAG}

max_retries=20
retry_count=0

while [ $retry_count -lt $max_retries ]; do
    sleep 2
    kubectl get pod -n vault vault-${FREE_PORT}-0 | grep "Running" && rc=$? || rc=$?
    if [ $rc -eq 0 ]; then
        break
    fi
    retry_count=$((retry_count + 1))
done

# Now unseal vault, which should move it to ready
kubectl exec -n vault-${FREE_PORT} vault-${FREE_PORT}-0 -- vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > cluster-keys.json

KEY=$(jq -r ".unseal_keys_b64[]" cluster-keys.json)
kubectl exec -n vault-${FREE_PORT} vault-${FREE_PORT}-0 -- vault operator unseal $KEY

kubectl wait --for=condition=ready -n vault-${FREE_PORT} --timeout=120s pod/vault-${FREE_PORT}-0
