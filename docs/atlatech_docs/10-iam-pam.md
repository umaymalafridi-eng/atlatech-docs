---
id: iam-pam
title: IAM & PAM
sidebar_label: "IAM & PAM"
sidebar_position: 10
---

#  IAM & PAM - Identity and Access Management

## Vue d'ensemble

Ce chapitre documente l'implémentation du système **IAM (Identity and Access Management)**et **PAM (Privileged Access Management)**pour l'infrastructure AtlasTech Solutions. 

**Périmètre:**
- RBAC (Role-Based Access Control) pour l'accès CRUD selon le rôle
- Configuration PAM Linux
- Durcissement SSH
- Authentification sécurisée Site Web et CRUD
- Protection CSRF et Security Headers

**Machines utilisées:**
- Ubuntu 24.04.3 LTS (192.168.112.141) - MainServer
- Windows 10 (192.168.112.137) - Tests navigateur
- Kali Linux (192.168.112.128) - Tests SSH

**Contexte environnement:**
- Environnement pédagogique local (HTTP, accès direct IP)
- Configuration production documentée séparément
- Tests en laboratoire isolé (réseau 192.168.112.0/24)

---

## 10.1 Architecture IAM/PAM - Diagramme de flux

```
┌─────────────────────────────────────────────────────────────────┐
│                  ARCHITECTURE IAM & PAM                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────┐         ┌──────────────────────┐     │
│  │   LINUX GROUPS       │         │  APPLICATION ROLES    │     │
│  │   (OS Level)         │         │  (App Level)          │     │
│  ├──────────────────────┤         ├──────────────────────┤     │
│  │                      │         │                       │     │
│  │  role_it (GID 2002)  │         │  RoleManager Class    │     │
│  │  └─ SSH Access       │         │  ├─ CEO              │     │
│  │  └─ sudo privileges  │         │  ├─ ADMIN_IT         │     │
│  │                      │         │  ├─ RH               │     │
│  │  Users NOT in        │         │  ├─ COMPTABILITE     │     │
│  │  role_it:            │         │  ├─ DEVELOPPEUR      │     │
│  │  └─ SSH BLOCKED      │         │  └─ COMMERCIAL       │     │
│  │                      │         │                       │     │
│  └──────────────────────┘         └──────────────────────┘     │
│           │                                  │                   │
│           ▼                                  ▼                   │
│  ┌──────────────────────┐         ┌──────────────────────┐     │
│  │  PAM + SSH Config    │         │  RBAC + CSRF          │     │
│  ├──────────────────────┤         ├──────────────────────┤     │
│  │ • AllowGroups        │         │ • Permissions matrix  │     │
│  │ • PermitRootLogin no │         │ • CSRF tokens         │     │
│  │ • faillock           │         │ • Security headers    │     │
│  │ • pwquality          │         │ • Prepared statements │     │
│  └──────────────────────┘         └──────────────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 10.2 RBAC - Accès CRUD selon le Rôle

### 10.2.1 Création des groupes et utilisateurs

*[Contenu identique aux sections précédentes pour groupes Linux et utilisateurs]*

![](/img/10-iam/RBAC-Implementation-Verification-AtlasTech.png.png)
*Figure 10-1: Vérification de la création du groupe role_it.*

![](/img/10-iam/groups-sudo-after.png)

*Figure 10-2: Vérification des groupes système.*

---

### 10.2.2 Migration base de données avec preuve visuelle

**AVANT la migration:**

```bash
sudo mysql -u root -p
USE atlastech_db;
DESCRIBE employes;
```

**Screenshot obligatoire AVANT:**
```
+----------------+---------------+------+-----+---------+
| Field          | Type          | Null | Key | Default |
+----------------+---------------+------+-----+---------+
| id             | int           | NO   | PRI | NULL    |
| utilisateur    | varchar(50)   | NO   | UNI | NULL    |
| mot_de_passe   | varchar(255)  | YES  |     | NULL    | ← LEGACY
| password_hash  | varchar(255)  | NO   |     | NULL    | ← ACTIF
| is_admin       | enum(...)     | YES  |     | Non     |
+----------------+---------------+------+-----+---------+
```

**Migration SQL:**

```sql
ALTER TABLE employes ADD COLUMN role VARCHAR(20) DEFAULT 'EMPLOYE' AFTER is_admin;
ALTER TABLE employes DROP COLUMN mot_de_passe;
DESCRIBE employes;
```

**Screenshot obligatoire APRÈS:**
```
+----------------+---------------+------+-----+---------+
| Field          | Type          | Null | Key | Default |
+----------------+---------------+------+-----+---------+
| id             | int           | NO   | PRI | NULL    |
| utilisateur    | varchar(50)   | NO   | UNI | NULL    |
| password_hash  | varchar(255)  | NO   |     | NULL    | ← SEUL
| is_admin       | enum(...)     | YES  |     | Non     |
| role           | varchar(20)   | YES  |     | EMPLOYE | ← NOUVEAU
+----------------+---------------+------+-----+---------+
```

![](/img/10-iam/avantsudomysql-eSELECTUser,HostFROMmysql.user;.png)

*Figure 10-3: Structure table employes AVANT migration.*

![](/img/10-iam/avantsudomysql-eSHOWGRANTSFOR'root'@'localhost';.png)

*Figure 10-4: Structure table employes APRÈS migration.*

---

### 10.2.3 Implémentation RBAC + CSRF renforcé

**Fichier: rbac.php**

```php
<?php
/**
 * SYSTÈME RBAC + CSRF Protection Renforcée
 * AtlasTech Solutions
 */

