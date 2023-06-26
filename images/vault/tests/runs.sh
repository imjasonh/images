#!/usr/bin/env bash

set -o errexit -o nounset -o errtrace -o pipefail -x

# Run the vault container in the background and make sure it works using the API
docker run --rm -d --name vault-${FREE_PORT} --cap-add IPC_LOCK -p ${FREE_PORT}:${FREE_PORT} "${IMAGE_NAME}" server -dev -dev-root-token-id=root

trap 'docker kill vault-${FREE_PORT}' EXIT

sleep 5

# Exec into the container and run the vault status command
docker exec vault-${FREE_PORT} vault status --address http://127.0.0.1:${FREE_PORT}
