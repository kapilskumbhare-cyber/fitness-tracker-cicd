#!/usr/bin/env bash
FAILED=0
ok(){ echo "[ OK ] $1"; }; bad(){ echo "[FAIL] $1"; FAILED=1; }
kubectl get nodes --no-headers | grep -vq NotReady && ok "nodes Ready" || bad "node NotReady"
kubectl -n jenkins get pod jenkins-0 -o jsonpath='{.status.phase}' | grep -q Running && ok "jenkins-0 running" || bad "jenkins-0"
kubectl -n fitness-tracker get pod mysql-0 -o jsonpath='{.status.phase}' | grep -q Running && ok "mysql-0 running" || bad "mysql-0"
R=$(kubectl -n fitness-tracker get deploy fitness-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "${R:-0}" -ge 1 ] && ok "fitness-app ready replicas: $R" || bad "fitness-app not ready"
curl -fs http://localhost:30080/ >/dev/null && ok "app responds on :30080" || bad "app not reachable"
curl -fs http://localhost:5050/v2/_catalog && echo && ok "registry reachable" || bad "registry"
exit $FAILED
