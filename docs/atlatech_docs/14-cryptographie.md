---
id: cryptographie
title: Cryptographie
sidebar_label: "Cryptographie"
sidebar_position: 14
---

# Cryptographie

## Introduction

La cryptographie constitue la pierre angulaire de la sécurité des systèmes d'information modernes. Elle assure la protection des données au repos (stockage) et en transit (communications réseau) contre les accès non autorisés, les interceptions et les modifications malveillantes.

Dans le contexte d'AtlasTech Solutions, l'absence totale de mécanismes cryptographiques expose l'infrastructure à des risques critiques identifiés lors de l'audit initial :

- Absence de chiffrement des disques de stockage
- Communications HTTP non chiffrées (référence : chapitre 7.3)
- Credentials stockés en clair dans les fichiers de configuration (VUL-06)
- Aucune politique de protection des données sur les appareils mobiles

Ce chapitre présente la mise en œuvre de quatre piliers cryptographiques essentiels pour sécuriser l'infrastructure AtlasTech :

**Objectifs de sécurité :**

1. **LUKS (Linux Unified Key Setup)** : Chiffrement transparent des disques pour protéger les données au repos contre le vol physique ou l'accès non autorisé
2. **HTTPS/TLS** : Sécurisation des communications web pour garantir la confidentialité et l'authenticité des échanges
3. **Secrets Management** : Gestion centralisée et sécurisée des credentials, clés API et certificats
4. **Chiffrement mobile** : Protection des données professionnelles sur les smartphones et téléphones VoIP

---

## État actuel (Before)

### Analyse de l'infrastructure non chiffrée

L'audit de sécurité a révélé une absence totale de mesures cryptographiques dans l'infrastructure AtlasTech Solutions :

#### Serveurs Linux

**Vérification du chiffrement de disques :**

```bash
# Connexion au serveur principal
ssh admin@192.168.176.135

# Vérification de la présence de volumes chiffrés LUKS
sudo lsblk -f

# Résultat observé
NAME   FSTYPE LABEL UUID                                 MOUNTPOINT
sda                                                      
├─sda1 ext4         a1b2c3d4-e5f6-7890-abcd-ef1234567890 /boot
└─sda2 ext4         b2c3d4e5-f6a7-8901-bcde-f12345678901 /

# Vérification de l'état de chiffrement
sudo cryptsetup status /dev/sda2

# Résultat
/dev/sda2 is not active
```

**Constat :** Aucun volume chiffré détecté. Les partitions système utilisent ext4 sans couche de chiffrement LUKS.

**Impact :** En cas de vol physique du serveur ou des disques de sauvegarde, l'intégralité des données est lisible directement, incluant :
- Base de données MariaDB contenant les mots de passe en clair (VUL-01)
- Fichiers de configuration avec credentials (VUL-06)
- Code source propriétaire
- Documents financiers et RH

#### Communications réseau

**Test de chiffrement des communications web :**

```bash
# Capture de trafic HTTP vers l'application commerciale
sudo tcpdump -i eth0 -A 'tcp port 80 and host 192.168.176.135'

# Simulation d'une connexion utilisateur
curl -X POST http://192.168.176.135/login.php \
  -d "username=jdupont&password=Azerty123"

# Analyse du fichier de capture
sudo tcpdump -r capture.pcap -A | grep -E "username|password"
```

**Résultat capturé :**

```
POST /login.php HTTP/1.1
Host: 192.168.176.135
Content-Type: application/x-www-form-urlencoded

username=jdupont&password=Azerty123
```

**Constat :** Les identifiants transitent en clair sur le réseau. Référence détaillée au chapitre 7.3 (Sessions & HTTPS).

#### Stockage des secrets

**Inspection des fichiers de configuration :**

```bash
# Analyse du script de sauvegarde automatisée
cat /home/admin/backup.sh

# Contenu observé
#!/bin/bash
rsync -avz /var/www/html/ backup@192.168.176.20:/backups/www/ \
  --password-file=/home/admin/.rsync_pass

# Lecture du fichier de mot de passe
cat /home/admin/.rsync_pass
# Résultat : BackupPass2024!

# Vérification des permissions
ls -la /home/admin/.rsync_pass
# Résultat : -rw-r--r-- 1 admin admin 17 Jan 15 10:23 .rsync_pass
```

**Problèmes identifiés :**
- Mot de passe stocké en texte clair (VUL-06)
- Permissions trop permissives (lecture possible par tous les utilisateurs du groupe)
- Pas de rotation des credentials
- Aucun mécanisme de chiffrement ou de vault

**Vérification dans crontab :**

```bash
sudo crontab -l

# Résultat
0 2 * * * mysqldump -u root -pRootPassword123 atlastech_db > /backups/db_backup.sql
```

**Constat :** Le mot de passe root MySQL est exposé directement dans la crontab.

#### Appareils mobiles

**Politique actuelle :**

```bash
# Vérification de l'existence d'un MDM (Mobile Device Management)
# Aucun système déployé

# Politique documentée
cat /docs/politique_mobile.txt
# Résultat : Fichier inexistant
```

**Constat :** 
- Aucune solution MDM pour gérer les smartphones professionnels
- Pas d'obligation de chiffrement des appareils
- Aucune politique BYOD (Bring Your Own Device) formalisée
- Téléphones VoIP non sécurisés (SIP sans TLS)

**Tableau récapitulatif de l'état actuel :**

| Composant | État actuel | Chiffrement | Risque |
|-----------|-------------|-------------|--------|
| Disques serveurs Linux | Non chiffré | Aucun | Vol physique = compromission totale |
| Sauvegardes | Non chiffrées | Aucun | Exposition des données historiques |
| Communications web | HTTP uniquement | Aucun | Interception Man-in-the-Middle |
| Secrets (passwords, API keys) | Fichiers texte clair | Aucun | Élévation de privilèges facile |
| Smartphones | Gestion manuelle | Variable (selon utilisateur) | Perte/vol = fuite de données |
| VoIP | SIP non sécurisé | Aucun | Écoute téléphonique possible |

---

## LUKS - Chiffrement des disques

### Principe et fonctionnement

**LUKS (Linux Unified Key Setup)** est le standard de facto pour le chiffrement de disques sous Linux. Il fournit une couche de chiffrement transparent entre le système de fichiers et le périphérique de stockage physique.

**Pourquoi utiliser LUKS ?**

La protection au niveau des fichiers individuels (chiffrement applicatif) présente plusieurs limites :
- Nécessite une gestion complexe des clés par application
- Ne protège pas les métadonnées du système de fichiers
- Laisse exposés les fichiers temporaires et de swap
- Vulnérable aux attaques forensiques sur les données supprimées

LUKS résout ces problèmes en chiffrant **l'intégralité du volume** au niveau bloc, garantissant que :
- Toutes les données écrites sont automatiquement chiffrées
- Les fichiers temporaires, swap et cache sont protégés
- Les métadonnées (noms de fichiers, structure de répertoires) sont inaccessibles
- La récupération de données supprimées devient impossible sans la clé

**Architecture technique :**

