#!/bin/bash

export DEBIAN_FRONTEND=noninteractive	# prevents access to stdin that give errors

sudo apt-get update -y
sudo apt-get install curl -y
curl -sfL https://get.k3s.io | sh -		# register k3s server
cp /var/lib/rancher/k3s/server/node-token /vagrant/k3s-node-token		# moves token to shared folder so agent can access later
