# Projet CSI - Déploiement Sécurisé Nextcloud

Ce dépôt contient l'infrastructure as code (IaC) et la configuration CI/CD pour le déploiement automatisé et sécurisé d'une instance Nextcloud adossée à une base de données PostgreSQL. Ce projet s'inscrit dans le cadre du jalon "Docker & CI/CD" du module CSI (Conteneurisation & Orchestration).

## Stack Technique & Architecture

* **Application :** [Nextcloud](https://nextcloud.com/) (image officielle Apache durcie).
* **Base de données :** PostgreSQL 15 (Alpine).
* **Conteneurisation :** Docker & Docker Compose (V2).
* **Hébergement :** VPS OVH (Ubuntu).
* **Exposition Publique :** Tunnel Cloudflare Zero Trust (réseau Docker externe `proxy-net`).
* **Gestion des Secrets :** HashiCorp Vault (centralisation de tous les mots de passe et clés SSH).
* **Sécurité & Scan :** Trivy (Aquasecurity).
* **CI/CD :** GitHub Actions (avec Runner auto-hébergé conteneurisé).

### Schéma d'Architecture Docker

Le schéma ci-dessous illustre l'isolation réseau mise en place : la base de données est inaccessible de l'extérieur, et seul le tunnel Cloudflare expose l'application.

```mermaid
graph TD
    User((🌐 Utilisateurs)) -->|Requêtes HTTPS| CF

    subgraph VPS OVH [Serveur VPS OVH]
        subgraph Docker Engine [Moteur Docker]
            
            subgraph ReseauProxy [Réseau : proxy-net]
                CF[Cloudflare Tunnel]
                Vault[(HashiCorp Vault)]
                Runner[GitHub Runner Local]
            end

            subgraph ReseauApp [Réseau : nextcloud-net]
                DB[(PostgreSQL 15)]
            end

            APP[Nextcloud App]
            
            %% Connexions réseaux
            CF -->|Expose le port 80| APP
            APP -->|Lit/Ecrit (Port 5432)| DB
            APP -.->|Récupération variables| Vault
            
            %% Volumes
            VolApp[(Volume: nextcloud_data)]
            VolDB[(Volume: db_data)]
            APP --- VolApp
            DB --- VolDB
        end
    end
    
    classDef network fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef container fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef db fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;
    
    class CF,APP,Vault,Runner container;
    class DB,VolApp,VolDB db;
    class ReseauProxy,ReseauApp network;
```

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

### Fonctionnement de la chaîne d'intégration

Le workflow agit comme une suite de verrous (*gates*). Si une étape échoue (comme le scan Trivy ou le Healthcheck), le déploiement est immédiatement annulé.

```mermaid
graph TD
    A[Git Push] -->|Déclenche| B{GitHub Actions}
    B --> C[Runner Auto-hébergé sur VPS]
    
    subgraph Phase CI [CI : Intégration Continue & Sécurité]
        C --> D[Checkout du code source]
        D --> E[Connexion Vault & Import des Secrets]
        E --> F[Docker Build de l'image locale]
        F --> G{Scan Trivy}
    end
    
    G -->|Vulnérabilités CRITICAL/HIGH| Z[❌ Arrêt du Pipeline]
    G -->|Pass (Aucune faille majeure)| H[Connexion SSH au VPS]
    
    subgraph Phase CD [CD : Déploiement Continu]
        H -->|Utilisateur: cddeploy| I[Mise à jour via Git Pull]
        I --> J[Génération du .env sécurisé]
        J --> K[Docker Compose Down & Up -d]
        K --> L{Healthcheck des conteneurs}
    end
    
    L -->|Conteneur 'exited'| Z
    L -->|Tous les conteneurs 'Up'| M((✅ Déploiement Validé))
```

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

3. **Créer le réseau externe (requis pour le tunnel Cloudflare ou le Vault) :**
   ```bash
   docker network create proxy-net
   ```

4. **Lancer la stack :**
   ```bash
   docker compose up --build -d
   ```