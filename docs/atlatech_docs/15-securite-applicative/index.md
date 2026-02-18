---
id: securite-applicative-index
title: Sécurité Applicative (Application Security)
sidebar_label: "Vue d'ensemble"
sidebar_position: 0
slug: /securite-applicative
---

# 15. Sécurité Applicative (Application Security)

## Introduction

La sécurité applicative représente l'ensemble des mesures de protection mises en œuvre au niveau du code et de l'architecture logicielle pour protéger les applications web contre les cyberattaques. Dans le contexte d'AtlasTech Solutions, cette section documente de manière exhaustive la sécurisation de deux applications critiques : le site web commercial et l'application CRUD de gestion des ressources humaines.

## Objectifs de cette Documentation

Cette documentation technique vise à :

1. **Identifier les vulnérabilités** présentes dans l'infrastructure initiale
2. **Démontrer les risques** associés à chaque vulnérabilité (état AVANT)
3. **Implémenter les solutions** de sécurisation (état APRÈS)
4. **Fournir le code complet** fonctionnel et testé
5. **Garantir la conformité** aux standards internationaux (OWASP, ISO 27001, RGPD)

## Public Cible

Cette documentation est conçue pour être accessible à **trois niveaux de lecture** :

### Niveau 1 : Non-Techniciens (Cadres, Managers)
- Explications simplifiées avec analogies
- Impacts métier et risques business
- Tableaux récapitulatifs et schémas visuels

### Niveau 2 : Techniciens (Développeurs, Administrateurs)
- Code source complet et commenté
- Commandes d'installation et de configuration
- Tests de validation et vérification

### Niveau 3 : Experts (Auditeurs, Professeurs, RSSI)
- Références normatives (CWE, CVSS, OWASP ASVS)
- Architecture de sécurité approfondie
- Analyse de risques détaillée

## Structure de la Documentation

### Architecture et Fondations

**15.1 Architecture Application**
- Description complète du site web commercial (frontend/backend)
- Architecture de l'application CRUD RH
- Flux de données et isolation des environnements
- Stack technique détaillée (Apache, PHP, MariaDB)

### Vulnérabilités d'Injection

**15.2 SQL Injection Prevention**
- Principe de l'injection SQL
- Code vulnérable (concaténation de requêtes)
- Solution sécurisée (PDO Prepared Statements)
- Configuration et tests avec SQLMap

**15.3 Cross-Site Scripting (XSS)**
- Types de XSS (Reflected, Stored, DOM-based)
- Échappement avec htmlspecialchars()
- Content Security Policy (CSP)
- Protection côté client et serveur

### Vulnérabilités de Contrôle d'Accès

**15.4 Cross-Site Request Forgery (CSRF)**
- Principe de l'attaque CSRF
- Implémentation de tokens CSRF
- SameSite cookies
- Double Submit Cookie pattern

**15.5 Mass Assignment Protection**
- Définition du Mass Assignment
- Whitelist et Blacklist de champs
- Approche orientée objet (fillable/guarded)
- Validation basée sur les rôles

**15.6 Insecure Direct Object Reference (IDOR)**
- Principe de l'IDOR
- Middleware d'autorisation
- Utilisation d'UUID
- Contrôle d'accès granulaire

### Validation et Intégrité des Données

**15.7 Upload de Fichiers Sécurisé**
- Validation multi-couches
- Vérification des magic bytes
- Scan antivirus (ClamAV)
- Désactivation de l'exécution de scripts

**15.8 Validation des Entrées**
- Validation côté serveur (obligatoire)
- Validation côté client (UX)
- Expressions régulières spécifiques (CIN, téléphone marocain)
- Sanitization vs Validation

### Traçabilité et Monitoring

**15.9 Logging Sécurisé**
- Table audit_logs complète
- Masquage des données sensibles
- Rotation et archivage des logs
- Centralisation SIEM

**15.10 Gestion des Erreurs**
- Configuration production vs développement
- Pages d'erreur personnalisées
- Handlers d'erreur sécurisés
- Codes d'erreur application

## Méthodologie Appliquée

### Approche "Before/After"

Chaque section suit une structure rigoureuse :

```
1. Introduction au concept (explication simple)
2. Code AVANT (vulnérable)
   - Démonstration de l'exploitation
   - Impact de l'attaque
   - Captures ou commandes de test
3. Code APRÈS (sécurisé)
   - Solution complète
   - Explications ligne par ligne
   - Justification technique
4. Vérification et tests
   - Commandes de validation
   - Outils professionnels (Burp, SQLMap, ZAP)
   - Résultats attendus
5. Références normatives
   - OWASP, CWE, CVSS
   - ISO 27001, RGPD, ANSSI
```

