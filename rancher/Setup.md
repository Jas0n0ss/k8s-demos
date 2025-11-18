```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  -f values.yml \
  --create-namespace

kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{ "\n" }}'

https://rancher.k8s.io

```