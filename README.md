# M2 Orchestration - Table 3

Nextcloud avec docker compose. Caddy devant (https), nextcloud, mariadb.

En ligne : https://ynov-orchestration-table3.duckdns.org
Branche de travail : `Mathias-Nextcloud`

## Lancer en local

```bash
cp .env.example .env
sh init-secrets.sh
docker compose up -d
```

-> https://localhost (certif auto-signé)
login `admin`, mdp dans `secrets/admin_password`

Le premier démarrage prend ~1 min (install de nextcloud). Des 502 au début c'est normal, faut attendre.

## Ce qu'il y a dans le compose

- `proxy` : caddy, seul conteneur avec des ports ouverts (80/443)
- `app` : nextcloud 33
- `db` : mariadb 11.4, healthcheck -> app attend que la base soit prête avant de démarrer

Réseaux :
- `frontend` : proxy <-> app
- `backend` : app <-> db, en `internal: true` donc pas d'internet pour la base

Le bloc `x-security` en haut c'est une ancre yaml, ça évite de répéter `restart` et `no-new-privileges` dans chaque service. `docker compose config` pour voir le résultat déplié.

## .env

| variable | local | serveur |
|---|---|---|
| NEXTCLOUD_DOMAIN | localhost | ynov-orchestration-table3.duckdns.org |
| BIND_IP | 127.0.0.1 | 0.0.0.0 |

Pas de mot de passe dans le .env (sinon visible avec `docker inspect`).
Les mdp sont dans `secrets/`, montés en docker secrets (`*_FILE`). `.env` et `secrets/` sont dans le .gitignore.

## Pièges rencontrés

- **les volumes gardent la config** : changer `NEXTCLOUD_TRUSTED_DOMAINS` ou un mdp dans le compose ne sert à rien si nextcloud est déjà installé. En dev -> `docker compose down -v` pour repartir de zéro (efface les données !)
- variables `MYSQL_*` pour nextcloud, `MARIADB_*` pour mariadb. Pas les mêmes, ne pas mélanger
- `docker compose down` ne fait rien si le nom du projet a changé (il dépend du nom du dossier). `docker compose -p <nom> down`
- erreur ssl sur un port http -> le navigateur a gardé HSTS pour localhost. `brave://net-internals/#hsts` -> delete localhost
- caddy en non-root + volume `caddy_data` créé avant en root = permission denied -> supprimer le volume
- `cap_drop: ALL` sur app/db = ils ne démarrent plus (ils ont besoin de chown + changer d'user au démarrage). Seulement sur le proxy

## Serveur Azure

- VM `DockerV2`, Debian 13, B2als_v2, Norway East, groupe `TP-Orchestration-Table3`
- connexion avec la clé .pem générée par Azure (à mettre dans `~/.ssh/` sous WSL + `chmod 600`, sinon ssh la refuse) :
  `ssh -i ~/.ssh/DockerV2_key.pem azureuser@ynov-orchestration-table3.duckdns.org`
- la clé est dans le keepass, ne pas la partager : pour donner l'accès à quelqu'un, il envoie sa clé publique et on l'ajoute dans `~/.ssh/authorized_keys` sur la VM
- NSG : 80/443 ouverts à tous, 22 seulement nos IP
- arrêt auto le soir -> l'IP publique change au redémarrage, c'est pour ça qu'on a duckdns

DuckDNS : crontab de azureuser (`crontab -l`), met à jour l'IP toutes les 5 min et au reboot.
Le token est seulement dans la crontab de la VM, jamais dans le repo.

Projet sur la VM : `~/M2-Orchestration-Table3/M2-Orchestration-Table3`

Mettre à jour à la main :
```bash
git pull
docker compose up -d
```

Certificat let's encrypt : si `Timeout during connect` dans `docker compose logs proxy` -> ports 80/443 fermés dans le NSG. Let's encrypt bloque après 5 échecs/heure, donc vérifier le NSG avant de relancer.

## Commandes utiles

```bash
docker compose ps                     # état des conteneurs
docker compose logs -f proxy          # certif, erreurs 502
docker compose logs -f app            # install nextcloud
docker compose top                    # quel user fait tourner quoi
docker compose config                 # le compose avec les variables remplacées
docker compose exec -u www-data app php occ status
docker compose exec -u www-data app php occ user:resetpassword admin
```

## CI/CD

- runner self-hosted directement sur la VM (label `nextcloud-vm`), service systemd
- le runner se connecte à github en sortie, pas besoin d'ouvrir de port
- `deploy.yml` : push sur `Mathias-Nextcloud` -> git pull + compose up + check que nextcloud répond

Attention : le runner tourne avec azureuser qui est dans le groupe docker = root sur la machine. Ne pas déclencher de workflow sur les PR.

## Vault (en cours)

Demandé par le prof. Stack à part dans `vault/`, écoute seulement sur 127.0.0.1:8200.

- les mdp de nextcloud sont stockés dans `secret/nextcloud` (kv v2)
- le runner se connecte avec une AppRole (`VAULT_ROLE_ID` / `VAULT_SECRET_ID` dans les secrets github), politique en lecture seule sur `secret/nextcloud`, token valable 5 min
- `fetch-secrets.sh` récupère les mdp et écrit `secrets/` avant le compose up

**Après chaque reboot de la VM, vault est scellé** :
```bash
cd vault && docker compose exec vault vault operator unseal
```
Unseal key + root token dans le keepass. Nextcloud continue de marcher pendant ce temps, c'est seulement le déploiement qui plante.

UI vault depuis le PC : `ssh -L 8200:127.0.0.1:8200 azureuser@...` puis http://localhost:8200

## TODO

- [ ] finir vault + tester un déploiement complet
- [ ] remettre la CI build + scan trivy et faire dépendre le deploy de la CI
- [ ] Dockerfile non-root pour le proxy (demandé pour le jalon)
- [ ] remplir le résultat du scan trivy
- [ ] schéma d'archi