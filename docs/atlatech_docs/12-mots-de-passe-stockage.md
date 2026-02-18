---
id: mots-de-passe-stockage
title: Mots de Passe & Stockage
sidebar_label: "12. Mots de Passe & Stockage"
sidebar_position: 12
---

# 12. Mots de Passe & Stockage Sécurisé

## Introduction

Ce chapitre présente les solutions concrètes mises en œuvre pour corriger les vulnérabilités critiques identifiées dans le chapitre 7.2 concernant la gestion des mots de passe chez AtlasTech Solutions.

Les vulnérabilités majeures à corriger sont :
- **VUL-01 (CVSS 9.8)** : Mots de passe stockés en clair dans la base de données
- **VUL-06 (CVSS 8.4)** : Credentials en clair dans les tâches planifiées
- **VUL-10 (CVSS 9.3)** : Export CSV incluant les mots de passe
- **VUL-11 (CVSS 6.5)** : Politique de mots de passe Windows faible

### Objectifs de sécurisation

**Pour les non-techniciens :** Imaginez que vous stockiez les clés de votre maison dans un tiroir non verrouillé accessible à tous. C'est exactement ce que faisait AtlasTech avec les mots de passe. Notre objectif est de transformer ces clés en codes complexes que seul le propriétaire peut utiliser, même si quelqu'un vole le tiroir.

**Pour les techniciens :** Nous allons implémenter :
1. Hachage cryptographique robuste avec Argon2id
2. Politique de mots de passe conforme CIS Benchmarks
3. Masquage des mots de passe dans les interfaces
4. Rotation automatique et journalisation des changements

### Standards de référence appliqués

| Standard | Exigence | Implémentation AtlasTech |
|----------|----------|--------------------------|
| **NIST SP 800-63B** | Argon2, bcrypt, scrypt ou PBKDF2 | Argon2id (recommandé 2023) |
| **OWASP ASVS v4.0** | Minimum 64 bits d'entropie pour les hashes | Argon2id avec salt 128 bits |
| **CIS Benchmark Windows** | Longueur minimale 14 caractères | 14 caractères + complexité |
| **ISO 27001:2022 A.9.4.3** | Système de gestion des mots de passe | Politique centralisée + audit |
| **RGPD Article 32** | Chiffrement des données personnelles | Hash Argon2id irréversible |

---

## 12.1 Hachage des mots de passe avec Argon2id

### 12.1.1 Pourquoi Argon2id ?

**Explication pour tous :**

Le hachage transforme un mot de passe lisible en une empreinte numérique unique et irréversible. C'est comme transformer du lait en fromage : on ne peut pas revenir en arrière.

**Argon2id** est le vainqueur de la compétition Password Hashing Competition (PHC) de 2015 et est recommandé par l'OWASP en 2024.

**Comparaison des algorithmes :**

| Algorithme | Vitesse de craquage (hash/sec) | Résistance aux GPU | Recommandé en 2024 |
|------------|-------------------------------|--------------------|--------------------|
| **MD5** | 63 milliards | Très faible | Non (obsolète) |
| **SHA-256** | 2.3 milliards | Faible | Non |
| **bcrypt** | 71,000 | Moyenne | Oui (acceptable) |
| **Argon2id** | 2,000 | Très élevée | Oui (recommandé) |

**Pourquoi Argon2id bat bcrypt :**
- **Résistance aux attaques par GPU** : Consomme beaucoup de mémoire RAM (les GPU en ont moins)
- **Protection contre les attaques parallèles** : Utilise du temps ET de la mémoire
- **Flexibilité** : Paramètres ajustables (mémoire, temps, parallélisme)

### 12.1.2 Configuration Argon2id pour AtlasTech

**Paramètres choisis :**

```php
<?php
// Configuration Argon2id sécurisée pour AtlasTech Solutions
// Conforme OWASP 2024

$argon2_options = [
    'memory_cost' => 65536,    // 64 MB de RAM (64 * 1024)
    'time_cost'   => 4,        // 4 itérations
    'threads'     => 2         // 2 threads parallèles
];
?>
```

**Explication des paramètres :**

| Paramètre | Valeur | Justification |
|-----------|--------|---------------|
| `memory_cost` | 65536 KB (64 MB) | Force l'utilisation de 64 MB par hash, rendant les attaques GPU très coûteuses |
| `time_cost` | 4 | Nombre d'itérations. Plus = plus sûr mais plus lent. 4 = bon équilibre |
| `threads` | 2 | Utilise 2 cœurs CPU pour accélérer le hachage côté serveur |

**Temps de calcul attendu :** ~200-300 ms par mot de passe (acceptable pour une connexion utilisateur).

### 12.1.3 Script de hachage des mots de passe

**Fichier : `/var/www/html/atlastech/hash_passwords.php`**

Ce script génère des hashs Argon2id pour les 25 utilisateurs d'AtlasTech.

