# Jenkins setup (manual, one time)

1. `kubectl -n jenkins port-forward svc/jenkins 8080:8080` and open http://localhost:8080
2. Unlock with the password printed by `scripts/00-bootstrap.sh`, install suggested plugins, create the admin user.
3. Manage Jenkins -> Plugins -> Available: install **Kubernetes** (and **GitHub** if missing). Restart Jenkins.
4. Manage Jenkins -> Clouds -> New cloud -> Kubernetes:
   - Kubernetes URL: leave empty (in-cluster)
   - Namespace: `jenkins`
   - Jenkins URL: `http://jenkins.jenkins.svc.cluster.local:8080`
   - Jenkins tunnel: `jenkins.jenkins.svc.cluster.local:50000`
5. New Item -> Pipeline named `fitness-tracker-pipeline`:
   - Build Triggers: GitHub hook trigger for GITScm polling
   - Pipeline script from SCM -> Git -> your repo URL, branch `*/main`, Script Path `Jenkinsfile`
6. Build Now once and check all four stages pass.

## Webhook
1. Terminal A: `kubectl -n jenkins port-forward svc/jenkins 8080:8080`
2. Terminal B: `./scripts/01-tunnel.sh`, copy the https URL
3. GitHub repo -> Settings -> Webhooks -> Add: `<url>/github-webhook/`, content type `application/json`, push events
