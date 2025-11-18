
#### https://doc.traefik.io/traefik/setup/kubernetes/#add-the-chart-repo-and-namespace
```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik --namespace kube-system 
```
```bash
#### install
helm install traefik traefik/traefik --namespace kube-system -f values.yaml

#### update
helm upgrade traefik traefik/traefik --namespace kube-system -f values.yaml

#### 卸载
helm uninstall traefik --namespace kube-system

# 安装或升级 Traefik
helm upgrade --install traefik traefik/traefik \
  --namespace traefik-system \
  --create-namespace \
  -f values.yaml
```


#### Enable Dashboard
```bash
helm install traefik traefik/traefik \
  --namespace kube-system \
  --create-namespace \
  -f values.yaml
```
```bash
[root@master-01 ~]# kubectl get all -n traefik-system
NAME                          READY   STATUS    RESTARTS   AGE
pod/traefik-f74fcf887-44crq   1/1     Running   0          7m12s

NAME              TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
service/traefik   LoadBalancer   10.68.246.114   192.168.2.200   80:31510/TCP,443:32241/TCP   7m12s

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/traefik   1/1     1            1           7m12s

NAME                                DESIRED   CURRENT   READY   AGE
replicaset.apps/traefik-f74fcf887   1         1         1       7m12s
[root@master-01 ~]# echo 192.168.2.200 traefik.k8s.io >> /etc/hosts
[root@master-01 ~]# curl -I http://192.168.2.200
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Tue, 18 Nov 2025 17:52:07 GMT
Content-Length: 19

[root@master-01 ~]# curl -I http://traefik.k8s.io
HTTP/1.1 405 Method Not Allowed
Date: Tue, 18 Nov 2025 17:52:15 GMT
```

---
#### 自动 TLS 证书 → 使用 cert-manager + Let’s Encrypt（免费、自动续期、浏览器信任）

```bash
# 添加 repo
helm repo add jetstack https://charts.jetstack.io
helm repo update

# 安装 cert-manager（含 CRDs）
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --version v1.16.1

kubectl -n cert-manager get pods
```

```yaml
# issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # Let's Encrypt 生产环境 endpoint（正式证书）
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com  # 🔔 替换为你的真实邮箱！
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: traefik  # 注意：Traefik v3 不再用 IngressClass，但 cert-manager 仍认这个
```
```bash
kubectl apply -f issuer.yaml
```

```bash
helm install traefik traefik/traefik \
  --namespace kube-system \
  --create-namespace \
  -f tls-values.yaml
```