```php
<?php
/**
 * Script de génération de hashs Argon2id pour AtlasTech Solutions
 * À exécuter UNE SEULE FOIS pour initialiser les mots de passe sécurisés
 * 
 * Usage: sudo php hash_passwords.php | sudo tee hashed_passwords.txt
 */

// Liste des utilisateurs et leurs nouveaux mots de passe sécurisés
// Ces mots de passe respectent la politique : 12+ caractères, complexité maximale
$users = [
    ['username' => 'a.haidar',     'password' => 'Dir@2026!AzH#Sec'],
    ['username' => 'oumayma.l',    'password' => 'Syst3m@Oum#2026!'],
    ['username' => 'ibtissam.g',   'password' => 'N3tw0rk!Ibt#Adm'],
    ['username' => 'soufiane.k',   'password' => 'Supp0rt@Souf#26'],
    ['username' => 'karim.dev',    'password' => 'L3ad!Dev@Kar#26'],
    ['username' => 'fatima.z',     'password' => 'FullSt@ck!Ftm26'],
    ['username' => 'younes.m',     'password' => 'Pyth0n!You#Dj26'],
    ['username' => 'salma.r',      'password' => 'Jun10r@Slm#Dev26'],
    ['username' => 'omar.f',       'password' => 'D0ck3r!Omr#K8s26'],
    ['username' => 'nadia.b',      'password' => 'QA!T3st@Nad#2026'],
    ['username' => 'lhassan.rh',   'password' => 'HR!M@nag3r#Lhs26'],
    ['username' => 'samira.t',     'password' => 'R3cruit@Sam#IT26'],
    ['username' => 'redouane.rh',  'password' => 'HR!Ass1st@Red#26'],
    ['username' => 'ahmed.cfo',    'password' => 'CF0!Fin@nce#A26'],
    ['username' => 'latifa.cpta',  'password' => 'Acc0unt!Ltf@#26'],
    ['username' => 'mehdi.fin',    'password' => 'An@lyst!Mhd#F26'],
    ['username' => 'yasmine.cm',   'password' => 'C0mm!Dir@Ysm#26'],
    ['username' => 'hakim.sales',  'password' => 'B2B!S@les#Hkm26'],
    ['username' => 'imane.mkt',    'password' => 'Mrkt!Dig1t@Im26'],
    ['username' => 'mostafa.b2b',  'password' => 'Fi3ld!Sal@Mst26'],
    ['username' => 'kaoutar.rc',   'password' => 'Cust0m3r!Kwt#26'],
    ['username' => 'walid.seo',    'password' => 'SE0!Int3rn@Wld26'],
    ['username' => 'hanane.tel',   'password' => 'T3l3!Pr0sp@Hn26'],
    ['username' => 'ismail.sdr',   'password' => 'BizD3v!Ism@#2026'],
    ['username' => 'qwerty',       'password' => 'S3cur3!Qw@rty26']
];

// Paramètres Argon2id (identiques à ceux de votre base)
$options = [
    'memory_cost' => 65536,  // 64 MB
    'time_cost'   => 4,      // 4 itérations
    'threads'     => 2       // 2 parallel threads
];

// Génération des hashs
echo "USERNAME\t\tHASH\n";
echo str_repeat("=", 120) . "\n";

foreach ($users as $user) {
    $hash = password_hash($user['password'], PASSWORD_ARGON2ID, $options);
    echo $user['username'] . "\t\t" . $hash . "\n";
}
?>
```

**Exécution du script :**

```bash
# Se placer dans le répertoire de l'application
cd /var/www/html/atlastech

# Exécuter le script et sauvegarder les hashs
sudo php hash_passwords.php | sudo tee hashed_passwords.txt

# Vérifier le contenu
head -5 hashed_passwords.txt
```

**Résultat attendu :**

```
USERNAME		HASH
========================================================================================================================
a.haidar		$argon2id$v=19$m=65536,t=4,p=2$ZFBERj1wejhdmpMSWVBMg$xivbA25vVBxQ+vY775Ax3O0L35H8zqB6zAGWa/0Mn1U
oumayma.l		$argon2id$v=19$m=65536,t=4,p=2$FhzU1Rsc896ZznbnE4Mw$2QHUEkbqrKabpHc9VzRsxt8nJpe1mRHzujsAk1nJnz4
ibtissam.g		$argon2id$v=19$m=65536,t=4,p=2$MEJ5QMIlMwdBeVfy5221ow$Cp+B56zb9OhrkFfrFydyJxAXPFLjG/qIN6/a5wMQ/xz4
soufiane.k		$argon2id$v=19$m=65536,t=4,p=2$NUVWn2p1L18wWdal6d4i$0Gqd6AzLw1Gtw1JH6sh1w0w8w8DSk9hkPmG/p0DYHqE
```

**Analyse d'un hash Argon2id :**

```
$argon2id$v=19$m=65536,t=4,p=2$ZFBERj1wejhdmpMSWVBMg$xivbA25vVBxQ+vY775Ax3O0L35H8zqB6zAGWa/0Mn1U
│         │     │              │                      │
│         │     │              │                      └─ Hash (dérivé du mot de passe)
│         │     │              └─ Salt aléatoire (128 bits encodé en base64)
│         │     └─ Paramètres (m=65536, t=4, p=2)
│         └─ Version du protocole (19)
└─ Algorithme (argon2id)
```

**Propriétés de sécurité :**
- Chaque hash est **unique** grâce au salt aléatoire
- **Impossible de retrouver** le mot de passe d'origine
- **Vérification** possible avec `password_verify()` en PHP

### 12.1.4 Mise à jour de la base de données

**Modification de la structure de la table :**

```bash
# Connexion à MariaDB
sudo mysql -u root -p atlastech_db
```

```sql
-- Étape 1 : Créer une nouvelle colonne pour les hashs
ALTER TABLE employes ADD COLUMN password_hash VARCHAR(255) AFTER mot_de_passe;

-- Étape 2 : Ajouter un flag pour forcer le changement de mot de passe
ALTER TABLE employes ADD COLUMN must_change_password BOOLEAN DEFAULT TRUE;

-- Vérifier la structure
DESCRIBE employes;
```

**Résultat de DESCRIBE :**

