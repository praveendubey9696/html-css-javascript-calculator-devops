#!/usr/bin/env bash
set -euo pipefail

# Config — change if you wish
GITHUB_USER="praveendubey9696"
REPO_NAME="html-css-javascript-calculator-devops"
FULL_REPO="$GITHUB_USER/$REPO_NAME"
IMAGE_PATH="ghcr.io/${GITHUB_USER}/calculator"

echo
echo "=== DevOps repo bootstrap for k3s — ${FULL_REPO} ==="
echo

# 1) Ensure running from project root (check Dockerfile exists)
if [ ! -f Dockerfile ]; then
  echo "ERROR: Dockerfile not found. Run this script from the project root where the files are located."
  exit 1
fi

# 2) Install minimal dependencies if missing: gh, kubectl, helm, git, docker
install_if_missing() {
  cmd="$1"
  pkg="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "-> Installing $pkg (for command: $cmd)..."
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y "$pkg"
    else
      echo "Please install $pkg manually (package manager not detected)."
      exit 1
    fi
  else
    echo "-> $cmd found"
  fi
}

# Try quick installs (may ask for sudo)
install_if_missing gh gh
install_if_missing kubectl kubectl
install_if_missing helm helm
install_if_missing git git
install_if_missing docker docker.io

echo
echo "-> All required CLIs appear available (or were installed)."
echo

# 3) Ensure gh authenticated
if ! gh auth status >/dev/null 2>&1; then
  echo "Please authenticate with GitHub CLI (gh). You will be redirected to browser."
  gh auth login
else
  echo "gh CLI already authenticated"
fi

# 4) Create repo (if not existing) and push current directory
if gh repo view "$FULL_REPO" >/dev/null 2>&1; then
  echo "-> Repository $FULL_REPO already exists. Will push current branch."
else
  echo "-> Creating GitHub repository $FULL_REPO (public)"
  gh repo create "$FULL_REPO" --public --source=. --remote=origin -y
fi

# Ensure git configured and push
if [ ! -d .git ]; then
  git init
  git add .
  git commit -m "Initial commit — full DevOps pipeline"
  git branch -M main
  git remote add origin "https://github.com/${FULL_REPO}.git" || true
fi

echo "-> Pushing to GitHub..."
git add .
git commit -m "chore: bootstrap repo for k3s deployment" || true
git push -u origin main --force

# 5) Detect kubeconfig (k3s typical locations)
KUBECONFIG_PATH=""
if [ -f "$HOME/.kube/config" ]; then
  KUBECONFIG_PATH="$HOME/.kube/config"
elif [ -f "/etc/rancher/k3s/k3s.yaml" ]; then
  # k3s default — copy to ~/.kube/config so kubectl works without sudo
  echo "Found k3s kubeconfig at /etc/rancher/k3s/k3s.yaml — copying to ~/.kube/config (requires sudo)"
  mkdir -p "$HOME/.kube"
  sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
  sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
  KUBECONFIG_PATH="$HOME/.kube/config"
fi

if [ -z "$KUBECONFIG_PATH" ]; then
  echo "ERROR: Could not find kubeconfig in ~/.kube/config or /etc/rancher/k3s/k3s.yaml"
  echo "Please ensure kubectl is configured and try again."
  exit 1
fi

echo "-> Using kubeconfig: $KUBECONFIG_PATH"

# 6) Create base64 of kubeconfig to set as GitHub secret
KUBECONFIG_B64=$(base64 "$KUBECONFIG_PATH" | tr -d '\n')

echo "-> Setting GitHub repo secret KUBECONFIG (base64 encoded)..."
echo "$KUBECONFIG_B64" | gh secret set KUBECONFIG --repo "$FULL_REPO" --body -

# Optional: ask user for Sentry DSN and set
read -p "Optional: enter Sentry DSN to store as repo secret (or press ENTER to skip): " SENTRY_DSN
if [ -n "$SENTRY_DSN" ]; then
  gh secret set SENTRY_DSN --repo "$FULL_REPO" --body "$SENTRY_DSN"
  echo "-> SENTRY_DSN secret set."
else
  echo "-> Skipping Sentry secret."
fi

# 7) Install Prometheus + Grafana and Loki using Helm in the cluster
echo
echo "-> Installing monitoring stack into k3s cluster via Helm (monitoring & logging)"
kubectl config current-context

# add repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo update

# install kube-prometheus-stack
if helm status monitor -n monitoring >/dev/null 2>&1; then
  echo "monitor (kube-prometheus-stack) already installed"
else
  helm install monitor prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
fi

# install loki stack
if helm status loki -n logging >/dev/null 2>&1; then
  echo "loki (loki-stack) already installed"
else
  helm install loki grafana/loki-stack -n logging --create-namespace
fi

echo
echo "-> Monitoring stack installed (Prometheus/Grafana in 'monitoring' ns and Loki in 'logging' ns)."
echo "   It may take a couple minutes for pods to become ready."

# 8) Update k8s/deployment.yaml to use GitHub Actions image tag expression
echo "-> Patching k8s/deployment.yaml to use GitHub Actions image reference..."
if grep -q "REPLACE_IMAGE_TAG" k8s/deployment.yaml; then
  sed -i 's|ghcr.io/praveendubey9696/calculator:REPLACE_IMAGE_TAG|ghcr.io/praveendubey9696/calculator:${{ github.sha }}|g' k8s/deployment.yaml || true
  git add k8s/deployment.yaml
  git commit -m "ci: use \${{ github.sha }} for image in k8s deployment" || true
  git push origin main
fi

# 9) Trigger GitHub Actions CI by making an empty commit (or it may already have been triggered)
echo "-> Triggering CI by creating a minor commit..."
git commit --allow-empty -m "ci: trigger CI after bootstrap" || true
git push origin main

echo
echo "=== Done ==="
echo "Your repo: https://github.com/${FULL_REPO}"
echo "CI will build and push image to: ${IMAGE_PATH} (GHCR)"
echo
echo "To see Grafana: run (port-forward):"
echo "  kubectl -n monitoring port-forward svc/monitor-grafana 3000:80"
echo "Default Grafana login may be created by the chart (check helm notes)."
echo
echo "If anything fails, copy/paste the terminal output and I'll help debug."
