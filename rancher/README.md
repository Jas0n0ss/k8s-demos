# Rancher Quick Start — Step-by-step tutorial (Traefik)

This guide shows two common installation flows with Traefik as the ingress controller:
1) Public domain with Let's Encrypt (recommended for production)  
2) Internal network using cert-manager + a private CA (for intranets)

Prerequisites
- A Kubernetes cluster with kubectl configured (context points to target cluster)
- Helm 3 installed (instructions below)
- Traefik installed as your ingress controller (instructions below)
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

## 1a. Install Traefik (if not already present)
Install Traefik v2 via Helm and expose it (example uses LoadBalancer; adjust for your environment):
```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update

helm install traefik traefik/traefik \
    --namespace traefik --create-namespace \
    --set service.type=LoadBalancer \
    --set ingressClass.enabled=true
```
Wait for Traefik to become reachable and note the external IP:
```bash
kubectl -n traefik get svc
```
Ensure the Traefik ingress class name is `traefik` (default for this chart). If you use a different ingress class name, substitute it in the Rancher install commands below.

---

## 2. Public domain using Let's Encrypt (via Traefik)
This flow assumes you own a public domain (e.g. rancher.example.com) and DNS points to your Traefik ingress.

1. Create the Rancher namespace:
```bash
kubectl create namespace cattle-system
```

2. (Optional) Install cert-manager if you want to manage certificates in-cluster:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl -n cert-manager get po
```

3. Install Rancher using the Helm chart. Replace `rancher.example.com` and `you@example.com` with your real hostname and email. Tell Rancher to request certs using Let's Encrypt and target the Traefik ingress class:
```bash
helm install rancher rancher-stable/rancher \
        --namespace cattle-system \
        --set hostname=rancher.example.com \
        --set replicas=3 \
        --set ingress.tls.source=letsEncrypt \
        --set letsEncrypt.email=you@example.com \
        --set letsEncrypt.ingress.class=traefik
```
Notes:
- `replicas=3` is recommended for HA; use `replicas=1` for testing.
- `letsEncrypt.ingress.class=traefik` tells Rancher/ACME to use Traefik for the HTTP-01 challenge. Depending on your cluster/Traefik setup you may prefer DNS-01; adapt accordingly.

4. Watch rollout and access Rancher:
```bash
kubectl -n cattle-system rollout status deploy/rancher
# then open: https://rancher.example.com
```

---

## 3. Internal network: cert-manager + self-signed private CA (Traefik)
This flow creates an internal CA and configures cert-manager to issue certificates for Rancher. Traefik will use the TLS secret produced by cert-manager.

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

5. Install Rancher configured to use cert-manager + the private CA. Replace hostname and ensure Traefik is the ingress class:
```bash
helm install rancher rancher-stable/rancher \
        --namespace cattle-system \
        --create-namespace \
        --set hostname=rancher.internal.local \
        --set replicas=3 \
        --set ingress.tls.source=secret \
        --set privateCA=true \
        --set letsEncrypt.ingress.class=traefik
```
Rancher/cert-manager will request a certificate using the ClusterIssuer and store it as a Kubernetes secret. Traefik will pick up the secret for TLS on the ingress.

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
- Inspect Traefik ingress objects & services:
        ```bash
        kubectl -n cattle-system describe ingress
        kubectl -n traefik get svc
        ```
- If Let's Encrypt fails, ensure:
        - DNS resolves correctly to Traefik's external IP
        - Traefik is reachable from the internet on port 80 (HTTP-01) or DNS challenge is configured
        - ACME challenge type configured matches your Traefik/cluster setup
