# html-css-javascript-calculator — DevOps bundle

This repository contains:
- A simple static calculator app in `src/`
- Dockerfile + docker-compose for local testing
- GitHub Actions CI (build & push to GHCR) and CD (deploy to Kubernetes)
- Kubernetes manifests in `k8s/` (namespace, deployment, service, ingress)
- Basic placeholders for Sentry, Prometheus & Grafana integration

**Pre-filled image path:** `ghcr.io/praveendubey9696/calculator`

## How to use

1. Download & unzip, or clone into your GitHub repo.
2. Edit `k8s/deployment.yaml` and replace `REPLACE_IMAGE_TAG` with the image tag (CI will set this automatically during deployment via GitHub Actions).
3. Create GitHub Actions secrets:
   - `KUBECONFIG` — base64 of your kubeconfig file
   - (optional) `SENTRY_DSN` — if you want Sentry client errors
4. Push to GitHub. CI will build and push the Docker image to GHCR (`ghcr.io/praveendubey9696/calculator`).
5. Add DNS pointing to your ingress and update `k8s/ingress.yaml` host.

## Notes
- This bundle includes a simple front-end calculator. If you prefer to import the original upstream project files, replace the `src/` folder contents with those files.
- For production monitoring and logging, install `kube-prometheus-stack` (Prometheus & Grafana) and `loki-stack` (Loki + Promtail) using Helm.

