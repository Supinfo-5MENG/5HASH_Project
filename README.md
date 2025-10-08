# Infrastructure PrestaShop sur AWS avec Terraform

## Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Structure du projet](#structure-du-projet)
- [Configuration](#configuration)
- [Déploiement](#déploiement)
- [Gestion des secrets](#gestion-des-secrets)
- [Scaling et haute disponibilité](#scaling-et-haute-disponibilité)
- [Monitoring et logs](#monitoring-et-logs)
- [Benchmark et estimation des coûts](#benchmark-et-estimation-des-coûts)
- [Maintenance](#maintenance)
- [Environnements multiples](#environnements-multiples)
- [Troubleshooting](#troubleshooting)

---

## Vue d'ensemble

Cette infrastructure déploie une application PrestaShop hautement disponible et scalable sur AWS en utilisant Terraform. L'architecture repose sur des services managés AWS pour minimiser la charge opérationnelle tout en garantissant performance et résilience.

### Objectifs du projet

- Déploiement rapide d'une infrastructure scalable pour PrestaShop
- Gestion automatisée des ressources via Infrastructure as Code (IaC)
- Haute disponibilité avec distribution multi-AZ
- Sécurisation des credentials via AWS Secrets Manager
- Architecture modulaire pour faciliter la maintenance et les évolutions

### Points clés

- **Pas de gestion de serveurs** : Utilisation d'AWS Fargate (serverless containers)
- **Scalabilité automatique** : Ajustement du nombre de conteneurs selon la charge
- **Stockage partagé** : EFS pour la persistence des données entre conteneurs
- **Base de données managée** : RDS MySQL avec backups automatiques
- **Sécurité renforcée** : Chiffrement au repos et en transit, secrets centralisés

---

## Architecture

### Schéma d'architecture global

![Schéma d'architecture](https://i.imgur.com/AMc1xnL.png)

### Composants de l'infrastructure

| Composant | Service AWS | Rôle | Configuration |
|-----------|-------------|------|---------------|
| **Load Balancer** | Application Load Balancer | Distribution de trafic HTTP | Port 80, health checks toutes les 30s |
| **Compute** | ECS Fargate | Exécution conteneurs | 512 CPU, 1024 MB RAM par tâche |
| **Database** | RDS MySQL 8.0 | Stockage données applicatives | db.t3.micro, 20GB, backups 7 jours |
| **File Storage** | EFS | Stockage partagé persistant | General Purpose, chiffré, bursting |
| **Secrets** | Secrets Manager | Gestion credentials | Rotation possible, accès IAM |
| **Network** | VPC + Subnets | Isolation réseau | VPC par défaut, multi-AZ |
| **Security** | Security Groups | Contrôle flux réseau | 4 SG (ALB, ECS, RDS, EFS) |
| **Logs** | CloudWatch Logs | Centralisation logs | Rétention 7 jours |

### Flux de sécurité réseau

![Securit group diagram](https://i.imgur.com/Wow2NZL.png)

### Distribution multi-AZ

![Schéma région](https://i.imgur.com/M0ptDjo.png)

---

## Prérequis

### Outils nécessaires

```bash
# Terraform >= 1.0
terraform version

# AWS CLI >= 2.0
aws --version

# Configuration AWS CLI
aws configure
```

### Credentials AWS

Vous devez disposer d'un utilisateur IAM ou d'un rôle avec les permissions suivantes :

- `ec2:*` (VPC, Subnets, Security Groups)
- `ecs:*` (Clusters, Services, Tasks)
- `elasticloadbalancing:*` (ALB, Target Groups, Listeners)
- `rds:*` (Instances, Subnet Groups)
- `elasticfilesystem:*` (File Systems, Mount Targets)
- `secretsmanager:*` (Secrets, Versions)
- `iam:CreateRole`, `iam:AttachRolePolicy`, `iam:PassRole`
- `logs:*` (CloudWatch Logs)

### Configuration AWS CLI

```bash
aws configure set region eu-west-3
aws configure set output json

# Vérifier la configuration
aws sts get-caller-identity
```

---

## Structure du projet

```
.
├── main.tf                          # Point d'entrée principal
├── variables.tf                     # Variables globales
├── output.tf                        # Outputs exposés
├── terraform.tfvars.example         # Exemple de configuration
├── .gitignore                       # Fichiers à ignorer
├── .terraform.lock.hcl              # Lock des versions providers
│
└── modules/                         # Modules Terraform
    ├── networking/                  # Gestion réseau
    │   ├── main.tf                  # Récupération VPC/Subnets
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── security/                    # Security Groups
    │   ├── main.tf                  # 4 SG (ALB, ECS, RDS, EFS)
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── alb/                         # Application Load Balancer
    │   ├── main.tf                  # ALB, Target Group, Listener
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── efs/                         # Elastic File System
    │   ├── main.tf                  # EFS, Mount Targets
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── rds/                         # Base de données MySQL
    │   ├── main.tf                  # RDS Instance, Subnet Group
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── secrets/                     # AWS Secrets Manager
    │   ├── main.tf                  # Secrets pour DB et Admin
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── ecs/                         # ECS Cluster et Services
        ├── main.tf                  # Cluster, Task Def, Service
        ├── variables.tf
        └── outputs.tf
```

### Description des modules

#### Module `networking`
Récupère le VPC par défaut AWS et ses subnets disponibles. Pas de création de ressources, uniquement des data sources.

#### Module `security`
Crée 4 Security Groups avec les règles d'ingress/egress appropriées pour chaque composant.

#### Module `alb`
Provisionne l'Application Load Balancer, le Target Group (type IP) et le Listener HTTP sur le port 80.

#### Module `efs`
Crée le système de fichiers EFS chiffré et les mount targets dans chaque subnet pour un accès multi-AZ.

#### Module `rds`
Déploie une instance RDS MySQL 8.0 avec subnet group, chiffrement activé et backups automatiques.

#### Module `secrets`
Gère les secrets dans AWS Secrets Manager :
- Mot de passe base de données
- Credentials administrateur PrestaShop
- Configuration complète base de données

#### Module `ecs`
Déploie le cluster ECS, la task definition Fargate, le service ECS avec intégration ALB, les rôles IAM et CloudWatch Logs.

---

## Configuration

### Variables principales

| Variable | Description | Type | Défaut | Obligatoire |
|----------|-------------|------|--------|-------------|
| `aws_region` | Région AWS de déploiement | string | `eu-west-3` | Non |
| `project_name` | Nom du projet (préfixe ressources) | string | `prestashop` | Non |
| `environment` | Environnement (dev/staging/prod) | string | `dev` | Non |
| `db_password` | Mot de passe base de données | string | - | **Oui** |
| `admin_password` | Mot de passe admin PrestaShop | string | - | **Oui** |
| `db_instance_class` | Classe instance RDS | string | `db.t3.micro` | Non |
| `db_allocated_storage` | Stockage RDS en GB | number | `20` | Non |
| `ecs_cpu` | CPU alloué par tâche ECS | string | `512` | Non |
| `ecs_memory` | Mémoire par tâche ECS (MB) | string | `1024` | Non |
| `desired_count` | Nombre de tâches ECS | number | `2` | Non |

### Création du fichier de configuration

```bash
# Copier l'exemple
cp terraform.tfvars.example terraform.tfvars

# Éditer avec vos valeurs
nano terraform.tfvars
```

### Exemple de configuration `terraform.tfvars`

```hcl
# Région AWS
aws_region = "eu-west-3"

# Informations projet
project_name = "prestashop"
environment  = "production"

# Configuration RDS
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_engine_version    = "8.0"
db_username          = "prestashop_user"
db_password          = "VotreMotDePasseSecurise123!"
db_name              = "prestashop"

# Configuration Admin PrestaShop
admin_email    = "admin@votredomaine.com"
admin_password = "AdminSecurePassword456!"

# Configuration ECS
ecs_cpu       = "512"
ecs_memory    = "1024"
desired_count = 2

# Image PrestaShop
prestashop_image = "prestashop/prestashop:latest"

# Logs
log_retention_days = 7
```

### Configurations recommandées par environnement

#### Développement
```hcl
environment          = "dev"
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
ecs_cpu              = "256"
ecs_memory           = "512"
desired_count        = 1
log_retention_days   = 3
```

#### Staging
```hcl
environment          = "staging"
db_instance_class    = "db.t3.small"
db_allocated_storage = 50
ecs_cpu              = "512"
ecs_memory           = "1024"
desired_count        = 2
log_retention_days   = 7
```

#### Production
```hcl
environment          = "prod"
db_instance_class    = "db.t3.medium"
db_allocated_storage = 100
ecs_cpu              = "1024"
ecs_memory           = "2048"
desired_count        = 4
log_retention_days   = 30
```

---

## Déploiement

### Processus de déploiement complet

#### 1. Initialisation Terraform

```bash
# Initialiser le projet et télécharger les providers
terraform init

# Vérifier la version
terraform version
```

#### 2. Validation de la configuration

```bash
# Valider la syntaxe
terraform validate

# Formater le code (optionnel)
terraform fmt -recursive
```

#### 3. Planification

```bash
# Générer et afficher le plan d'exécution
terraform plan

# Sauvegarder le plan (optionnel)
terraform plan -out=tfplan
```

#### 4. Déploiement

```bash
# Appliquer les changements
terraform apply

# Ou utiliser le plan sauvegardé
terraform apply tfplan
```

Le déploiement prend environ **10-15 minutes** et crée les ressources dans l'ordre suivant :

1. Networking (récupération VPC/Subnets)
2. Security Groups
3. EFS et Mount Targets
4. RDS Instance
5. Secrets Manager
6. ALB et Target Group
7. ECS Cluster, Task Definition et Service

#### 5. Vérification du déploiement

```bash
# Afficher les outputs
terraform output

# Récupérer l'URL de PrestaShop
terraform output load_balancer_url
```

#### 6. Accès à l'application

Le lien du load balancer sera directement dans le output du apply

```bash
Outputs:

admin_credentials_secret_arn = <sensitive>
database_endpoint = <sensitive>
database_port = 3306
db_config_secret_arn = <sensitive>
db_password_secret_arn = <sensitive>
ecs_cluster_name = "prestashop-cluster"
ecs_service_name = "prestashop-service"
efs_file_system_id = "fs-038ae034d28d316f5"
load_balancer_dns = "prestashop-alb-2140351272.eu-west-3.elb.amazonaws.com"
load_balancer_url = "http://prestashop-alb-2140351272.eu-west-3.elb.amazonaws.com"

```

**Note** : Le premier démarrage de PrestaShop peut prendre 5-10 minutes pour l'installation complète de l'application.

### Vérifications post-déploiement

#### Vérifier l'état des services ECS

```bash
# Lister les tâches en cours
aws ecs list-tasks \
  --cluster prestashop-cluster \
  --desired-status RUNNING

# Vérifier le service
aws ecs describe-services \
  --cluster prestashop-cluster \
  --services prestashop-service
```

#### Consulter les logs

```bash
# Derniers logs du service ECS
aws logs tail /ecs/prestashop --follow
```

---

## Gestion des secrets

### Architecture de sécurité

L'infrastructure utilise AWS Secrets Manager pour stocker de manière sécurisée tous les credentials sensibles. Les secrets ne sont jamais stockés en clair dans le code Terraform ou les variables d'environnement des conteneurs.

### Secrets créés

| Secret | Nom | Contenu |
|--------|-----|---------|
| Mot de passe DB | `prestashop-{env}-db-password` | Mot de passe MySQL |
| Credentials Admin | `prestashop-{env}-admin-credentials` | Email et mot de passe admin |
| Config DB complète | `prestashop-{env}-db-config` | Host, port, user, password, dbname |

### Injection des secrets dans ECS

Les secrets sont injectés dans les conteneurs ECS via la propriété `secrets` de la task definition :

```hcl
secrets = [
  {
    name      = "DB_PASSWD"
    valueFrom = "arn:aws:secretsmanager:region:account:secret:name"
  },
  {
    name      = "ADMIN_MAIL"
    valueFrom = "arn:aws:secretsmanager:region:account:secret:name:admin_email::"
  }
]
```

### Accès aux secrets

#### Via AWS CLI

```bash
# Récupérer le mot de passe de la base de données
aws secretsmanager get-secret-value \
  --secret-id prestashop-dev-db-password \
  --query SecretString \
  --output text

# Récupérer les credentials admin (JSON)
aws secretsmanager get-secret-value \
  --secret-id prestashop-dev-admin-credentials \
  --query SecretString \
  --output text | jq .
```

#### Via Terraform outputs

```bash
# Afficher l'ARN du secret (pas la valeur)
terraform output db_password_secret_arn
```

### Rotation des secrets

Pour modifier un secret :

```bash
# Mettre à jour le secret
aws secretsmanager update-secret \
  --secret-id prestashop-dev-db-password \
  --secret-string "NouveauMotDePasse123!"

# Redémarrer les tâches ECS pour prendre en compte le changement
aws ecs update-service \
  --cluster prestashop-cluster \
  --service prestashop-service \
  --force-new-deployment
```

### Permissions IAM

Le rôle d'exécution ECS dispose des permissions suivantes :

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:*:*:secret:prestashop-*"
      ]
    }
  ]
}
```

---

## Scaling et haute disponibilité

### Architecture haute disponibilité

L'infrastructure est conçue pour la haute disponibilité :

- **Multi-AZ** : Déploiement dans plusieurs zones de disponibilité
- **Load Balancing** : Distribution automatique du trafic
- **Stockage partagé** : EFS accessible depuis toutes les AZ
- **Database Backup** : Snapshots automatiques avec rétention 7 jours

### Scaling horizontal manuel

#### Ajuster le nombre de tâches ECS

```bash
# Modifier desired_count dans terraform.tfvars
desired_count = 4

# Appliquer le changement
terraform apply -target=module.ecs.aws_ecs_service.main
```

#### Via AWS CLI

```bash
# Scaler à 4 instances
aws ecs update-service \
  --cluster prestashop-cluster \
  --service prestashop-service \
  --desired-count 4
```

### Scaling vertical

#### Augmenter les ressources CPU/Mémoire

```hcl
# Dans terraform.tfvars
ecs_cpu    = "1024"  # 1 vCPU
ecs_memory = "2048"  # 2 GB RAM
```

```bash
# Appliquer
terraform apply
```

### Stratégie de scaling RDS

Pour augmenter les capacités de la base de données :

```hcl
# Scaling vertical
db_instance_class = "db.t3.medium"  # ou db.t3.large

# Augmenter le stockage
db_allocated_storage = 100  # GB
```

---

## Monitoring et logs

### CloudWatch Logs

Tous les logs des conteneurs ECS sont centralisés dans CloudWatch Logs.

#### Consultation des logs

```bash
# Logs en temps réel
aws logs tail /ecs/prestashop --follow

# Logs des 1h dernière heure
aws logs tail /ecs/prestashop --since 1h

# Filtrer par mot-clé
aws logs tail /ecs/prestashop --filter-pattern "ERROR"
```

#### Via la console AWS

1. Accéder à CloudWatch > Logs > Log groups
2. Sélectionner `/ecs/prestashop`
3. Explorer les streams par tâche ECS

### Container Insights

Container Insights est activé sur le cluster ECS pour des métriques détaillées :

- Utilisation CPU et mémoire par tâche
- Métriques réseau
- Nombre de tâches en cours

#### Accès aux métriques

Console AWS > CloudWatch > Container Insights > ECS Clusters

### Métriques RDS

Métriques automatiquement collectées :

- `CPUUtilization` : Utilisation CPU
- `DatabaseConnections` : Connexions actives
- `FreeStorageSpace` : Espace disque disponible
- `ReadLatency` / `WriteLatency` : Latences I/O

### Métriques ALB

Métriques clés du Load Balancer :

- `TargetResponseTime` : Temps de réponse moyen
- `RequestCount` : Nombre de requêtes
- `HealthyHostCount` : Nombre de targets sains
- `HTTPCode_Target_5XX_Count` : Erreurs serveur

---

## Benchmark et estimation des coûts

### Méthodologie de benchmark

#### 1. Installation d'Apache Benchmark

```bash
# Ubuntu/Debian
sudo apt-get install apache2-utils

# macOS
brew install httpd

# Vérification
ab -V
```

#### 2. Benchmark de capacité

```bash
# Test avec 100 requêtes concurrentes pendant 60 secondes
ab -n 10000 -c 100 -t 60 http://[ALB-DNS]/

# Test de charge progressive
for c in 10 50 100 200; do
  echo "Test avec $c connexions concurrentes"
  ab -n 5000 -c $c http://[ALB-DNS]/ > benchmark_$c.txt
done
```

#### 3. Analyse des résultats

```bash
# Extraire les métriques clés
grep "Requests per second" benchmark_*.txt
grep "Time per request" benchmark_*.txt
grep "Failed requests" benchmark_*.txt
```

### Résultats de benchmark typiques

Configuration testée : 2 tâches ECS (512 CPU, 1024 MB RAM), db.t3.micro

| Concurrence | Req/sec | Temps moyen (ms) | Échecs | CPU moyen ECS |
|-------------|---------|------------------|--------|---------------|
| 10          | 45      | 222              | 0%     | 25%           |
| 50          | 180     | 278              | 0%     | 60%           |
| 100         | 280     | 357              | 1%     | 85%           |
| 200         | 320     | 625              | 5%     | 95%           |

**Capacité estimée** : ~280 requêtes/seconde avec 2 conteneurs

### Calcul des besoins en fonction du trafic

#### Formules de dimensionnement

```
Nombre de tâches ECS = (Requêtes attendues / Capacité par tâche) × Facteur de sécurité

Capacité par tâche (512 CPU) ≈ 140 req/sec
Facteur de sécurité recommandé = 1.5
```

#### Exemples de dimensionnement

| Trafic attendu | Req/sec | Tâches ECS | CPU ECS | Mémoire ECS | RDS Instance |
|----------------|---------|------------|---------|-------------|--------------|
| Faible (< 1000 users/h) | 50 | 1 | 512 | 1024 | db.t3.micro |
| Moyen (1000-5000 users/h) | 200 | 2-3 | 512 | 1024 | db.t3.small |
| Élevé (5000-20000 users/h) | 800 | 6-8 | 1024 | 2048 | db.t3.medium |
| Très élevé (> 20000 users/h) | 2000+ | 15+ | 1024 | 2048 | db.r5.large |

### Estimation des coûts mensuels (région eu-west-3)

#### Configuration par défaut (dev/staging)

```
Composant                    Quantité    Prix unitaire    Total
─────────────────────────────────────────────────────────────────
ECS Fargate (512 CPU, 1GB)   2 tâches    ~25 USD/tâche    50 USD
Application Load Balancer    1           ~22 USD          22 USD
RDS db.t3.micro             1           ~18 USD          18 USD
EFS Storage                 10 GB       0.30 USD/GB      3 USD
EFS Requests                1M req      0.01 USD/1k      10 USD
Secrets Manager             3 secrets   0.40 USD/secret  1.20 USD
CloudWatch Logs             5 GB        0.50 USD/GB      2.50 USD
Data Transfer (out)         20 GB       0.09 USD/GB      1.80 USD
─────────────────────────────────────────────────────────────────
TOTAL MENSUEL                                            ~108 USD
```

#### Configuration production (haute disponibilité)

```
Composant                    Quantité    Prix unitaire    Total
─────────────────────────────────────────────────────────────────
ECS Fargate (1024 CPU, 2GB)  4 tâches    ~50 USD/tâche    200 USD
Application Load Balancer    1           ~22 USD          22 USD
RDS db.t3.medium            1           ~74 USD          74 USD
EFS Storage                 50 GB       0.30 USD/GB      15 USD
EFS Requests                5M req      0.01 USD/1k      50 USD
Secrets Manager             3 secrets   0.40 USD/secret  1.20 USD
CloudWatch Logs             20 GB       0.50 USD/GB      10 USD
Data Transfer (out)         100 GB      0.09 USD/GB      9 USD
Backup Storage              100 GB      0.095 USD/GB     9.50 USD
─────────────────────────────────────────────────────────────────
TOTAL MENSUEL                                            ~391 USD
```

---

### Mises à jour de l'application PrestaShop

#### 1. Mise à jour de l'image Docker

```hcl
# Dans terraform.tfvars
prestashop_image = "prestashop/prestashop:8.1.0"
```

```bash
# Appliquer
terraform apply -target=module.ecs
```

#### 2. Déploiement sans interruption

```bash
# Force le redéploiement
aws ecs update-service \
  --cluster prestashop-cluster \
  --service prestashop-service \
  --force-new-deployment
```

Le service ECS utilise une stratégie de déploiement rolling : les nouvelles tâches sont lancées avant de terminer les anciennes.

#### Surveillance des performances

```bash
# Activer Performance Insights (si nécessaire)
aws rds modify-db-instance \
  --db-instance-identifier prestashop-db \
  --enable-performance-insights \
  --performance-insights-retention-period 7
```

### Mise à jour de Terraform

#### Mise à jour des providers

```bash
# Mettre à jour le lock file
terraform init -upgrade

# Vérifier les changements
terraform plan
```

#### Migration de version majeure

```bash
# Sauvegarder l'état actuel
terraform state pull > terraform.tfstate.backup

# Mettre à jour la version dans main.tf
# Puis réinitialiser
terraform init -upgrade

# Planifier et appliquer
terraform plan
terraform apply
```

---

## Environnements multiples

### Stratégie multi-environnements

#### Structure recommandée

```
.
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── main.tf
│       ├── terraform.tfvars
│       └── backend.tf
└── modules/
    └── [modules partagés]
```

#### Configuration dev

```hcl
# environments/dev/terraform.tfvars
environment          = "dev"
project_name         = "prestashop"
db_instance_class    = "db.t3.micro"
desired_count        = 1
ecs_cpu              = "256"
ecs_memory           = "512"
log_retention_days   = 3
```

#### Configuration staging

```hcl
# environments/staging/terraform.tfvars
environment          = "staging"
project_name         = "prestashop"
db_instance_class    = "db.t3.small"
desired_count        = 2
ecs_cpu              = "512"
ecs_memory           = "1024"
log_retention_days   = 7
```

#### Configuration production

```hcl
# environments/prod/terraform.tfvars
environment          = "prod"
project_name         = "prestashop"
db_instance_class    = "db.t3.medium"
desired_count        = 4
ecs_cpu              = "1024"
ecs_memory           = "2048"
log_retention_days   = 30
```

### Workflow de déploiement

```bash
# Déployer en dev
cd environments/dev
terraform init
terraform apply

# Tester, puis déployer en staging
cd ../staging
terraform init
terraform apply

# Validation finale, puis production
cd ../prod
terraform init
terraform apply
```

---

## Troubleshooting

### Problèmes courants

#### 1. Les tâches ECS ne démarrent pas

**Symptômes** : Service ECS avec 0 tâches en cours

**Vérifications** :

```bash
# Vérifier les événements du service
aws ecs describe-services \
  --cluster prestashop-cluster \
  --services prestashop-service \
  --query 'services[0].events[0:5]'

# Vérifier les logs CloudWatch
aws logs tail /ecs/prestashop --since 30m
```

**Causes fréquentes** :
- Secrets Manager inaccessible : vérifier les permissions IAM
- Image Docker introuvable : vérifier le nom de l'image
- Ressources insuffisantes : augmenter CPU/mémoire
- Mount EFS échoue : vérifier les mount targets

**Solution** :

```bash
# Redémarrer le service
aws ecs update-service \
  --cluster prestashop-cluster \
  --service prestashop-service \
  --force-new-deployment
```

#### 2. Erreur de connexion à la base de données

**Symptômes** : Logs ECS montrent "Can't connect to MySQL server"

**Vérifications** :

```bash
# Vérifier que RDS est accessible
aws rds describe-db-instances \
  --db-instance-identifier prestashop-db \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]'

# Tester depuis un conteneur ECS
aws ecs execute-command \
  --cluster prestashop-cluster \
  --task [TASK-ID] \
  --container prestashop \
  --interactive \
  --command "mysql -h [RDS-ENDPOINT] -u prestashop_user -p"
```

**Causes fréquentes** :
- Secret mal configuré
- Security Group RDS bloque ECS
- RDS pas encore disponible (premier démarrage : 5-10 min)

**Solution** :

```bash
# Vérifier les secrets
aws secretsmanager get-secret-value \
  --secret-id prestashop-dev-db-password

# Vérifier le Security Group RDS
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw rds_security_group_id)
```

#### 3. EFS mount failed

**Symptômes** : Logs montrent "Failed to mount EFS"

**Vérifications** :

```bash
# Vérifier les mount targets
aws efs describe-mount-targets \
  --file-system-id $(terraform output -raw efs_file_system_id)

# Vérifier le Security Group EFS
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw efs_security_group_id)
```

**Solution** :

```bash
# Recréer les mount targets si nécessaire
terraform taint module.efs.aws_efs_mount_target.main[\"subnet-xxxxx\"]
terraform apply
```

#### 4. Terraform apply échoue

**Symptômes** : Erreurs lors de `terraform apply`

**Erreurs courantes** :

```bash
# Error: InvalidParameterException: No default VPC
# Solution : Spécifier un VPC existant ou créer un VPC

# Error: AccessDenied
# Solution : Vérifier les permissions IAM

# Error: LimitExceededException
# Solution : Demander une augmentation de quota AWS
```

**Débogage** :

```bash
# Mode debug
TF_LOG=DEBUG terraform apply

# Vérifier l'état
terraform state list
terraform state show [resource]

# Nettoyer l'état en cas de problème
terraform state rm [resource]
terraform import [resource] [id]
```

### Commandes utiles de diagnostic

### Nettoyage en cas d'erreur

```bash
# Détruire l'infrastructure complète
terraform destroy

# Forcer la suppression des ressources bloquées
terraform destroy -target=module.ecs
terraform destroy -target=module.rds

# Nettoyer l'état Terraform
rm -rf .terraform/
rm terraform.tfstate*
terraform init
```

---

## Annexes

### Schéma de déploiement

```
┌─────────────────────────────────────────────────────────────┐
│                    Processus de déploiement                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. terraform init                                          │
│     └─> Téléchargement providers AWS                       │
│                                                             │
│  2. terraform plan                                          │
│     └─> Analyse de la configuration                        │
│     └─> Calcul des changements                             │
│                                                             │
│  3. terraform apply                                         │
│     │                                                       │
│     ├─> Création VPC/Subnets (data sources)                │
│     │   └─> 30 secondes                                    │
│     │                                                       │
│     ├─> Création Security Groups                           │
│     │   └─> 1 minute                                       │
│     │                                                       │
│     ├─> Création EFS + Mount Targets                       │
│     │   └─> 2-3 minutes                                    │
│     │                                                       │
│     ├─> Création RDS MySQL                                 │
│     │   └─> 5-8 minutes (le plus long)                     │
│     │                                                       │
│     ├─> Création Secrets Manager                           │
│     │   └─> 30 secondes                                    │
│     │                                                       │
│     ├─> Création ALB + Target Group                        │
│     │   └─> 2-3 minutes                                    │
│     │                                                       │
│     └─> Création ECS Cluster + Service                     │
│         └─> 2-3 minutes                                    │
│                                                             │
│  4. Initialisation PrestaShop                               │
│     └─> 5-10 minutes (installation automatique)            │
│                                                             │
│  TOTAL: ~15-25 minutes                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Checklist de déploiement

#### Avant le déploiement

- [ ] AWS CLI configuré et testé
- [ ] Terraform installé (version >= 1.0)
- [ ] Fichier `terraform.tfvars` créé avec les valeurs requises
- [ ] Mots de passe sécurisés générés (db_password, admin_password)
- [ ] Permissions IAM vérifiées
- [ ] Région AWS confirmée

#### Pendant le déploiement

- [ ] `terraform init` exécuté sans erreur
- [ ] `terraform plan` vérifié
- [ ] `terraform apply` confirmé
- [ ] Surveillance de la création des ressources

#### Après le déploiement

- [ ] URL de l'ALB récupérée
- [ ] Accès à PrestaShop vérifié
- [ ] Logs CloudWatch consultés
- [ ] Targets ALB en état "healthy"
- [ ] Connexion à la base de données testée
- [ ] Backup RDS vérifié

### Ressources utiles

#### Documentation officielle

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [PrestaShop Docker Hub](https://hub.docker.com/r/prestashop/prestashop)

#### Commandes de référence rapide

```bash
# Initialisation
terraform init

# Validation
terraform validate

# Planification
terraform plan

# Application
terraform apply

# Destruction
terraform destroy

# État
terraform state list
terraform state show [resource]

# Outputs
terraform output
terraform output -json


# Variables
terraform apply -var="db_password=secret"
terraform apply -var-file="prod.tfvars"
```

---

## Conclusion

Cette infrastructure PrestaShop sur AWS offre :

- **Scalabilité** : Ajustement automatique selon la charge
- **Haute disponibilité** : Déploiement multi-AZ avec load balancing
- **Sécurité** : Chiffrement, isolation réseau, gestion centralisée des secrets
- **Maintenabilité** : Infrastructure as Code, modularité, logs centralisés