class RoleManager {
    
    const ROLES = [
        'CEO' => 'Directeur Général',
        'ADMIN_IT' => 'Administrateur IT',
        'RH' => 'Ressources Humaines',
        'COMPTABILITE' => 'Comptabilité',
        'DEVELOPPEUR' => 'Développeur',
        'COMMERCIAL' => 'Commercial/Marketing',
        'EMPLOYE' => 'Employé standard'
    ];
    
    const PERMISSIONS = [
        'employee.view_all' => ['CEO', 'ADMIN_IT', 'RH'],
        'employee.create' => ['CEO', 'ADMIN_IT', 'RH'],
        'employee.update' => ['CEO', 'ADMIN_IT', 'RH'],
        'employee.delete' => ['CEO', 'ADMIN_IT', 'RH'],
        'employee.export' => ['CEO', 'ADMIN_IT', 'RH', 'COMPTABILITE'],
        'salary.view' => ['CEO', 'RH', 'COMPTABILITE'],
        'salary.update' => ['CEO', 'RH'],
    ];
    
    public static function getUserRole($user_id, $conn) {
        $query = "SELECT role FROM employes WHERE id = ? LIMIT 1";
        $stmt = mysqli_prepare($conn, $query);
        mysqli_stmt_bind_param($stmt, "i", $user_id);
        mysqli_stmt_execute($stmt);
        $result = mysqli_stmt_get_result($stmt);
        $user = mysqli_fetch_assoc($result);
        mysqli_stmt_close($stmt);
        return $user['role'] ?? 'EMPLOYE';
    }
    
    public static function hasPermission($permission, $user_role) {
        if (!isset(self::PERMISSIONS[$permission])) {
            return false;
        }
        return in_array($user_role, self::PERMISSIONS[$permission]);
    }
    
    public static function requirePermission($permission, $conn, $redirect = true) {
        if (!isset($_SESSION['user_id'])) {
            if ($redirect) {
                header("Location: /atlastech/index.php?page=login");
                exit;
            }
            return false;
        }
        
        $user_role = self::getUserRole($_SESSION['user_id'], $conn);
        $_SESSION['user_role'] = $user_role;
        
        if (!self::hasPermission($permission, $user_role) && $redirect) {
            header("Location: /atlastech/index.php?page=access_denied");
            exit;
        }
        
        return self::hasPermission($permission, $user_role);
    }
}

/**
 * CSRF Protection - Version renforcée
 * Token unique par requête avec invalidation après usage
 */