```
┌─────────────────────────────────────────────┐
│   Applications et système d'exploitation     │
│          (lecture/écriture normale)          │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│         Système de fichiers (ext4)          │
│      /dev/mapper/atlastech-root             │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│      Couche de chiffrement LUKS2            │
│   Algorithme : AES-256-XTS                  │
│   Gestion des clés : dm-crypt               │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│      Périphérique physique (/dev/sda2)      │
│      (données chiffrées sur disque)         │
└─────────────────────────────────────────────┘
```

**LUKS2 vs LUKS1 :**

| Critère | LUKS1 | LUKS2 (recommandé) |
|---------|-------|-------------------|
| Format header | 2 MB fixe | Flexible, extensible |
| Algorithmes | Limités | Support complet (AES-XTS, Argon2) |
| Backup header | Non intégré | Automatique et résilient |
| Slots de clés | 8 maximum | 32 maximum |
| Intégrité | Optionnelle | Intégrée (dm-integrity) |

### Installation sur serveur existant

**Avertissement :** Cette procédure nécessite une sauvegarde complète du serveur et un arrêt temporaire des services.

**Prérequis :**

```bash
# Vérification de l'espace disque disponible
df -h

# Installation des outils nécessaires
sudo apt update
sudo apt install cryptsetup cryptsetup-bin -y

# Vérification de la version installée
cryptsetup --version
# Résultat attendu : cryptsetup 2.6.1
```

**Procédure d'installation LUKS sur nouvelle installation :**

Lors de la réinstallation d'Ubuntu Server 24.04, l'option de chiffrement est activée directement pendant le processus d'installation.

**Étape 1 - Partitionnement guidé :**

```
Ubuntu Server Installation
==========================

Storage configuration:
[X] Use an entire disk and set up encrypted LVM

Select disk: /dev/sda (100 GB)

Passphrase: ********************************
Confirm passphrase: ********************************

Warning: This passphrase is required at boot.
Make sure you store it securely.

[Continue]
```

**Commande équivalente (installation manuelle) :**

```bash
# Création de la partition chiffrée
sudo cryptsetup luksFormat --type luks2 \
  --cipher aes-xts-plain64 \
  --key-size 512 \
  --hash sha512 \
  --iter-time 5000 \
  --use-random \
  /dev/sda2

# Confirmation
WARNING!
========
This will overwrite data on /dev/sda2 irrevocably.

Are you sure? (Type 'yes' in capital letters): YES
Enter passphrase for /dev/sda2: 
Verify passphrase:
```

**Explication des paramètres :**

- `--type luks2` : Utilise le format LUKS2 moderne
- `--cipher aes-xts-plain64` : Algorithme de chiffrement recommandé par le NIST
- `--key-size 512` : Clé de 512 bits (double AES-256)
- `--hash sha512` : Fonction de hachage pour dériver la clé
- `--iter-time 5000` : Temps de dérivation de clé (protection contre brute-force)
- `--use-random` : Utilise /dev/random pour la génération de clé maîtresse

**Étape 2 - Ouverture du volume chiffré :**

```bash
# Déverrouillage du volume
sudo cryptsetup luksOpen /dev/sda2 atlastech_crypt

Enter passphrase for /dev/sda2: **********************

# Vérification
ls -l /dev/mapper/
# Résultat
lrwxrwxrwx 1 root root 7 Feb 10 08:15 atlastech_crypt -> ../dm-0
```

**Étape 3 - Configuration LVM sur le volume chiffré :**

```bash
# Création du Physical Volume
sudo pvcreate /dev/mapper/atlastech_crypt
  Physical volume "/dev/mapper/atlastech_crypt" successfully created.

# Création du Volume Group
sudo vgcreate atlastech-vg /dev/mapper/atlastech_crypt
  Volume group "atlastech-vg" successfully created

# Création des Logical Volumes
sudo lvcreate -L 50G -n root atlastech-vg
sudo lvcreate -L 20G -n var atlastech-vg
sudo lvcreate -L 10G -n home atlastech-vg

# Vérification
sudo lvs
  LV   VG           Attr       LSize  Pool Origin Data%  Meta%
  root atlastech-vg -wi-a----- 50.00g
  var  atlastech-vg -wi-a----- 20.00g
  home atlastech-vg -wi-a----- 10.00g
```

### Vérification et validation

**Test 1 - Vérification de l'état de chiffrement :**

```bash
# Statut du volume chiffré
sudo cryptsetup status atlastech_crypt

# Résultat
/dev/mapper/atlastech_crypt is active and is in use.
  type:    LUKS2
  cipher:  aes-xts-plain64
  keysize: 512 bits
  key location: keyring
  device:  /dev/sda2
  sector size:  512
  offset:  32768 sectors
  size:    204767232 sectors
  mode:    read/write
```

**Test 2 - Analyse de l'entête LUKS :**

```bash
# Dump des métadonnées LUKS
sudo cryptsetup luksDump /dev/sda2

# Résultat (extrait)
LUKS header information
Version:        2
Epoch:          3
Metadata area:  16384 [bytes]
Keyslots area:  16744448 [bytes]
UUID:           a1b2c3d4-e5f6-7890-abcd-ef1234567890
Label:          (no label)
Subsystem:      (no subsystem)

Flags:          (no flags)

Data segments:
  0: crypt
        offset: 16777216 [bytes]
        length: (whole device)
        cipher: aes-xts-plain64
        sector: 512 [bytes]

Keyslots:
  0: luks2
        Key:        512 bits
        Priority:   normal
        Cipher:     aes-xts-plain64
        Cipher key: 512 bits
        PBKDF:      argon2id
        Time cost:  4
        Memory:     1048576
        Threads:    4
        Salt:       a1 b2 c3 d4 ... (32 bytes)
        AF stripes: 4000
        AF hash:    sha512
        Area offset:32768 [bytes]
        Area length:258048 [bytes]
        Digest ID:  0
```

**Analyse de sécurité :**

- **PBKDF : Argon2id** - Algorithme moderne résistant aux attaques GPU (recommandation OWASP)
- **Memory cost : 1 MB** - Rend le brute-force coûteux en mémoire
- **Time cost : 4** - Itérations pour ralentir les tentatives
- **AF (Anti-Forensic) stripes : 4000** - Diffusion de la clé pour empêcher la récupération partielle

**Test 3 - Performance de lecture/écriture :**

```bash
# Test de performance sans chiffrement (pour comparaison)
# Sur partition non chiffrée /dev/sda1 (boot)
sudo hdparm -tT /dev/sda1

# Résultat
Timing cached reads:   12000 MB in  2.00 seconds = 6000.00 MB/sec
Timing buffered disk reads: 450 MB in  3.01 seconds = 149.50 MB/sec

# Test sur volume chiffré
sudo hdparm -tT /dev/mapper/atlastech_crypt

# Résultat
Timing cached reads:   12000 MB in  2.00 seconds = 6000.00 MB/sec
Timing buffered disk reads: 420 MB in  3.02 seconds = 139.07 MB/sec

# Impact : ~7% de perte de performance (acceptable pour le niveau de sécurité)
```

**Test 4 - Tentative d'accès sans déchiffrement :**

