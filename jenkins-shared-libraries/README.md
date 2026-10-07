# jenkins-shared-libraries

Reusable Groovy Shared Library for Jenkins pipelines on Kubernetes.

| Step | Purpose |
|------|---------|
| `standardPipeline` | Checkout, unit tests, Kaniko build, deploy, smoke test in one call |
| `pythonTest` | pytest in a throwaway python container, publishes JUnit results |
| `kanikoBuild` | Daemonless image build and push |
| `k8sSetImage` | `kubectl set image` plus rollout wait |
| `smokeTest` | curl from a short-lived pod against the Service |

Layout: `vars/` for steps, `resources/pods/ci-pod.yaml` for the agent pod.

```groovy
@Library('jenkins-shared-libraries') _
standardPipeline()
```