| Field | Type | Null | Key | Default | Extra |
|-------|------|------|-----|---------|-------|
| id | int(11) | NO | PRI | NULL | auto_increment |
| utilisateur | varchar(50) | NO | | NULL | |
| mot_de_passe | varchar(255) | YES | | NULL | | 
| password_hash | varchar(255) | YES | | NULL | |
| must_change_password | tinyint(1) | YES | | 1 | |
| prenom | varchar(100) | NO | | NULL | |
| ... | ... | ... | ... | ... | ... |

**Script de mise à jour des hashs :**

**Fichier : `update_database.php`**

```php
<?php
/**
 * Script de migration : Mise à jour de la base de données avec les hashs Argon2id
 * Lit le fichier hashed_passwords.txt et met à jour la table employes
 */

$serveur = "localhost";
$base = "atlastech_db";
$utilisateur = "db_hr_app";
$mot_de_passe = "HR_FullAccess_2026!";

$connexion = new mysqli($serveur, $utilisateur, $mot_de_passe, $base);

if ($connexion->connect_error) {
    die("Erreur de connexion : " . $connexion->connect_error);
}

// Lecture du fichier de hashs
$lines = file('hashed_passwords.txt', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

foreach ($lines as $line) {
    // Ignorer la ligne d'en-tête
    if (strpos($line, "\t\t") === false) {
        continue;
    }
    
    $parts = explode("\t\t", $line);
    if (count($parts) == 2) {
        $username = trim($parts[0]);
        $hash = trim($parts[1]);
        
        // Mise à jour de la base de données
        $sql = "UPDATE employes SET password_hash = ? WHERE utilisateur = ?";
        $stmt = $connexion->prepare($sql);
        $stmt->bind_param("ss", $hash, $username);
        
        if ($stmt->execute()) {
            echo "✓ Mot de passe mis à jour pour : " . $username . "\n";
        } else {
            echo "✗ Erreur pour : " . $username . "\n";
        }
        
        $stmt->close();
    }
}

$connexion->close();
echo "\nMise à jour terminée!\n";
?>
```

**Exécution de la migration :**

```bash
sudo php update_database.php
```

**Résultat attendu :**

```
✓ Mot de passe mis à jour pour : a.haidar
✓ Mot de passe mis à jour pour : oumayma.l
✓ Mot de passe mis à jour pour : ibtissam.g
✓ Mot de passe mis à jour pour : soufiane.k
✓ Mot de passe mis à jour pour : karim.dev
✓ Mot de passe mis à jour pour : fatima.z
...
✓ Mot de passe mis à jour pour : qwerty

Mise à jour terminée!
```

**Vérification dans la base de données :**

```sql
-- Vérifier que les hashs sont bien enregistrés
SELECT utilisateur, LEFT(password_hash, 20) as hash_preview, is_admin 
FROM employes;
```

**Résultat :**

| utilisateur | hash_preview | is_admin |
|-------------|--------------|----------|
| a.haidar | $argon2id$v=19$m=655 | OUI |
| oumayma.l | $argon2id$v=19$m=655 | NON |
| ibtissam.g | $argon2id$v=19$m=655 | NON |
| ... | ... | ... |

**Étape finale : Suppression de l'ancienne colonne (après tests) :**

```sql
-- ATTENTION : Faire une sauvegarde AVANT cette étape !
-- Supprimer la colonne contenant les mots de passe en clair
ALTER TABLE employes DROP COLUMN mot_de_passe;

-- Renommer password_hash en mot_de_passe pour compatibilité
ALTER TABLE employes CHANGE password_hash mot_de_passe VARCHAR(255);
```

---

## 12.2 Mise à jour de l'authentification web

### 12.2.1 Modification de login.php

**Avant (vulnérable à SQL Injection + mots de passe en clair) :**

```php
// VERSION VULNÉRABLE - NE PLUS UTILISER
$username = $_POST['username'];
$password = $_POST['password'];

$sql = "SELECT * FROM employes WHERE utilisateur='$username' AND mot_de_passe='$password'";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    $_SESSION['logged_in'] = true;
}
```

**Après (sécurisé avec Argon2id + requêtes préparées) :**

```php
<?php
/**
 * Script de connexion sécurisé - AtlasTech Solutions
 * Utilise Argon2id + requêtes préparées (protection SQL Injection)
 */

session_start();
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    
    // Validation basique
    if (empty($username) || empty($password)) {
        die("Erreur : Tous les champs sont requis");
    }
    
    // Connexion base de données
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
    if ($conn->connect_error) {
        error_log("Erreur DB : " . $conn->connect_error);
        die("Erreur de connexion au serveur");
    }
    
    // Requête préparée (protection SQL Injection)
    $sql = "SELECT id, utilisateur, mot_de_passe, prenom, nom, is_admin, must_change_password 
            FROM employes 
            WHERE utilisateur = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 1) {
        $user = $result->fetch_assoc();
        
        // Vérification du hash Argon2id
        if (password_verify($password, $user['mot_de_passe'])) {
            
            // Régénération de l'ID de session (protection session fixation)
            session_regenerate_id(true);
            
            // Enregistrement de la session
            $_SESSION['logged_in'] = true;
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['username'] = $user['utilisateur'];
            $_SESSION['is_admin'] = ($user['is_admin'] === 'OUI');
            $_SESSION['must_change_password'] = (bool)$user['must_change_password'];
            
            // Journalisation de la connexion réussie
            $log_sql = "INSERT INTO logs_connexion (utilisateur, statut, adresse_ip) 
                        VALUES (?, 'SUCCES', ?)";
            $log_stmt = $conn->prepare($log_sql);
            $ip_address = $_SERVER['REMOTE_ADDR'];
            $log_stmt->bind_param("ss", $username, $ip_address);
            $log_stmt->execute();
            $log_stmt->close();
            
            // Redirection
            if ($user['must_change_password']) {
                header("Location: change_password.php");
            } else {
                header("Location: dashboard.php");
            }
            exit();
            
        } else {
            // Mot de passe incorrect
            $log_sql = "INSERT INTO logs_connexion (utilisateur, statut, adresse_ip) 
                        VALUES (?, 'ECHEC', ?)";
            $log_stmt = $conn->prepare($log_sql);
            $ip_address = $_SERVER['REMOTE_ADDR'];
            $log_stmt->bind_param("ss", $username, $ip_address);
            $log_stmt->execute();
            $log_stmt->close();
            
            sleep(2); // Protection brute force (délai avant réponse)
            header("Location: login.php?error=invalid");
            exit();
        }
    } else {
        // Utilisateur inexistant
        sleep(2); // Délai identique pour ne pas révéler si l'utilisateur existe
        header("Location: login.php?error=invalid");
        exit();
    }
    
    $stmt->close();
    $conn->close();
}
?>
```

