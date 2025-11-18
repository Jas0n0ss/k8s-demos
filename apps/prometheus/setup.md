```bash
# 创建命名空间 (如果不存在)
kubectl create namespace monitoring

# 安装或升级
helm upgrade --install my-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f values.yml \
  --create-namespace # 如果 monitoring 命名空间不存在，此标志会自动创建

