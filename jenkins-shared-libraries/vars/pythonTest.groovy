// Unit tests in a throwaway python container.
// Usage: pythonTest(dir: 'app')
def call(Map cfg = [:]) {
    String appDir = cfg.dir ?: '.'
    String deps   = cfg.deps ?: 'flask pytest'
    stage('Unit Tests') {
        try {
            container('python') {
                dir(appDir) {
                    sh "pip install --no-cache-dir --retries 5 --timeout 60 ${deps}"
                    sh 'python -m pytest -q --junitxml=test-results.xml'
                }
            }
        } finally {
            junit allowEmptyResults: true, testResults: "${appDir}/test-results.xml"
        }
    }
}