```bash
# Simulation : lecture directe du disque chiffré
sudo dd if=/dev/sda2 bs=4096 count=100 | strings

# Résultat : données inintelligibles (garbage)
# Exemple de sortie
x██#██8██L██m██X███H██
████████████████?███
# Aucune chaîne de caractères lisible détectée
```

**Constat :** Les données sont correctement chiffrées et illisibles sans déverrouillage.

### Gestion des clés de récupération

**Ajout d'une clé de secours (keyfile) :**

```bash
# Génération d'un fichier de clé aléatoire
sudo dd if=/dev/urandom of=/root/luks-backup.key bs=1024 count=4
4+0 records in
4+0 records out
4096 bytes (4.1 kB, 4.0 KiB) copied, 0.000234 s, 17.5 MB/s

# Sécurisation du fichier
sudo chmod 400 /root/luks-backup.key

# Ajout de la clé au slot 1
sudo cryptsetup luksAddKey /dev/sda2 /root/luks-backup.key
Enter any existing passphrase: **********************

# Vérification des slots actifs
sudo cryptsetup luksDump /dev/sda2 | grep "Keyslots:" -A 10

Keyslots:
  0: luks2
        Key:        512 bits
        [...]
  1: luks2
        Key:        512 bits
        [...]
```

**Sauvegarde de l'entête LUKS :**

```bash
# Backup de l'entête (critique pour la récupération)
sudo cryptsetup luksHeaderBackup /dev/sda2 \
  --header-backup-file /root/luks-header-backup-sda2.img

# Vérification
ls -lh /root/luks-header-backup-sda2.img
-rw------- 1 root root 16M Feb 10 09:30 luks-header-backup-sda2.img

# Stockage sécurisé : transférer ce fichier sur un support externe chiffré
# JAMAIS sur le même disque que le volume chiffré
```

**Révocation d'une clé compromise :**

```bash
# Liste des slots de clés actifs
sudo cryptsetup luksDump /dev/sda2 | grep "^  [0-9]:"

# Suppression du slot 1 (si compromis)
sudo cryptsetup luksKillSlot /dev/sda2 1
Enter any remaining passphrase: **********************

# Confirmation
About to kill keyslot 1
Are you sure? (Type 'yes' in capital letters): YES
```

### Automatisation du déverrouillage au démarrage

Par défaut, LUKS requiert une saisie manuelle du mot de passe au boot. Pour les serveurs de production, deux approches sont possibles :

**Option 1 - Serveur avec console physique accessible :**

Configuration actuelle maintenue (saisie manuelle au boot). Recommandé pour :
- Serveurs critiques (base de données, secrets management)
- Environnements hautement sécurisés

**Option 2 - Déverrouillage automatique via TPM 2.0 (Trusted Platform Module) :**

```bash
# Vérification de la présence d'un TPM
sudo dmesg | grep -i tpm

[    1.234567] tpm_tis 00:05: 2.0 TPM (device-id 0x1A, rev-id 16)

# Installation des outils TPM
sudo apt install tpm2-tools clevis clevis-luks clevis-tpm2 -y

# Liaison de LUKS avec TPM
sudo clevis luks bind -d /dev/sda2 tpm2 '{"pcr_ids":"0,7"}'

# Explication :
# - PCR 0 : Firmware UEFI
# - PCR 7 : Secure Boot
# Le déverrouillage ne fonctionnera que si ces mesures correspondent
```

**Vérification du déverrouillage automatique :**

```bash
# Test de déchiffrement via TPM
sudo clevis luks unlock -d /dev/sda2 -n test_unlock

# Si succès, le volume est accessible sans mot de passe
ls /dev/mapper/test_unlock
```

**Sécurité :** Cette méthode protège contre le vol physique du disque (clé stockée dans TPM hardware), mais pas contre le vol du serveur entier en fonctionnement.

### Chiffrement des sauvegardes

Les sauvegardes doivent également être chiffrées pour garantir la protection des données historiques.

**Création d'un volume chiffré pour les backups :**

```bash
# Sur le serveur de sauvegarde (192.168.176.20)
ssh admin@192.168.176.20

# Préparation du disque de sauvegarde externe
sudo cryptsetup luksFormat --type luks2 /dev/sdb1
Enter passphrase: **********************
Verify passphrase: **********************

# Ouverture du volume
sudo cryptsetup luksOpen /dev/sdb1 backup_crypt

# Création du système de fichiers
sudo mkfs.ext4 /dev/mapper/backup_crypt

# Montage
sudo mkdir -p /mnt/backups_encrypted
sudo mount /dev/mapper/backup_crypt /mnt/backups_encrypted

# Ajout au fstab (avec clé automatique via fichier sécurisé)
echo "backup_crypt /dev/sdb1 /root/backup.key luks" | sudo tee -a /etc/crypttab
echo "/dev/mapper/backup_crypt /mnt/backups_encrypted ext4 defaults 0 2" | sudo tee -a /etc/fstab
```

---

## HTTPS pour Site Web

### Déploiement de Let's Encrypt

**Let's Encrypt** est une autorité de certification gratuite et automatisée qui délivre des certificats TLS valides reconnus par tous les navigateurs modernes.

**Pourquoi Let's Encrypt ?**

- **Gratuit** : Aucun coût de certification (vs. 50-300€/an pour un certificat commercial)
- **Automatisé** : Renouvellement automatique tous les 90 jours
- **Reconnu universellement** : Chaîne de confiance établie avec tous les navigateurs
- **Sécurité renforcée** : Support natif de TLS 1.3 et OCSP Stapling

**Alternatives considérées :**

| Solution | Avantages | Inconvénients | Choix |
|----------|-----------|---------------|-------|
| Certificat auto-signé | Gratuit, rapide | Avertissement navigateur, pas de confiance | Non |
| Certificat commercial (DigiCert, etc.) | Support premium, garantie financière | Coût élevé, renouvellement manuel | Non |
| Let's Encrypt | Gratuit, automatique, reconnu | Validité courte (90j) | Oui |

**Installation de Certbot :**

```bash
# Mise à jour des dépôts
sudo apt update

# Installation de Certbot et du plugin Apache
sudo apt install certbot python3-certbot-apache -y

# Vérification de la version
certbot --version
# Résultat : certbot 2.7.4
```

**Prérequis DNS :**

Avant de demander un certificat, le domaine doit pointer vers le serveur :

```bash
# Vérification de la résolution DNS
nslookup www.atlastech-solutions.com

# Résultat attendu
Server:         8.8.8.8
Address:        8.8.8.8#53

Name:   www.atlastech-solutions.com
Address: 203.0.113.45  # IP publique du serveur
```

**Demande du certificat TLS :**

```bash
# Obtention automatique du certificat et configuration Apache
sudo certbot --apache -d www.atlastech-solutions.com -d atlastech-solutions.com

# Interaction du processus
Saving debug log to /var/log/letsencrypt/letsencrypt.log

Enter email address (used for urgent renewal and security notices): admin@atlastech-solutions.com

Please read the Terms of Service at
https://letsencrypt.org/documents/LE-SA-v1.3-September-21-2022.pdf
(A)gree/(C)ancel: A

Would you be willing to share your email address? (Y)es/(N)o: N

Requesting a certificate for www.atlastech-solutions.com and atlastech-solutions.com

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/www.atlastech-solutions.com/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/www.atlastech-solutions.com/privkey.pem
This certificate expires on 2026-05-11.
```