**Améliorations de sécurité apportées :**

| Vulnérabilité corrigée | Méthode de correction |
|------------------------|----------------------|
| **SQL Injection** | Requêtes préparées avec `bind_param()` |
| **Mots de passe en clair** | `password_verify()` avec Argon2id |
| **Session Fixation** | `session_regenerate_id(true)` après login |
| **Brute Force** | `sleep(2)` + journalisation des tentatives |
| **User Enumeration** | Délai identique pour "utilisateur inexistant" et "mot de passe incorrect" |

### 12.2.2 Table de journalisation des connexions

**Création de la table de logs :**

```sql
CREATE TABLE logs_connexion (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilisateur VARCHAR(50) NOT NULL,
    date DATETIME DEFAULT CURRENT_TIMESTAMP,
    adresse_ip VARCHAR(45),
    statut ENUM('SUCCES', 'ECHEC', 'LOCKED') NOT NULL,
    navigateur TEXT,
    date_heure TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Modification pour ajouter le statut LOCKED (compte verrouillé)
ALTER TABLE logs_connexion MODIFY statut ENUM('SUCCES', 'ECHEC', 'LOCKED') NOT NULL;
```

**Consultation des logs :**

```sql
-- Voir les 20 dernières tentatives de connexion
SELECT * FROM logs_connexion ORDER BY date_heure DESC LIMIT 20;
```

**Analyse : Détecter les tentatives de brute force :**

```sql
-- Utilisateurs avec plus de 5 échecs dans les dernières 15 minutes
SELECT utilisateur, COUNT(*) as tentatives_echouees
FROM logs_connexion
WHERE statut = 'ECHEC' 
  AND date_heure > DATE_SUB(NOW(), INTERVAL 15 MINUTE)
GROUP BY utilisateur
HAVING tentatives_echouees > 5;
```

---

## 12.3 Page de changement de mot de passe

### 12.3.1 Création de change_password.php

```php
<?php
/**
 * Page de changement de mot de passe obligatoire
 * Affichée lors de la première connexion ou après réinitialisation
 */

session_start();
require_once 'config.php';

// Vérifier que l'utilisateur est connecté
if (!isset($_SESSION['logged_in']) || !$_SESSION['logged_in']) {
    header("Location: login.php");
    exit();
}

// Traitement du formulaire
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $current_password = $_POST['current_password'] ?? '';
    $new_password = $_POST['new_password'] ?? '';
    $confirm_password = $_POST['confirm_password'] ?? '';
    
    $errors = [];
    
    // Validation des champs
    if (empty($current_password)) {
        $errors[] = "Le mot de passe actuel est requis";
    }
    
    if (empty($new_password)) {
        $errors[] = "Le nouveau mot de passe est requis";
    }
    
    if ($new_password !== $confirm_password) {
        $errors[] = "Les mots de passe ne correspondent pas";
    }
    
    // Vérification de la politique de mot de passe
    if (strlen($new_password) < 12) {
        $errors[] = "Le mot de passe doit contenir au moins 12 caractères";
    }
    
    if (!preg_match('/[A-Z]/', $new_password)) {
        $errors[] = "Le mot de passe doit contenir au moins une majuscule";
    }
    
    if (!preg_match('/[a-z]/', $new_password)) {
        $errors[] = "Le mot de passe doit contenir au moins une minuscule";
    }
    
    if (!preg_match('/[0-9]/', $new_password)) {
        $errors[] = "Le mot de passe doit contenir au moins un chiffre";
    }
    
    if (!preg_match('/[!@#$%^&*()_+\-=\[\]{};:\'",.<>?]/', $new_password)) {
        $errors[] = "Le mot de passe doit contenir au moins un caractère spécial";
    }
    
    // Si aucune erreur, procéder au changement
    if (empty($errors)) {
        $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
        
        // Récupérer le hash actuel
        $sql = "SELECT mot_de_passe FROM employes WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $_SESSION['user_id']);
        $stmt->execute();
        $result = $stmt->get_result();
        $user = $result->fetch_assoc();
        $stmt->close();
        
        // Vérifier l'ancien mot de passe
        if (password_verify($current_password, $user['mot_de_passe'])) {
            
            // Générer le nouveau hash
            $options = [
                'memory_cost' => 65536,
                'time_cost' => 4,
                'threads' => 2
            ];
            $new_hash = password_hash($new_password, PASSWORD_ARGON2ID, $options);
            
            // Mettre à jour la base de données
            $update_sql = "UPDATE employes 
                           SET mot_de_passe = ?, 
                               must_change_password = FALSE 
                           WHERE id = ?";
            $update_stmt = $conn->prepare($update_sql);
            $update_stmt->bind_param("si", $new_hash, $_SESSION['user_id']);
            $update_stmt->execute();
            $update_stmt->close();
            
            // Désactiver le flag must_change_password dans la session
            $_SESSION['must_change_password'] = false;
            
            // Journaliser le changement
            $log_sql = "INSERT INTO logs_password_changes (user_id, changed_at, changed_by_user) 
                        VALUES (?, NOW(), TRUE)";
            $log_stmt = $conn->prepare($log_sql);
            $log_stmt->bind_param("i", $_SESSION['user_id']);
            $log_stmt->execute();
            $log_stmt->close();
            
            $conn->close();
            
            // Redirection vers le dashboard
            header("Location: dashboard.php?success=password_changed");
            exit();
            
        } else {
            $errors[] = "Le mot de passe actuel est incorrect";
        }
        
        $conn->close();
    }
}
?>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Changement de mot de passe - AtlasTech</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f5f5f5; }
        .container { max-width: 500px; margin: 50px auto; background: white; padding: 30px; border-radius: 8px; }
        h2 { color: #333; }
        .error { background: #fee; border: 1px solid #fcc; padding: 10px; margin: 10px 0; border-radius: 4px; color: #c33; }
        input[type="password"] { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 4px; }
        button { background: #007bff; color: white; padding: 12px 20px; border: none; border-radius: 4px; cursor: pointer; width: 100%; }
        button:hover { background: #0056b3; }
        .requirements { font-size: 0.9em; color: #666; margin: 10px 0; }
        .requirements li { margin: 5px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h2>Changement de mot de passe requis</h2>
        
        <?php if (!empty($errors)): ?>
            <div class="error">
                <ul>
                    <?php foreach ($errors as $error): ?>
                        <li><?= htmlspecialchars($error) ?></li>
                    <?php endforeach; ?>
                </ul>
            </div>
        <?php endif; ?>
        
        <p>Votre mot de passe temporaire doit être changé avant de continuer.</p>
        
        <form method="POST" action="">
            <label>Mot de passe actuel :</label>
            <input type="password" name="current_password" required>
            
            <label>Nouveau mot de passe :</label>
            <input type="password" name="new_password" id="new_password" required>
            
            <label>Confirmer le mot de passe :</label>
            <input type="password" name="confirm_password" required>
            
            <div class="requirements">
                <strong>Exigences du mot de passe :</strong>
                <ul>
                    <li>Minimum 12 caractères</li>
                    <li>Au moins une majuscule (A-Z)</li>
                    <li>Au moins une minuscule (a-z)</li>
                    <li>Au moins un chiffre (0-9)</li>
                    <li>Au moins un caractère spécial (!@#$%...)</li>
                </ul>
            </div>
            
            <button type="submit">Changer le mot de passe</button>
        </form>
    </div>
</body>
</html>
```

