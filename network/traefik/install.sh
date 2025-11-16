
# https://doc.traefik.io/traefik/setup/kubernetes/#add-the-chart-repo-and-namespace
helm repo add traefik https://traefik.github.io/charts
helm repo update
kubectl create ns traefik
helm install traefik traefik/traefik --namespace traefik

# https://doc.traefik.io/traefik/reference/install-configuration/providers/kubernetes/kubernetes-crd/
#kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.6/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

