#### MetalLB Cloud Compatibility
https://metallb.io/installation/clouds/
#### Network Addon Compatibility
https://metallb.io/installation/network-addons/
#### Installation
https://metallb.io/installation/
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
```
##### Advanced L2 configuration
https://metallb.io/configuration/_advanced_l2_configuration/
```yaml
# IPPool
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: home-ip-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.1.100-10.0.1.150  # 分配给 LoadBalancer 的外部 IP
---
# L2 configuration
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - home-ip-pool
---
apiVersion: v1
kind: Namespace
metadata:
  name: lab  # 测试用命名空间
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: traefik/whoami:latest
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-lb
  namespace: lab
spec:
  type: LoadBalancer  # LoadBalancer 类型让 MetalLB 分配外部 IP
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80                   # Service 端口
      targetPort: 80             # Pod 端口
  loadBalancerIP:                # 测试用静态 IP，可替换为你的 MetalLB IP 池中的任意地址

```
##### Advanced BGP configuration
https://metallb.io/configuration/_advanced_bgp_configuration/