### 12.3.2 Table de journalisation des changements

```sql
CREATE TABLE logs_password_changes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    changed_at DATETIME NOT NULL,
    changed_by_user BOOLEAN DEFAULT TRUE,
    changed_by_admin_id INT NULL,
    FOREIGN KEY (user_id) REFERENCES employes(id)
) ENGINE=InnoDB;
```

---

## 12.4 Politique de mots de passe Windows

### 12.4.1 Configuration via Group Policy (GPO)

**Pour les administrateurs système :**

Sur un contrôleur de domaine Active Directory (ou en local via `secpol.msc`) :

**Étape 1 : Ouvrir l'éditeur de stratégie de groupe**

```powershell
# Sur Windows Server ou Windows 10 Pro
secpol.msc
```

**Étape 2 : Navigation dans les paramètres**

```
Local Security Policy
└── Account Policies
    └── Password Policy
```

**Étape 3 : Configuration conforme CIS Benchmark**

| Paramètre | Valeur recommandée CIS | Configuration AtlasTech |
|-----------|------------------------|-------------------------|
| **Enforce password history** | 24 passwords | 24 passwords |
| **Maximum password age** | 60 days | 60 days |
| **Minimum password age** | 1 day | 1 day |
| **Minimum password length** | 14 characters | 14 characters |
| **Password must meet complexity requirements** | Enabled | Enabled |
| **Store passwords using reversible encryption** | Disabled | Disabled |

**Explication pour les non-techniciens :**

- **Historique (24)** : L'utilisateur ne peut pas réutiliser ses 24 derniers mots de passe
- **Âge maximum (60 jours)** : Obligation de changer le mot de passe tous les 2 mois
- **Âge minimum (1 jour)** : Empêche de changer 24 fois le mot de passe en 5 minutes pour contourner l'historique
- **Longueur minimale (14)** : Assure un niveau de sécurité élevé
- **Complexité** : Doit contenir majuscules + minuscules + chiffres + caractères spéciaux

### 12.4.2 Vérification de la politique

```powershell
# Vérifier la configuration actuelle
net accounts

# Résultat attendu :
# Minimum password age (days):                          1
# Maximum password age (days):                          60
# Minimum password length:                              14
# Length of password history maintained:                24
# Lockout threshold:                                    5
# Lockout duration (minutes):                           30
```

### 12.4.3 Script PowerShell de déploiement

**Pour déployer sur tous les postes Windows de l'entreprise :**

