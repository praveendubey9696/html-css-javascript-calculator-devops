# monitoring

This `monitoring` folder contains a production-ready, **local-optimized** monitoring stack for **K3s** on **Ubuntu 24.04**.
It installs Prometheus, Grafana, Loki and Alertmanager via Helm and includes:
- Helm values tuned for local machines (4–16GB RAM)
- Grafana dashboard JSON (Advanced)
- Alert rules (CPU, Pod CrashLoopBackOff, NodeDown)
- step-by-step `setup.md`

Paths:
```
monitoring/
├── setup.md
├── README.md
├── values-grafana.yaml
├── values-prometheus.yaml
├── values-loki.yaml
├── alerts-prometheus.yaml
└── dashboards/
    └── K3s-Advanced-Monitoring.json
```

**Notes (Ubuntu 24.04)**:
- k3s bundles containerd; no extra container runtime is required.
- Ensure you have at least 4GB RAM free (8GB recommended) for the full stack.
- All `kubectl` commands in the `setup.md` use the kubeconfig from k3s (`/etc/rancher/k3s/k3s.yaml`) or `kubectl` after copying config into `~/.kube/config`.