### Configuration TLS 1.3 et durcissement

**Durcissement de la configuration TLS :**

```bash
# Backup de la configuration d'origine
sudo cp /etc/letsencrypt/options-ssl-apache.conf \
       /etc/letsencrypt/options-ssl-apache.conf.backup

# Édition de la configuration
sudo nano /etc/letsencrypt/options-ssl-apache.conf
```

**Configuration renforcée :**

```apache
# Configuration TLS 1.3 uniquement (recommandation ANSSI 2024)
SSLProtocol -all +TLSv1.3

# Cipher suites TLS 1.3 (ordre de préférence)
SSLCipherSuite TLS_AES_256_GCM_SHA384:TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256

# Ordre de chiffrement imposé par le serveur
SSLHonorCipherOrder on

# Désactivation des session tickets (forward secrecy)
SSLSessionTickets off

# OCSP Stapling (vérification de révocation performante)
SSLUseStapling on
SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"

# Compression désactivée (protection contre CRIME)
SSLCompression off
```

**Explication des paramètres :**

**SSLProtocol -all +TLSv1.3 :**
- Désactive tous les protocoles obsolètes (SSLv2, SSLv3, TLS 1.0, 1.1, 1.2)
- Active uniquement TLS 1.3 (standard depuis 2018, recommandé par ANSSI)
- Protège contre les attaques connues (POODLE, BEAST, CRIME)

**TLS_AES_256_GCM_SHA384 :**
- **AES-256** : Chiffrement symétrique (256 bits, niveau militaire)
- **GCM** : Galois/Counter Mode (chiffrement authentifié, protection intégrité)
- **SHA-384** : Fonction de hachage pour HMAC

**OCSP Stapling :**
- Le serveur interroge l'OCSP (révocation de certificats) au lieu du client
- Améliore les performances (pas de requête supplémentaire du navigateur)
- Protège la confidentialité (l'autorité de certification ne sait pas quel site est visité)

**Redémarrage et validation :**

```bash
# Test de configuration
sudo apache2ctl configtest
# Syntax OK

# Redémarrage complet (nécessaire pour OCSP Stapling)
sudo systemctl restart apache2

# Vérification du protocole TLS
openssl s_client -connect www.atlastech-solutions.com:443 -tls1_3

# Résultat (extrait)
SSL-Session:
    Protocol  : TLSv1.3
    Cipher    : TLS_AES_256_GCM_SHA384
    Session-ID: ...
    Master-Key: ...
    TLS session ticket: (none)
```

### Headers de sécurité HTTP

**Configuration dans Apache :**

```bash
# Activation du module headers
sudo a2enmod headers

# Édition de la configuration du site HTTPS
sudo nano /etc/apache2/sites-available/000-default-le-ssl.conf
```

**Ajout des headers de sécurité :**

```apache
<VirtualHost *:443>
    ServerName www.atlastech-solutions.com
    
    # ... (configuration SSL existante) ...
    
    # Headers de sécurité
    
    # HSTS - Force HTTPS pendant 1 an
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    
    # CSP - Content Security Policy
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'"
    
    # Protection contre clickjacking
    Header always set X-Frame-Options "DENY"
    
    # Protection MIME sniffing
    Header always set X-Content-Type-Options "nosniff"
    
    # Protection XSS intégrée navigateur
    Header always set X-XSS-Protection "1; mode=block"
    
    # Politique Referrer (ne pas envoyer d'URL complète)
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    
    # Permissions Policy (anciennement Feature Policy)
    Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
    
</VirtualHost>
```

**Explication détaillée des headers :**

**1. Strict-Transport-Security (HSTS) :**

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

- **max-age=31536000** : Le navigateur forcera HTTPS pendant 1 an (31 536 000 secondes)
- **includeSubDomains** : Applique la règle à tous les sous-domaines (ex: admin.atlastech-solutions.com)
- **preload** : Permet l'inscription dans la liste HSTS Preload des navigateurs (protection dès la première visite)

**Protection :** Empêche les attaques de type SSL Stripping (downgrade HTTPS → HTTP).

**2. Content-Security-Policy (CSP) :**

```
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'; ...
```

Directive par directive :

- **default-src 'self'** : Par défaut, autoriser uniquement les ressources du même domaine
- **script-src 'self' 'unsafe-inline'** : Scripts autorisés depuis le domaine + inline (à durcir ultérieurement)
- **style-src 'self' 'unsafe-inline'** : Styles CSS depuis le domaine + inline
- **img-src 'self' data:** : Images depuis le domaine ou data URIs (base64)
- **frame-ancestors 'none'** : Interdire l'embedding du site (redondant avec X-Frame-Options)
- **form-action 'self'** : Les formulaires ne peuvent soumettre que vers le même domaine

**Protection :** Bloque l'injection de scripts XSS provenant de domaines externes.

**3. X-Frame-Options :**

```
X-Frame-Options: DENY
```

Interdit totalement l'affichage du site dans une iframe/frame.

**Alternatives :**
- **DENY** : Aucun embedding (recommandé)
- **SAMEORIGIN** : Embedding autorisé uniquement depuis le même domaine

**Protection :** Clickjacking (un attaquant cache une iframe malveillante sous un bouton légitime).

**4. X-Content-Type-Options :**

```
X-Content-Type-Options: nosniff
```

Force le navigateur à respecter le Content-Type déclaré. Empêche l'interprétation d'un fichier image comme du JavaScript.

**5. Permissions-Policy :**

```
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

Désactive les APIs sensibles du navigateur (géolocalisation, micro, caméra).

**Application et vérification :**

```bash
# Rechargement de la configuration
sudo systemctl reload apache2

# Test des headers avec curl
curl -I https://www.atlastech-solutions.com

# Résultat
HTTP/2 200
server: Apache/2.4.52 (Ubuntu)
strict-transport-security: max-age=31536000; includeSubDomains; preload
content-security-policy: default-src 'self'; script-src 'self' 'unsafe-inline'; ...
x-frame-options: DENY
x-content-type-options: nosniff
x-xss-protection: 1; mode=block
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=()
```

### Tests et validation SSL Labs

**SSL Labs (Qualys) :**

Accès via navigateur : https://www.ssllabs.com/ssltest/analyze.html?d=www.atlastech-solutions.com

**Résultats attendus :**

```
Overall Rating: A+

Certificate:
- Issuer: Let's Encrypt
- Validity: 90 days
- Key: RSA 2048 bits (sufficient)
- Signature algorithm: SHA256withRSA

Protocol Support:
- TLS 1.3: Yes
- TLS 1.2: No (désactivé)
- TLS 1.1: No
- TLS 1.0: No
- SSL 3.0: No
- SSL 2.0: No

Cipher Suites (TLS 1.3):
- TLS_AES_256_GCM_SHA384 (0x1302)   ECDH x25519   256
- TLS_AES_128_GCM_SHA256 (0x1301)   ECDH x25519   128
- TLS_CHACHA20_POLY1305_SHA256 (0x1303)   ECDH x25519   256

Security Features:
- HSTS: Yes (max-age=31536000)
- OCSP Stapling: Yes
- Forward Secrecy: Yes (all suites)
```

**Commande alternative pour test local :**

```bash
# Utilisation de testssl.sh (outil open source)
git clone --depth 1 https://github.com/drwetter/testssl.sh.git
cd testssl.sh

./testssl.sh --full https://www.atlastech-solutions.com

# Résultat (extrait)
Testing protocols via sockets

 SSLv2      not offered (OK)
 SSLv3      not offered (OK)
 TLS 1      not offered
 TLS 1.1    not offered
 TLS 1.2    not offered
 TLS 1.3    offered (OK): final

Testing vulnerabilities

 Heartbleed (CVE-2014-0160)                not vulnerable (OK)
 CCS (CVE-2014-0224)                       not vulnerable (OK)
 Ticketbleed (CVE-2016-9244)               not vulnerable (OK)
 ROBOT                                     not vulnerable (OK)
 Secure Renegotiation (RFC 5746)           not vulnerable (OK)
 CRIME, TLS (CVE-2012-4929)                not vulnerable (OK)
 POODLE, SSL (CVE-2014-3566)               not vulnerable (OK)
 SWEET32 (CVE-2016-2183)                   not vulnerable (OK)
 FREAK (CVE-2015-0204)                     not vulnerable (OK)
 DROWN (CVE-2016-0800)                     not vulnerable (OK)
 LOGJAM (CVE-2015-4000)                    not vulnerable (OK)
```

---

## Secrets Management

### Problématique de la gestion des secrets

**État actuel (rappel VUL-06) :**

Les credentials sont stockés en texte clair dans plusieurs emplacements :

```bash
# Exemple 1 : Script de sauvegarde
cat /home/admin/backup.sh
rsync ... --password-file=/home/admin/.rsync_pass

# Exemple 2 : Crontab
crontab -l
0 2 * * * mysqldump -u root -pRootPassword123 atlastech_db > /backup/db.sql

# Exemple 3 : Fichier de configuration PHP
cat /var/www/html/config.php
<?php
$db_host = "localhost";
$db_user = "webapp";
$db_pass = "webapp123";
?>
```

**Risques :**

1. **Exposition accidentelle** : Les credentials peuvent être commités dans Git, envoyés par email, ou exposés dans les logs
2. **Pas de rotation** : Changer un mot de passe nécessite de modifier manuellement tous les scripts
3. **Audit impossible** : Aucune traçabilité sur qui a accédé à quel secret
4. **Compromission en cascade** : Si un système est compromis, tous les secrets sont exposés

### Architecture de gestion des secrets

**Solution retenue : HashiCorp Vault**

Vault est une solution open-source de gestion centralisée des secrets qui fournit :

- **Stockage chiffré** : Tous les secrets sont chiffrés au repos (AES-256-GCM)
- **Contrôle d'accès** : Politiques granulaires par application/utilisateur
- **Audit complet** : Logs de tous les accès aux secrets
- **Rotation automatique** : Les secrets peuvent être renouvelés automatiquement
- **API universelle** : Intégration avec scripts, applications, CI/CD

**Architecture déployée :**

```
┌─────────────────────────────────────────────────────┐
│            Applications & Services                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │  Apache  │  │  Backup  │  │  Cron    │          │
│  │   PHP    │  │  Script  │  │  Jobs    │          │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘          │
│       │             │             │                 │
│       └─────────────┴─────────────┘                 │
│                     │                               │
│              Authentification via                   │
│              AppRole / Token                        │
│                     │                               │
│       ┌─────────────▼─────────────────┐             │
│       │      HashiCorp Vault API      │             │
│       │      (Port 8200 - HTTPS)      │             │
│       └─────────────┬─────────────────┘             │
│                     │                               │
│       ┌─────────────▼─────────────────┐             │
│       │    Secrets Engines             │             │
│       │  ├─ KV v2 (Key-Value)         │             │
│       │  ├─ Database (MySQL dynamic)  │             │
│       │  └─ PKI (Certificates)        │             │
│       └─────────────┬─────────────────┘             │
│                     │                               │
│       ┌─────────────▼─────────────────┐             │
│       │   Encrypted Storage Backend   │             │
│       │   (AES-256-GCM + Shamir)      │             │
│       └───────────────────────────────┘             │
└─────────────────────────────────────────────────────┘
```

### Installation et configuration de Vault

**Installation :**

```bash
# Ajout du dépôt HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Installation
sudo apt update && sudo apt install vault -y

# Vérification
vault version
# Résultat : Vault v1.15.4
```

**Configuration du serveur Vault :**

```bash
# Création du fichier de configuration
sudo mkdir -p /etc/vault.d
sudo nano /etc/vault.d/vault.hcl
```

Contenu :

```hcl
# Configuration du stockage (fichier local pour démo, Consul/etcd en production)
storage "file" {
  path = "/opt/vault/data"
}

# Écoute HTTPS uniquement
listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = false
  tls_cert_file = "/etc/vault.d/vault-cert.pem"
  tls_key_file  = "/etc/vault.d/vault-key.pem"
}

