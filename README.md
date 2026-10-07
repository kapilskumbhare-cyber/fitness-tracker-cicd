# Fitness Tracker - CI/CD & Containerized Deployment

A Git push triggers a Jenkins pipeline on a local Kubernetes (Kind) cluster that builds the Flask + MySQL app with Kaniko, pushes it to a local registry, deploys it with kubectl, and smoke-tests it.

## Flow

```
+--------------------------+
|  git push to GitHub      |
+------------+-------------+
             |
             v
+--------------------------+
|  GitHub webhook          |
+------------+-------------+
             |
             v
+--------------------------+
|  Cloudflare Tunnel       |
+------------+-------------+
             |
             v
+--------------------------+
|  Jenkins StatefulSet     |
|  (namespace: jenkins)    |
+------------+-------------+
             |  spawns
             v
+--------------------------+
|  Agent pod               |
|  kaniko | kubectl        |
+------------+-------------+
             |
             v
+--------------------------+
|  Kaniko build and push   |
|  kind-registry:5000      |
+------------+-------------+
             |
             v
+--------------------------+
|  kubectl set image       |
|  rollout status          |
+------------+-------------+
             |
             v
+--------------------------+
|  Smoke test pod (curl)   |
+--------------------------+
```

## Build everything from zero

```bash
./scripts/00-bootstrap.sh     # registry, Kind cluster, MySQL, app, Jenkins
# then follow docs/JENKINS_SETUP.md
./scripts/02-verify.sh
```

App: http://localhost:30080 (`/`, `/history`, `/metrics`; `POST /log` with JSON weight, water_liters, calories, notes).

## Layout

```
Jenkinsfile                 Pipeline (Checkout, Kaniko build, Deploy, Smoke Test)
Jenkinsfile.shared-library  Phase 2 version using the shared library
app/                        Flask app, Dockerfile, schema.sql, tests/
k8s/                        namespace, MySQL StatefulSet, app Deployment + Service
jenkins/                    namespace, RBAC, Jenkins StatefulSet + Service
kind-config.yaml            3-node Kind cluster "fitness-tracker"
jenkins-shared-libraries/   Groovy shared library (push as its own repo)
scripts/                    bootstrap, tunnel, verify
docs/                       Jenkins setup, resume entry, interview notes
```

## Phase 2: shared library and unit tests

1. Create GitHub repo `jenkins-shared-libraries`; push the contents of `jenkins-shared-libraries/` (`vars/` and `resources/` at repo root, branch `main`).
2. Jenkins -> Manage Jenkins -> System -> Global Trusted Pipeline Libraries: name `jenkins-shared-libraries`, default version `main`, Modern SCM -> Git, that repo's URL.
3. `git mv Jenkinsfile Jenkinsfile.original && git mv Jenkinsfile.shared-library Jenkinsfile`, commit, push.
4. The build must show: Checkout, Unit Tests, Build & Push with Kaniko, Deploy to Kubernetes, Smoke Test. If it fails: `git mv Jenkinsfile.original Jenkinsfile`.

## Troubleshooting

| Symptom | Check |
|---|---|
| App pods `ImagePullBackOff` | `docker exec fitness-tracker-control-plane cat "/etc/containerd/certs.d/kind-registry:5000/hosts.toml"`; `curl localhost:5050/v2/_catalog` must list `fitness-tracker` |
| Kaniko cannot push | `docker network inspect kind` must contain `kind-registry`; keep `--insecure` flags |
| Agent pod never starts | Jenkins cloud URL and tunnel values (docs/JENKINS_SETUP.md); `kubectl -n jenkins get pods` |
| Smoke test `forbidden` | `kubectl -n fitness-tracker get role jenkins-deployer -o yaml` must include `pods/attach` |
| Webhook does not fire | tunnel and port-forward must both be running; GitHub -> Webhooks -> Recent Deliveries |

## Known limitations

- Local lab on one machine; not highly available.
- Registry is plain HTTP; Kaniko runs with `--insecure`.
- Jenkins itself is configured through the UI (see docs/JENKINS_SETUP.md), not as code.
- If the Cloudflare quick-tunnel URL changes, update the GitHub webhook.
- The bootstrap script was written after the original files were lost; it has not been run end to end yet.
