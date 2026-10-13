# M2 Orchestration — Table 3

Stack Nextcloud avec Docker Compose : Caddy (HTTPS) → Nextcloud → MariaDB + Redis.

## Lancer

```bash
cp .env.example .env
./scripts/init-secrets.sh
docker compose up -d --build
```

Puis https://localhost:8443 (certificat auto-signé).
Login : `admin`, mot de passe dans `secrets/admin_password`.

## Sécurité

- Image du proxy construite par nous, lancée avec `USER caddy` (non-root)
- Mots de passe en Docker secrets, générés localement, jamais dans Git ni dans les images
- `db` et `redis` sur un réseau `internal`, aucun port exposé
- Ports publiés uniquement sur `127.0.0.1`
- `no-new-privileges` partout, `cap_drop: ALL` et `read_only` sur proxy et redis
- Versions d'images fixées dans `.env`

## CI

GitHub Actions à chaque push : build de l'image proxy, scan Trivy (échoue sur CRITICAL/HIGH corrigeable), push sur GHCR avec le tag `sha-<commit>`, puis test `docker compose up --build` complet.

Tag par SHA plutôt que `latest` : on sait exactement quel commit tourne.

## Scan Trivy

<!-- à compléter avec le résultat du run CI -->
