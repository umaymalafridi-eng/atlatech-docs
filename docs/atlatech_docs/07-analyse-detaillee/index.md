---
title: Analyse Détaillée par Domaine 
sidebar_label: Vue d'ensemble
sidebar_position: 0
---

# Analyse Détaillée par Domaine

## Vue d'ensemble du chapitre

Le **Chapitre 7** présente l'analyse technique exhaustive de l'infrastructure AtlasTech Solutions **dans son état vulnérable initial** (AVANT toute correction).

**Objectif:** Documenter de manière reproductible tous les aspects techniques permettant de comprendre les vulnérabilités identifiées au Chapitre 6.

**Méthodologie:** 
- Commandes copy-paste reproductibles
- Explication de chaque outil/protocole utilisé
- Tests depuis machines réelles (Windows 10, Ubuntu, Kali Linux)
- Screenshots et preuves tangibles

---

## Structure du chapitre

### 7.1 Identity and Access Management (IAM)

**Contenu:** 700+ lignes de documentation

**Couverture:**
- Politique de mots de passe système (Linux + Windows)
- Configuration PAM (Pluggable Authentication Modules)
- Utilisateurs et groupes (Linux + Windows)
- Privilèges sudo
- Tentatives de connexion échouées
- Historique des connexions

**Vulnérabilités critiques:**
- Mots de passe n'expirent jamais (PASS_MAX_DAYS=99999)
- Aucune complexité imposée (pam_pwquality absent)
- Windows accepte mots de passe vides (longueur min=0)
- Groupe sudo sans restriction
- Pas de fail2ban

**Score CVSS:** 9.8 (CRITIQUE)

**Fichier:** `7.1-iam-complete.md`

---

### 7.2 Gestion des mots de passe

**Contenu:** Analyse MySQL, Linux shadow, Windows

**Couverture:**
- Stockage en clair dans MySQL (25 employés)
- Statistiques (longueur min=7, max=11, avg=8.5)
- Patterns prévisibles (Prénom+Chiffres)
- Hachage Linux (yescrypt - BON)
- Politique Windows (longueur min=0 - CRITIQUE)

**Impact:**
- 25 mots de passe exposés
- Exploitation en quelques secondes avec wordlist ciblée

**Score CVSS:** 9.1 (CRITIQUE)

**Fichier:** `7.2-passwords-complete.md`

---

### 7.3 Sessions et HTTPS

**Contenu:** PHP sessions, cookies, absence HTTPS

**Couverture:**
- Configuration PHP (php.ini)
- Flags de sécurité cookies (HttpOnly, Secure, SameSite)
- Session fixation
- Interception HTTP (démonstration tcpdump)
- Port 443 fermé

**Vulnérabilités:**
- `session.use_strict_mode = 0` → Session fixation
- `session.cookie_httponly = 0` → XSS → Vol cookie
- `session.cookie_secure = 0` → Transmission non chiffrée
- HTTPS complètement absent

**Score CVSS:** 8.2 (HAUTE)

**Fichier:** `7.3-sessions-complete.md`

---

### 7.4 Cryptographie

**Contenu:** SSL/TLS, SSH, hachage, chiffrement

**Couverture:**
- HTTPS absent (port 443 fermé)
- Module SSL Apache chargé mais non configuré
- Algorithmes SSH (3DES, CBC obsolètes présents)
- MySQL sans SSL
- OpenSSL 3.0.13 (récent, sécurisé)
- Aucun chiffrement data-at-rest

**Impact:**
- Tout le trafic en clair (credentials, cookies, données)
- Secrets hardcodés dans le code

**Score CVSS:** 8.6 (HAUTE)

**Fichier:** `7.4-cryptographie-complete.md`

---

### 7.5 Application Web (Site + CRUD)

**Contenu:** 1500+ lignes (3 parties), 12 fichiers PHP analysés

**Partie 1:**
- Cartographie application (12 fichiers PHP)
- config.php (credentials hardcodés)
- login.php (SQL Injection critique)
- Tests SQLMap automatisés

**Partie 2:**
- search.php (SQL Injection UNION + XSS Reflected)
- view_employee.php (IDOR - 25 dossiers accessibles)
- admin_backup.php (téléchargement DB sans auth)

**Partie 3:**
- CRUD complet (add, edit, delete, Quick-update)
- export.php (export mots de passe en CSV)
- Tests CSRF, Mass Assignment
- Code source intégral (2411 lignes PHP)
- Matrice finale des vulnérabilités
- Scripts de test automatisés