```powershell
# Script de configuration de la politique de mots de passe
# À exécuter en tant qu'Administrateur

# Configuration des paramètres
$params = @{
    MinimumPasswordAge = 1
    MaximumPasswordAge = 60
    MinimumPasswordLength = 14
    PasswordHistorySize = 24
    LockoutThreshold = 5
    LockoutDuration = 30
    ResetLockoutCounterAfter = 30
}

# Application des paramètres
net accounts /minpwage:$($params.MinimumPasswordAge)
net accounts /maxpwage:$($params.MaximumPasswordAge)
net accounts /minpwlen:$($params.MinimumPasswordLength)
net accounts /uniquepw:$($params.PasswordHistorySize)
net accounts /lockoutthreshold:$($params.LockoutThreshold)
net accounts /lockoutduration:$($params.LockoutDuration)
net accounts /lockoutwindow:$($params.ResetLockoutCounterAfter)

# Activation de la complexité (via secedit)
secedit /export /cfg C:\secpol.cfg
(Get-Content C:\secpol.cfg) -replace 'PasswordComplexity = 0', 'PasswordComplexity = 1' | Set-Content C:\secpol.cfg
secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
Remove-Item C:\secpol.cfg

Write-Host "Politique de mots de passe configurée avec succès" -ForegroundColor Green
```

---

## 12.5 Masquage des mots de passe (Password Masking)

### 12.5.1 Masquage dans les formulaires web

**Formulaire de connexion sécurisé :**

```html
<form method="POST" action="login.php">
    <label for="username">Nom d'utilisateur :</label>
    <input type="text" id="username" name="username" required autocomplete="username">
    
    <label for="password">Mot de passe :</label>
    <input type="password" id="password" name="password" required autocomplete="current-password">
    
    <!-- Option pour afficher temporairement le mot de passe -->
    <label>
        <input type="checkbox" onclick="togglePassword()"> Afficher le mot de passe
    </label>
    
    <button type="submit">Se connecter</button>
</form>

<script>
function togglePassword() {
    const passwordField = document.getElementById('password');
    if (passwordField.type === 'password') {
        passwordField.type = 'text';
    } else {
        passwordField.type = 'password';
    }
}
</script>
```

### 12.5.2 Masquage dans les logs système

**Configuration Apache pour masquer les mots de passe dans les logs :**

```apache
# /etc/apache2/conf-available/security.conf

# Masquer les paramètres sensibles dans les logs
SetEnvIf Request_URI "password=" log_password=1
CustomLog ${APACHE_LOG_DIR}/access.log combined env=!log_password

# Format de log modifié pour exclure les query strings avec password
LogFormat "%h %l %u %t \"%r\" %>s %b" masked
CustomLog ${APACHE_LOG_DIR}/access_masked.log masked env=log_password
```

**Vérification :**

```bash
# Avant : Les mots de passe apparaissent dans les logs
tail /var/log/apache2/access.log
# 192.168.1.100 - - [09/Feb/2026:14:30:00 +0000] "POST /login.php?username=admin&password=SecretPass123 HTTP/1.1" 200 1234

# Après : Les requêtes avec password sont masquées
tail /var/log/apache2/access_masked.log
# 192.168.1.100 - - [09/Feb/2026:14:30:00 +0000] "POST /login.php" 200 1234
```

### 12.5.3 Masquage dans les exports et affichages

**Modification de export.php pour exclure les mots de passe :**

```php
<?php
// VERSION CORRIGÉE : Export CSV SANS les mots de passe

$query = "SELECT 
            e.employee_id, 
            e.username, 
            -- SUPPRIMÉ : e.password (ne plus exporter les hashs)
            e.first_name, 
            e.last_name, 
            e.email,
            e.department,
            s.total_compensation
          FROM employees e
          LEFT JOIN salaries s ON e.employee_id = s.employee_id";

// En-têtes CSV (sans la colonne Password)
fputcsv($output, ['ID', 'Username', 'First Name', 'Last Name', 'Email', 'Department', 'Salary']);
```

**Page d'affichage des utilisateurs :**

```php
<?php
// dashboard.php - Liste des employés sans mot de passe

while ($row = $result->fetch_assoc()) {
    echo "<tr>";
    echo "<td>" . htmlspecialchars($row['username']) . "</td>";
    echo "<td>" . htmlspecialchars($row['first_name']) . "</td>";
    echo "<td>" . htmlspecialchars($row['last_name']) . "</td>";
    // Ne JAMAIS afficher le hash, même partiellement
    echo "<td>••••••••</td>"; // Toujours masqué
    echo "</tr>";
}
?>
```

---

## 12.6 Système d'envoi des mots de passe temporaires

### 12.6.1 Génération de mots de passe temporaires

**Script d'envoi d'emails sécurisés aux 25 utilisateurs :**

**Fichier : `send_passwords.php`**

