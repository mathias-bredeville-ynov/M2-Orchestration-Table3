#!/bin/sh

set -eu

if [ -z "${VAULT_ROLE_ID:-}" ]; then
    echo "ERROR: VAULT_ROLE_ID is missing"
    exit 1
fi

if [ -z "${VAULT_SECRET_ID:-}" ]; then
    echo "ERROR: VAULT_SECRET_ID is missing"
    exit 1
fi

mkdir -p /vault/auth /vault/secrets

printf '%s' "$VAULT_ROLE_ID" > /vault/auth/role_id
printf '%s' "$VAULT_SECRET_ID" > /vault/auth/secret_id

chmod 600 /vault/auth/role_id
chmod 600 /vault/auth/secret_id

exec vault agent \
    -config=/vault/config/agent.hcl
