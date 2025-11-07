# Monitoring Setup for K3s on Ubuntu 24.04 (Prometheus + Grafana + Loki)

These commands are tuned for a **local K3s single-node cluster** running on Ubuntu 24.04.

## 0) Prepare the machine
```bash
# update & essentials
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl unzip git
```

## 1) (Optional) Remove previous minikube or k3s installs
```bash
# Remove old k3s (if any)
sudo /usr/local/bin/k3s-uninstall.sh 2>/dev/null || true
# Stop minikube if running
minikube stop 2>/dev/null || true
```

## 2) Install K3s (single-node)
```bash
# Install latest k3s (uses containerd)
curl -sfL https://get.k3s.io | sudo sh -
# Verify
sudo systemctl status k3s
sudo k3s kubectl get nodes
```

## 3) Make kubectl available without sudo (optional)
```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
# now you can use kubectl directly
kubectl get nodes
```

## 4) Install Helm (if not installed)
```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm version
```

## 5) Add Helm repos & update
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

## 6) Create monitoring namespace
```bash
kubectl create namespace monitoring
```

## 7) Install Prometheus stack (kube-prometheus-stack) with tuned values
```bash
# use provided values file for persistence & smaller default resources
helm upgrade --install monitor prometheus-community/kube-prometheus-stack   -n monitoring   -f monitoring/values-prometheus.yaml
```

## 8) Install Loki stack (logs) with tuned values
```bash
helm upgrade --install loki grafana/loki-stack   -n monitoring   -f monitoring/values-loki.yaml
```

## 9) Install Grafana (if not bundled with stack) or rely on kube-prometheus-stack Grafana
# Access Grafana
```bash
# port-forward Grafana service (kube-prometheus-stack creates monitor-grafana svc)
kubectl port-forward svc/monitor-grafana -n monitoring 3000:80
# open in browser: http://localhost:3000
# default credentials:
# user: admin
# pass: prom-operator
```

## 10) Import Grafana dashboard
1. In Grafana → Dashboards → Import → Upload `monitoring/dashboards/K3s-Advanced-Monitoring.json`
2. Choose the Prometheus data source (created by kube-prometheus-stack)
3. Save

## 11) Apply Alert rules (Prometheus)
```bash
kubectl apply -n monitoring -f monitoring/alerts-prometheus.yaml
```

## 12) Useful checks
```bash
kubectl get pods -n monitoring
kubectl get pvc -n monitoring
kubectl logs -n monitoring deploy/monitor-kube-prometheus-sta-prometheus -c prometheus || true
```

## 13) Uninstall / cleanup
```bash
helm uninstall monitor -n monitoring || true
helm uninstall loki -n monitoring || true
kubectl delete ns monitoring || true
```

## Troubleshooting
- If Grafana fails to start, describe its pod and view events:
  `kubectl describe pod <pod> -n monitoring` and `kubectl logs pod/<pod> -n monitoring`
- If PVCs remain Pending, ensure local-storage class exists or set `volume.emptyDir` in Helm values for test/dev.
