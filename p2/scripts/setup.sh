#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive	# prevents access to stdin that give errors
export INSTALL_K3S_VERSION="v1.36.4+k3s1"
NODE_READY_WAIT_SECONDS=300

sudo apt-get update -y
sudo apt-get install curl -y
curl -sfL https://get.k3s.io | sh -		# single-node k3s server, no agent to join

waited=0
until sudo kubectl get nodes 2>/dev/null | grep -q " Ready"; do
	if [ "$waited" -ge "$NODE_READY_WAIT_SECONDS" ]; then
		echo "Timed out after ${NODE_READY_WAIT_SECONDS}s waiting for K3s node to be Ready" >&2
		exit 1
	fi
	sleep 1
	waited=$((waited + 1))
done
sudo kubectl apply -f /vagrant/confs/	# deploy apps as part of provisioning, not a manual test step