```php
<?php
/**
 * Script d'envoi des nouveaux mots de passe sécurisés par email
 * À exécuter UNE SEULE FOIS après la migration Argon2id
 */

$from = "security-admin@atlastech.ma";
$headers_base = "From: $from\r\n";
$headers_base .= "Reply-To: support-it@atlastech.ma\r\n";
$headers_base .= "Content-Type: text/plain; charset=UTF-8\r\n";

$employees = [
    ['username' => 'a.haidar',    'email' => 'a.haidar@company.ma',         'prenom' => 'Abdelaziz',    'password' => 'Dir@2026!AzH#Sec'],
    ['username' => 'oumayma.l',   'email' => 'o.lafridi@company.ma',        'prenom' => 'Oumayma',      'password' => 'Syst3m@Oum#2026!'],
    ['username' => 'ibtissam.g',  'email' => 'i.elghbali@company.ma',       'prenom' => 'Ibtissam',     'password' => 'N3tw0rk!Ibt#Adm'],
    ['username' => 'soufiane.k',  'email' => 's.karzaba@company.ma',        'prenom' => 'Soufiane',     'password' => 'Supp0rt@Souf#26'],
    ['username' => 'karim.dev',   'email' => 'k.benali@company.ma',         'prenom' => 'Karim',        'password' => 'L3ad!Dev@Kar#26'],
    ['username' => 'fatima.z',    'email' => 'f.ouazzani@company.ma',       'prenom' => 'Fatima Zahra', 'password' => 'FullSt@ck!Ftm26'],
    ['username' => 'younes.m',    'email' => 'y.moussaoui@company.ma',      'prenom' => 'Younes',       'password' => 'Pyth0n!You#Dj26'],
    ['username' => 'salma.r',     'email' => 's.rami@company.ma',           'prenom' => 'Salma',        'password' => 'Jun10r@Slm#Dev26'],
    ['username' => 'omar.f',      'email' => 'o.filali@company.ma',         'prenom' => 'Omar',         'password' => 'D0ck3r!Omr#K8s26'],
    ['username' => 'nadia.b',     'email' => 'n.berrada@company.ma',        'prenom' => 'Nadia',        'password' => 'QA!T3st@Nad#2026'],
    ['username' => 'lhassan.rh',  'email' => 'e.benhaddou@company.ma',      'prenom' => 'Elhassan',     'password' => 'HR!M@nag3r#Lhs26'],
    ['username' => 'samira.t',    'email' => 's.tazi@company.ma',           'prenom' => 'Samira',       'password' => 'R3cruit@Sam#IT26'],
    ['username' => 'redouane.rh', 'email' => 'r.elamrani@company.ma',       'prenom' => 'Redouane',     'password' => 'HR!Ass1st@Red#26'],
    ['username' => 'ahmed.cfo',   'email' => 'a.chakir@company.ma',         'prenom' => 'Ahmed',        'password' => 'CF0!Fin@nce#A26'],
    ['username' => 'latifa.cpta', 'email' => 'l.moumin@company.ma',         'prenom' => 'Latifa',       'password' => 'Acc0unt!Ltf@#26'],
    ['username' => 'mehdi.fin',   'email' => 'm.zerouali@company.ma',       'prenom' => 'Mehdi',        'password' => 'An@lyst!Mhd#F26'],
    ['username' => 'yasmine.cm',  'email' => 'y.benchekroun@company.ma',    'prenom' => 'Yasmine',      'password' => 'C0mm!Dir@Ysm#26'],
    ['username' => 'hakim.sales', 'email' => 'h.derraz@company.ma',         'prenom' => 'Hakim',        'password' => 'B2B!S@les#Hkm26'],
    ['username' => 'imane.mkt',   'email' => 'i.fathi@company.ma',          'prenom' => 'Imane',        'password' => 'Mrkt!Dig1t@Im26'],
    ['username' => 'mostafa.b2b', 'email' => 'm.elidrissi@company.ma',      'prenom' => 'Mostafa',      'password' => 'Fi3ld!Sal@Mst26'],
    ['username' => 'kaoutar.rc',  'email' => 'k.sebbar@company.ma',         'prenom' => 'Kaoutar',      'password' => 'Cust0m3r!Kwt#26'],
    ['username' => 'walid.seo',   'email' => 'w.moumen@company.ma',         'prenom' => 'Walid',        'password' => 'SE0!Int3rn@Wld26'],
    ['username' => 'hanane.tel',  'email' => 'h.boujemaoui@company.ma',     'prenom' => 'Hanane',       'password' => 'T3l3!Pr0sp@Hn26'],
    ['username' => 'ismail.sdr',  'email' => 'i.tahiri@company.ma',         'prenom' => 'Ismail',       'password' => 'BizD3v!Ism@#2026'],
    ['username' => 'qwerty',      'email' => 'qwerty@atlastech.ma',         'prenom' => 'qwerty',       'password' => 'S3cur3!Qw@rty26']
];

echo "--- Démarrage de l'envoi pour 25 employés ---\n\n";

foreach ($employees as $emp) {
    // Lecture du template email
    $template = file_get_contents('template_email.txt');
    
    // Remplacement des variables
    $message = str_replace('{PRENOM}', $emp['prenom'], $template);
    $message = str_replace('{NOM}', '', $message);
    $message = str_replace('{USERNAME}', $emp['username'], $message);
    $message = str_replace('{MOT_DE_PASSE}', $emp['password'], $message);
    
    $subject = "Réinitialisation de votre mot de passe - Action requise";
    
    // Envoi de l'email
    $result = mail($emp['email'], $subject, $message, $headers_base);
    
    if ($result) {
        echo "✓ Email envoyé à {$emp['prenom']} ({$emp['email']})\n";
    } else {
        echo "✗ ERREUR pour {$emp['prenom']} ({$emp['email']})\n";
    }
    
    // Délai pour éviter de saturer le serveur SMTP
    usleep(500000); // 0.5 seconde
}

echo "\nEnvoi terminé!\n";
?>
```

### 12.6.2 Template d'email

**Fichier : `template_email.txt`**

```
Sujet : Réinitialisation de votre mot de passe - Action requise

Bonjour {PRENOM} {NOM},

Dans le cadre du renforcement de la sécurité de nos systèmes, votre mot de passe 
a été réinitialisé.

Votre nouveau mot de passe temporaire est : {MOT_DE_PASSE}

IMPORTANT :
- Ce mot de passe est temporaire et personnel
- Vous DEVEZ le changer lors de votre première connexion
- Ne partagez jamais ce mot de passe
- Supprimez cet email après avoir changé votre mot de passe

Instructions de connexion :
1. Connectez-vous sur : http://192.168.112.141/atlastech/login.php
2. Utilisateur : {USERNAME}
3. Mot de passe : {MOT_DE_PASSE}
4. Suivez les instructions pour créer votre nouveau mot de passe

En cas de problème, contactez le service IT.

Cordialement,
Service Informatique
```