## Technologies Couvertes

### Backend
- **PHP 8.1** : Langage serveur
- **Apache 2.4** : Serveur web
- **MariaDB 10.6** : Base de données
- **PDO** : Abstraction base de données

### Frontend
- **HTML5 / CSS3** : Structure et présentation
- **JavaScript ES6+** : Interactivité
- **Tailwind CSS** : Framework CSS

### Sécurité
- **Let's Encrypt** : Certificats SSL/TLS
- **ClamAV** : Antivirus
- **ModSecurity** : WAF (Web Application Firewall)
- **Fail2ban** : Protection brute-force

### Outils d'Audit
- **SQLMap** : Test injection SQL
- **OWASP ZAP** : Scanner de vulnérabilités
- **Burp Suite** : Proxy d'interception
- **Nikto** : Scanner serveur web

## Standards et Conformité

### OWASP Top 10 2021

Cette documentation couvre les vulnérabilités critiques :

| Rang | Vulnérabilité | Section(s) |
|------|--------------|-----------|
| A01 | Broken Access Control | 15.4, 15.6 |
| A02 | Cryptographic Failures | 15.3, 15.7 |
| A03 | Injection | 15.2, 15.3 |
| A04 | Insecure Design | 15.5, 15.10 |
| A05 | Security Misconfiguration | 15.1, 15.10 |
| A06 | Vulnerable Components | (Infrastructure) |
| A07 | Authentication Failures | 15.2, 15.4 |
| A08 | Software/Data Integrity | 15.8, 15.9 |
| A09 | Logging Failures | 15.9 |
| A10 | Server-Side Request Forgery | (Non applicable) |

### ISO/IEC 27001:2013

**Annexes couvertes :**
- **A.9** : Contrôle d'accès (15.4, 15.6)
- **A.12** : Sécurité des opérations (15.9, 15.10)
- **A.14** : Sécurité des systèmes d'information (15.2, 15.3, 15.8)
- **A.18** : Conformité (15.9)

### RGPD (Règlement Général sur la Protection des Données)

**Articles couverts :**
- **Article 5** : Principes (minimisation, exactitude)
- **Article 25** : Privacy by Design (15.1, 15.5)
- **Article 32** : Sécurité du traitement (toutes les sections)
- **Article 33** : Notification de violation (15.9)

### ANSSI (Agence Nationale de la Sécurité des Systèmes d'Information)

**Guides de référence :**
- Recommandations relatives aux applications web
- Guide d'hygiène informatique
- Recommandations de sécurité pour un système GNU/Linux

## Principes de Sécurité Transversaux

### 1. Defense in Depth (Défense en Profondeur)

Application de multiples couches de sécurité :
- **Réseau** : Pare-feu, segmentation VLAN
- **Serveur** : Durcissement OS, WAF
- **Application** : Validation, échappement, tokens
- **Données** : Chiffrement, hachage

### 2. Principle of Least Privilege (Moindre Privilège)

Chaque composant n'a que les permissions strictement nécessaires :
- Utilisateurs base de données avec privilèges limités
- Séparation des rôles (admin, RH, utilisateur)
- Restriction d'accès par IP (application RH)

### 3. Never Trust User Input (Ne Jamais Faire Confiance)

Toute donnée externe est considérée comme potentiellement malveillante :
- Validation côté serveur obligatoire
- Sanitization avant affichage
- Whitelisting préféré au blacklisting

### 4. Fail Securely (Échouer de Manière Sécurisée)

En cas d'erreur, l'application doit rester sécurisée :
- Fermeture de session en cas d'erreur critique
- Messages génériques en production
- Logging détaillé des incidents

### 5. Separation of Concerns (Séparation des Responsabilités)

Isolation des environnements et des données :
- DMZ pour le site public
- VLAN interne pour l'application RH
- Bases de données séparées

## Exemples de Code Réels

Tous les exemples de code fournis dans cette documentation sont :

- **Fonctionnels** : Testés et validés
- **Complets** : Pas de pseudo-code, code production-ready
- **Commentés** : Explications ligne par ligne
- **Sécurisés** : Conformes aux best practices

### Exemple de Structure

```php
<?php
/**
 * Description claire de la fonction
 * @param type $param Description du paramètre
 * @return type Description du retour
 */
function secureFunction($param) {
    // Validation
    if (!validate($param)) {
        throw new Exception("Invalid input");
    }
    
    // Traitement sécurisé
    $result = processSecurely($param);
    
    // Logging
    logAction('function_called', $param);
    
    return $result;
}
?>
```

