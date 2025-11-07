# Kubernetes Monitoring Setup using Helm
This guide installs Prometheus, Grafana, and Loki for Kubernetes monitoring and logging.

## ✅ Prerequisites
- Kubernetes cluster running (K3s / Minikube / EKS / etc.)
- Helm 3+ installed
- kubectl configured to access the cluster

Verify:
```bash
kubectl get nodes
helm version
```

---

## ✅ Step 1: Add Helm Repositories
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

---

## ✅ Step 2: Create Monitoring Namespace
```bash
kubectl create namespace monitoring
```

---

## ✅ Step 3: Install Prometheus Stack (metrics)
This installs:
✔ Prometheus  
✔ Grafana  
✔ Alertmanager  
✔ Node Exporter  
```bash
helm install monitor prometheus-community/kube-prometheus-stack -n monitoring
```

Check installation:
```bash
kubectl get pods -n monitoring
```

---

## ✅ Step 4: Install Loki Stack (logs)
This installs:
✔ Loki  
✔ Promtail (log collector)
```bash
helm install loki grafana/loki-stack -n monitoring
```

Check pods:
```bash
kubectl get pods -n monitoring
```

---

## ✅ Step 5: Access Grafana Dashboard
Port-forward service:
```bash
kubectl port-forward svc/monitor-grafana -n monitoring 3000:80
```

Open in browser:
```
http://localhost:3000
```

Default login:
- Username: admin
- Password: prom-operator

> ⚠️ Change the password after login (Admin → Settings)

---

## ✅ Step 6: Check Prometheus & Loki
Prometheus port-forward:
```bash
kubectl port-forward svc/monitor-kube-prometheus-sta-prometheus -n monitoring 9090:9090
```

Loki port-forward:
```bash
kubectl port-forward svc/loki -n monitoring 3100:3100
```

---

## Optional: Enable Grafana persistence
```bash
helm upgrade monitor   prometheus-community/kube-prometheus-stack   -n monitoring   --set grafana.persistence.enabled=true   --set grafana.persistence.size=10Gi
```

---

## ✅ Uninstall All Monitoring Components
```bash
helm uninstall monitor -n monitoring
helm uninstall loki -n monitoring
kubectl delete ns monitoring
```

---

## Done ✅
Prometheus, Grafana & Loki are running on your Kubernetes cluster!
