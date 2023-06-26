#!/usr/bin/env bash

set -o errexit -o nounset -o errtrace -o pipefail -x

# Create Corefile
cat >Corefile <<EOF
.:53 {
    forward . 8.8.8.8 1.1.1.1
    log
    errors
    health
}

labs.hello.db.:53 {
    log
    errors
    health
    file /etc/master.db
}
EOF
trap 'rm Corefile' ERR

# Create dummy A, CNAME, TXT record entries
cat >master.db <<EOF
labs.hello.db.              IN  SOA    dns.labs.hello.db. admin.labs.hello.db. 1675303881 7200 3600 1209600 3600
dns.labs.hello.db.          IN  A      192.168.1.3
node.labs.hello.db.         IN  A      192.168.1.10
mgmt.dns.labs.hello.db.     IN  CNAME  dns.labs.hello.db.
mgmt.node.labs.hello.db.    IN  CNAME  node.labs.hello.db.
dns.labs.hello.db.          IN  TXT    "Hello from dummy DNS server"
node.labs.hello.db.         IN  TXT    "Hello from dummy node"
EOF
trap 'rm master.db' ERR

# TODO: Check if nslookup is available on the host and if not, install it

# Run coredns with host port mapped to open port (only UDP needed here)
container_name="coredns-${FREE_PORT}"
# Change the default sysctl to check that the binary has the
# appropriate "setcap" configured properly.
docker run --sysctl net.ipv4.ip_unprivileged_port_start=100 --name "${container_name}" -v ${PWD}:/etc -p ${FREE_PORT}:53/udp "${IMAGE_NAME}" -conf=/etc/Corefile -dns.port=53 &
trap 'docker rm -f "${container_name}"' EXIT

# Create a temporary file for stdout & stderr on txt record lookup
tmp_file=$(mktemp)
trap 'rm ${tmp_file}' ERR

# Coredns doesn't have any built in health check functions or API, so wait a moment for the docker container to become ready
sleep 5
if netstat -uln | grep :${FREE_PORT} >/dev/null; then
	echo "Coredns container started"

	# Do a txt record lookup and output stdout/stderr to temp file
	nslookup -port=${FREE_PORT} -q=TXT node.labs.hello.db 127.0.0.1 >"${tmp_file}" 2>&1
else
	echo "Coredns container failed to start"
fi

# And check the temporary file to confirm the lookup was successful and logged
lookup_text="Hello from dummy node"
if ! grep -q "${lookup_text}" "${tmp_file}"; then
	echo "Failed to find ${lookup_text} in ${tmp_file}"
	cat "${tmp_file}"
	exit 1
fi
