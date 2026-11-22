#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")/../p2"

vagrant up

vagrant ssh -c 'bash -s' <<'EOF'
set -euo pipefail

echo "=== Waiting for deployments ==="
sudo kubectl rollout status deployment/app1 --timeout=120s
sudo kubectl rollout status deployment/app2 --timeout=120s

echo
echo "=== Pods ==="
sudo kubectl get pods

echo
echo "=== Services ==="
sudo kubectl get svc

# Retrieve ClusterIPs dynamically
APP1_IP=$(sudo kubectl get svc app1 -o jsonpath='{.spec.clusterIP}')
APP2_IP=$(sudo kubectl get svc app2 -o jsonpath='{.spec.clusterIP}')

# Test App1
echo
echo "=== Testing App1 ($APP1_IP) ==="

APP1_RESPONSE=$(curl -fsS --max-time 10 "http://$APP1_IP:80")

if [[ "$APP1_RESPONSE" == "app1" ]]; then
    echo "PASS: App1 returned 'app1'"
else
    echo "FAIL: App1 returned unexpected response"
    echo "$APP1_RESPONSE"
    exit 1
fi

# Test App2
echo
echo "=== Testing App2 ($APP2_IP) ==="

APP2_RESPONSE=$(curl -fsS --max-time 10 "http://$APP2_IP:80")

if grep -qE '^Hostname: app2' <<< "$APP2_RESPONSE"; then
    echo "PASS: App2 returned a hostname starting with 'app2'"
else
    echo "FAIL: App2 returned unexpected response"
    echo "$APP2_RESPONSE"
    exit 1
fi

echo
echo "=== All tests passed successfully ==="
EOF
