#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive	# prevents access to stdin that give errors
export INSTALL_K3S_VERSION="v1.36.4+k3s1"

sudo apt-get update -y
sudo apt-get install curl -y
curl -sfL https://get.k3s.io | sh -		# single-node k3s server, no agent to join
