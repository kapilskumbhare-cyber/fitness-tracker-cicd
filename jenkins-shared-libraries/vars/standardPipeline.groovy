// Whole flow in one call: Checkout, Unit Tests, Build & Push, Deploy, Smoke Test.
// Defaults match the fitness tracker; override any key per project.
def call(Map cfg = [:]) {
    Map c = [
        appDir    : 'app',
        image     : 'kind-registry:5000/fitness-tracker',
        namespace : 'fitness-tracker',
        deployment: 'fitness-app',
        container : 'fitness-app',
        service   : 'fitness-app',
        port      : 5000,
        runTests  : true,
    ] + cfg

    podTemplate(yaml: libraryResource('pods/ci-pod.yaml')) {
        node(POD_LABEL) {
            String tag = "build-${env.BUILD_NUMBER}"

            stage('Checkout') {
                checkout scm
            }

            if (c.runTests) {
                pythonTest(dir: c.appDir)
            }

            kanikoBuild(dir: c.appDir, image: c.image, tag: tag)

            k8sSetImage(namespace: c.namespace, deployment: c.deployment,
                        container: c.container, image: "${c.image}:${tag}")

            smokeTest(namespace: c.namespace, service: c.service, port: c.port)
        }
    }
}
