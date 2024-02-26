# Prepare environment
KUBERNETES_MANIFESTS_PATH="/etc/kubernetes/manifests"
REPOSITORY_URL="https://charts.jenkins.io"
TOOL_NAME="jenkins"
NAMESPACE_NAME="$TOOL_NAME-system"
INSTANCE_NAME="$TOOL_NAME-master"

# Prepare deployment
CONTAINER_AGENT_NAME="jnlp"
CONTAINER_AGENT_IMAGE="jenkins/jnlp-agent:latest"
PROD_REPLICAS="1"
DEV_REPLICAS="1"

# Prepare variables for prod
PROD_NAMESPACE="prod-$TOOL_NAME"
PROD_WORKER="$PROD_NAMESPACE-worker"
PROD_AGENT="$PROD_WORKER-agent"
PROD_ROLE="$PROD_AGENT-role"
PROD_ROLE_BINDING="$PROD_AGENT-rolebinding"
PROD_ROLE_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$PROD_ROLE.yaml"
PROD_ROLE_BINDING_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$PROD_ROLE_BINDING.yaml"
PROD_AGENT_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$PROD_AGENT.yaml"

# Prod StorageClass
PROD_STORAGECLASS_NAME="$PROD_AGENT-local-storage"
PROD_STORAGECLASS_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$PROD_STORAGECLASS_NAME.yaml"

# Prod Persistent volumes
PROD_VOLUME_PATH="/srv/volumes/$PROD_AGENT"
PROD_VOLUME_CAPACITY="10Gi"
PROD_VOLUME_NAME="$PROD_AGENT-pv"
PROD_VOLUME_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$PROD_VOLUME_NAME.yaml"

# Prod Persistent volumes claim
PROD_VOLUME_CLAIM_CAPACITY="10Gi"
PROD_VOLUME_CLAIM_NAME="$PROD_AGENT-pvc"
PROD_VOLUME_CLAIM_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$PROD_VOLUME_CLAIM_NAME.yaml"

# Prepare variables for dev
DEV_NAMESPACE="dev-$TOOL_NAME"
DEV_WORKER="$DEV_NAMESPACE-worker"
DEV_AGENT="$DEV_WORKER-agent"
DEV_ROLE="$DEV_AGENT-role"
DEV_ROLE_BINDING="$DEV_AGENT-rolebinding"
DEV_ROLE_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$DEV_ROLE.yaml"
DEV_ROLE_BINDING_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$DEV_ROLE_BINDING.yaml"
DEV_AGENT_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$DEV_AGENT.yaml"

# Dev StorageClass
DEV_STORAGECLASS_NAME="$DEV_AGENT-local-storage"
DEV_STORAGECLASS_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$DEV_STORAGECLASS_NAME.yaml"

# Dev Persistent volumes
DEV_VOLUME_PATH="/srv/volumes/$DEV_AGENT"
DEV_VOLUME_CAPACITY="10Gi"
DEV_VOLUME_NAME="$DEV_AGENT-pv"
DEV_VOLUME_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$DEV_VOLUME_NAME.yaml"

# Dev Persistent volumes claim
DEV_VOLUME_CLAIM_CAPACITY="10Gi"
DEV_VOLUME_CLAIM_NAME="$DEV_AGENT-pvc"
DEV_VOLUME_CLAIM_CONFIG_PATH="$KUBERNETES_MANIFESTS_PATH/$DEV_VOLUME_CLAIM_NAME.yaml"

# Create prod role and role binding config
cat <<EOF | sudo tee $PROD_ROLE_CONFIG_PATH
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: $PROD_ROLE
  namespace: $PROD_WORKER
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "create", "delete", "watch"]
  - apiGroups: ["batch"]
    resources: ["jobs"]
    verbs: ["get", "list", "create", "delete", "watch"]

EOF
cat <<EOF | sudo tee $PROD_ROLE_BINDING_CONFIG_PATH
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $PROD_ROLE_BINDING
  namespace: $PROD_WORKER
subjects:
  - kind: ServiceAccount
    name: $PROD_AGENT
    namespace: $PROD_WORKER
roleRef:
  kind: Role
  name: $PROD_ROLE
  apiGroup: rbac.authorization.k8s.io

EOF

# Create dev role and role binding config
cat <<EOF | sudo tee $DEV_ROLE_CONFIG_PATH
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: $DEV_ROLE
  namespace: $DEV_WORKER
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "create", "delete", "watch"]
  - apiGroups: ["batch"]
    resources: ["jobs"]
    verbs: ["get", "list", "create", "delete", "watch"]

EOF
cat <<EOF | sudo tee $DEV_ROLE_BINDING_CONFIG_PATH
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $DEV_ROLE_BINDING
  namespace: $DEV_WORKER
subjects:
  - kind: ServiceAccount
    name: $DEV_AGENT
    namespace: $DEV_WORKER
roleRef:
  kind: Role
  name: $DEV_ROLE
  apiGroup: rbac.authorization.k8s.io

EOF

