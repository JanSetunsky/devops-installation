# Get variables
NAMESPACE="monitoring-system"
INSTANCE_NAME="prometheus"
STORAGE_CLASS="prometheus-local-storage"
PVC_NAME="$INSTANCE_NAME-pvc"
PV_NAME="$INSTANCE_NAME-pv"
REPOSITORY_URL="https://prometheus-community.github.io/helm-charts"

# Create namespace
kubectl create namespace $NAMESPACE

# Untaint node
kubectl taint nodes ubuntu-test node-role.kubernetes.io/control-plane:NoSchedule-

# Create and deploy StorageClassu
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $TOOL_NAME-local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

# Create PersistentVolumeClaim for Prometheus
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PVC_NAME
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: $STORAGE_CLASS
EOF


# Install Prometheus
helm repo add prometheus-community $REPOSITORY_URL
helm repo update
helm upgrade --install $INSTANCE_NAME prometheus-community/prometheus \
  --namespace $NAMESPACE \
  --set alertmanager.enabled=false \
  --set prometheus-pushgateway.enabled=false \
  --set prometheus-node-exporter.enabled=false \
  --set server.persistentVolume.enabled=false \
  --set server.persistentVolume.size=10Gi \
  --set server.persistentVolume.storageClass=$STORAGE_CLASS \
  --set server.persistentVolume.existingClaim=$PVC_NAME \
  --set server.retention=1d \
  --set server.resources.requests.memory=400Mi \
  --set server.resources.requests.cpu=200m \
  --set server.resources.limits.memory=2Gi \
  --set server.resources.limits.cpu=2 \
  --wait