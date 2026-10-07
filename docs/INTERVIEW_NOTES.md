# How to explain this project

**One line:** A git push fires a GitHub webhook through a Cloudflare Tunnel to Jenkins on my Kind cluster. Jenkins starts an agent pod, Kaniko builds and pushes the image to a local registry, kubectl rolls the Deployment to the new tag, and a smoke-test pod curls the Service.

## Why each piece
- **Jenkins as a StatefulSet:** stable identity and a persistent volume (4Gi) so jobs and config survive pod restarts.
- **Agent pods:** each build gets a clean pod with Kaniko and kubectl containers, then it is deleted.
- **Kaniko:** builds images without a Docker daemon or privileged containers. A mounted Secret (`registry-credentials`) provides registry config.
- **Local registry on the kind network:** Kaniko pushes to `kind-registry:5000`; nodes pull from the same name.
- **`kubectl set image` + `rollout status`:** rolling update; a bad image fails the stage and the old ReplicaSet keeps serving.
- **Cloudflare Tunnel:** GitHub cannot reach localhost, so the tunnel exposes Jenkins' webhook endpoint.
- **Tags:** `build-<number>` plus `latest`, so every deploy is traceable to a build.
- **RBAC:** a dedicated service account (`jenkins-sa`) with namespace-scoped permissions.

## Say these first, before they ask
- Local lab, single machine, not highly available.
- Registry is HTTP without TLS.
- DB credentials are in manifests rather than referenced from Secrets.
- Tunnel URL changes if the quick tunnel restarts.

## Likely questions
- Rollback: `kubectl rollout undo deployment/fitness-app -n fitness-tracker`.
- Why not Docker-in-Docker: needs privileged containers; Kaniko does not.
- What would you add next: Helm or Argo CD, TLS registry, Prometheus and Grafana, secrets from a vault.
- What went wrong during the project: the smoke test pod was forbidden from attaching (missing `pods/attach` permission), found in the build log and fixed with a Role.