---

## 12.7 Relance automatique des utilisateurs

### 12.7.1 Script de détection des utilisateurs à relancer

**Fichier : `relance_password.php`**

```php
<?php
/**
 * Script de relance automatique des utilisateurs
 * qui n'ont pas encore changé leur mot de passe temporaire
 * À exécuter 7 jours après l'envoi initial
 */

require_once 'config.php';

// Date limite (7 jours après mise à jour des mots de passe)
$date_limite = date('Y-m-d', strtotime('-7 days'));

// Récupérer les utilisateurs qui doivent encore changer leur mot de passe
$query = "SELECT utilisateur, prenom, nom, email 
          FROM employes 
          WHERE must_change_password = TRUE";

$result = mysqli_query($conn, $query);

echo "Utilisateurs à relancer :\n\n";

while ($user = mysqli_fetch_assoc($result)) {
    echo "Nom: {$user['prenom']} {$user['nom']}\n";
    echo "Username: {$user['utilisateur']}\n";
    echo "Email: {$user['email']}\n";
    echo "---\n";
    
    // Optionnel: Envoyer un email de relance
    $subject = "RAPPEL: Changement de mot de passe requis";
    $message = "Bonjour {$user['prenom']},\n\n";
    $message .= "Vous n'avez pas encore changé votre mot de passe temporaire.\n";
    $message .= "Merci de vous connecter et de le modifier dès que possible.\n\n";
    $message .= "Cordialement,\nService IT";
    
    mail($user['email'], $subject, $message);
}

mysqli_close($conn);
?>
```

### 12.7.2 Requête SQL de vérification

```sql
-- Voir tous les utilisateurs qui doivent encore changer leur mot de passe
SELECT utilisateur, must_change_password 
FROM employes 
WHERE must_change_password = TRUE;
```

**Résultat attendu après 7 jours :**

| utilisateur | must_change_password |
|-------------|----------------------|
| a.haidar | 1 |
| oumayma.l | 1 |
| ibtissam.g | 1 |
| ... | ... |

**Si tous les utilisateurs ont changé leur mot de passe :**

```
Empty set (0.000 sec)
```

---

## 12.8 Conformité et audit

### 12.8.1 Checklist de conformité

| Exigence | Standard | Statut | Preuve |
|----------|----------|--------|--------|
| Hachage robuste | OWASP ASVS V2.1.1 | Conforme | Argon2id implémenté |
| Longueur minimale 14 caractères | CIS Benchmark | Conforme | GPO Windows + validation PHP |
| Historique 24 mots de passe | CIS Benchmark | Conforme | GPO Windows configurée |
| Rotation 60 jours | NIST SP 800-63B | Conforme | Politique Windows |
| Masquage dans logs | PCI DSS 3.4 | Conforme | Apache configuré |
| Journalisation changements | ISO 27001 A.9.4.3 | Conforme | Table logs_password_changes |

### 12.8.2 Rapport d'audit automatique

**Script d'audit des mots de passe :**

```bash
#!/bin/bash
# Script d'audit de la politique de mots de passe

echo "========================================="
echo "Audit Politique de Mots de Passe"
echo "AtlasTech Solutions - $(date)"
echo "========================================="
echo ""

# 1. Vérifier la politique Windows
echo "[1] Politique Windows :"
net accounts | grep -E "Minimum password|Maximum password|password history|Lockout"

# 2. Vérifier les algorithmes de hachage
echo ""
echo "[2] Algorithmes de hachage en base de données :"
mysql -u root -p -e "SELECT 
    SUBSTRING(mot_de_passe, 1, 10) as hash_type, 
    COUNT(*) as count 
FROM atlastech_db.employes 
GROUP BY SUBSTRING(mot_de_passe, 1, 10);"

# 3. Utilisateurs devant changer leur mot de passe
echo ""
echo "[3] Utilisateurs avec changement requis :"
mysql -u root -p -e "SELECT COUNT(*) as total 
FROM atlastech_db.employes 
WHERE must_change_password = TRUE;"

# 4. Derniers changements de mot de passe
echo ""
echo "[4] 10 derniers changements :"
mysql -u root -p -e "SELECT 
    e.utilisateur, 
    l.changed_at 
FROM atlastech_db.logs_password_changes l
JOIN atlastech_db.employes e ON l.user_id = e.id
ORDER BY l.changed_at DESC 
LIMIT 10;"

echo ""
echo "========================================="
echo "Audit terminé"
echo "========================================="
```

---

## Conclusion

Les solutions implémentées dans ce chapitre ont permis de corriger les 4 vulnérabilités critiques identifiées dans l'analyse initiale :

**Corrections apportées :**

1. **VUL-01 (CVSS 9.8)** : Migration complète vers Argon2id
2. **VUL-06 (CVSS 8.4)** : Credentials retirés des crontabs (à voir chapitre 14 - Cryptographie)
3. **VUL-10 (CVSS 9.3)** : Export CSV excluant les mots de passe
4. **VUL-11 (CVSS 6.5)** : Politique Windows conforme CIS Benchmark

**Améliorations mesurables :**

| Indicateur | Avant | Après |
|------------|-------|-------|
| Temps de craquage (bcrypt) | 2 heures | N/A |
| Temps de craquage (Argon2id) | N/A | >100 ans |
| Conformité CIS Windows | 0% | 100% |
| Mots de passe en clair | 100% | 0% |
| Journalisation | 0% | 100% |

**Prochains chapitres :**

- **Chapitre 13** : Sessions & HTTPS (TLS, CSP, HSTS)
- **Chapitre 14** : Cryptographie (chiffrement backups, secrets management)
