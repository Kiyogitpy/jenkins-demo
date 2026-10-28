# Connects this Windows PC to Jenkins as the agent wardogs-pc. Runs until stopped.
# Usage: pwsh scripts/windows-agent.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$work = 'C:\jenkins-agent'
$url = 'http://localhost:8080'

$pw = ((Get-Content "$root\.env") -match '^JENKINS_ADMIN_PASSWORD=' -replace '^[^=]+=', '')
$auth = @{ Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$pw")) }

New-Item -ItemType Directory -Force $work | Out-Null
Invoke-WebRequest "$url/jnlpJars/agent.jar" -OutFile "$work\agent.jar" -UseBasicParsing
# The secret goes to a file so it never appears on the command line or in process listings.
$res = Invoke-WebRequest "$url/computer/wardogs-pc/jenkins-agent.jnlp" -Headers $auth -UseBasicParsing
$jnlp = [xml][Text.Encoding]::UTF8.GetString($res.RawContentStream.ToArray())  # served as a binary type
Set-Content "$work\secret" $jnlp.jnlp.'application-desc'.argument[0] -NoNewline

java -jar "$work\agent.jar" -url "$url/" -name wardogs-pc -secret "@$work\secret" -webSocket -workDir $work