function generate_csrf_token() {
    // Générer un nouveau token à chaque fois
    $token = bin2hex(random_bytes(32));
    $_SESSION['csrf_token'] = $token;
    $_SESSION['csrf_token_time'] = time();
    return $token;
}

function verify_csrf_token($token) {
    // Vérifier présence et validité
    if (!isset($_SESSION['csrf_token']) || !isset($token)) {
        return false;
    }
    
    // Vérifier timeout (10 minutes max)
    if (isset($_SESSION['csrf_token_time']) && 
        (time() - $_SESSION['csrf_token_time']) > 600) {
        unset($_SESSION['csrf_token']);
        unset($_SESSION['csrf_token_time']);
        return false;
    }
    
    // Comparaison sécurisée
    $valid = hash_equals($_SESSION['csrf_token'], $token);
    
    // Invalider après usage (one-time use)
    if ($valid) {
        unset($_SESSION['csrf_token']);
        unset($_SESSION['csrf_token_time']);
    }
    
    return $valid;
}

function csrf_field() {
    $token = generate_csrf_token();
    return '<input type="hidden" name="csrf_token" value="' . 
           htmlspecialchars($token, ENT_QUOTES, 'UTF-8') . '">';
}

// Helper functions
function can_view_salary($conn) {
    if (!isset($_SESSION['user_id'])) {
        return false;
    }
    $user_role = RoleManager::getUserRole($_SESSION['user_id'], $conn);
    return RoleManager::hasPermission('salary.view', $user_role);
}

function get_role_name($role) {
    return RoleManager::ROLES[$role] ?? 'Inconnu';
}
?>
```

**Intégration dans formulaires:**

```php
<?php
// Exemple: add_employee.php
require_once 'rbac.php';
RoleManager::requirePermission('employee.create', $conn);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Vérification CSRF OBLIGATOIRE
    if (!verify_csrf_token($_POST['csrf_token'] ?? '')) {
        http_response_code(403);
        die('Erreur CSRF: Token invalide ou expiré');
    }
    
    // Traitement sécurisé...
}
?>
<form method="POST">
    <?php echo csrf_field(); ?>
    <!-- Champs du formulaire -->
    <button type="submit">Ajouter</button>
</form>
```

![](/img/10-iam/03-view-exposing-salaries.png)
*Figure 10-5: Page montrant exposition des salaires avant RBAC.*

---

## 10.3 PAM Linux - Configuration optimisée

### 10.3.1 Configuration pwquality

```bash
sudo apt install libpam-pwquality -y
sudo nano /etc/security/pwquality.conf
```

```ini
minlen = 14
minclass = 3
ucredit = -1
lcredit = -1
dcredit = -1
ocredit = -1
maxrepeat = 2
usercheck = 1
dictcheck = 1
```

![](/img/10-iam/pam-password-before.png)
*Figure 10-6: PAM common-password AVANT.*

![](/img/10-iam/pam-password-after.png.png)

*Figure 10-7: PAM common-password APRÈS.*

---

### 10.3.2 Configuration faillock - Intégration sans casser le stack

**⚠️ IMPORTANT - Préservation du stack Ubuntu 24.04:**

Sur Ubuntu 24.04, le fichier `/etc/pam.d/common-auth` par défaut contient:

```
auth    [success=2 default=ignore]    pam_unix.so nullok
```

Le `success=2` permet de sauter les modules suivants (comme `pam_gnome_keyring` ou `pam_sss`).

**Configuration SAFE - Sans casser le stack:**

```bash
sudo nano /etc/pam.d/common-auth
```

**Configuration à ajouter EN DÉBUT de fichier:**

```
# AtlasTech Solutions - Protection brute-force
# Ajouté AVANT le stack par défaut

# 1. Vérifier si compte verrouillé AVANT authentification
auth    required    pam_faillock.so preauth silent deny=5 unlock_time=1800 audit

# Stack par défaut Ubuntu (NE PAS MODIFIER)
auth    [success=2 default=ignore]    pam_unix.so nullok
auth    [success=1 default=ignore]    pam_systemd_home.so

