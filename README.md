# jenkins-demo

A small Python HTTP app with a Jenkins setup that covers the parts of Jenkins most teams use: configuration as code, SSH and Docker agents, credentials, multibranch pipelines, webhooks, approval gates, a shared library and backups. Everything runs locally in Docker.

## What is where

| Topic | Where | What it shows |
| --- | --- | --- |
| Configuration as code | [jenkins/casc.yaml](jenkins/casc.yaml) | Users, permissions, the agent, credentials, the shared library and the job are all defined in YAML. No setup wizard. Changes in the UI are lost on restart. |
| Plugin management | [jenkins/plugins.txt](jenkins/plugins.txt), [jenkins/Dockerfile](jenkins/Dockerfile) | Plugins are baked into the image and pinned to versions that match the pinned Jenkins core. |
| Agents | [agent/Dockerfile](agent/Dockerfile), `nodes` in casc.yaml | The controller has 0 executors and only schedules. Builds run on `agent-1`, an SSH agent. The Test stage runs inside a `python:3.13-slim` container on that agent. |
| Credentials | `credentials` in casc.yaml, Push stage in [Jenkinsfile](Jenkinsfile) | Secrets come from `.env`, live in the Jenkins credential store and reach the build only through `withCredentials`. Jenkins masks them in logs. |
| Users and permissions | `securityRealm` and `authorizationStrategy` in casc.yaml | `admin` can do everything. `viewer` can only read. Anonymous users see nothing. |
| Multibranch pipelines | `jobs` in casc.yaml | Every branch and pull request gets its own build. Only `main` pushes and deploys (`when { branch 'main' }`). |
| Webhooks | `ngrok` in [docker-compose.yml](docker-compose.yml), [scripts/github-webhook.sh](scripts/github-webhook.sh) | GitHub calls Jenkins through an ngrok tunnel on every push or PR, and the payload is checked against a shared secret. Build results show up as commit statuses on GitHub. |
| Test results and artifacts | Test and Build stages | `junit` publishes pytest results with trends. `archiveArtifacts` keeps the report and image info. |
| `post` blocks | Test stage, Push stage, end of Jenkinsfile | `always` publishes results and logs out of Docker Hub, `success` and `failure` report the outcome. |
| Parameters and approval | `parameters` and the production stage | Ticking `DEPLOY_PRODUCTION` adds an approval step before deploying to port 5000. The wait holds no executor. |
| Shared library | [shared-library/vars/deployContainer.groovy](shared-library/vars/deployContainer.groovy) | A reusable deploy step with a health check, loaded with `@Library('demo-lib')`. |
| Backups | [scripts/backup.sh](scripts/backup.sh) | Backs up and restores the `jenkins_home` volume, leaving out what Jenkins rebuilds. |

## Pipeline

Every branch and PR runs **Test** and **Build image**. `main` also runs:

1. **Push to Docker Hub**: `<user>/jenkins-demo:<build>` and `:latest`.
2. **Deploy to staging**: http://localhost:5001.
3. **Deploy to production**: http://localhost:5000, only when you start the build with `DEPLOY_PRODUCTION` ticked and then approve it.

## Setup

You need Docker Desktop and Git Bash.

1. Run `scripts/setup.sh`. It creates `.env` with generated passwords and an SSH key for the agent in `secrets/`. Both are git-ignored.
2. Fill in the rest of `.env`:
   - **Docker Hub:** an access token with Read & Write scope, from Account settings → Personal access tokens.
   - **GitHub:** a fine-grained token for this repo with *Commit statuses: read and write* and *Contents, Metadata, Pull requests: read*.
   - **ngrok:** your authtoken and your free static domain, from the ngrok dashboard.
3. Start everything:
   ```sh
   docker compose --profile webhook up -d --build
   ```
4. Register the webhook (needs `gh` signed in as the repo owner):
   ```sh
   scripts/github-webhook.sh
   ```
5. Open http://localhost:8080 and sign in as `admin` with `JENKINS_ADMIN_PASSWORD` from `.env`.

Without the `webhook` profile, Jenkins still scans GitHub once a day. Click **Scan Repository Now** on the job to build sooner.

To change Jenkins settings, edit `jenkins/casc.yaml` and run `docker compose up -d jenkins` again.

## Windows agent and the Wardogs patch watch

`casc.yaml` also defines `wardogs-pc`, an inbound agent on the Windows host, and the job `wardogs-patch-watch`. That job
runs [`jenkins/patch-watch.Jenkinsfile`](https://github.com/Kiyogitpy/wardogs-data-docs/blob/main/jenkins/patch-watch.Jenkinsfile)
from wardogs-data-docs: it needs the game install and the local tools, which only this PC has, so it cannot run on the
Docker agent. Start the agent with:

```powershell
pwsh scripts/windows-agent.ps1
```

It downloads `agent.jar`, stores the agent secret in `C:\jenkins-agent\secret` and stays connected until stopped. The
secret is fixed for this node, so after that first run Task Scheduler can start `javaw` (Java without a console window)
directly at every logon. Register it once:

```powershell
$javaw = Join-Path (Split-Path (Get-Command java).Source) 'javaw.exe'
$a = New-ScheduledTaskAction -Execute $javaw -WorkingDirectory C:\jenkins-agent -Argument '-jar C:\jenkins-agent\agent.jar -url http://localhost:8080/ -name wardogs-pc -secret @C:\jenkins-agent\secret -webSocket -workDir C:\jenkins-agent'
Register-ScheduledTask jenkins-wardogs-agent -Action $a -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME)
```

Run the script again only after `jenkins_home` is reset, because that changes the secret.

## Backups

```sh
scripts/backup.sh                                  # writes backups/jenkins_home-<time>.tgz
scripts/backup.sh restore backups/<file>.tgz       # stops Jenkins, replaces jenkins_home, starts it
```

## Run tests locally

```sh
pip install -r requirements-dev.txt
pytest
```
