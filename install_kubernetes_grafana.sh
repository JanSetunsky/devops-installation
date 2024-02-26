# Get Variables
NAMESPACE="monitoring-system"
INSTANCE_NAME="grafana"
STORAGE_CLASS="grafana-local-storage"
REPOSITORY_URL="https://grafana.github.io/helm-charts"
ADMIN_PASSWORD="12345"

# Create namespace
kubectl create namespace "$NAMESPACE"

# Install Grafana
helm repo add grafana "$REPOSITORY_URL"
helm repo update
helm upgrade --install "$INSTANCE_NAME" grafana/grafana \
  --namespace "$NAMESPACE" \
  --set persistence.enabled=false \
  --set adminPassword="$ADMIN_PASSWORD" \
  --wait