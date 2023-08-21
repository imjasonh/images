#!/usr/bin/env bash

set -o errexit -o nounset -o errtrace -o pipefail -x

docker run --name pause \
    -d \
    "${IMAGE_NAME}"

sleep 3

docker ps | grep pause

docker rm -f pause
