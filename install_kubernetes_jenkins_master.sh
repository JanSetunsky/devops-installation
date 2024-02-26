# Prepare environment
KUBERNETES_MANIFESTS_PATH="/etc/kubernetes/manifests"
REPOSITORY_URL="https://charts.jenkins.io"
TOOL_NAME="jenkins"
NAMESPACE_NAME="$TOOL_NAME-system"
INSTANCE_NAME="$TOOL_NAME-master"

# StorageClass
STORAGECLASS_NAME="$TOOL_NAME-local-storage"
STORAGECLASS_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$STORAGECLASS_NAME.yaml"

# Persistent volumes
VOLUME_PATH="/srv/volumes/$TOOL_NAME"
VOLUME_CAPACITY="10Gi"
VOLUME_NAME="$TOOL_NAME-pv"
VOLUME_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$VOLUME_NAME.yaml"

# Persistent volumes claim
VOLUME_CLAIM_CAPACITY="10Gi"
VOLUME_CLAIM_NAME="$TOOL_NAME-pvc"
VOLUME_CLAIM_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$VOLUME_CLAIM_NAME.yaml"


# Create volume directory
sudo mkdir -p $VOLUME_PATH

# Create namespace
kubectl create namespace $NAMESPACE_NAME

# Create default configuration for StorageClass
cat <<EOF | sudo tee $STORAGECLASS_CONFIG_PATH
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $STORAGECLASS_NAME
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

# Create PersistentVolume
cat <<EOF | sudo tee $VOLUME_CONFIG_PATH
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $VOLUME_NAME
  labels:
    app.kubernetes.io/instance: $INSTANCE_NAME
spec:
  capacity:
    storage: $VOLUME_CAPACITY
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: $STORAGECLASS_NAME
  local:
    path: $VOLUME_PATH
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - $HOSTNAME
EOF

# Create PersistentVolumeClaim
cat <<EOF | sudo tee $VOLUME_CLAIM_CONFIG_PATH
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $VOLUME_CLAIM_NAME
  namespace: $NAMESPACE_NAME
spec:
  storageClassName: $STORAGECLASS_NAME
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: $VOLUME_CLAIM_CAPACITY
EOF

# Deploy storageclass and persisten volume and persistent volume claim configuration
kubectl apply -f $STORAGECLASS_CONFIG_PATH
kubectl apply -f $VOLUME_CONFIG_PATH
kubectl apply -f $VOLUME_CLAIM_CONFIG_PATH

# Untaint node
kubectl taint nodes ubuntu-test node-role.kubernetes.io/control-plane:NoSchedule-

# Adding the Jenkins chart repository
CHART_UID="$(uuidgen | cut -c 1-8)"
CHART_NAME="$INSTANCE_NAME-$CHART_UID"
helm repo add $CHART_NAME $REPOSITORY_URL
helm repo update

# Install instance with PersistentVolumeClaim
helm upgrade --install $CHART_NAME $CHART_NAME/$TOOL_NAME \
  -n $NAMESPACE_NAME \
  --set persistence.enabled=true \
  --set persistence.existingClaim=$VOLUME_CLAIM_NAME \
  --set persistence.storageClass="$STORAGECLASS_NAME" \
  --set tolerations[0].key=node-role.kubernetes.io/control-plane \
  --set tolerations[0].operator=Exists \
  --set tolerations[0].effect=NoSchedule \
  --set controller.serviceType=ClusterIP \
  --wait

# Create pod name
POD_NAME="$CHART_NAME-0"
sleep 3

# jenkins agent passwords for prod and dev
MASTER_PASSWORD=$(kubectl exec --namespace $NAMESPACE_NAME -it $POD_NAME -c $TOOL_NAME -- /bin/cat /run/secrets/additional/chart-admin-password && echo)
echo "MASTER_PASSWORD: $MASTER_PASSWORD"

sleep 3

# Time limited port forwarding for pod
(timeout 20s kubectl port-forward --namespace $NAMESPACE_NAME $POD_NAME 8080:8080 > /dev/null 2>&1 &) || true

# Install pluginu
kubectl exec --namespace $NAMESPACE_NAME -it $POD_NAME -c $TOOL_NAME -- /bin/bash -c 'jenkins-plugin-cli --plugins gitlab-plugin:1.8.0'

# Get crumb
CRUMB=$(curl --verbose --location --insecure -u "admin:$MASTER_PASSWORD" -s 'http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
echo "$CRUMB"

# Restart connection
# code .....

# Test connection
# code .....