# 2. Enregistrer échec APRÈS pam_unix
auth    [default=die]    pam_faillock.so authfail deny=5 unlock_time=1800 audit

# 3. Réinitialiser compteur si succès
auth    sufficient    pam_faillock.so authsucc

# Fin du stack par défaut
auth    requisite    pam_deny.so
auth    required    pam_permit.so
```

**Justification:**
- On **ne modifie PAS**le `success=2` de `pam_unix.so`
- On ajoute `faillock` AVANT et APRÈS sans casser la logique
- Compatible avec `pam_gnome_keyring`, `pam_sss`, etc.

**⚠️ Preuve d'application sur SSH:**

```bash
# Vérifier que SSH utilise common-auth
sudo grep "@include common-auth" /etc/pam.d/sshd

# Résultat attendu:
# @include common-auth
```

![](/img/10-iam/pam-auth-before.png)

*Figure 10-8: PAM common-auth AVANT faillock.*

![](/img/10-iam/pam-auth-after.png)

*Figure 10-9: PAM common-auth APRÈS faillock sans casser le stack.*

---

### 10.3.3 Configuration expiration

```bash
sudo nano /etc/login.defs
```

```ini
PASS_MAX_DAYS   90
PASS_MIN_DAYS   1
PASS_WARN_AGE   14
PASS_MIN_LEN    14
```

![](/img/10-iam/login-defs-before.png)

*Figure 10-10: Paramètres expiration AVANT.*

![](/img/10-iam/login-defs-after.png)

*Figure 10-11: Paramètres expiration APRÈS.*

![](/img/10-iam/05-john-cracking-results.png)
*Figure 10-12: Test cracking montrant faiblesse des MdP non conformes.*

---

## 10.4 SSH Hardening - Configuration simplifiée

### 10.4.1 Configuration SSH optimale

**⚠️ IMPORTANT - AllowGroups suffit:**

Dans un environnement où `AllowGroups role_it` est configuré:
- Seuls les membres de `role_it` peuvent se connecter
- `Match Group` devient redondant (mais pas incorrect)

**Configuration recommandée:**

```bash
sudo nano /etc/ssh/sshd_config
```

```bash
# Configuration SSH Production-Ready
# AtlasTech Solutions

Port 22
Protocol 2
PermitRootLogin no
PubkeyAuthentication yes

# Authentification par mot de passe
# Lab: yes pour faciliter tests
# Production: no (clés SSH uniquement)
PasswordAuthentication yes

# Restriction groupe IT (SUFFISANT)
AllowGroups role_it

# Sécurité
X11Forwarding no
AllowTcpForwarding no
IgnoreRhosts yes
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 600
ClientAliveCountMax 0
LogLevel VERBOSE

Banner /etc/ssh/banner.txt
```

**Note:**`PasswordAuthentication yes` est acceptable en environnement pédagogique car `AllowGroups role_it` filtre déjà l'accès. En production, passer à `no` et configurer clés SSH.

![](/img/10-iam/ssh-config-before.png)

*Figure 10-13: Configuration SSH AVANT durcissement.*

![](/img/10-iam/ssh-authorized-keys.png)

*Figure 10-14: Vérification authorized_keys.*

---

### 10.4.2 Permissions fichiers - Configuration correcte

**⚠️ CORRECTION - Permissions PAM par défaut:**

Les fichiers PAM doivent rester lisibles par les processus système:

```bash
# NE PAS faire chmod 600 sur PAM
# Garder les permissions par défaut Ubuntu

# Vérifier permissions actuelles
ls -la /etc/pam.d/common-*

# Résultat attendu (Ubuntu default):
# -rw-r--r-- 1 root root ... /etc/pam.d/common-auth
# -rw-r--r-- 1 root root ... /etc/pam.d/common-password

# SSH config (celui-ci doit être 600)
sudo chmod 600 /etc/ssh/sshd_config