**Vulnérabilités par fichier:**
- 8/12 fichiers avec SQL Injection (67%)
- 4/12 fichiers avec CSRF (33%)
- 2/12 fichiers avec Mass Assignment
- 1/12 fichier sans authentification (admin_backup.php)

**Données compromissables:**
- 25 identifiants + mots de passe
- 25 salaires
- 25 CIN (identité nationale)
- 25 numéros CNOPS
- Base de données complète

**Score CVSS moyen:** 7.7 (HAUTE)  
**Score CVSS max:** 9.8 (CRITIQUE) × 3 fichiers

**Fichiers:**
- `7.5-application-web-part1.md`
- `7.5-application-web-part2.md`
- `7.5-application-web-part3-final.md`

---

### 7.6 Base de données MySQL/MariaDB

**Contenu:** Structure, GRANTS, privilèges

**Couverture:**
- MariaDB 10.11.14
- 2 tables (employes, departements)
- SHOW CREATE TABLE complet
- Utilisateurs MySQL (root, admin@%, atlastech_user@%)
- GRANTS détaillés
- Variables de sécurité (local_infile, secure_file_priv)
- Pas de Foreign Keys
- Pas de triggers/stored procedures

**Vulnérabilités:**
- Mots de passe en clair (champ VARCHAR)
- admin@% avec ALL PRIVILEGES + GRANT OPTION
- local_infile = ON (lecture fichiers système)
- secure_file_priv = NULL (aucune restriction)
- Aucun chiffrement data-at-rest

**Score CVSS:** 9.8 (CRITIQUE)

**Fichier:** `7.6-database-complete.md`

---

### 7.7 Infrastructure Réseau

**Contenu:** Nmap, ports, services obsolètes

**Couverture:**
- Scan Nmap complet (7 ports analysés)
- Services exposés (SSH, HTTP, rlogin, rsh)
- Protocoles obsolètes (rlogin port 513, rsh port 514)
- Configuration pare-feu UFW (désactivé)
- Ports en écoute (ss, netstat)
- Configuration SSH (PasswordAuth, PermitRootLogin)

**Services critiques:**
- Port 80 (HTTP) - Non chiffré
- Port 513 (rlogin) - Protocole 1980, obsolète
- Port 514 (rsh) - Non chiffré
- Port 443 (HTTPS) - **FERMÉ**

**Protections absentes:**
- Pare-feu UFW désactivé
- Pas de fail2ban
- Pas de HTTPS

**Score CVSS:** 9.5 (CRITIQUE)

**Fichier:** `7.7-reseau-complete.md`

---

## Statistiques globales du Chapitre 7

### Volume de documentation

| Métrique | Valeur |
|----------|--------|
| **Sections complètes** | 7/7 (100%) |
| **Lignes de documentation** | 4000+ |
| **Fichiers analysés** | 12 PHP + configs système |
| **Commandes reproductibles** | 150+ |
| **Tests effectués** | 50+ |
| **Screenshots référencés** | 40+ |

### Vulnérabilités par domaine

| Domaine | Vulnérabilités | Score CVSS | Priorité |
|---------|----------------|------------|----------|
| 7.1 IAM | 6 critiques | 9.8 | P1 |
| 7.2 Passwords | 4 critiques | 9.1 | P1 |
| 7.3 Sessions | 4 critiques | 8.2 | P1 |
| 7.4 Crypto | 5 critiques | 8.6 | P1 |
| 7.5 WebApp | 10 critiques | 7.7 (moy) | P1 |
| 7.6 Database | 5 critiques | 9.8 | P1 |
| 7.7 Network | 4 critiques | 9.5 | P1 |

**Total:** 38 vulnérabilités critiques identifiées

### Répartition CVSS

```
CRITIQUE (9.0-10.0):  18 vulnérabilités (47%)  ████████████████████
HAUTE    (7.0-8.9):   15 vulnérabilités (39%)  ████████████████
MOYENNE  (4.0-6.9):    5 vulnérabilités (13%)  █████
BASSE    (0.1-3.9):    0 vulnérabilité   (0%)  
```

### Conformité réglementaire

**RGPD - Violations:**
- Article 5(1)(f) - Intégrité et confidentialité 
- Article 25 - Protection dès la conception 
- Article 32 - Sécurité du traitement 
- Article 33 - Notification violation (obligatoire sous 72h si exploitation)

**Loi 09-08 (Maroc):**
- Article 23 - Obligation de sécurisation 

