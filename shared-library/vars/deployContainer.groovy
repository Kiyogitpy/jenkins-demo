// Replaces the named container with one running the image, then waits until the app answers.
// Usage: deployContainer(name: 'jenkins-demo-staging', port: 5001, image: 'jenkins-demo:main-7')
def call(Map args) {
    sh """
        docker rm -f '${args.name}' || true
        docker run -d --name '${args.name}' -p ${args.port}:5000 '${args.image}'
        for i in 1 2 3 4 5 6 7 8 9 10; do
            docker exec '${args.name}' python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000')" && exit 0
            sleep 1
        done
        echo '${args.name} did not answer on port 5000'
        docker logs '${args.name}'
        exit 1
    """
}
