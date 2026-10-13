#!/bin/sh
set -e
cd "$(dirname "$0")/.."

mkdir -p secrets
chmod 700 secrets

for s in db_root_password db_password redis_password admin_password; do
  [ -s "secrets/$s" ] || openssl rand -hex 16 > "secrets/$s"
done

# lus par des users non-root dans les conteneurs
chmod 644 secrets/*