# Create deployment for prod-agent and dev-agent
cat <<EOF | sudo tee $PROD_AGENT_CONFIG_PATH
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $PROD_AGENT
  namespace: $PROD_WORKER
spec:
  replicas: $PROD_REPLICAS
  selector:
    matchLabels:
      app: $PROD_AGENT
  template:
    metadata:
      labels:
        app: $PROD_AGENT
    spec:
      serviceAccountName: $PROD_AGENT
      containers:
      - name: $CONTAINER_AGENT_NAME
        image: $CONTAINER_AGENT_IMAGE
EOF
cat <<EOF | sudo tee $DEV_AGENT_CONFIG_PATH
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEV_AGENT
  namespace: $DEV_WORKER
spec:
  replicas: $DEV_REPLICAS
  selector:
    matchLabels:
      app: $DEV_AGENT
  template:
    metadata:
      labels:
        app: $DEV_AGENT
    spec:
      serviceAccountName: $DEV_AGENT
      containers:
      - name: $CONTAINER_AGENT_NAME
        image: $CONTAINER_AGENT_IMAGE
EOF

# Create prod default configuration for StorageClass
cat <<EOF | sudo tee $PROD_STORAGECLASS_CONFIG_PATH
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $PROD_STORAGECLASS_NAME
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

# Create prod PersistentVolume
cat <<EOF | sudo tee $PROD_VOLUME_CONFIG_PATH
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $PROD_VOLUME_NAME
  labels:
    app.kubernetes.io/instance: $PROD_INSTANCE_NAME
spec:
  capacity:
    storage: $PROD_VOLUME_CAPACITY
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: $PROD_STORAGECLASS_NAME
  local:
    path: $PROD_VOLUME_PATH
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - $HOSTNAME
EOF

# Create prod PersistentVolumeClaim
cat <<EOF | sudo tee $PROD_VOLUME_CLAIM_CONFIG_PATH
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PROD_VOLUME_CLAIM_NAME
  namespace: $PROD_WORKER
spec:
  storageClassName: $PROD_STORAGECLASS_NAME
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: $PROD_VOLUME_CLAIM_CAPACITY
EOF

# Create dev default configuration for StorageClass
cat <<EOF | sudo tee $DEV_STORAGECLASS_CONFIG_PATH
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $DEV_STORAGECLASS_NAME
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

# Create dev PersistentVolume
cat <<EOF | sudo tee $DEV_VOLUME_CONFIG_PATH
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $DEV_VOLUME_NAME
  labels:
    app.kubernetes.io/instance: $DEV_INSTANCE_NAME
spec:
  capacity:
    storage: $DEV_VOLUME_CAPACITY
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: $DEV_STORAGECLASS_NAME
  local:
    path: $DEV_VOLUME_PATH
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - $HOSTNAME
EOF

# Create dev PersistentVolumeClaim
cat <<EOF | sudo tee $DEV_VOLUME_CLAIM_CONFIG_PATH
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $DEV_VOLUME_CLAIM_NAME
  namespace: $DEV_WORKER
spec:
  storageClassName: $DEV_STORAGECLASS_NAME
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: $DEV_VOLUME_CLAIM_CAPACITY
EOF

# Create prod and dev volume directory
sudo mkdir -p $PROD_VOLUME_PATH
sudo mkdir -p $DEV_VOLUME_PATH

# Create namespace for prod-worker and dev-worker
kubectl create namespace $PROD_WORKER
kubectl create namespace $DEV_WORKER

# Create roles and roles binding for prod-agent and dev-agent
kubectl apply -f $PROD_ROLE_CONFIG_PATH
kubectl apply -f $PROD_ROLE_BINDING_CONFIG_PATH
kubectl apply -f $DEV_ROLE_CONFIG_PATH
kubectl apply -f $DEV_ROLE_BINDING_CONFIG_PATH

# Deploy prod storageclass and persisten volume and persistent volume claim configuration
kubectl apply -f $PROD_STORAGECLASS_CONFIG_PATH
kubectl apply -f $PROD_VOLUME_CONFIG_PATH
kubectl apply -f $PROD_VOLUME_CLAIM_CONFIG_PATH

# Deploy dev storageclass and persisten volume and persistent volume claim configuration
kubectl apply -f $DEV_STORAGECLASS_CONFIG_PATH
kubectl apply -f $DEV_VOLUME_CONFIG_PATH
kubectl apply -f $DEV_VOLUME_CLAIM_CONFIG_PATH

# Create service accounts for prod-agent and dev-agent
#kubectl create serviceaccount $PROD_AGENT -n $PROD_WORKER
#kubectl create serviceaccount $DEV_AGENT -n $DEV_WORKER

# Setup service accounts for prod
#kubectl label serviceaccount $PROD_AGENT app.kubernetes.io/managed-by=Helm \
#  --namespace=$PROD_WORKER
#kubectl annotate serviceaccount $PROD_AGENT meta.helm.sh/release-name=$PROD_AGENT \
#  --namespace=$PROD_WORKER
#kubectl annotate serviceaccount $PROD_AGENT meta.helm.sh/release-namespace=$PROD_WORKER \
#  --namespace=$PROD_WORKER

