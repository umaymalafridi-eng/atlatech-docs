---
title: Analyse de l'Infrastructure Actuelle
sidebar_label: Analyse Infrastructure
sidebar_position: 5
---

# 5. Analyse de l'Infrastructure Actuelle

Ce chapitre présente l'analyse détaillée de l'infrastructure existante d'AtlasTech Solutions dans son état initial avant toute modification ou correction de sécurité. L'objectif est de documenter l'architecture actuelle, les services déployés, les configurations en place, et les flux de données entre les différents composants du système.

## 5.1 Vue d'ensemble de l'architecture

L'infrastructure d'AtlasTech Solutions repose sur une architecture réseau locale de classe C (192.168.112.0/24) interconnectant plusieurs machines avec des rôles distincts.

### 5.1.1 Topologie réseau

![Diagramme réseau de l'infrastructure AtlasTech](/img/infrastructure/network-diagram.png)

```
Réseau: 192.168.112.0/24
Gateway: 192.168.112.2
DNS: 192.168.112.2

┌─────────────────────────────────────────────────────────────┐
│                    Réseau Local 192.168.112.0/24            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐        ┌──────────────────┐         │
│  │   MainServer     │        │  BackupServer    │         │
│  │  192.168.112.141 │◄──────►│ 192.168.112.142  │         │
│  │  Ubuntu 24.04    │ rsync  │  Ubuntu 24.04    │         │
│  └──────────────────┘        └──────────────────┘         │
│          ▲                                                  │
│          │ HTTP/HTTPS                                      │
│          ▼                                                  │
│  ┌──────────────────┐        ┌──────────────────┐         │
│  │  Windows 10      │        │   Kali Linux     │         │
│  │  192.168.112.137 │        │ 192.168.112.128  │         │
│  │  (Admin: a.haidar)│        │  (Pentest)       │         │
│  └──────────────────┘        └──────────────────┘         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5.1.2 Inventaire des machines

| Machine | Adresse IP | Système d'exploitation | Rôle | Hostname |
|---------|-----------|------------------------|------|----------|
| MainServer | 192.168.112.141 | Ubuntu 24.04.3 LTS | Serveur web et base de données | atlastech-mainserver |
| BackupServer | 192.168.112.142 | Ubuntu 24.04.3 LTS | Serveur de sauvegarde | atlastech-backupserver |
| Windows 10 | 192.168.112.137 | Windows 10 Pro (Build 19042) | Poste de travail administrateur | WIN-DA9HK0109ND |
| Kali Linux | 192.168.112.128 | Kali Linux 2024.4 | Machine de tests de pénétration | kali |

---

## 5.2 Infrastructure serveurs

### 5.2.1 MainServer - Serveur principal (192.168.112.141)

Le MainServer héberge les applications web de l'entreprise ainsi que la base de données centralisée.

#### A. Informations système

Pour obtenir les informations système du serveur, les commandes suivantes ont été exécutées:

```bash
# Connexion SSH au serveur
ssh atlastechadmin@192.168.112.141

# Informations sur le noyau Linux
uname -a

# Version de la distribution
lsb_release -a

# Nom d'hôte du serveur
hostname

# Configuration réseau complète
ip addr show

# Adresses IP assignées
hostname -I
```

**Explication des commandes**:
- `uname -a`: Affiche toutes les informations sur le système (nom du noyau, version, architecture matérielle)
- `lsb_release -a`: Affiche les informations sur la distribution Linux (nom, version, codename)
- `hostname`: Affiche le nom d'hôte configuré pour la machine
- `ip addr show`: Affiche la configuration détaillée de toutes les interfaces réseau
- `hostname -I`: Liste toutes les adresses IP attribuées au serveur

**Résultats obtenus**:

![Informations système MainServer](/img/infrastructure/beforeuname-alsb_release-a%20hostname.png)

```
Noyau: Linux 6.8.0-94-generic #96-Ubuntu SMP PREEMPT_DYNAMIC
Architecture: x86_64
Distribution: Ubuntu 24.04.3 LTS (Noble)
Hostname: atlastech-mainserver

Interface réseau: ens33
MAC Address: 00:0c:29:8d:a1:e2
Adresse IPv4: 192.168.112.141/24
```

![Configuration réseau MainServer](/img/infrastructure/ip%20addr%20show%20sur%20MainServer.png)

#### B. Services actifs

Pour lister tous les services en cours d'exécution:

```bash
# Lister tous les services actifs
sudo systemctl list-units --type=service --state=running
```

**Explication de la commande**:
- `systemctl`: Utilitaire de gestion des services sous systemd
- `list-units --type=service`: Filtre pour afficher uniquement les services
- `--state=running`: Filtre pour afficher uniquement les services en cours d'exécution

**Services critiques identifiés**:

![Services actifs sur MainServer](/img/infrastructure/beforesudo%20systemctl%20list-units%20--type=service%20--state=running.png)

| Service | Port | Description | État |
|---------|------|-------------|------|
| apache2.service | 80/tcp | Serveur web Apache HTTP Server 2.4.58 | Actif |
| mariadb.service | 3306/tcp | Serveur de base de données MariaDB 10.11.14 | Actif |
| ssh.service | 22/tcp | Serveur SSH pour l'accès à distance | Actif |
| inetd.service | 513,514/tcp | Super-serveur internet (rlogin, rsh) | Actif |
| rsyslog.service | - | Service de journalisation système | Actif |
| cron.service | - | Planificateur de tâches | Actif |

**Point d'attention**: La présence du service `inetd` avec les protocoles obsolètes rlogin et rsh est notable.

#### C. Ports réseau ouverts

Pour identifier tous les ports en écoute sur le serveur:

```bash
# Afficher tous les ports TCP et UDP en écoute
sudo ss -tulnp

# Alternative avec netstat
sudo netstat -tulnp
```

**Explication des commandes**:
- `ss`: Socket Statistics - utilitaire moderne pour examiner les sockets réseau
  - `-t`: Affiche les connexions TCP
  - `-u`: Affiche les connexions UDP
  - `-l`: Affiche uniquement les sockets en écoute (listening)
  - `-n`: Affiche les adresses numériques (pas de résolution DNS)
  - `-p`: Affiche le processus associé à chaque socket

**Ports ouverts identifiés**:

![Ports ouverts - ss -tulnp](/img/infrastructure/beforesudo%20ss%20-tulnp.png)

```
LISTEN  0  80  0.0.0.0:80       0.0.0.0:*   users:(("apache2",pid=xxx))
LISTEN  0  128 0.0.0.0:22       0.0.0.0:*   users:(("sshd",pid=xxx))
LISTEN  0  128 0.0.0.0:513      0.0.0.0:*   users:(("inetd",pid=xxx))
LISTEN  0  128 0.0.0.0:514      0.0.0.0:*   users:(("inetd",pid=xxx))
LISTEN  0  80  127.0.0.1:3306   0.0.0.0:*   users:(("mariadbd",pid=xxx))
```

![Ports ouverts - netstat](/img/infrastructure/atlastech-mainserver~$%20sudo%20netstat%20-tulnp.png)

**Analyse de la surface d'attaque**:

| Port | Protocole | Service | Exposition | Risque |
|------|-----------|---------|------------|--------|
| 22 | TCP | SSH | Internet | Moyen - Authentification par mot de passe activée |
| 80 | TCP | HTTP | Internet | Élevé - Pas de chiffrement, injection SQL possible |
| 513 | TCP | rlogin | Internet | Critique - Protocole obsolète non chiffré |
| 514 | TCP | rsh | Internet | Critique - Protocole obsolète non chiffré |
| 3306 | TCP | MariaDB | Localhost uniquement | Faible - Exposition limitée |

#### D. Configuration Apache

Pour examiner la configuration du serveur web:

```bash
# Version d'Apache
apache2 -v

# Lister les sites activés
ls -la /etc/apache2/sites-enabled/

# Afficher la configuration du VirtualHost par défaut
cat /etc/apache2/sites-enabled/000-default.conf
```

**Explication**:
- Apache est le serveur web HTTP le plus utilisé au monde
- VirtualHost: Configuration permettant d'héberger plusieurs sites sur un même serveur
- sites-enabled: Répertoire contenant les liens symboliques vers les configurations actives

**Configuration actuelle**:

![Configuration VirtualHost Apache](/img/infrastructure/beforecat%20etcapache2sites-enabled000-default.conf.png)

```apache
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

![Sites Apache activés](/img/infrastructure/beforels%20-la%20etcapache2sites-enabled.png)

**Points importants**:
- Port d'écoute: 80 (HTTP uniquement, pas de HTTPS)
- DocumentRoot: `/var/www/html` - Racine des fichiers web
- Logs: Journalisation des accès et erreurs dans `/var/log/apache2/`
- Aucun en-tête de sécurité configuré (X-Frame-Options, CSP, HSTS, etc.)

#### E. Structure de l'application web

Pour explorer l'arborescence de l'application:

```bash
# Afficher la structure des fichiers de l'application
ls -la /var/www/html/
ls -la /var/www/html/atlastech/

# Trouver tous les fichiers PHP
find /var/www/html/atlastech/ -maxdepth 2 -type f -name "*.php"
```

**Explication**:
- `find`: Commande de recherche de fichiers
  - `-maxdepth 2`: Limite la recherche à 2 niveaux de profondeur
  - `-type f`: Recherche uniquement les fichiers (pas les répertoires)
  - `-name "*.php"`: Filtre sur les fichiers avec extension .php

**Arborescence de l'application**:

![Structure de l'application web](/img/infrastructure/beforefind%20varwwwhtmlatlastech%20-maxdepth%202%20-type%20f.png)

```
/var/www/html/atlastech/
├── auth/                    # Dossier d'authentification
├── config.php               # Configuration de la base de données
├── login.php                # Page de connexion
├── dashboard.php            # Tableau de bord principal
├── add_employee.php         # Ajout d'employé
├── edit_employee.php        # Modification d'employé
├── delete_employee.php      # Suppression d'employé
├── search.php               # Recherche d'employés
├── export.php               # Export des données
├── admin_backup.php         # Sauvegarde de la base de données
└── Quick-update.php         # Mise à jour rapide
```

![Contenu du répertoire web](/img/infrastructure/beforels%20-la%20varwwwhtml.png)

**Propriétaire et permissions**:

```bash
# Vérifier les permissions
ls -la /var/www/html/atlastech/
```

Tous les fichiers appartiennent à l'utilisateur `www-data` (utilisateur par défaut d'Apache).

---

### 5.2.2 BackupServer - Serveur de sauvegarde (192.168.112.142)

Le BackupServer est dédié à la réception et au stockage des sauvegardes de la base de données.

#### A. Informations système

Commandes pour obtenir les informations du serveur:

```bash
# Connexion SSH
ssh atlastechuser@192.168.112.142

# Informations système
uname -a
lsb_release -a
hostname
ip addr show
hostname -I
```

**Résultats**:

![Configuration réseau BackupServer](/img/infrastructure/ip%20addr%20show%20sur%20BackupServer.png)

```
Noyau: Linux 6.8.0-94-generic
Distribution: Ubuntu 24.04.3 LTS (Noble)
Hostname: atlastech-backupserver
Adresse IPv4: 192.168.112.142/24
```

#### B. Services actifs

Pour lister les services:

```bash
sudo systemctl list-units --type=service --state=running
```

**Services identifiés**:

| Service | Port | Description | État |
|---------|------|-------------|------|
| ssh.service | 22/tcp | Serveur SSH | Actif |
| rsyslog.service | - | Journalisation système | Actif |
| cron.service | - | Planificateur de tâches | Actif |

**Note importante**: Le service rsync ne fonctionne pas en mode daemon autonome dans la configuration actuelle.

#### C. Configuration rsync

Pour vérifier la configuration rsync:

```bash
# Vérifier si rsync est installé
which rsync
rsync --version

# Vérifier le fichier de configuration (si existe)
cat /etc/rsyncd.conf

# Vérifier le statut du service
sudo systemctl status rsync
```

**Explication de rsync**:
- rsync: Utilitaire de synchronisation de fichiers à distance
- Modes de fonctionnement:
  - Mode daemon: rsync écoute sur le port 873
  - Mode SSH: rsync utilise SSH comme transport (port 22)

**État actuel**: 
- rsync est installé mais le fichier `/etc/rsyncd.conf` n'existe pas
- Le service rsync.service n'est pas configuré pour démarrer automatiquement
- Les transferts se font probablement via SSH

#### D. Répertoire de sauvegarde

Pour examiner le répertoire de sauvegarde:

```bash
# Lister le contenu du répertoire de sauvegarde
ls -la /var/backups/
ls -la /var/backups/mysql/

# Vérifier les permissions
stat /var/backups/mysql/
```

**Explication**:
- `stat`: Affiche les informations détaillées sur un fichier ou répertoire (permissions, propriétaire, horodatages)

**Configuration identifiée**:

![Permissions sur le répertoire de sauvegarde](/img/infrastructure/cat%20etcrsyncd.confls-lavarbackupsmysql.png)

```bash
drwxrwxrwx 2 root root 4096 Feb 13 21:34 /var/backups/mysql/
```

**Point critique**: Les permissions 777 permettent à n'importe quel utilisateur du système de lire, écrire et exécuter dans ce répertoire.

#### E. Ports ouverts

```bash
sudo ss -tulnp
```

**Résultat**:

```
LISTEN  0  128  0.0.0.0:22  0.0.0.0:*  users:(("sshd",pid=xxx))
```

Seul le port SSH (22) est ouvert, ce qui est cohérent avec l'absence de service rsync en mode daemon.

---

## 5.3 Postes de travail Windows 10

### 5.3.1 Machine administrateur (192.168.112.137)

#### A. Informations système

Pour obtenir les informations système sur Windows:

```powershell
# Ouvrir PowerShell en tant qu'Administrateur

# Informations complètes sur l'ordinateur
Get-ComputerInfo | Select-Object CsName, OsName, OsVersion, OsArchitecture, CsDomain

# Configuration IP
ipconfig /all

# Informations réseau détaillées
Get-NetIPConfiguration
```

**Explication des commandes PowerShell**:
- `Get-ComputerInfo`: Cmdlet PowerShell qui retourne toutes les informations système
- `Select-Object`: Filtre pour afficher uniquement les propriétés spécifiées
- `ipconfig /all`: Commande Windows classique pour afficher la configuration réseau complète
- `Get-NetIPConfiguration`: Cmdlet PowerShell moderne pour la configuration réseau

**Résultats**:

![Configuration Windows 10](/img/infrastructure/Windows%2010%20avec%20ipconfig.png)

```
Nom de l'ordinateur: WIN-DA9HK0109ND
Système d'exploitation: Microsoft Windows 10 Pro
Version: 10.0.19042
Architecture: 64-bit
Domaine: WORKGROUP (pas de domaine Active Directory)

Configuration réseau:
Interface: Intel(R) 82574L Gigabit Network Connection
Adresse IPv4: 192.168.112.137
Masque de sous-réseau: 255.255.255.0
Passerelle par défaut: 192.168.112.2
Serveur DHCP: 192.168.112.254
Serveurs DNS: 192.168.112.2
```

#### B. Utilisateurs locaux

Pour lister les utilisateurs:

```powershell
# Lister tous les utilisateurs locaux
net user

# Détails sur un utilisateur spécifique
net user a.haidar

# Obtenir les utilisateurs avec PowerShell
Get-LocalUser | Select-Object Name, Enabled, PasswordRequired, LastLogon
```

**Explication**:
- `net user`: Commande Windows classique pour gérer les utilisateurs
- `Get-LocalUser`: Cmdlet PowerShell pour obtenir les comptes locaux
- LastLogon: Date de la dernière connexion de l'utilisateur

**Utilisateurs créés**:

![Liste des utilisateurs Windows](/img/infrastructure/net%20user.png)

Total de 24 employés créés selon le script `create_users.bat`.

**Répartition par département**:

| Département | Nombre | Exemples d'utilisateurs |
|-------------|--------|------------------------|
| Direction Générale | 1 | a.haidar (Administrateur) |
| IT | 3 | oumayma.l, ibtissam.g, soufiane.k |
| Développement | 6 | karim.dev, fatima.z, younes.m |
| RH | 3 | lhassan.rh (Power User), samira.t |
| Finance | 3 | ahmed.cfo (Power User), latifa.cpta |
| Commercial/Marketing | 8 | yasmine.cm (Power User), hakim.sales |

#### C. Groupes locaux

Pour afficher les groupes et leurs membres:

```powershell
# Lister tous les groupes locaux
net localgroup

# Membres du groupe Administrateurs
net localgroup Administrateurs

# Avec PowerShell
Get-LocalGroup
Get-LocalGroupMember -Group "Administrateurs"
```

**Explication**:
- Groupes locaux: Définissent les niveaux de privilèges sur la machine
- Administrateurs: Groupe avec les privilèges les plus élevés
- Power Users: Groupe avec des privilèges élevés mais limités (obsolète dans Windows 10)

**Groupes identifiés**:

| Groupe | Membres | Privilèges |
|--------|---------|-----------|
| Administrateurs | a.haidar | Contrôle total sur la machine |
| Utilisateurs avec pouvoir | lhassan.rh, ahmed.cfo, yasmine.cm | Privilèges étendus mais limités |
| Utilisateurs | Tous les autres employés | Privilèges standards |

#### D. Politique de sécurité locale

Pour examiner la politique de sécurité:

```powershell
# Afficher la politique de compte
net accounts

# Exporter la politique de sécurité complète
secedit /export /cfg C:\security_policy.cfg

# Afficher le contenu
Get-Content C:\security_policy.cfg
```

**Explication**:
- `net accounts`: Affiche les paramètres de la politique de compte (durée de vie du mot de passe, verrouillage, etc.)
- `secedit`: Utilitaire d'édition de la configuration de sécurité
- `/export`: Exporte la configuration actuelle vers un fichier

**Politique actuelle**:

```
Durée de vie maximale du mot de passe: 42 jours
Durée de vie minimale du mot de passe: 0 jours
Longueur minimale du mot de passe: 0 caractères
Historique des mots de passe: 0 mots de passe mémorisés
Seuil de verrouillage: Jamais
```

**Point critique**: Aucune exigence de complexité de mot de passe n'est configurée.

#### E. Configuration du pare-feu Windows

Pour vérifier le pare-feu:

```powershell
# Statut des profils de pare-feu
Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction

# Règles entrantes actives
Get-NetFirewallRule -Direction Inbound -Enabled True | Select-Object DisplayName, Action

# Règles sortantes actives
Get-NetFirewallRule -Direction Outbound -Enabled True | Select-Object DisplayName, Action
```

**Explication**:
- Windows Firewall: Pare-feu intégré à Windows
- Profils: Domaine, Privé, Public (configurations différentes selon le type de réseau)
- Règles entrantes: Contrôlent le trafic entrant vers la machine
- Règles sortantes: Contrôlent le trafic sortant de la machine

**Configuration identifiée**:

| Profil | État | Action par défaut (entrant) | Action par défaut (sortant) |
|--------|------|----------------------------|----------------------------|
| Domaine | Activé | Bloquer | Autoriser |
| Privé | Activé | Bloquer | Autoriser |
| Public | Activé | Bloquer | Autoriser |

#### F. Test de connectivité vers MainServer

Pour tester l'accès au serveur principal:

```powershell
# Test ping
ping 192.168.112.141

# Test de connexion au port HTTP (80)
Test-NetConnection -ComputerName 192.168.112.141 -Port 80

# Test de connexion au port HTTPS (443)
Test-NetConnection -ComputerName 192.168.112.141 -Port 443

# Test avec curl
curl.exe -I http://192.168.112.141/atlastech/
curl.exe -kI https://192.168.112.141/atlastech/
```

**Explication**:
- `ping`: Envoie des paquets ICMP pour tester la connectivité réseau
- `Test-NetConnection`: Cmdlet PowerShell pour tester les connexions TCP
- `curl`: Utilitaire pour effectuer des requêtes HTTP/HTTPS
  - `-I`: Affiche uniquement les en-têtes HTTP
  - `-k`: Ignore les erreurs de certificat SSL

**Résultats**:

![Test ping vers MainServer](/img/infrastructure/ping%20192.168.112.141.png)

```
Ping vers 192.168.112.141: Réussi (TTL=64)
Port 80 (HTTP): Ouvert
Port 443 (HTTPS): Fermé (pas de service HTTPS configuré)
```

![Test nslookup](/img/infrastructure/nslookup%20atlastech.local.png)

---

## 5.4 Applications déployées

### 5.4.1 Application Web PHP (Site Commercial)

L'application web est accessible via `http://192.168.112.141/atlastech/`.

#### A. Page de connexion (login.php)

![Page de connexion AtlasTech](/img/infrastructure/Screenshot2026-02-011015700.png)

**URL d'accès**: `http://192.168.112.141/atlastech/login.php`

**Caractéristiques de la page**:
- Titre: "Connexion - AtlasTech Solutions"
- Slogan: "Système de gestion des ressources humaines"
- Champs: Nom d'utilisateur, Mot de passe
- Option "Se souvenir de moi"
- Bouton "Se connecter"
- Affichage de l'adresse IP du client: `192.168.112.137`
- Date et heure affichées au format: `2026-02-13 22:26:35`

**Point d'attention**: Le protocole HTTP (non chiffré) est utilisé, visible par l'icône "Not secure" dans le navigateur.

#### B. Code source de login.php

Pour examiner le code:

```bash
# Sur le MainServer
cat /var/www/html/atlastech/login.php
```

**Extrait du code vulnérable**:

```php
<?php
session_start();
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $utilisateur = $_POST['utilisateur'];
    $mot_de_passe = $_POST['mot_de_passe'];
    
    // VULNÉRABILITÉ: Concaténation directe dans la requête SQL
    $query = "SELECT * FROM employes WHERE utilisateur = '$utilisateur' AND mot_de_passe = '$mot_de_passe'";
    
    $result = mysqli_query($conn, $query);
    
    if ($row = mysqli_fetch_assoc($result)) {
        $_SESSION['user_id'] = $row['id'];
        $_SESSION['username'] = $row['utilisateur'];
        $_SESSION['is_admin'] = $row['is_admin'];
        header('Location: dashboard.php');
        exit();
    } else {
        $error = "Identifiants incorrects";
    }
}
?>
```

**Analyse du code**:

1. **Absence de préparation de requête**: Les variables `$utilisateur` et `$mot_de_passe` sont directement concaténées dans la requête SQL
2. **Pas de validation des entrées**: Aucun filtrage ou échappement des données utilisateur
3. **Comparaison de mot de passe en clair**: Le mot de passe est comparé directement sans hachage
4. **Vulnérabilité d'injection SQL**: Un attaquant peut injecter du code SQL via les champs de formulaire

**Exemple d'exploitation**:
```sql
Utilisateur: admin' OR '1'='1
Mot de passe: anything
Requête générée: SELECT * FROM employes WHERE utilisateur = 'admin' OR '1'='1' AND mot_de_passe = 'anything'
```

#### C. Fichier de configuration (config.php)

Pour examiner la configuration:

```bash
cat /var/www/html/atlastech/config.php
```

![Fichier config.php avec identifiants en clair](/img/infrastructure/cat%20varwwwhtmlatlastechconfig.php.png)

**Contenu du fichier**:

```php
<?php
$host = 'localhost';
$dbname = 'atlastech_db';
$username = 'atlastech_user';
$password = 'password123';  // MOT DE PASSE EN CLAIR

try {
    $conn = new mysqli($host, $username, $password, $dbname);
    
    if ($conn->connect_error) {
        die("Échec de la connexion: " . $conn->connect_error);
    }
    
    $conn->set_charset("utf8mb4");
    
} catch (Exception $e) {
    die("Erreur de connexion à la base de données");
}
?>
```

**Points critiques**:

1. **Identifiants hardcodés**: Le mot de passe de la base de données est écrit en clair dans le fichier
2. **Mot de passe trivial**: `password123` est un mot de passe faible et facilement devinable
3. **Gestion d'erreur**: Les messages d'erreur peuvent révéler des informations sur la structure de la base de données
4. **Permissions du fichier**: Tout utilisateur ayant accès au serveur web peut lire ce fichier

### 5.4.2 Application CRUD RH (Module interne)

#### A. Dashboard principal (dashboard.php)

![Dashboard après connexion](/img/infrastructure/Screenshot2026-02-08022255.png)

**Fonctionnalités visibles**:

1. **En-tête**:
   - Logo et nom de l'entreprise: "AtlasTech Solutions"
   - Utilisateur connecté: "Connecté en tant que: a.haidar"
   - Bouton de déconnexion

2. **Mode Administrateur**:
   - Bannière orange indiquant les privilèges élevés
   - Bouton "Télécharger backup DB" pour exporter la base de données

3. **Liste des employés (25 employés)**:
   - Boutons d'action:
     - "Ajouter employé"
     - "Rechercher"
     - "Exporter Excel"
   
4. **Tableau des employés**:
   
   | Colonne | Description |
   |---------|-------------|
   | ID | Identifiant unique de l'employé |
   | Nom complet | Prénom et nom |
   | Département | Service de rattachement |
   | Poste | Fonction occupée |
   | Type contrat | CDI, CDD, etc. |
   | Salaire (MAD) | Rémunération mensuelle |
   | CIN | Numéro de carte d'identité nationale |
   | Numéro CNOPS | Numéro d'affiliation à la CNOPS |
   | Actions | Boutons pour voir détails, modifier, supprimer |

**Exemple de données affichées**:

| ID | Nom | Département | Poste | Salaire |
|----|-----|-------------|-------|---------|
| 1 | Abdelaziz Haidar | Direction Generale | Directeur General | 500.00 MAD |
| 2 | Oumayma Lafridi | Informatique | Admin Systemes | 14,500.00 MAD |
| 3 | Ibtissam Elghbali | Informatique | Responsable Reseaux | 13,200.00 MAD |

#### B. Fichier search.php (Recherche d'employés)

Pour examiner le code de recherche:

```bash
cat /var/www/html/atlastech/search.php
```

**Code vulnérable**:

```php
<?php
require_once 'config.php';

$search_term = $_GET['search'];

// VULNÉRABILITÉ: Injection SQL via UNION
$query = "SELECT id, utilisateur, email, poste, departement_id, salaire 
          FROM employes 
          WHERE utilisateur LIKE '%$search_term%' 
             OR email LIKE '%$search_term%' 
             OR poste LIKE '%$search_term%'";

$result = mysqli_query($conn, $query);

$employees = [];
while ($row = mysqli_fetch_assoc($result)) {
    $employees[] = $row;
}

echo json_encode($employees);
?>
```

**Vulnérabilité UNION SQL Injection**:

Cette page est vulnérable à l'injection SQL de type UNION qui permet d'extraire des données de n'importe quelle table.

**Exemple d'exploitation**:

```
http://192.168.112.141/atlastech/search.php?search=' UNION SELECT 1,2,3,4,5,6 FROM employes--

Permet de déterminer le nombre de colonnes, puis:

http://192.168.112.141/atlastech/search.php?search=' UNION SELECT id,utilisateur,mot_de_passe,email,poste,salaire FROM employes--
```

#### C. Fichier admin_backup.php

Pour examiner le fichier de sauvegarde:

```bash
cat /var/www/html/atlastech/admin_backup.php
```

**Code du fichier**:

```php
<?php
// VULNÉRABILITÉ: Pas d'authentification requise

header('Content-Type: application/sql');
header('Content-Disposition: attachment; filename="atlastech_backup_' . date('Y-m-d') . '.sql"');

$host = 'localhost';
$user = 'root';
$pass = 'P@ssw0rd123';  // MOT DE PASSE ROOT EN CLAIR
$db = 'atlastech_db';

$command = "mysqldump -u $user -p'$pass' $db";

system($command);
?>
```

**Vulnérabilités critiques**:

1. **Aucune authentification**: N'importe qui peut télécharger la base de données
2. **Mot de passe root exposé**: Le mot de passe root de MySQL est en clair
3. **Export complet**: Toute la base de données est exportée sans filtrage
4. **URL accessible publiquement**: `http://192.168.112.141/atlastech/admin_backup.php`

#### D. Fichier export.php

```bash
cat /var/www/html/atlastech/export.php
```

**Code du fichier**:

```php
<?php
require_once 'config.php';

header('Content-Type: text/csv; charset=utf-8');
header('Content-Disposition: attachment; filename="employes_' . date('Y-m-d') . '.csv"');

$output = fopen('php://output', 'w');

// En-têtes CSV
fputcsv($output, ['ID', 'Utilisateur', 'Mot de passe', 'Email', 'Poste', 'Salaire']);

$query = "SELECT id, utilisateur, mot_de_passe, email, poste, salaire FROM employes";
$result = mysqli_query($conn, $query);

while ($row = mysqli_fetch_assoc($result)) {
    fputcsv($output, $row);
}

fclose($output);
?>
```

**Problème majeur**: Ce fichier exporte les mots de passe des employés en clair dans un fichier CSV.

---

## 5.5 Serveurs LAMP

### 5.5.1 Composants de la stack LAMP

LAMP est un acronyme désignant:
- **L**inux: Système d'exploitation (Ubuntu 24.04.3 LTS)
- **A**pache: Serveur web HTTP (version 2.4.58)
- **M**ySQL: Système de gestion de base de données (MariaDB 10.11.14)
- **P**HP: Langage de programmation côté serveur (version à déterminer)

#### A. Linux - Ubuntu 24.04.3 LTS

**Commande pour vérifier**:

```bash
lsb_release -a
```

**Résultat**:
```
Distributor ID: Ubuntu
Description: Ubuntu 24.04.3 LTS
Release: 24.04
Codename: noble
```

**Caractéristiques**:
- Version LTS (Long Term Support): Support jusqu'en avril 2029
- Noyau: Linux 6.8.0-94-generic
- Architecture: x86_64 (64 bits)

#### B. Apache HTTP Server 2.4.58

**Commandes pour examiner Apache**:

```bash
# Version d'Apache
apache2 -v

# Modules activés
apache2ctl -M

# Configuration des sites
ls -la /etc/apache2/sites-available/
ls -la /etc/apache2/sites-enabled/
```

**Explication**:
- `apache2 -v`: Affiche la version d'Apache et la date de compilation
- `apache2ctl -M`: Liste tous les modules Apache chargés
- sites-available: Configurations de sites disponibles
- sites-enabled: Configurations de sites actifs (liens symboliques vers sites-available)

**Modules Apache chargés**:

| Module | Fonction |
|--------|----------|
| core_module | Fonctionnalités de base d'Apache |
| mpm_prefork_module | Modèle de processus multi-processus |
| http_module | Protocole HTTP |
| so_module | Chargement dynamique de modules |
| php_module | Interpréteur PHP intégré |
| rewrite_module | Réécriture d'URL |
| ssl_module | Support SSL/TLS (chargé mais non utilisé) |
| headers_module | Manipulation des en-têtes HTTP |

**Configuration actuelle**:

```apache
# Port d'écoute
Listen 80

# Utilisateur et groupe d'exécution
User www-data
Group www-data

# DocumentRoot par défaut
DocumentRoot /var/www/html

# Fichiers index
DirectoryIndex index.php index.html index.htm
```

**Points notables**:
- Aucun VirtualHost HTTPS configuré
- Module SSL chargé mais non utilisé
- Aucune redirection HTTP vers HTTPS
- Absence d'en-têtes de sécurité

#### C. Version de PHP

**Commande pour vérifier**:

```bash
php -v

# Afficher la configuration PHP
php -i | head -20
```

**Explication**:
- `php -v`: Affiche la version de PHP et les informations de compilation
- `php -i`: Équivalent en ligne de commande de `phpinfo()`

**Extensions PHP installées**:

```bash
php -m
```

**Extensions critiques pour l'application**:

| Extension | Rôle |
|-----------|------|
| mysqli | Connexion à MySQL/MariaDB |
| pdo_mysql | PDO pour MySQL (alternative à mysqli) |
| session | Gestion des sessions utilisateur |
| json | Manipulation de données JSON |
| mbstring | Gestion des chaînes multi-octets |

---

## 5.6 Base de données MySQL/MariaDB

### 5.6.1 Informations sur le serveur de base de données

**Commandes pour accéder à MySQL**:

```bash
# Connexion en tant que root
sudo mysql -u root

# Vérifier la version
mysql --version

# Ou depuis le shell MySQL
SELECT VERSION();
```

**Explication**:
- MariaDB: Fork open-source de MySQL créé par les développeurs originaux de MySQL
- Compatible avec MySQL mais avec des fonctionnalités supplémentaires
- `sudo mysql -u root`: Connexion root sans mot de passe (authentification via socket Unix)

**Version installée**:

```
mysql  Ver 15.1 Distrib 10.11.14-MariaDB, for debian-linux-gnu (x86_64)
```

### 5.6.2 Bases de données existantes

**Commande**:

```sql
SHOW DATABASES;
```

**Résultat**:

| Database | Fonction |
|----------|----------|
| atlastech_db | Base de données de l'application |
| information_schema | Métadonnées sur toutes les bases de données |
| mysql | Base système de MySQL (utilisateurs, privilèges) |
| performance_schema | Données de performance du serveur |
| sys | Vues simplifiées de performance_schema |

### 5.6.3 Structure de la base atlastech_db

**Commande pour lister les tables**:

```sql
USE atlastech_db;
SHOW TABLES;
```

**Tables identifiées**:

![Liste des tables dans atlastech_db](/img/infrastructure/USE%20atlastech_db;SHOW%20TABLES;.png)

| Table | Description |
|-------|-------------|
| employes | Informations sur les employés (25 enregistrements) |
| departements | Liste des départements (6 départements) |
| informations_entreprise | Données de l'entreprise |
| vue_credentials | Vue exposant les identifiants |
| vue_all_data | Vue consolidée de toutes les données |
| vue_salaires | Informations salariales |

#### A. Table employes

**Commande pour voir la structure**:

```sql
DESCRIBE employes;
```

![Structure de la table employes](/img/infrastructure/DESCRIBE%20employes;.png)

**Structure de la table**:

| Champ | Type | Null | Clé | Défaut | Extra |
|-------|------|------|-----|--------|-------|
| id | int(11) | NO | PRI | NULL | auto_increment |
| utilisateur | varchar(50) | YES | | NULL | |
| mot_de_passe | varchar(255) | YES | | NULL | |
| prenom | varchar(100) | YES | | NULL | |
| nom | varchar(100) | YES | | NULL | |
| email | varchar(150) | YES | | NULL | |
| departement_id | int(11) | YES | | NULL | |
| poste | varchar(100) | YES | | NULL | |
| type_contrat | varchar(20) | YES | | NULL | |
| salaire | decimal(10,2) | YES | | NULL | |
| cin | varchar(20) | YES | | NULL | |
| ville | varchar(100) | YES | | NULL | |
| numero_cnops | varchar(13) | YES | | NULL | |
| statut_cnops | varchar(20) | YES | | NULL | |
| is_admin | varchar(10) | YES | | NULL | |
| commentaires | text | YES | | NULL | |

**Point critique**: Le champ `mot_de_passe` stocke les mots de passe en texte clair (type varchar).

#### B. Exemple de données sensibles

**Commande**:

```sql
SELECT id, utilisateur, mot_de_passe, email, poste, salaire 
FROM employes 
LIMIT 5;
```

**Résultat**:

| id | utilisateur | mot_de_passe | email | poste | salaire |
|----|-------------|--------------|-------|-------|---------|
| 1 | a.haidar | DG2024! | a.haidar@company.ma | Directeur General | 500.00 |
| 2 | oumayma.l | Oum1234! | o.lafridi@company.ma | Admin Systemes | 14500.00 |
| 3 | ibtissam.g | Ibti2024 | i.elghbali@company.ma | Responsable Reseaux | 13200.00 |
| 4 | soufiane.k | SoufPass | s.karzaba@company.ma | Technicien Support | 8500.00 |
| 5 | karim.dev | DevKarim99 | k.benali@company.ma | Lead Developer | 18000.00 |

**Observations**:

1. **Mots de passe en clair**: Tous les mots de passe sont visibles sans hachage
2. **Mots de passe faibles**: Patterns prévisibles (prenom + chiffres, etc.)
3. **Données sensibles**: Les salaires sont accessibles directement

#### C. Table departements

**Commande**:

```sql
SELECT * FROM departements;
```

**Résultat**:

| id | nom_departement | responsable |
|----|-----------------|-------------|
| 1 | Direction Generale | Abdelaziz Haidar |
| 2 | Informatique | Oumayma Lafridi |
| 3 | Developpement | Karim Benali |
| 4 | Ressources Humaines | Lhassan |
| 5 | Finance | Ahmed |
| 6 | Commercial et Marketing | Yasmine |

### 5.6.4 Utilisateurs MySQL et privilèges

**Commande pour lister les utilisateurs**:

```sql
SELECT User, Host FROM mysql.user;
```

![Liste des utilisateurs MySQL](/img/infrastructure/SELECT%20User,Host%20FROMmysql.user;.png)

**Résultat**:

| User | Host |
|------|------|
| root | localhost |
| atlastech_user | % |
| admin | % |
| mysql | localhost |
| mariadb.sys | localhost |

**Explication du champ Host**:
- `localhost`: Connexion uniquement depuis la machine locale
- `%`: Connexion autorisée depuis n'importe quelle adresse IP

#### A. Privilèges de atlastech_user

**Commande**:

```sql
SHOW GRANTS FOR 'atlastech_user'@'%';
```

**Résultat**:

```sql
GRANT USAGE ON *.* TO 'atlastech_user'@'%' 
IDENTIFIED BY PASSWORD '*A0F874BC7F54EE086FCE60A37CE7887D8B31086B'

GRANT ALL PRIVILEGES ON atlastech_db.* TO 'atlastech_user'@'%'
```

**Analyse**:
- Mot de passe hashé: `password123` (hash SHA1 faible)
- ALL PRIVILEGES sur atlastech_db: Lecture, écriture, modification de structure
- Connexion autorisée depuis n'importe où (%)

#### B. Privilèges de admin

**Commande**:

```sql
SHOW GRANTS FOR 'admin'@'%';
```

**Résultat**:

```sql
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' 
IDENTIFIED BY PASSWORD '*4ACFE3202A5FF5CF467898FC58AAB1D615029441' 
WITH GRANT OPTION
```

**Point critique**: 
- ALL PRIVILEGES sur toutes les bases de données (`*.*`)
- WITH GRANT OPTION: Peut créer d'autres utilisateurs et leur donner des privilèges
- Connexion autorisée depuis n'importe où
- Mot de passe hashé: `admin` (mot de passe trivial)

### 5.6.5 Configuration de sécurité MySQL

**Commande pour examiner les variables**:

```sql
SHOW VARIABLES LIKE '%version%';
SHOW VARIABLES LIKE 'bind%';
SHOW VARIABLES LIKE 'ssl%';
```

**Variables importantes**:

| Variable | Valeur | Signification |
|----------|--------|---------------|
| version | 10.11.14-MariaDB | Version du serveur |
| bind-address | 127.0.0.1 | Écoute uniquement sur localhost |
| have_ssl | YES | Support SSL disponible |
| ssl_cert | (vide) | Pas de certificat SSL configuré |

**Point positif**: Le serveur MySQL écoute uniquement sur localhost (127.0.0.1), ce qui limite l'exposition.

---

## 5.7 Flux de données

### 5.7.1 Flux de connexion utilisateur

```
1. Utilisateur (192.168.112.137)
   ↓
   HTTP GET http://192.168.112.141/atlastech/login.php
   ↓
2. Apache (192.168.112.141:80)
   ↓
   Traite la requête PHP
   ↓
3. PHP exécute login.php
   ↓
   Connexion à MySQL
   ↓
4. MariaDB (127.0.0.1:3306)
   ↓
   Requête SQL: SELECT * FROM employes WHERE...
   ↓
   Retourne les données
   ↓
5. PHP crée la session
   ↓
   Redirection vers dashboard.php
   ↓
6. Utilisateur voit le dashboard
```

**Points d'attention**:
- Aucun chiffrement entre l'utilisateur et le serveur (HTTP)
- Mots de passe transmis en clair sur le réseau
- Sessions stockées côté serveur sans paramètres de sécurité renforcés

### 5.7.2 Flux de sauvegarde de la base de données

```
1. Tâche cron sur MainServer (192.168.112.141)
   ↓
   Exécution de: /usr/bin/mysqldump -u root -p'P@ssw0rd123' atlastech_db
   ↓
2. mysqldump se connecte à MariaDB
   ↓
   Extraction complète de la base
   ↓
3. Sauvegarde écrite dans /backup.sql
   ↓
4. rsync vers BackupServer
   ↓
   rsync -av /backup.sql atlastechuser@192.168.112.142:/var/backups/mysql/
   ↓
5. BackupServer (192.168.112.142)
   ↓
   Fichier stocké dans /var/backups/mysql/ (permissions 777)
```

**Vulnérabilités du flux**:

1. **Mot de passe en clair dans crontab**:

```bash
# Afficher le crontab
sudo crontab -l
```

![Crontab avec mot de passe en clair](/img/infrastructure/sudo%20crontab%20-lcat%20etccrontab.png)

Résultat:
```bash
30 2 * * * root /usr/bin/mysqldump -u root -p'P@ssw0rd123' atlastech_db > /backup.sql
```

2. **Mot de passe visible dans la liste des processus**:

Pendant l'exécution de mysqldump:
```bash
ps aux | grep mysqldump
```

Affiche le mot de passe en clair dans la ligne de commande.

3. **Fichier de sauvegarde non chiffré**:
   - /backup.sql est stocké en texte clair
   - Lisible par n'importe quel utilisateur si les permissions sont incorrectes

4. **Transfer rsync non chiffré**:
   - Si rsync est configuré sur le port 873 (mode daemon), le transfert n'est pas chiffré
   - Mot de passe potentiellement transmis en clair

### 5.7.3 Flux de recherche d'employés

```
1. Utilisateur saisit un terme de recherche dans le dashboard
   ↓
   JavaScript envoie une requête AJAX
   ↓
2. GET http://192.168.112.141/atlastech/search.php?search=terme
   ↓
3. Apache traite la requête
   ↓
   PHP exécute search.php
   ↓
4. Requête SQL non préparée:
   SELECT * FROM employes WHERE utilisateur LIKE '%terme%'
   ↓
5. MariaDB retourne les résultats
   ↓
6. PHP encode en JSON
   ↓
7. Réponse HTTP au navigateur
   ↓
8. JavaScript affiche les résultats
```

**Vulnérabilité**: Injection SQL possible à l'étape 2 en manipulant le paramètre `search`.

---

## 5.8 Tests depuis Kali Linux

### 5.8.1 Configuration de Kali Linux

#### A. Informations système

**Commandes**:

```bash
# Version de Kali
cat /etc/os-release

# Interface réseau
ip addr show

# Version des outils
nmap --version
sqlmap --version
nikto -Version
```

**Configuration identifiée**:

![Configuration Kali Linux](/img/infrastructure/kali%20Linux%20(Machine%20de%20Pentest).png)

```
Système: Kali Linux 2024.4
Adresse IP: 192.168.112.128/24
Interface: eth0
Gateway: 192.168.112.2
```

![Adresse IP Kali Linux](/img/infrastructure/ip%20addr%20show%20sur%20Kali%20Linux.png)

#### B. Outils de pentest installés

| Outil | Version | Fonction |
|-------|---------|----------|
| Nmap | 7.95 | Scan de ports et détection de services |
| SQLMap | 1.9.8 | Exploitation d'injections SQL |
| Nikto | 2.5.0 | Scanner de vulnérabilités web |
| Metasploit | 6.4.84-dev | Framework d'exploitation |
| Burp Suite | 2025.12.5 | Proxy d'interception HTTP |

### 5.8.2 Scan de ports avec Nmap

**Commande pour scanner MainServer**:

```bash
nmap -sV -sC -p 22,80,443,513,514,873,3306 192.168.112.141
```

**Explication de la commande**:
- `nmap`: Network Mapper - outil de découverte réseau et d'audit de sécurité
- `-sV`: Détection de version des services
- `-sC`: Exécution des scripts par défaut de Nmap (détection de vulnérabilités communes)
- `-p 22,80,...`: Spécifie les ports à scanner
- Ports ciblés:
  - 22: SSH
  - 80: HTTP
  - 443: HTTPS
  - 513: rlogin
  - 514: rsh
  - 873: rsync
  - 3306: MySQL

**Résultat du scan**:

```
Starting Nmap 7.95

PORT     STATE  SERVICE    VERSION
22/tcp   open   ssh        OpenSSH 9.6p1 Ubuntu (protocol 2.0)
80/tcp   open   http       Apache httpd 2.4.58 ((Ubuntu))
443/tcp  closed https
513/tcp  open   login      
514/tcp  open   shell      
873/tcp  closed rsync
3306/tcp closed mysql

Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

**Analyse des résultats**:

| Port | État | Service | Remarque |
|------|------|---------|----------|
| 22 | Ouvert | SSH | Accès distant sécurisé |
| 80 | Ouvert | HTTP | **Non chiffré - critique** |
| 443 | Fermé | HTTPS | Pas de service SSL/TLS |
| 513 | Ouvert | rlogin | **Protocole obsolète - critique** |
| 514 | Ouvert | rsh | **Protocole obsolète - critique** |
| 873 | Fermé | rsync | Pas de daemon rsync actif |
| 3306 | Fermé | MySQL | Écoute uniquement sur localhost (127.0.0.1) |

### 5.8.3 Scan de vulnérabilités web avec Nikto

**Commande**:

```bash
nikto -h http://192.168.112.141/atlastech/ -Tuning 1,2,3,4,5,6
```

**Explication de la commande**:
- `nikto`: Scanner de vulnérabilités pour serveurs web
- `-h`: Spécifie l'hôte cible
- `-Tuning`: Sélectionne les catégories de tests
  - 1: Tests intéressants
  - 2: Mauvaise configuration
  - 3: Divulgation d'information
  - 4: Injection (XSS/Script/HTML)
  - 5: Récupération de fichiers à distance
  - 6: Déni de service

**Résultat du scan** (extrait):

```
- Nikto v2.5.0
---------------------------------------------------------------------------
+ Target IP:          192.168.112.141
+ Target Hostname:    192.168.112.141
+ Target Port:        80
+ Start Time:         2026-02-13 16:38:49
---------------------------------------------------------------------------
+ Server: Apache/2.4.58 (Ubuntu)
+ The anti-clickjacking X-Frame-Options header is not present.
+ The X-Content-Type-Options header is not set.
+ No CGI Directories found
+ Server may leak inodes via ETags
+ Allowed HTTP Methods: GET, POST, OPTIONS, HEAD
+ OSVDB-3268: /atlastech/: Directory indexing found.
+ OSVDB-3092: /atlastech/login.php: This might be interesting...
+ 7915 requests: 0 error(s) and 7 item(s) reported on remote host
```

**Vulnérabilités détectées**:

1. **Absence d'en-têtes de sécurité**:
   - X-Frame-Options: Permet le clickjacking
   - X-Content-Type-Options: Permet le MIME sniffing
   - Content-Security-Policy: Pas de politique de sécurité du contenu

2. **Directory indexing**: Les fichiers du répertoire peuvent être listés

3. **Fichiers sensibles accessibles**: login.php, config.php, etc.

### 5.8.4 Test d'injection SQL avec SQLMap

**Commande pour tester login.php**:

```bash
sqlmap -u "http://192.168.112.141/atlastech/login.php" \
  --data="utilisateur=test&mot_de_passe=test" \
  --batch \
  --level=1 \
  --risk=1
```

**Explication de la commande**:
- `sqlmap`: Outil automatisé de détection et exploitation d'injections SQL
- `-u`: URL cible
- `--data`: Données POST à envoyer
- `--batch`: Mode automatique (accepte les valeurs par défaut)
- `--level=1`: Niveau de tests (1-5, 1 étant le plus rapide)
- `--risk=1`: Niveau de risque des tests (1-3)

**Résultat attendu**:

```
[16:40:12] [INFO] testing connection to the target URL
[16:40:12] [INFO] testing if the target URL is stable
[16:40:13] [INFO] target URL is stable
[16:40:13] [INFO] testing if POST parameter 'utilisateur' is dynamic
[16:40:13] [WARNING] POST parameter 'utilisateur' does not appear to be dynamic
[16:40:13] [INFO] heuristic (basic) test shows that POST parameter 'utilisateur' might be injectable (possible DBMS: 'MySQL')
[16:40:14] [INFO] testing for SQL injection on POST parameter 'utilisateur'
it looks like the back-end DBMS is 'MySQL'. Do you want to skip test payloads specific for other DBMSes? [Y/n] Y
[16:40:15] [INFO] POST parameter 'utilisateur' appears to be 'MySQL >= 5.0 AND error-based - WHERE, HAVING, ORDER BY or GROUP BY clause (FLOOR)' injectable
```

**Conclusion**: Le paramètre `utilisateur` est vulnérable à l'injection SQL.

### 5.8.5 Test des services obsolètes (rlogin/rsh)

#### A. Test de rlogin

**Commande**:

```bash
rlogin 192.168.112.141
```

**Explication**:
- `rlogin`: Remote Login - protocole d'accès distant non chiffré des années 1980
- Permet de se connecter à un système distant sans chiffrement
- Vulnérable aux attaques de type "man-in-the-middle"
- Remplacé par SSH dans les systèmes modernes

**Résultat attendu**:
```
Trying 192.168.112.141...
Connected to 192.168.112.141.
```

Si le service répond, cela confirme que rlogin est actif.

#### B. Test de rsh

**Commande**:

```bash
rsh 192.168.112.141 whoami
```

**Explication**:
- `rsh`: Remote Shell - permet d'exécuter des commandes sur un système distant
- Protocole non chiffré et non authentifié
- Même vulnérabilités que rlogin

**Résultat**:

Si le service répond, il exécutera la commande `whoami` sur le serveur distant.

#### C. Test avec Netcat

**Commande**:

```bash
# Test du port 513 (rlogin)
nc -v 192.168.112.141 513

# Test du port 514 (rsh)
nc -v 192.168.112.141 514
```

**Explication**:
- `nc` (netcat): Utilitaire réseau polyvalent
- `-v`: Mode verbeux (affiche plus d'informations)
- Permet de se connecter à n'importe quel port TCP/UDP
- Utile pour tester la disponibilité des services

**Résultat**:

```
Connection to 192.168.112.141 513 port [tcp/login] succeeded!
Connection to 192.168.112.141 514 port [tcp/shell] succeeded!
```

Cela confirme que les ports sont ouverts et que les services répondent.

### 5.8.6 Test du service rsync sur BackupServer

**Commande**:

```bash
# Test de connexion au port 873 (rsync en mode daemon)
rsync rsync://192.168.112.142:873/

# Test avec netcat
nc -v 192.168.112.142 873
```

**Explication**:
- `rsync`: Outil de synchronisation de fichiers
- Mode daemon: rsync écoute sur le port 873
- Format d'URL: `rsync://hôte:port/module`

**Résultat attendu si le service est actif**:

```
@RSYNCD: 31.0
Liste des modules disponibles...
```

**Résultat actuel**:

```
Connection refused
```

Cela indique que rsync n'est pas configuré en mode daemon sur le port 873.

---

## 5.9 Synthèse de l'infrastructure actuelle

### 5.9.1 Points forts identifiés

1. **Séparation des rôles**:
   - Serveur web dédié (MainServer)
   - Serveur de sauvegarde dédié (BackupServer)
   - Machine de pentest isolée (Kali)

2. **MySQL localhost uniquement**:
   - La base de données n'est pas exposée directement sur le réseau
   - Connexion uniquement via 127.0.0.1

3. **Journalisation basique**:
   - rsyslog actif
   - Logs Apache (access.log, error.log)

4. **Structure d'application organisée**:
   - Séparation des fichiers PHP par fonction
   - Organisation claire du code

### 5.9.2 Vulnérabilités critiques identifiées

| Catégorie | Vulnérabilité | Gravité | Impact |
|-----------|---------------|---------|--------|
| Authentification | Mots de passe en clair dans la BD | Critique | Compromission de tous les comptes |
| Injection | SQL Injection dans login.php | Critique | Accès non autorisé à l'application |
| Injection | SQL Injection dans search.php | Critique | Extraction de données sensibles |
| Accès | admin_backup.php sans authentification | Critique | Vol de la base de données complète |
| Chiffrement | HTTP uniquement (pas de HTTPS) | Élevé | Interception des credentials |
| Services obsolètes | rlogin/rsh actifs | Critique | Accès non chiffré au système |
| Configuration | Permissions 777 sur /var/backups/mysql/ | Élevé | Accès non autorisé aux sauvegardes |
| Mots de passe | password123, admin, etc. | Critique | Mots de passe triviaux |
| Cron | Mot de passe root en clair dans crontab | Critique | Exposition du mot de passe root |
| MySQL | Utilisateur admin@% avec GRANT OPTION | Critique | Création d'utilisateurs malveillants |

### 5.9.3 Surface d'attaque totale

**Ports exposés sur MainServer**:
- 22/tcp (SSH) - Authentification par mot de passe
- 80/tcp (HTTP) - Non chiffré
- 513/tcp (rlogin) - Protocole obsolète
- 514/tcp (rsh) - Protocole obsolète

**Fichiers accessibles publiquement**:
- http://192.168.112.141/atlastech/login.php
- http://192.168.112.141/atlastech/admin_backup.php
- http://192.168.112.141/atlastech/export.php
- http://192.168.112.141/atlastech/search.php

**Vecteurs d'attaque identifiés**:
1. Injection SQL via login.php → Bypass authentification
2. Injection SQL via search.php → Extraction de données
3. Téléchargement direct de la BD via admin_backup.php
4. Interception HTTP → Capture des identifiants
5. Exploitation de rlogin/rsh → Accès système non chiffré
6. Brute force SSH → Accès administrateur

### 5.9.4 Conformité et standards

**Non-conformités identifiées**:

| Standard | Exigence | État actuel | Conformité |
|----------|----------|-------------|------------|
| OWASP Top 10 | Protection contre injection SQL | Aucune | Non conforme |
| OWASP Top 10 | Authentification sécurisée | Mots de passe en clair | Non conforme |
| OWASP Top 10 | Chiffrement des données | HTTP uniquement | Non conforme |
| PCI DSS | Hachage des mots de passe | Stockage en clair | Non conforme |
| ISO 27001 | Gestion des accès | Pas de contrôle d'accès | Non conforme |
| ISO 27001 | Chiffrement des communications | Pas de TLS/SSL | Non conforme |
| CIS Benchmarks | Désactivation des services inutiles | rlogin/rsh actifs | Non conforme |
| RGPD | Protection des données personnelles | Accès non contrôlé | Non conforme |

---

## Conclusion du chapitre

Ce chapitre a présenté une analyse détaillée de l'infrastructure actuelle d'AtlasTech Solutions dans son état initial. Les commandes documentées permettent de reproduire l'audit de manière systématique et les résultats montrent clairement les vulnérabilités présentes dans l'architecture existante.

Les chapitres suivants (8 à 21) présenteront les solutions et corrections à apporter pour sécuriser cette infrastructure, conformément aux bonnes pratiques de l'industrie et aux standards de sécurité reconnus.

**Points clés à retenir**:

1. L'infrastructure repose sur une stack LAMP classique (Linux, Apache, MySQL, PHP)
2. Plusieurs vulnérabilités critiques sont présentes, notamment des injections SQL et des mots de passe stockés en clair
3. Des services obsolètes (rlogin, rsh) sont actifs et présentent des risques majeurs
4. Aucun chiffrement n'est utilisé pour les communications (HTTP au lieu de HTTPS)
5. La configuration actuelle ne respecte pas les standards de sécurité reconnus (OWASP, ISO 27001, PCI DSS)

L'analyse des postes Windows et des tests de pénétration depuis Kali Linux confirment que l'infrastructure est vulnérable à de multiples vecteurs d'attaque et nécessite une refonte complète de sa sécurité.