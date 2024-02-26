# Get variables
NAMESPACE="sonarqube-system-1"
INSTANCE_NAME="sonarqube"
REPOSITORY_URL="https://SonarSource.github.io/helm-chart-sonarqube"

# Add SonarQube Helm repo
helm repo add $INSTANCE_NAME $REPOSITORY_URL

# Update Helm repos
helm repo update

# Create namespace
kubectl create namespace $NAMESPACE

# Install SonarQube
helm install $INSTANCE_NAME $INSTANCE_NAME/sonarqube \
  --namespace $NAMESPACE \
  --set sonarqube.service.type=NodePort \
  --set sonarqube.service.nodePort=30000 \
  --set sonarqube.persistence.enabled=true \
  --set sonarqube.persistence.storageClass=standard \
  --set sonarqube.env.SONARQUBE_JDBC_URL="jdbc:postgresql://sonarqube-postgresql:5432/sonarqube?currentSchema=public&useSSL=false" \
  --set sonarqube.env.SONARQUBE_JDBC_USERNAME="sonarqube" \
  --set sonarqube.env.SONARQUBE_JDBC_PASSWORD="sonarqube" \
  --set postgresql.enabled=true \
  --set postgresql.postgresqlUsername="sonarqube" \
  --set postgresql.postgresqlPassword="sonarqube" \
  --set postgresql.postgresqlDatabase="sonarqube" \
  --wait








#!/bin/bash

# Get variables
NAMESPACE="sonarqube-system-2"
INSTANCE_NAME="sonarqube"
REPOSITORY_URL="https://SonarSource.github.io/helm-chart-sonarqube"

# Add SonarQube Helm repo
helm repo add $INSTANCE_NAME $REPOSITORY_URL

# Update Helm repos
helm repo update

# Create namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create PersistentVolume for PostgreSQL
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: sonarqube-postgresql-pv
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data/sonarqube-postgresql
EOF

# Install SonarQube
helm install $INSTANCE_NAME $INSTANCE_NAME/sonarqube \
  --namespace $NAMESPACE \
  --set sonarqube.service.type=NodePort \
  --set sonarqube.service.nodePort=30000 \
  --set sonarqube.persistence.enabled=true \
  --set sonarqube.persistence.storageClass=standard \
  --set sonarqube.env.SONARQUBE_JDBC_URL="jdbc:postgresql://sonarqube-postgresql:5432/sonarqube?currentSchema=public&useSSL=false" \
  --set sonarqube.env.SONARQUBE_JDBC_USERNAME="sonarqube" \
  --set sonarqube.env.SONARQUBE_JDBC_PASSWORD="sonarqube" \
  --set postgresql.enabled=true \
  --set postgresql.postgresqlUsername="sonarqube" \
  --set postgresql.postgresqlPassword="sonarqube" \
  --set postgresql.postgresqlDatabase="sonarqube" \
  --wait
