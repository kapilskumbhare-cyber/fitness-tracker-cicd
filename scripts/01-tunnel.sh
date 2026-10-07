#!/usr/bin/env bash
# Needs: kubectl -n jenkins port-forward svc/jenkins 8080:8080  running in another terminal.
# Prints a public https URL; GitHub webhook payload URL is  <that URL>/github-webhook/
exec cloudflared tunnel --url http://localhost:8080