# Setup service accounts for dev
#kubectl label serviceaccount $DEV_AGENT app.kubernetes.io/managed-by=Helm \
#  --namespace=$DEV_WORKER
#kubectl annotate serviceaccount $DEV_AGENT meta.helm.sh/release-name=$DEV_AGENT \
#  --namespace=$DEV_WORKER
#kubectl annotate serviceaccount $DEV_AGENT meta.helm.sh/release-namespace=$DEV_WORKER \
#  --namespace=$DEV_WORKER

# Install Jenkins agent for prod and dev
#kubectl apply -f $PROD_AGENT_CONFIG_PATH
#kubectl apply -f $DEV_AGENT_CONFIG_PATH

# Adding the Jenkins chart repository
PROD_CHART_UID="$(uuidgen | cut -c 1-8)"
DEV_CHART_UID="$(uuidgen | cut -c 1-8)"
PROD_CHART_NAME="$PROD_AGENT-$PROD_CHART_UID"
DEV_CHART_NAME="$DEV_AGENT-$DEV_CHART_UID"
helm repo add $PROD_CHART_NAME $REPOSITORY_URL
helm repo add $DEV_CHART_NAME $REPOSITORY_URL
helm repo update

# Install jenkins agent for prod
helm upgrade --install $PROD_CHART_NAME $PROD_CHART_NAME/$TOOL_NAME \
  -n $PROD_WORKER \
  --set persistence.enabled=true \
  --set persistence.existingClaim=$PROD_VOLUME_CLAIM_NAME \
  --set persistence.storageClass="$PROD_STORAGECLASS_NAME" \
  --set tolerations[0].key=node-role.kubernetes.io/control-plane \
  --set tolerations[0].operator=Exists \
  --set tolerations[0].effect=NoSchedule \
  --set controller.serviceType=ClusterIP \
  --wait

# Instal jenkins agent for dev
helm upgrade --install $DEV_CHART_NAME $DEV_CHART_NAME/$TOOL_NAME \
  -n $DEV_WORKER \
  --set persistence.enabled=true \
  --set persistence.existingClaim=$DEV_VOLUME_CLAIM_NAME \
  --set persistence.storageClass="$DEV_STORAGECLASS_NAME" \
  --set tolerations[0].key=node-role.kubernetes.io/control-plane \
  --set tolerations[0].operator=Exists \
  --set tolerations[0].effect=NoSchedule \
  --set controller.serviceType=ClusterIP \
  --wait

# Create prod pod name
POD_NAME="$PROD_CHART_NAME-0"
sleep 3

# jenkins agent passwords for prod and dev
PROD_AGENT_PASSWORD=$(kubectl exec --namespace $PROD_WORKER -it $POD_NAME -c $TOOL_NAME -- /bin/cat /run/secrets/additional/chart-admin-password && echo)
echo "PROD_AGENT_PASSWORD: $PROD_AGENT_PASSWORD"

sleep 3

# Create secrets for prod and dev
kubectl create secret generic $POD_NAME-token --from-literal=token=$PROD_AGENT_PASSWORD -n $PROD_WORKER

# Time limited port forwarding for pod on prod
(timeout 20s kubectl port-forward --namespace $PROD_WORKER $POD_NAME 8080:8080 > /dev/null 2>&1 &) || true

# Install pluginu
kubectl exec --namespace $PROD_WORKER -it $POD_NAME -c $TOOL_NAME -- /bin/bash -c 'jenkins-plugin-cli --plugins gitlab-plugin:1.8.0'

# Get crumb
CRUMB=$(curl --verbose --location --insecure -u "admin:$PROD_AGENT_PASSWORD" -s 'http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
echo "$CRUMB"

# Restart connection
# code .....

# Test connection
# code .....

# Check finished installation dev
POD_NAME="$DEV_CHART_NAME-0"
sleep 3

# jenkins agent passwords for prod and dev
DEV_AGENT_PASSWORD=$(kubectl exec --namespace $DEV_WORKER -it $POD_NAME -c $TOOL_NAME -- /bin/cat /run/secrets/additional/chart-admin-password && echo)
echo "DEV_AGENT_PASSWORD: $DEV_AGENT_PASSWORD"

sleep 20

# Create secrets for prod and dev
kubectl create secret generic $POD_NAME-token --from-literal=token=$DEV_AGENT_PASSWORD -n $DEV_WORKER

# Time limited port forwarding for pod on prod
(timeout 20s kubectl port-forward --namespace $DEV_WORKER $POD_NAME 8080:8080 > /dev/null 2>&1 &) || true

# Install pluginu
kubectl exec --namespace $DEV_WORKER -it $POD_NAME -c $TOOL_NAME -- /bin/bash -c 'jenkins-plugin-cli --plugins gitlab-plugin:1.8.0'

# Get crumb
CRUMB=$(curl --verbose --location --insecure -u "admin:$DEV_AGENT_PASSWORD" -s 'http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
echo "$CRUMB"

# Restart connection
# code .....

# Test connection
# code .....