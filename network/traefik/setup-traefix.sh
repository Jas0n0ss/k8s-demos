#!/bin/bash
# setup-traefik.sh —— 部署 Traefik 到 traefik-system，域名 traefik.k8s.io

set -euo pipefail

NS="traefik-system"
DOMAIN="traefik.k8s.io"
CERT_SECRET="local-selfsigned-tls"
DASHBOARD_USER="admin"
DASHBOARD_PASS="P@ssw0rd"  # 🔐 生产请替换！

echo "🚀 Preparing namespace: $NS"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

echo "🔐 Generating TLS certificate for $DOMAIN (and *.k8s.io)"
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /tmp/tls.key -out /tmp/tls.crt \
  -subj "/CN=$DOMAIN" \
  -addext "subjectAltName = DNS:$DOMAIN,DNS:*.k8s.io" >/dev/null 2>&1

echo "📦 Creating TLS secret: $CERT_SECRET in namespace $NS"
kubectl create secret tls "$CERT_SECRET" \
  --namespace "$NS" \
  --cert=/tmp/tls.crt \
  --key=/tmp/tls.key \
  --dry-run=client -o yaml | kubectl apply -f -

echo "🖥️  Configuring local hosts for $DOMAIN"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "127.0.0.1")
if ! grep -q "$DOMAIN" /etc/hosts 2>/dev/null; then
  echo "$NODE_IP $DOMAIN" | sudo tee -a /etc/hosts
fi
echo "✅ Hosts entry added: $NODE_IP $DOMAIN"

echo "📥 Adding Helm repo"
helm repo add traefik https://traefik.github.io/charts >/dev/null
helm repo update >/dev/null
echo "✅ Helm repo added: traefik"

echo "🚀 Installing Traefik Helm chart into namespace $NS"
helm upgrade --install traefik traefik/traefik \
  --namespace "$NS" \
  --values values.yaml \
  --version "^3.0"

echo
echo "✅ DONE! Dashboard will be ready in ~10s."
echo
echo "🔗 Access Dashboard at: https://traefik.k8s.io:30001"
echo "   → Username: $DASHBOARD_USER"
echo "   → Password: $DASHBOARD_PASS"
echo
echo "🔍 Verify:"
echo "   kubectl -n $NS get pods,svc,gateway"
echo "   curl -kI https://traefik.k8s.io:30001/api/rawdata  # (requires auth)"