## Commandes et Vérifications

Chaque section inclut des commandes de vérification réelles :

```bash
# Installation d'un composant
sudo apt install package-name

# Configuration
sudo nano /etc/config/file.conf

# Vérification
command --version
# Résultat attendu : version X.Y.Z

# Test de sécurité
tool -u https://target.com --test-option
# Résultat attendu : No vulnerability detected
```

## Outils de Développement

### Environnement de Test

Pour reproduire l'environnement :

```bash
# OS
Ubuntu 22.04 LTS

# PHP
PHP 8.1.27

# Apache
Apache/2.4.52

# MariaDB
MariaDB 10.6.16

# Installation minimale
sudo apt update
sudo apt install apache2 php libapache2-mod-php mariadb-server
sudo apt install php-mysql php-mbstring php-gd
```

### Configuration Réseau

```
VLAN 10 (DMZ) : 192.168.10.0/24
  - Site commercial : 192.168.10.10

VLAN 20 (Interne) : 192.168.20.0/24
  - Application RH : 192.168.20.10

VLAN 30 (Données) : 192.168.30.0/24
  - Serveur MariaDB : 192.168.30.10
```

## Utilisation de cette Documentation

### Pour les Débutants

1. Commencez par la section **15.1 Architecture** pour comprendre le contexte
2. Lisez les sections dans l'ordre (15.1 → 15.10)
3. Concentrez-vous sur les explications en début de section
4. Consultez les tableaux récapitulatifs

### Pour les Développeurs

1. Lisez le code AVANT pour identifier les anti-patterns
2. Étudiez le code APRÈS pour comprendre les solutions
3. Testez les commandes de vérification dans votre environnement
4. Adaptez le code à vos besoins spécifiques

### Pour les Auditeurs

1. Vérifiez la conformité aux standards (OWASP, ISO, RGPD)
2. Consultez les références normatives en fin de section
3. Utilisez les outils d'audit recommandés
4. Validez les scores CVSS et classifications CWE

## Navigation

### Sections Principales

- [15.1 Architecture Application](./15-1-architecture-application.md)
- [15.2 SQL Injection Prevention](./15-2-sql-injection-prevention.md)
- [15.3 Cross-Site Scripting (XSS)](./15-3-xss-protection.md)
- [15.4 Cross-Site Request Forgery (CSRF)](./15-4-csrf-protection.md)
- [15.5 Mass Assignment Protection](./15-5-mass-assignment-protection.md)
- [15.6 IDOR Protection](./15-6-idor-protection.md)
- [15.7 Upload Sécurisé](./15-7-secure-file-upload.md)
- [15.8 Validation des Entrées](./15-8-input-validation.md)
- [15.9 Logging Sécurisé](./15-9-secure-logging.md)
- [15.10 Gestion des Erreurs](./15-10-error-handling.md)

## Contribuer

Cette documentation est un document vivant. Pour toute suggestion d'amélioration :

1. Vérifiez que la suggestion est alignée avec les standards OWASP
2. Fournissez du code testé et fonctionnel
3. Incluez les références normatives appropriées
4. Documentez les commandes de vérification

## Licence et Crédits

**Projet :** Infrastructure Réseau et Sécurité - AtlasTech Solutions  
**Formation :** Cybersécurité - JobInTech  
**Année Académique :** 2025-2026  
**Date de soumission :** 12 février 2026

**Réalisé par :**
- Oumayma Lafridi
- Ibtissam Elghbali
- Soufiane Karzaba

**Encadré par :**
- Abdelaziz Haidar

## Références Globales

### Documentation OWASP
- OWASP Top 10 2021 : https://owasp.org/Top10/
- OWASP ASVS v4.0 : https://owasp.org/www-project-application-security-verification-standard/
- OWASP Cheat Sheet Series : https://cheatsheetseries.owasp.org/

### Standards ISO
- ISO/IEC 27001:2013 : Systèmes de management de la sécurité de l'information
- ISO/IEC 27002:2013 : Code de bonnes pratiques

### Réglementation
- RGPD : https://www.cnil.fr/fr/reglement-europeen-protection-donnees
- ANSSI : https://www.ssi.gouv.fr/

### CWE (Common Weakness Enumeration)
- CWE-79 : Cross-site Scripting (XSS)
- CWE-89 : SQL Injection
- CWE-352 : Cross-Site Request Forgery (CSRF)
- CWE-915 : Improperly Controlled Modification of Dynamically-Determined Object Attributes

---

**Bonne lecture et bonne sécurisation !**