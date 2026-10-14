#!/bin/sh
# récupère les mdp nextcloud depuis vault et les écrit dans secrets/
set -e
cd "$(dirname "$0")"
: "${VAULT_TOKEN:?faire export VAULT_TOKEN=... avant}"

mkdir -p secrets
chmod 700 secrets

for s in db_root_password db_password admin_password; do
  docker compose -f vault/compose.yaml exec -T -e VAULT_TOKEN="$VAULT_TOKEN" vault \
    vault kv get -field="$s" secret/nextcloud > "secrets/$s"
done

chmod 644 secrets/*
echo "secrets récupérés depuis vault"