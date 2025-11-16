
#### https://doc.traefik.io/traefik/setup/kubernetes/#add-the-chart-repo-and-namespace
```
helm repo add traefik https://traefik.github.io/charts
helm repo update
kubectl create ns traefik
helm install traefik traefik/traefik --namespace traefik
```
#### https://doc.traefik.io/traefik/reference/install-configuration/providers/kubernetes/kubernetes-crd/
```
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.6/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml
```
#### Traefik + LetsEncrypt + 持久化（本地或 NFS）安装脚本
```bash
helm upgrade --install traefik traefik/traefik \
  -n traefik --create-namespace \
  --set service.type=NodePort \
  --set ports.web.nodePort=32080 \
  --set ports.websecure.nodePort=32443 \
  --set persistence.enabled=true \
  --set persistence.storageClass=managed-nfs-storage \
  --set persistence.size=128Mi \
  --set additionalArguments="{\
      \"--certificatesresolvers.le.acme.httpchallenge=true\",\
      \"--certificatesresolvers.le.acme.httpchallenge.entrypoint=web\",\
      \"--certificatesresolvers.le.acme.email=azure@msft.org\",\
      \"--certificatesresolvers.le.acme.storage=/data/acme.json\"\
  }"
```
