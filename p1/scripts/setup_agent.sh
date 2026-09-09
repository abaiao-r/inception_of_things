#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive	# prevents access to stdin that give errors
export INSTALL_K3S_VERSION="v1.36.4+k3s1"

SERVER_IP="192.168.56.110"
TOKEN_FILE="/vagrant/k3s-node-token"
TOKEN_WAIT_SECONDS=300

sudo apt-get update -y
sudo apt-get install curl -y

waited=0
until [ -s "$TOKEN_FILE" ]; do
	if [ "$waited" -ge "$TOKEN_WAIT_SECONDS" ]; then
		echo "Timed out after ${TOKEN_WAIT_SECONDS}s waiting for $TOKEN_FILE (server did not publish its token)" >&2
		exit 1
	fi
	sleep 1
	waited=$((waited + 1))
done
K3S_TOKEN=$(cat "$TOKEN_FILE")

curl -sfL https://get.k3s.io | K3S_URL="https://${SERVER_IP}:6443" K3S_TOKEN="$K3S_TOKEN" sh -		# register k3s agent, joins the server
