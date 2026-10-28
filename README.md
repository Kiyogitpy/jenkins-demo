# jenkins-demo

A small Python HTTP app with a Jenkins pipeline that tests the app, builds a Docker image and deploys it as a local container.

## Requirements

- Docker Desktop

## Run Jenkins

```sh
docker compose up -d --build
docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

1. Open http://localhost:8080 and paste the password.
2. Choose "Install suggested plugins" and create an admin user.
3. Click **New Item**, pick **Pipeline** and name it `jenkins-demo`.
4. Under **Build Triggers**, tick **Poll SCM** and set the schedule to `H/2 * * * *`.
5. Under **Pipeline**, set **Definition** to *Pipeline script from SCM*, **SCM** to *Git*, **Repository URL** to `https://github.com/Kiyogitpy/jenkins-demo.git` and **Branch** to `*/main`.
6. Click **Build Now**.

The deployed app runs at http://localhost:5000.

Jenkins checks GitHub every 2 minutes and builds each new commit on `main`, so pushing is enough to start a build.

## Run tests locally

```sh
python -m unittest discover -s tests -t . -v
```