# Interface Web UI activée
ui = true

# Niveau de log
log_level = "INFO"

# Désactivation de mlock (à activer en production)
disable_mlock = true
```

**Génération du certificat auto-signé pour Vault (interne) :**

```bash
# Création du certificat TLS pour Vault
sudo openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 \
  -nodes -keyout /etc/vault.d/vault-key.pem \
  -out /etc/vault.d/vault-cert.pem \
  -subj "/CN=vault.atlastech.local" \
  -addext "subjectAltName=DNS:vault.atlastech.local,IP:127.0.0.1"

# Permissions
sudo chmod 640 /etc/vault.d/vault-key.pem
sudo chown vault:vault /etc/vault.d/vault-*.pem
```

**Initialisation de Vault :**

```bash
# Démarrage du service
sudo systemctl start vault
sudo systemctl enable vault

# Export de l'adresse du serveur
export VAULT_ADDR='https://127.0.0.1:8200'
export VAULT_SKIP_VERIFY=true  # Uniquement pour certificat auto-signé

# Initialisation (génération des clés de déverrouillage)
vault operator init

# Résultat
Unseal Key 1: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
Unseal Key 2: b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7
Unseal Key 3: c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8
Unseal Key 4: d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9
Unseal Key 5: e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0

Initial Root Token: hvs.a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6

Vault initialized with 5 key shares and a key threshold of 3.
Please securely distribute the key shares printed above.
```

**Important :** 
- Les **Unseal Keys** doivent être distribuées à 5 personnes différentes (principe de Shamir's Secret Sharing)
- Il faut **3 clés sur 5** pour déverrouiller Vault après un redémarrage
- Le **Root Token** donne un accès complet (à révoquer après configuration initiale)

### Migration des secrets

**Activation du moteur KV (Key-Value) v2 :**

```bash
# Activation du secret engine
vault secrets enable -path=atlastech kv-v2

# Vérification
vault secrets list