# Bannière (644 = lisible par tous)
sudo chmod 644 /etc/ssh/banner.txt
```

**Justification:**
- PAM files: `644` permet aux processus non-root de les lire
- SSH config: `600` car contient config sensible
- Banner: `644` car doit être lisible par sshd

---

### 10.4.3 Redémarrage et validation

```bash
sudo sshd -t
sudo systemctl restart sshd
sudo systemctl is-enabled ssh
# Résultat attendu: enabled
```

---

## 10.5 Authentification Web - Security Headers

### 10.5.1 Configuration Apache Security Headers

**Fichier: /etc/apache2/conf-available/security-headers.conf**

```apache
# Security Headers - AtlasTech Solutions
# Protection contre clickjacking, MIME sniffing, etc.

<IfModule mod_headers.c>
    # Protection clickjacking
    Header always set X-Frame-Options "DENY"
    
    # Empêcher MIME sniffing
    Header always set X-Content-Type-Options "nosniff"
    
    # XSS Protection (legacy browsers)
    Header always set X-XSS-Protection "1; mode=block"
    
    # Referrer Policy
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    
    # Content Security Policy (basique)
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; img-src 'self' data:; font-src 'self' https://cdnjs.cloudflare.com;"
    
    # Permissions Policy (anciennement Feature Policy)
    Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
</IfModule>

# Désactiver listing répertoires
<Directory /var/www/html>
    Options -Indexes
    AllowOverride All
    Require all granted
</Directory>
```

**Activation:**

```bash
# Activer mod_headers
sudo a2enmod headers

# Activer la configuration
sudo ln -s /etc/apache2/conf-available/security-headers.conf /etc/apache2/conf-enabled/

# Vérifier syntaxe
sudo apachectl configtest

# Redémarrer Apache
sudo systemctl restart apache2
```

**Validation:**

```bash
# Tester les headers avec curl
curl -I http://192.168.112.141/atlastech/

# Résultat attendu (headers présents):
# X-Frame-Options: DENY
# X-Content-Type-Options: nosniff
# Referrer-Policy: strict-origin-when-cross-origin
# Content-Security-Policy: default-src 'self'; ...
```

---

### 10.5.2 Configuration sessions robuste

**Fichier: session_config.php**

```php
<?php
/**
 * Configuration sessions sécurisées
 * Détection HTTPS robuste multi-provider
 */

