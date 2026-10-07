# Resume entry

Use the PHASE 1 text now. Switch to PHASE 2 only after the shared-library build has succeeded in Jenkins.

## PHASE 1 (true today, original pipeline)

**Fitness Tracker - CI/CD & Containerized Deployment**
Jenkins | Kubernetes (Kind) | Kaniko | Docker Registry | GitHub Webhooks | Cloudflare Tunnel | Flask | MySQL
github.com/kapilskumbhare-cyber/fitness-tracker-cicd

- Built an end-to-end CI/CD pipeline using Jenkins and Kubernetes that builds, deploys and smoke-tests a Flask + MySQL application on every Git push.
- Ran Jenkins as a StatefulSet with ephemeral Kubernetes agent pods, and used Kaniko for daemonless image builds pushed to a local Docker registry.
- Integrated GitHub Webhooks with a Cloudflare Tunnel to trigger builds automatically on every commit, removing manual releases.
- Managed Kubernetes Deployments, Services, StatefulSets and RBAC to orchestrate the application and its MySQL database, with rolling updates verified by rollout status and an in-cluster smoke test.

## PHASE 2 (after the shared-library build succeeds)

Replace the last bullet with these two:

- Managed Kubernetes Deployments, Services, StatefulSets and RBAC to orchestrate the application and its MySQL database, with rolling updates verified by rollout status.
- Wrote reusable Groovy Shared Libraries (unit tests, Kaniko build, deploy, smoke test) so a full pipeline is a single call in the Jenkinsfile.