**Standards techniques:**
- OWASP Top 10 2021 
- CIS Benchmarks 
- ISO 27001 
- PCI DSS 

---

## Navigation du chapitre

### Ordre de lecture recommandé

**Pour une compréhension globale:**
1. **INDEX** (ce document)
2. **7.5 Application Web** (vulnérabilités les plus critiques)
3. **7.6 Database** (données exposées)
4. **7.1 IAM** (gestion des accès)
5. **7.7 Réseau** (surface d'attaque)
6. **7.2, 7.3, 7.4** (aspects complémentaires)

**Pour un audit technique:**
- Lire dans l'ordre numérique (7.1 → 7.7)

**Pour une revue de sécurité rapide:**
- Consulter uniquement les "Synthèse" et "Score CVSS" de chaque section

---

## Outils et technologies documentés

### Outils d'analyse

| Outil | Usage | Section |
|-------|-------|---------|
| **curl** | Tests HTTP, exploitation SQL Injection | 7.5 |
| **sqlmap** | Exploitation SQL Injection automatisée | 7.5 |
| **nmap** | Scan de ports, détection services | 7.7 |
| **nikto** | Scan vulnérabilités web | 7.5 |
| **tcpdump** | Capture trafic réseau | 7.3 |
| **Burp Suite** | Proxy HTTP, tests CSRF/IDOR | 7.5 |

### Commandes système

| Commande | Usage | Section |
|----------|-------|---------|
| `mysql` | Requêtes SQL, extraction données | 7.6 |
| `ss / netstat` | Ports en écoute | 7.7 |
| `lastlog / lastb` | Historique connexions | 7.1 |
| `cat /etc/shadow` | Analyse hachage mots de passe | 7.2 |
| `apache2ctl -M` | Modules Apache | 7.4 |
| `ufw status` | État pare-feu | 7.7 |

### Protocoles et standards

| Protocole | Description | Section |
|-----------|-------------|---------|
| **HTTP** | Non chiffré (vulnérable) | 7.3, 7.4 |
| **HTTPS/TLS** | Absent (critique) | 7.3, 7.4 |
| **SSH** | Chiffré (présent mais auth faible) | 7.7 |
| **rlogin/rsh** | Obsolètes, non chiffrés | 7.7 |
| **PHP Sessions** | Non sécurisées | 7.3 |
| **MySQL** | Sans SSL | 7.6 |

---

## Reproductibilité

**Toutes les commandes de ce chapitre sont reproductibles.**

**Prérequis:**
- Accès SSH à MainServer (192.168.112.141)
- Machine Kali Linux (192.168.112.128) pour tests
- Poste Windows 10 (192.168.112.137) pour tests IAM

**Scripts d'automatisation fournis:**
- `test_sql_injection_all.sh` (7.5)
- `idor_enumeration.sh` (7.5)
- `csrf_add_employee.sh` (7.5)
- `collect_iam_evidence.sh` (7.1)

---

## Références aux chapitres correctifs

**Les corrections de ces vulnérabilités sont documentées dans:**

| Vulnérabilité | Chapitre correctif |
|---------------|-------------------|
| SQL Injection | Chapitre 15 - Sécurité Applicative |
| XSS, CSRF, IDOR | Chapitre 15 - Sécurité Applicative |
| IAM, PAM | Chapitre 15.2 - Configuration PAM |
| HTTPS absent | Chapitre 14 - SSL/TLS |
| Database | Chapitre 16 - Base de données sécurisée |
| Réseau | Chapitre 18 - Durcissement réseau |
| Services obsolètes | Chapitre 18 - Désactivation services |

---

## Conclusion

Le **Chapitre 7** constitue la **base technique** de tout le projet de sécurisation AtlasTech Solutions.

**Points clés:**
- **38 vulnérabilités critiques** documentées
- **100% reproductibles** avec commandes fournies
- **4000+ lignes** de documentation technique
- **150+ commandes** copy-paste ready

**Ce chapitre répond aux questions:**
-  **Comment** les vulnérabilités existent-elles techniquement ?
-  **Pourquoi** sont-elles exploitables ?
-  **Comment** les reproduire pour validation ?

**Impact organisationnel:**
- Violation RGPD Articles 5, 25, 32
- Exposition de 25 dossiers employés complets
- Risque d'amende jusqu'à 4% CA ou 20M€
- Compromission complète possible en < 60 secondes

---

**Prochaine étape:** Chapitre 8 et suivants - Corrections et sécurisation

---

**Version:** 1.0  
**Date:** 14 février 2026  
**Statut:**  COMPLET