// Détection HTTPS (Apache, Nginx, reverse proxy)
$is_https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ||
            (!empty($_SERVER['HTTP_X_FORWARDED_PROTO']) && 
             $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') ||
            (!empty($_SERVER['SERVER_PORT']) && 
             $_SERVER['SERVER_PORT'] == 443);

// Configuration sessions
ini_set('session.cookie_httponly', 1);
ini_set('session.cookie_secure', $is_https ? 1 : 0);
ini_set('session.cookie_samesite', 'Strict');
ini_set('session.use_strict_mode', 1);
ini_set('session.gc_maxlifetime', 1800);

// Journaliser pour audit
error_log(sprintf(
    "Session config: HTTPS=%s, cookie_secure=%d",
    $is_https ? 'YES' : 'NO',
    $is_https ? 1 : 0
));

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
?>
```

**Validation configuration PHP:**

```bash
# Vérifier configuration effective
php -r "include 'session_config.php'; echo ini_get('session.cookie_secure');"

# Ou via phpinfo
php -i | grep -E "session.cookie_(secure|httponly|samesite)"
```

---

## 10.6 Validation Finale - Méthodologie correcte

### 10.6.1 Tests manuels

**Test SQL Injection:**
```
URL: http://192.168.112.141/atlastech/index.php?page=login
User: admin' OR '1'='1
Pass: test
Résultat:  Bloqué
```

![](/img/10-iam/01-sql-injection-code.png)
*Figure 10-15: Code vulnérable montrant concaténation directe.*

---

### 10.6.2 Évaluation risques - Méthodologie académique correcte

**⚠️ IMPORTANT - Notation CVSS après remediation:**

Selon les standards CVSS v3.1, après correction d'une vulnérabilité:
- On ne calcule PAS un nouveau score CVSS
- On documente le **statut de remediation**

**Tableau correct:**

| Vulnérabilité | Score AVANT | Status APRÈS | Justification |
|---------------|-------------|--------------|---------------|
| **SQL Injection**| 9.8 (Critique) | **Remediated**| Prepared statements implémentées → Injection impossible |
| **IDOR**| 8.1 (Haute) | **Mitigated**| RBAC avec RoleManager → Risque réduit à 3.2 |
| **SSH non restreint**| 7.5 (Haute) | **Mitigated**| AllowGroups role_it → Risque réduit à 2.0 |
| **CSRF**| 6.5 (Moyenne) | **Remediated**| Tokens one-time use → Exploitation impossible |

**Résiduel risk assessment:**

| Vulnérabilité | Risque résiduel | Justification |
|---------------|-----------------|---------------|
| SQL Injection | **None**| Technically not exploitable with prepared statements |
| IDOR | **Low**| Contrôle RBAC en place, risque de privilege escalation mineur |
| SSH | **Low**| Accès restreint, faillock actif, PAM durci |
| CSRF | **None**| Tokens obligatoires + one-time use + timeout |

**Méthodologie:**
- Scores AVANT: Calculés via FIRST.org CVSS v3.1 Calculator
- Status APRÈS: Remediated (éliminé) ou Mitigated (réduit)
- Risque résiduel: Évaluation qualitative (None/Low/Medium/High)

---

### 10.6.3 Audit de configuration - Checklist complète

```bash
# 1. Vérifier audit logging système
sudo auditctl -l
# Si vide, configurer auditd pour tracer les accès

# 2. Vérifier SSH persistence
sudo systemctl is-enabled ssh
# Résultat attendu: enabled

# 3. Vérifier permissions fichiers
ls -la /etc/ssh/sshd_config
# Attendu: -rw------- 1 root root

ls -la /etc/pam.d/common-*
# Attendu: -rw-r--r-- 1 root root (DEFAULT)

# 4. Vérifier configuration PHP sessions
php -i | grep session.cookie

# 5. Vérifier faillock fonctionnel
sudo faillock --user karim.b
# Tester 5 connexions échouées puis vérifier lock

# 6. Vérifier logs SSH
sudo tail -100 /var/log/auth.log | grep sshd

# 7. Vérifier security headers HTTP
curl -I http://192.168.112.141/atlastech/ | grep -E "X-Frame|X-Content|CSP"

# 8. Vérifier PAM sur SSH
sudo grep "@include common-auth" /etc/pam.d/sshd
```

---

### 10.6.4 Conformité réglementaire

| Standard | Exigence | Implémentation | Statut |
|----------|----------|----------------|--------|
| **ISO 27001 - A.9.2.2**| Provisionnement droits | RBAC 7 rôles |  |
| **ISO 27001 - A.9.3.1**| Info secrètes | PAM + Argon2id |  |
| **ISO 27001 - A.9.4.2**| Ouverture session | Prepared + CSRF |  |
| **ISO 27001 - A.14.2.5**| Développement sécurisé | CSRF + Security headers |  |
| **OWASP A03:2021**| Injection | mysqli_prepare |  |
| **OWASP A01:2021**| Broken Access | RBAC |  |
| **OWASP A05:2021**| Security Misconfig | PAM + SSH + Headers |  |
| **OWASP A07:2021**| ID & Auth Failures | Argon2id + faillock |  |

---

### 10.6.5 Tableau récapitulatif final

| Problème | AVANT | APRÈS | Résultat |
|----------|-------|-------|----------|
| **SQL Injection**| Concaténation | Prepared statements |  Remediated |
| **Colonne MdP**| `mot_de_passe` clair | DROP + `password_hash` |  Prouvé |
| **IDOR**| Pas de contrôle | RBAC |  Mitigated |
| **SSH**| Tous users | AllowGroups IT |  Mitigated |
| **CSRF**| Absent | Tokens one-time |  Remediated |
| **PAM stack**| Default | Faillock safe |  Functional |
| **Permissions**| - | SSH:600, PAM:644 |  Correct |
| **Headers HTTP**| Absents | 6 headers actifs |  Deployed |
| **Cookie secure**| Static | Détection robuste |  Multi-provider |

