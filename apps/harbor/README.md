```bash
helm repo add harbor https://helm.goharbor.io
helm repo update

kubectl create ns harbor

openssl req -x509 -nodes -days 3650 \
  -newkey rsa:4096 \
  -keyout harbor.key \
  -out harbor.crt \
  -subj "/C=US/ST=Local/L=Local/O=K8s/OU=Harbor/CN=harbor.k8s.io"


kubectl -n harbor create secret tls harbor-tls \
  --cert=harbor.crt \
  --key=harbor.key

helm install harbor harbor/harbor \
  -n harbor \
  -f values.yml

kubectl apply -f middleware-upload.yaml 
kubectl apply -f ngressroute-core.yaml

kubectl get pod,svc -n harbor 
```
