# Rancher Quick Start — Step-by-step tutorial

This guide shows two common installation flows:
1) Public domain with Let's Encrypt (recommended for production)  
2) Internal network using cert-manager + a private CA (for intranets)

Prerequisites
- A Kubernetes cluster with kubectl configured (context points to target cluster)
- Helm 3 installed (instructions below)
- For public installs: a DNS A record pointing your chosen hostname to your cluster ingress IP
- For private installs: ability to import a CA certificate into client browsers/systems

---

## 1. Install Helm 3 (if needed)
Run the official installer:
```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

Add Rancher chart repo and update:
```bash
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
```

---

## 2. Public domain using Let's Encrypt
This flow assumes you own a public domain (e.g. rancher.example.com) and its DNS points to your ingress.

1. Create the Rancher namespace:
```bash
kubectl create namespace cattle-system
```

2. (Optional) Install cert-manager if you want to manage certificates in-cluster:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl -n cert-manager get po
```

3. Install Rancher using the Helm chart. Replace `rancher.example.com` and `you@example.com` with your real hostname and email:
```bash
helm install rancher rancher-stable/rancher \
    --namespace cattle-system \
    --set hostname=rancher.example.com \
    --set replicas=3 \
    --set ingress.tls.source=letsEncrypt \
    --set letsEncrypt.email=you@example.com \
    --set letsEncrypt.ingress.class=nginx
```
Notes:
- `replicas=3` is recommended for HA; use `replicas=1` for testing.
- `ingress.tls.source=letsEncrypt` tells Rancher to request certificates via Let's Encrypt.

4. Watch rollout and access Rancher:
```bash
kubectl -n cattle-system rollout status deploy/rancher
# then open: https://rancher.example.com
```

---

## 3. Internal network: cert-manager + self-signed private CA
This flow creates an internal CA and configures cert-manager to issue certificates for Rancher automatically.

1. Generate a private root CA (keep the key secret):
```bash
openssl genrsa -out rootCA.key 4096
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 \
    -out rootCA.crt -subj "/CN=My-Private-CA"
```
- `rootCA.key` is the private key (do not share).
- `rootCA.crt` is the public root certificate (import into browsers/OS).

2. Install cert-manager and verify:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl -n cert-manager get po
```

3. Create a TLS secret in cert-manager namespace containing your private CA:
```bash
kubectl -n cert-manager create secret tls private-ca \
    --cert=rootCA.crt --key=rootCA.key
```

4. Create a ClusterIssuer that uses the private CA. Save and apply:
```bash
cat > private-ca-issuer.yaml <<'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
    name: private-ca-issuer
spec:
    ca:
        secretName: private-ca
EOF

kubectl apply -f private-ca-issuer.yaml
```

5. Install Rancher configured to use cert-manager + the private CA. Replace hostname:
```bash
helm install rancher rancher-stable/rancher \
    --namespace cattle-system \
    --create-namespace \
    --set hostname=rancher.internal.local \
    --set replicas=3 \
    --set ingress.tls.source=secret \
    --set privateCA=true
```
Rancher/Cerit-Manager will request a certificate using the ClusterIssuer and store it as a secret.

6. Verify certificates and ingress:
```bash
kubectl -n cattle-system get certificate
kubectl -n cattle-system get ingress
```

7. Import rootCA.crt into your browser/OS so the browser trusts certificates issued by your private CA.

---

## 4. Verification & troubleshooting (quick)
- Check Rancher pods:
    ```bash
    kubectl -n cattle-system get pods
    kubectl -n cattle-system logs deploy/rancher
    ```
- Check cert-manager resources:
    ```bash
    kubectl -n cert-manager get pods
    kubectl -n cert-manager describe order,challenge,certificate
    ```
- Inspect ingress:
    ```bash
    kubectl -n cattle-system describe ingress
    ```
- If Let's Encrypt fails, ensure:
    - DNS resolves correctly
    - Ingress controller is reachable from the internet
    - ACME HTTP-01 or DNS-01 challenge configuration matches your ingress setup

---

If you want, I can adapt this to use a specific ingress controller (nginx/traefik) or produce ready-made YAML for your environment.