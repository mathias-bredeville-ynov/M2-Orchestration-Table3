#!/bin/sh
set -e
cd "$(dirname "$0")"

mkdir -p secrets
chmod 700 secrets

for s in db_root_password db_password admin_password; do
  [ -s "secrets/$s" ] || tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 > "secrets/$s"
done

# lus par des users non-root dans les conteneurs
chmod 644 secrets/*

echo "Mot de passe admin : $(cat secrets/admin_password)"