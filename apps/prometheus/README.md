

## **Prerequisites**

1. A working Kubernetes cluster (v1.20+ recommended)
2. `kubectl` configured to access the cluster
3. `Helm` installed (v3+)
4. Optional but recommended: `kubectl create namespace monitoring` for isolation



## **Step 1: Add the Helm repo**

The kube-prometheus-stack is maintained in the **Prometheus Community Helm charts** repo.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

Check that the chart is available:

```bash
helm search repo prometheus-community/kube-prometheus-stack
```



## **Step 2: Create a namespace (optional but recommended)**

```bash
kubectl create namespace monitoring
```



## **Step 3: Install kube-prometheus-stack using Helm**

You can install with default values first:

```bash
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
```

**Explanation:**

* `prometheus` → release name
* `--namespace monitoring` → namespace to deploy into

> This will install:
>
> * Prometheus server
> * Alertmanager
> * Node Exporter
> * Kube-state-metrics
> * Grafana

---

## **Step 4: Verify the installation**

Check pods:

```bash
kubectl get pods -n monitoring
```

You should see pods for Prometheus, Alertmanager, Grafana, etc.

Check services:

```bash
kubectl get svc -n monitoring
```

---

## **Step 5: Access Grafana**

Grafana is installed by default. To access it:

```bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```

Then open your browser at: `http://localhost:3000`

**Default credentials:**

* User: `admin`
* Password: `prom-operator`



> You can change these via a `values.yaml` file.

---

## **Step 6: (Optional) Custom Configuration**

You can customize the installation using a `values.yaml` file:

```yaml
grafana:
  adminPassword: "yourpassword"
prometheus:
  prometheusSpec:
    retention: 15d
    scrapeInterval: "30s"
```

Then install:

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f values.yaml
```

---

## **Step 7: Uninstall**

```bash
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```