# Résultat
Path          Type       Description
----          ----       -----------
atlastech/    kv         n/a
cubbyhole/    cubbyhole  per-token private secret storage
identity/     identity   identity store
sys/          system     system endpoints used for control
```

**Stockage des credentials MySQL :**

```bash
# Stockage du mot de passe root MySQL
vault kv put atlastech/database/mysql \
  root_password="RootPassword123" \
  webapp_user="webapp" \
  webapp_password="webapp123"

# Vérification
vault kv get atlastech/database/mysql

# Résultat
====== Data ======
Key               Value
---               -----
root_password     RootPassword123
webapp_user       webapp
webapp_password   webapp123
```

**Stockage des credentials de sauvegarde rsync :**

```bash
vault kv put atlastech/backup/rsync \
  username="backup" \
  password="BackupPass2024!"

# Vérification
vault kv get -field=password atlastech/backup/rsync
# Résultat : BackupPass2024!
```

---

## Chiffrement des téléphones

### Politique de chiffrement mobile

**Contexte :**

AtlasTech Solutions dispose de :
- **25 employés** avec accès email professionnel sur smartphone
- **8 commerciaux** manipulant des données clients sensibles
- **3 administrateurs IT** avec accès aux systèmes critiques

**Objectifs de la politique :**

1. **Chiffrement au repos** : Protection des données stockées sur l'appareil
2. **Chiffrement en transit** : Sécurisation des communications (email, VoIP)
3. **Wipe à distance** : Effacement en cas de perte/vol
4. **Séparation professionnel/personnel** : Conteneurisation des applications

### Chiffrement des smartphones (iOS/Android)

**Solution MDM : Microsoft Intune**

**Configuration du chiffrement obligatoire :**

**Pour Android :**

Politique de conformité dans Intune :

```
Intune Admin Center > Devices > Compliance policies > Create policy

Platform: Android Enterprise
Profile type: Fully Managed, Dedicated, and Corporate-Owned Work Profile

Settings:
- Device Health
  Require device encryption
  
- System Security
  Encryption of data storage on device: Require
  Require a password to unlock mobile devices
  Minimum password length: 8
  Required password type: At least alphanumeric
  Maximum minutes of inactivity before password is required: 5 minutes
```

**Pour iOS :**

```
Platform: iOS/iPadOS

Settings:
- System Security
  Require encryption: Yes (activé par défaut sur iOS 8+)
  Block simple passwords: Yes
  Minimum password length: 8
  Required password type: Alphanumeric
  Auto-Lock: 5 minutes
```

**Vérification du chiffrement :**

**Sur Android :**

```
Settings > Security > Encryption & credentials
Status: Encrypted

# Vérification technique (via ADB pour audit)
adb shell getprop ro.crypto.state
# Résultat : encrypted
```

**Sur iOS :**

Le chiffrement est activé automatiquement dès qu'un code de déverrouillage est configuré (FileVault matériel via Secure Enclave).

```
Settings > Face ID & Passcode > Data Protection is enabled
```

### Chiffrement des communications VoIP

**Solution déployée : 3CX avec chiffrement SRTP**

AtlasTech utilise 3CX Phone System pour la téléphonie IP.

**Activation du chiffrement SRTP (Secure Real-time Transport Protocol) :**

**Configuration du serveur 3CX :**

```
3CX Management Console > Settings > SIP > Security

Enable TLS for SIP signaling
Force SRTP for media encryption
Minimum TLS version: 1.2

Certificate:
- Use Let's Encrypt certificate (auto-renew)
- Domain: voip.atlastech-solutions.com
```

**Configuration des extensions utilisateur :**

```
Extensions > [User Extension] > Options

Transport: TLS (TCP/TLS)
Require SRTP encryption
```

**Vérification du chiffrement :**

**Capture de trafic pendant un appel :**

```bash
# Capture sur le port SIP (5061 pour TLS)
sudo tcpdump -i eth0 port 5061 -w voip_tls.pcap

# Analyse avec Wireshark
wireshark voip_tls.pcap

# Filtres
sip && tls

# Résultat attendu
Protocol: TLSv1.3
Cipher Suite: TLS_AES_256_GCM_SHA384
```

**Pour SRTP (flux audio) :**

```bash
# Le trafic RTP doit être illisible
sudo tcpdump -i eth0 udp and portrange 10000-20000 -X

# Résultat : données chiffrées (garbage)
0x0000:  4500 0064 1a2b 4000 4011 a1b2 c0a8 b087  E..d.+@.@.......
0x0010:  c0a8 b088 2710 2711 0050 c3d4 e5f6 a7b8  ....'.'.P......
```

---

## Outils utilisés

### Cryptsetup

**Version :** 2.6.1  
**Licence :** GPL v2  
**Site :** https://gitlab.com/cryptsetup/cryptsetup

**Description :**  
Cryptsetup est l'utilitaire de référence pour gérer le chiffrement de disques sous Linux via LUKS. Il fournit une interface en ligne de commande pour créer, ouvrir, et gérer des volumes chiffrés.

**Utilisation dans le projet :**

- Chiffrement des partitions serveurs Linux (MainServer + BackupServer)
- Vérification de l'état de chiffrement
- Gestion des clés de récupération

**Commandes principales :**

```bash
# Création d'un volume chiffré
cryptsetup luksFormat /dev/sdX

# Ouverture d'un volume
cryptsetup luksOpen /dev/sdX nom_mapping

# Statut
cryptsetup status nom_mapping

# Backup de l'entête
cryptsetup luksHeaderBackup /dev/sdX --header-backup-file backup.img
```

### Certbot (Let's Encrypt)

**Version :** 2.7.4  
**Licence :** Apache 2.0  
**Site :** https://certbot.eff.org/

**Description :**  
Certbot est le client officiel Let's Encrypt pour l'obtention et le renouvellement automatique de certificats TLS gratuits.

**Utilisation dans le projet :**

- Déploiement de certificats TLS sur le serveur web Apache
- Renouvellement automatique tous les 90 jours
- Configuration automatique des VirtualHosts HTTPS

### HashiCorp Vault

**Version :** 1.15.4  
**Licence :** Business Source License (BSL) 1.1 / Mozilla Public License 2.0  
**Site :** https://www.vaultproject.io/

**Description :**  
Vault est une solution de gestion centralisée des secrets offrant stockage chiffré, contrôle d'accès granulaire, rotation automatique et audit complet.

**Utilisation dans le projet :**

- Stockage sécurisé des credentials (MySQL, rsync, APIs)
- Génération de credentials dynamiques pour les bases de données
- Audit des accès aux secrets

### testssl.sh

**Version :** 3.0.8  
**Licence :** GPL v2  
**Site :** https://github.com/drwetter/testssl.sh

**Description :**  
testssl.sh est un outil open source d'audit de configuration TLS/SSL. Il teste les protocoles, cipher suites, et vulnérabilités connues (POODLE, BEAST, etc.).

**Utilisation dans le projet :**

- Validation de la configuration TLS 1.3
- Vérification de l'absence de vulnérabilités SSL/TLS
- Audit des headers de sécurité HTTP

### Microsoft Intune

**Version :** Cloud (SaaS)  
**Licence :** Commerciale (inclus dans Microsoft 365 Business Premium)  
**Site :** https://intune.microsoft.com/

**Description :**  
Microsoft Intune est une solution MDM (Mobile Device Management) permettant de gérer et sécuriser les appareils mobiles (iOS, Android, Windows).

**Utilisation dans le projet :**

- Enforcement du chiffrement sur les smartphones
- Politique de conformité (code PIN, version OS)
- Wipe à distance en cas de perte/vol
- Conteneurisation des applications professionnelles

---

## Analyse des risques

### Scénarios de menaces mitigés

#### Scénario 1 : Vol physique du serveur

**Avant (sans LUKS) :**

Un attaquant vole le serveur MainServer ou un disque de sauvegarde.

**Exploitation :**

```bash
# Connexion du disque volé sur une machine de l'attaquant
sudo mount /dev/sdb2 /mnt/stolen

