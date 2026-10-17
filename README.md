#  Projet CSI - Déploiement Sécurisé Nextcloud

Ce dépôt contient l'infrastructure as code (IaC) et la configuration CI/CD pour le déploiement automatisé et sécurisé d'une instance Nextcloud adossée à une base de données PostgreSQL. Ce projet s'inscrit dans le cadre du jalon "Docker & CI/CD" du module CSI (Conteneurisation & Orchestration).

##  Stack Technique & Architecture

* **Application :** [Nextcloud](https://nextcloud.com/) (image officielle Apache durcie).
* **Base de données :** PostgreSQL 15 (Alpine).
* **Conteneurisation :** Docker & Docker Compose (V2).
* **Hébergement :** VPS OVH (Ubuntu).
* **Exposition Publique :** Tunnel Cloudflare Zero Trust (réseau Docker externe `proxy-net`).
* **Gestion des Secrets :** HashiCorp Vault (centralisation de tous les mots de passe et clés SSH).
* **Sécurité & Scan :** Trivy (Aquasecurity).
* **CI/CD :** GitHub Actions (avec Runner auto-hébergé conteneurisé).

##  Sécurité & Bonnes Pratiques Implémentées

Le projet respecte les standards de sécurité de l'industrie :
1. **Principe de moindre privilège :** 
   * L'image Nextcloud tourne avec l'utilisateur non-root `www-data` (via un `Dockerfile` personnalisé).
   * Le déploiement CI/CD utilise un utilisateur système dédié (`cddeploy`) restreint via SSH.
2. **Gestion des Secrets (Zéro secret dans Git) :**
   * Aucun mot de passe n'est versionné. 
   * Le pipeline interroge dynamiquement un serveur **HashiCorp Vault** pour récupérer les mots de passe (DB, Admin) et la clé SSH de déploiement en mémoire.
   * Le fichier `.env` est généré à la volée sur le VPS lors du déploiement et est exclu par `.gitignore`.
3. **Isolation Réseau :**
   * La base de données PostgreSQL est isolée sur un réseau interne (`nextcloud-net`) et n'est pas exposée à Cloudflare ni à l'hôte.
4. **DevSecOps :**
   * Analyse de vulnérabilités bloquante à chaque build via Trivy (échec du pipeline si failles `CRITICAL` ou `HIGH`).

##  Pipeline CI/CD Automatisé

L'intégration et le déploiement continus sont gérés par GitHub Actions (`.github/workflows/ci.yml`) et s'exécutent sur un runner Docker auto-hébergé sur le VPS.

**Le workflow agit comme une suite de verrous (gates) :**
1. **Checkout :** Récupération du code source.
2. **Vault Auth :** Connexion au Vault et récupération des secrets en mémoire.
3. **Build :** Construction de l'image locale `nextcloud-custom:latest`.
4. **Scan (Trivy) :** Recherche de CVE sur l'image construite.
5. **Déploiement (SSH) :** 
   * Connexion au VPS via l'utilisateur `cddeploy`.
   * `git pull` du dépôt.
   * Injection des secrets Vault dans un fichier `.env` éphémère.
   * `docker compose up --build -d`.
6. **Healthcheck :** Vérification du statut des conteneurs après 10 secondes (échec si un conteneur est `exited`).

##  Guide de Déploiement Local (Développement)

Pour tester la stack en local sans la CI/CD :

1. **Cloner le dépôt :**
   ```bash
   git clone https://github.com/ynov-m2-table3/M2-Orchestration-Table3.git
   cd M2-Orchestration-Table3/V1
   ```

2. **Configurer l'environnement :**
   Copiez le fichier d'exemple et remplissez vos informations :
   ```bash
   cp .env.example .env
   ```

3. **Créer le réseau externe (requis pour le tunnel Cloudflare) :**
   ```bash
   docker network create proxy-net
   ```

4. **Lancer la stack :**
   ```bash
   docker compose up --build -d
   ```
6. test 1
