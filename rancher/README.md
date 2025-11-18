### Rancher Quick Start Guide

This guide shows **two common Rancher installation flows** using Traefik as the ingress controller:

1. **Public domain with Let's Encrypt** (recommended for production)  
2. **Internal network using cert-manager + a private CA** (for intranets)

---

#### Prerequisites

- Kubernetes cluster with `kubectl` configured
- Helm 3 installed
- Traefik installed as ingress controller
- For public installs: a DNS A record pointing your hostname to the cluster ingress IP
- For private installs: ability to import a CA certificate into client browsers/OS

---

##### 1. Install Helm 3

```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
```

------

##### 2. Install Traefik

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update

helm install traefik traefik/traefik \
    --namespace traefik --create-namespace \
    --set service.type=LoadBalancer \
    --set ingressClass.enabled=true
```

Check the external IP and ingress class:

```bash
kubectl -n traefik get svc
kubectl get ingressclass
```

------

#### 3. Public Domain Installation (Let's Encrypt)

##### 3.1 Create Namespace

```bash
kubectl create namespace cattle-system
```

##### 3.2 Install cert-manager (optional)

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl -n cert-manager get pods
```

##### 3.3 Install Rancher

```bash
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.example.com \
  --set replicas=3 \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=you@example.com \
  --set letsEncrypt.ingress.class=traefik
```

##### 3.4 Access Rancher

```bash
kubectl -n cattle-system rollout status deploy/rancher
# Access at: https://rancher.example.com
```

------

#### 4. Internal Network Installation (Private CA)

##### 4.1 Generate Private Root CA

```bash
openssl genrsa -out rootCA.key 4096
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 \
  -out rootCA.crt \
  -subj "/CN=Private-Rancher-CA"
```

> Keep `rootCA.key` secure. Import `rootCA.crt` into client browsers/OS.

##### 4.2 Install cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl -n cert-manager get pods
```

##### 4.3 Create TLS Secret

```bash
kubectl -n cert-manager create secret tls private-ca \
  --cert=rootCA.crt \
  --key=rootCA.key
```

##### 4.4 Create ClusterIssuer

`private-ca-issuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: private-ca-issuer
spec:
  ca:
    secretName: private-ca
kubectl apply -f private-ca-issuer.yaml
```

##### 4.5 Install Rancher

```bash
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --create-namespace \
  --set hostname=rancher.internal.local \
  --set replicas=3 \
  --set ingress.tls.source=secret \
  --set privateCA=true \
  --set ingress.ingressClassName=traefik
```

##### 4.6 Create Rancher Certificate

`rancher-certificate.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: rancher-cert
  namespace: cattle-system
spec:
  secretName: tls-rancher-ingress
  issuerRef:
    name: private-ca-issuer
    kind: ClusterIssuer
  commonName: rancher.internal.local
  dnsNames:
  - rancher.internal.local
kubectl apply -f rancher-certificate.yaml
kubectl -n cattle-system get certificate
kubectl -n cattle-system get secret tls-rancher-ingress
kubectl -n cattle-system get ingress
```

> Import `rootCA.crt` into your browser/OS to trust the certificate.

