// Runs curl from a short-lived pod against the in-cluster Service. Non-2xx fails the build.
// Usage: smokeTest(namespace: 'fitness-tracker', service: 'fitness-app', port: 5000)
def call(Map cfg) {
    stage('Smoke Test') {
        container('kubectl') {
            sh """
                sleep 5
                kubectl run smoke-test-${env.BUILD_NUMBER} --rm -i --restart=Never \\
                  --image=curlimages/curl -n ${cfg.namespace} -- \\
                  curl -sf http://${cfg.service}:${cfg.port}/
            """
        }
    }
}
