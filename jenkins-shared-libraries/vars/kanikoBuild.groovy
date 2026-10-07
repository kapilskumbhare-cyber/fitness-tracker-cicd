// Daemonless build and push to the local registry.
// Usage: kanikoBuild(dir: 'app', image: 'kind-registry:5000/fitness-tracker', tag: 'build-8')
def call(Map cfg) {
    stage('Build & Push with Kaniko') {
        container('kaniko') {
            sh """
                /kaniko/executor \\
                  --context=${env.WORKSPACE}/${cfg.dir} \\
                  --dockerfile=${env.WORKSPACE}/${cfg.dir}/Dockerfile \\
                  --destination=${cfg.image}:${cfg.tag} \\
                  --destination=${cfg.image}:latest \\
                  --insecure \\
                  --skip-tls-verify
            """
        }
    }
}
