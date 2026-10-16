#!/bin/sh
# Lancé par la CI en SSH sur la VM.
# Récupère le code, lit les secrets dans Vault (token local), puis déploie.
set -eu
cd "$(dirname "$0")"

git pull --ff-only

TOKEN=$(cat "$HOME/.vault-token")
vault_get() {
  docker exec -e VAULT_TOKEN="$TOKEN" vault-vault-1 vault kv get -field="$1" secret/nextcloud
}

export DB_ROOT_PASSWORD="$(vault_get db_root_password)"
export DB_PASSWORD="$(vault_get db_password)"
export ADMIN_PASSWORD="$(vault_get admin_password)"
export NEXTCLOUD_DOMAIN="$(vault_get domain)"
export BIND_IP="$(vault_get bind_ip)"

# --wait : attend que les services soient démarrés et "healthy", échoue sinon
docker compose up -d --build --wait --wait-timeout 300