# Accès direct aux fichiers
ls /mnt/stolen/var/www/html
config.php  # Contient les credentials MySQL en clair
```

**Impact :** Compromission totale (base de données, code source, fichiers de configuration).

**Après (avec LUKS) :**

```bash
# Tentative de montage
sudo mount /dev/sdb2 /mnt/stolen
# Erreur : filesystem inconnu (données chiffrées)

# Tentative de lecture directe
sudo dd if=/dev/sdb2 bs=4096 count=100 | strings
# Résultat : garbage (aucune donnée lisible)
```

**Impact :** Attaque bloquée. Les données restent inaccessibles sans la passphrase LUKS.

**Risque résiduel :** Attaque par force brute sur la passphrase (mitigé par Argon2id avec coût mémoire élevé).

#### Scénario 2 : Interception Man-in-the-Middle (MITM)

**Avant (HTTP uniquement) :**

Un attaquant sur le même réseau Wi-Fi (client malveillant ou point d'accès compromis) effectue une attaque MITM.

**Exploitation :**

```bash
# Configuration de l'attaque (Ettercap + sslstrip)
sudo ettercap -T -M arp:remote /gateway_ip// /victim_ip//
sudo sslstrip -l 8080

# Capture des credentials
sudo tcpdump -i eth0 -A 'tcp port 80' | grep -E 'username=|password='

# Résultat
username=jdupont&password=Azerty123
```

**Après (HTTPS + HSTS) :**

```bash
# Tentative de downgrade HTTPS → HTTP
sudo sslstrip -l 8080

# Résultat côté client
Browser: "This site requires HTTPS (HSTS policy active)"
Connection blocked.

# Même si l'attaquant tente de modifier le header HSTS
# Le navigateur l'a mémorisé pour 1 an (max-age=31536000)
```

**Impact :** Attaque bloquée par HSTS. L'utilisateur ne peut se connecter qu'en HTTPS.

**Risque résiduel :** Première visite avant activation HSTS (mitigé par HSTS Preload).

#### Scénario 3 : Compromission d'un script avec credentials

**Avant (credentials en clair) :**

Un attaquant obtient un accès en lecture sur le serveur (LFI, backup exposé, etc.).

**Exploitation :**

```bash
# Lecture du script de sauvegarde
cat /home/admin/backup.sh
# Résultat : --password-file=/home/admin/.rsync_pass

cat /home/admin/.rsync_pass
# BackupPass2024!

# Lecture de crontab
crontab -l
# 0 2 * * * mysqldump -u root -pRootPassword123 ...
```

**Impact :** L'attaquant récupère tous les credentials (MySQL root, rsync).

**Après (Vault) :**

```bash
# Lecture du script
cat /home/admin/backup.sh
# BACKUP_PASSWORD=$(vault kv get -field=password atlastech/backup/rsync)

# Tentative de récupération sans token Vault
vault kv get atlastech/backup/rsync
# Error: permission denied

# Même avec accès root au serveur, pas de token Vault
# Les secrets restent protégés dans Vault (authentification AppRole nécessaire)
```

**Impact :** Attaque bloquée. Les secrets ne sont pas exposés dans les fichiers.

**Risque résiduel :** Si l'attaquant compromise l'application web, il pourrait utiliser son AppRole pour accéder aux secrets (mitigé par TTL courte des tokens et audit logs).

#### Scénario 4 : Perte d'un smartphone professionnel

**Avant (sans MDM) :**

Un commercial perd son smartphone contenant :
- Accès email professionnel (derniers 30 jours synchronisés)
- Documents clients (PDF, devis)
- Application CRM (contacts clients)

**Impact :** Fuite de données clients sensibles.

**Après (Intune + chiffrement) :**

```
Timeline:
- T+0 : Commercial signale la perte
- T+5min : Admin IT déclenche un "Wipe" via Intune
- T+30min : Le smartphone se connecte au Wi-Fi
- T+31min : Wipe exécuté, toutes les données effacées
```

**Résultat pour un attaquant :**

```
1. Tentative d'allumage du téléphone
   → Écran de verrouillage (code PIN requis)

2. Tentative de bypass via récupération matérielle
   → Données chiffrées (AES-256 via Secure Enclave/Android FileVault)
   → Aucune récupération possible sans le code PIN

3. Si le téléphone était déverrouillé au moment de la perte
   → Wipe à distance efface tout dans les 8h max
