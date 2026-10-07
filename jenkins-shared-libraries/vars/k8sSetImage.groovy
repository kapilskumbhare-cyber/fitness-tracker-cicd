// Rolls a Deployment to a new image and waits for the rollout.
// Usage: k8sSetImage(namespace: 'fitness-tracker', deployment: 'fitness-app',
//                    container: 'fitness-app', image: 'kind-registry:5000/fitness-tracker:build-8')
def call(Map cfg) {
    stage('Deploy to Kubernetes') {
        container('kubectl') {
            sh """
                kubectl set image deployment/${cfg.deployment} \\
                  ${cfg.container}=${cfg.image} -n ${cfg.namespace}
                kubectl rollout status deployment/${cfg.deployment} -n ${cfg.namespace} --timeout=240s
            """
        }
    }
}
