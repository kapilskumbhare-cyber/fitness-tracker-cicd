#!/usr/bin/env bash
# Builds the whole environment from zero: registry, Kind cluster, MySQL, app, Jenkins.
set -euo pipefail
cd "$(dirname "$0")/.."

CLUSTER=fitness-tracker
REG=kind-registry
REG_PORT=5050

for b in docker kind kubectl openssl; do
  command -v "$b" >/dev/null || { echo "Missing tool: $b"; exit 1; }
done

EXISTING=$(kind get clusters 2>/dev/null || true)
if printf '%s\n' "$EXISTING" | grep -qx "$CLUSTER"; then
  echo "Cluster '$CLUSTER' already exists. Remove it first: kind delete cluster --name $CLUSTER"
  exit 1
fi

echo "==> Registry container"
CONTAINERS=$(docker ps -a --format '{{.Names}}')
if printf '%s\n' "$CONTAINERS" | grep -qx "$REG"; then
  docker start "$REG" >/dev/null
else
  docker run -d --restart=always -p "127.0.0.1:${REG_PORT}:5000" --name "$REG" registry:2 >/dev/null
fi

echo "==> Kind cluster"
kind create cluster --config kind-config.yaml
docker network connect kind "$REG" 2>/dev/null || true

echo "==> Registry config on every node (plain HTTP)"
for node in $(kind get nodes --name "$CLUSTER"); do
  docker exec "$node" mkdir -p "/etc/containerd/certs.d/${REG}:5000"
  cat <<TOML | docker exec -i "$node" tee "/etc/containerd/certs.d/${REG}:5000/hosts.toml" >/dev/null
server = "http://${REG}:5000"

[host."http://${REG}:5000"]
  capabilities = ["pull", "resolve"]
TOML
done

echo "==> Namespaces, RBAC"
kubectl apply -f k8s/00-namespace.yaml -f jenkins/00-jenkins-namespace.yaml
kubectl apply -f jenkins/01-jenkins-rbac.yaml

echo "==> Secrets (created once, never stored in Git)"
kubectl -n fitness-tracker get secret mysql-secret >/dev/null 2>&1 || \
  kubectl -n fitness-tracker create secret generic mysql-secret \
    --from-literal=root-password="$(openssl rand -hex 12)"
kubectl -n jenkins get secret registry-credentials >/dev/null 2>&1 || \
  kubectl -n jenkins create secret generic registry-credentials --from-literal=config.json='{}'

echo "==> MySQL"
kubectl apply -f k8s/02-mysql-statefulset.yaml
kubectl -n fitness-tracker rollout status statefulset/mysql --timeout=300s
ROOTPW=$(kubectl -n fitness-tracker get secret mysql-secret -o jsonpath='{.data.root-password}' | base64 -d)
until kubectl -n fitness-tracker exec mysql-0 -- mysqladmin ping -uroot -p"$ROOTPW" --silent 2>/dev/null; do sleep 3; done
kubectl -n fitness-tracker exec -i mysql-0 -- mysql -uroot -p"$ROOTPW" < app/schema.sql

echo "==> First image (so the app starts before Jenkins exists)"
docker build -t "localhost:${REG_PORT}/fitness-tracker:latest" app/
docker push "localhost:${REG_PORT}/fitness-tracker:latest"

echo "==> App"
kubectl apply -f k8s/03-app-deployment.yaml
kubectl -n fitness-tracker rollout status deployment/fitness-app --timeout=300s

echo "==> Jenkins"
kubectl apply -f jenkins/02-jenkins-deployment.yaml
kubectl -n jenkins rollout status statefulset/jenkins --timeout=600s
until kubectl -n jenkins exec jenkins-0 -- test -f /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null; do sleep 3; done

echo
echo "App:      http://localhost:30080   (also /history, /metrics)"
echo "Jenkins:  run  kubectl -n jenkins port-forward svc/jenkins 8080:8080  then open http://localhost:8080"
echo "Unlock password: $(kubectl -n jenkins exec jenkins-0 -- cat /var/jenkins_home/secrets/initialAdminPassword)"
echo "Next: follow docs/JENKINS_SETUP.md"