```

**Impact :** Risque minimisé. Données inaccessibles ou effacées à distance.

---

## Références normatives

### ANSSI (Agence Nationale de la Sécurité des Systèmes d'Information)

**Guide "Recommandations de sécurité relatives à TLS" (version 1.3 - 2024) :**

- Interdiction de SSLv2, SSLv3, TLS 1.0, TLS 1.1
- TLS 1.2 toléré uniquement avec cipher suites robustes
- TLS 1.3 recommandé en priorité
- Cipher suites :
  - **TLS 1.3** : TLS_AES_256_GCM_SHA384, TLS_AES_128_GCM_SHA256
  - **TLS 1.2** (si nécessaire) : TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384

**Statut AtlasTech :** Conforme (TLS 1.3 uniquement).

### NIST (National Institute of Standards and Technology)

**NIST SP 800-52 Rev. 2 - Guidelines for the Selection, Configuration, and Use of TLS :**

- TLS 1.2 minimum requis
- TLS 1.3 recommandé
- Cipher suites :
  - Cipher suites avec Perfect Forward Secrecy (PFS) obligatoires
  - Exemple : ECDHE + AES-GCM

**Statut AtlasTech :** Conforme.

**NIST SP 800-111 Rev. 1 - Guide to Storage Encryption Technologies :**

- Chiffrement complet du disque recommandé pour les données sensibles
- Algorithmes approuvés : AES-128, AES-256
- Gestion des clés : protection par passphrase avec dérivation de clé (PBKDF2, Argon2)

**Statut AtlasTech :** Conforme (LUKS2 + AES-256-XTS + Argon2id).

**NIST SP 800-57 - Recommendation for Key Management :**

- Durée de vie des clés cryptographiques :
  - Clés symétriques (AES-256) : 2 à 5 ans
  - Clés asymétriques (RSA 2048) : 1 à 3 ans
  - Certificats TLS : 90 jours à 1 an (Let's Encrypt : 90 jours)

**Statut AtlasTech :** Conforme (renouvellement automatique Let's Encrypt tous les 90 jours).

### OWASP (Open Web Application Security Project)

**OWASP Mobile Security Project - Mobile Top 10 (2024) :**

**M1: Improper Platform Usage**
- Stockage insécurisé des données
- Recommandation : Utilisation de Keychain (iOS) et Keystore (Android)
- **Statut AtlasTech :** Conforme (Intune impose le chiffrement).

**M2: Insecure Data Storage**
- Données sensibles stockées sans chiffrement
- Recommandation : Chiffrement au repos obligatoire
- **Statut AtlasTech :** Conforme (politique de conformité Intune).

**M9: Insecure Communication**
- Communications non chiffrées (HTTP, SIP)
- Recommandation : TLS 1.2+ pour toutes les communications
- **Statut AtlasTech :** Conforme (HTTPS + SRTP).

**OWASP Cheat Sheet Series - Cryptographic Storage :**

- Ne jamais stocker de secrets en clair
- Utiliser des solutions de gestion de secrets (Vault, AWS Secrets Manager)
- Rotation régulière des secrets

**Statut AtlasTech :** Conforme (migration vers Vault).

### ISO/IEC 27001:2022 - Annexe A

**A.8.24 - Use of cryptography :**

Objectif : Assurer l'utilisation efficace et appropriée de la cryptographie pour protéger la confidentialité, l'authenticité et l'intégrité de l'information.

**Mesures de contrôle :**
- Politique d'utilisation de la cryptographie documentée
- Gestion du cycle de vie des clés cryptographiques
- Algorithmes conformes aux standards (NIST, ANSSI)

**Statut AtlasTech :** Conforme (LUKS, TLS 1.3, Vault).

**A.5.14 - Information transfer :**

Objectif : Maintenir la sécurité de l'information lors du transfert au sein de l'organisation et vers des entités externes.

**Mesures de contrôle :**
- Chiffrement des communications réseau (TLS, VPN)
- Protection contre l'interception (MITM)

**Statut AtlasTech :** Conforme (HTTPS, SRTP).

**A.8.10 - Deletion of information :**

Objectif : Supprimer les informations stockées dans les systèmes lorsqu'elles ne sont plus nécessaires.

**Mesures de contrôle :**
- Effacement sécurisé des données (wipe, shred)
- Remote wipe pour les appareils mobiles

**Statut AtlasTech :** Conforme (Intune remote wipe, shred dans scripts).

### RGPD (Règlement Général sur la Protection des Données)

**Article 32 - Sécurité du traitement :**

Le responsable du traitement met en œuvre les mesures techniques appropriées pour garantir un niveau de sécurité adapté au risque, incluant :

**a) La pseudonymisation et le chiffrement des données à caractère personnel :**

- **Chiffrement au repos** : LUKS sur serveurs
- **Chiffrement en transit** : HTTPS, SRTP
- **Chiffrement mobile** : Intune enforcement

**Statut AtlasTech :** Conforme.

**Article 33 - Notification de violation de données :**

En cas de violation (perte/vol d'un appareil), l'entreprise doit notifier la CNIL sous 72h si les données ne sont pas chiffrées.

**Impact du chiffrement :**
- Si un smartphone chiffré est perdu : Pas d'obligation de notification (données inintelligibles pour un tiers)
- Si un disque non chiffré est volé : Notification obligatoire + amendes potentielles

**Statut AtlasTech :** Protégé (chiffrement sur tous les supports).

---

## Conclusion

La mise en œuvre des quatre piliers cryptographiques (LUKS, HTTPS, Vault, MDM) transforme radicalement la posture de sécurité d'AtlasTech Solutions.

### Tableau comparatif Before/After

| Composant | Before | After | Gain de sécurité |
|-----------|--------|-------|------------------|
| **Disques serveurs** | Non chiffré | LUKS2 AES-256-XTS | Vol physique bloqué |
| **Communications web** | HTTP | HTTPS TLS 1.3 + HSTS | MITM impossible |
| **Secrets** | Fichiers texte clair | HashiCorp Vault | Rotation automatique, audit |
| **Smartphones** | Chiffrement variable | Intune enforcement | Conformité 100%, wipe à distance |
| **VoIP** | SIP clair | SIP/TLS + SRTP | Écoute téléphonique bloquée |

### Indicateurs de sécurité

**Couverture du chiffrement :**

- **Données au repos** : 100% (serveurs + sauvegardes + mobiles)
- **Données en transit** : 100% (HTTPS + VPN + SRTP)
- **Secrets management** : 100% (migration complète vers Vault)

**Score SSL Labs :** F (HTTP) → A+ (TLS 1.3)

**Score Mozilla Observatory :** 0/100 → 95/100

**Conformité réglementaire :**

- **RGPD Article 32** : Conforme (chiffrement adapté au risque)
- **ISO 27001 A.8.24** : Conforme (politique cryptographique documentée)
- **ANSSI TLS** : Conforme (TLS 1.3 uniquement)

### Prochaines étapes recommandées

**Court terme (1-3 mois) :**

1. **HSTS Preload :**
   - Soumettre le domaine à la liste HSTS Preload (https://hstspreload.org/)
   - Garantit la protection HTTPS dès la première visite

2. **MFA pour Vault :**
   - Activer Duo Security ou TOTP pour l'authentification Vault
   - Renforcer la protection des secrets critiques

3. **Certificate Transparency Monitoring :**
   - Surveillance des certificats émis pour atlastech-solutions.com (détection de certificats frauduleux)

**Moyen terme (3-6 mois) :**

4. **Hardware Security Module (HSM) :**
   - Déploiement d'un HSM pour stocker les clés de chiffrement Vault
   - Standard FIPS 140-2 Level 2 minimum

5. **Chiffrement de la base de données MySQL :**
   - Activation de Transparent Data Encryption (TDE) via plugin InnoDB
   - Protection complémentaire au chiffrement LUKS

6. **VPN Site-to-Site chiffré :**
   - Mise en place d'IPsec entre MainServer et BackupServer
   - Chiffrement des flux de sauvegarde

**Long terme (6-12 mois) :**

7. **Zero Trust Architecture :**
   - Mutual TLS (mTLS) pour l'authentification client-serveur
   - Micro-segmentation réseau avec chiffrement bout-en-bout

8. **Quantum-Safe Cryptography :**
   - Surveillance des standards post-quantiques (NIST PQC)
   - Préparation à la migration vers des algorithmes résistants aux ordinateurs quantiques

### Ressources complémentaires

**Documentation officielle :**

- LUKS : https://gitlab.com/cryptsetup/cryptsetup/-/wikis/home
- Let's Encrypt : https://letsencrypt.org/docs/
- HashiCorp Vault : https://developer.hashicorp.com/vault/docs
- Microsoft Intune : https://learn.microsoft.com/intune/

**Outils de validation :**

- SSL Labs : https://www.ssllabs.com/ssltest/
- Mozilla Observatory : https://observatory.mozilla.org/
- testssl.sh : https://github.com/drwetter/testssl.sh
- HSTS Preload : https://hstspreload.org/

**Standards et guides :**

- ANSSI : https://cyber.gouv.fr/publications
- NIST Cybersecurity Framework : https://www.nist.gov/cyberframework
- OWASP : https://owasp.org/www-project-mobile-security/
- ISO/IEC 27001 : https://www.iso.org/standard/27001


