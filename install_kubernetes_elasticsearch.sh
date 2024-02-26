# Set namespace
NAMESPACE="logging-system"
INSTANCE_NAME="elasticsearch"
REPOSITORY_URL="https://helm.elastic.co"

# Adding the chart repository
CHART_UID="$(uuidgen | cut -c 1-8)"
CHART_NAME="$INSTANCE_NAME-$CHART_UID"
helm repo add $CHART_NAME $REPOSITORY_URL

# Update Helm repos
helm repo update

# Create namespace
kubectl create namespace $NAMESPACE

# Install Elasticsearch with adjusted settings
helm install $CHART_NAME $CHART_NAME/elasticsearch \
  --namespace $NAMESPACE \
  --set replicas=1 \
  --set minimumMasterNodes=1 \
  --set antiAffinity="soft" \
  --set resources.requests.cpu="100m" \
  --set resources.requests.memory="512Mi" \
  --set resources.limits.cpu="1" \
  --set resources.limits.memory="2Gi" \
  --set persistence.enabled=false \
  --set readinessProbe.initialDelaySeconds=60 \
  --set readinessProbe.timeoutSeconds=300 \
  --wait

