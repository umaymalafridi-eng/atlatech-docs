---
id: table-des-matieres
title: Table des Matières
sidebar_label: "02. Table des Matières"
sidebar_position: 2
---

![Jobin Logo](/img/jobinlogo.png)

# Table des Matières

---

## I. Introduction et État des Lieux

1. **Page de Garde**
   - Titre du projet
   - Nom de l'étudiant
   - Date de soumission
   - Version du document

2. **Table des Matières**
   - Liste des chapitres
   - Numéros de pages
   - Liste des figures
   - Liste des tableaux
   - Liste des codes

3. **Executive Summary**
   - Contexte
   - Objectifs
   - Méthodologie
   - Résultats clés
   - Recommandations

4. **Introduction et Contexte**
   - AtlasTech (25 employés)
   - Architecture : Site Web Commercial + CRUD RH
   - Infrastructure 2 serveurs
   - Enjeux sécurité

5. **Analyse de l'Infrastructure Actuelle**
   - Application Web PHP (Site Commercial)
   - Application CRUD RH (Module interne)
   - Serveurs LAMP
   - Base de données MySQL
   - Flux de données

6. **Identification des Vulnérabilités**
   - Vulnérabilités Site Web : SQL Injection, XSS, CSRF
   - Vulnérabilités CRUD : Mass Assignment, IDOR
   - Évaluation CVSS
   - Matrice des risques

---

## II. Analyse Détaillée et Audit

7. **Analyse Détaillée par Domaine**
   - 7.1 IAM
   - 7.2 Mots de passe
   - 7.3 Sessions
   - 7.4 Cryptographie
   - 7.5 Application Web (Site + CRUD)
   - 7.6 Base de données
   - 7.7 Réseau

8. **Sécurité Réseau (FortiGate)**
   - VLANs
   - Firewall Policies
   - NAT/VIP
   - Protection Site Web depuis Internet

9. **Sécurité Windows**
   - Hardening SysHardener
   - GPO
   - Postes clients accédant au Site Web et CRUD

---

## III. Gestion des Accès et Identités

10. **IAM et PAM**
    - RBAC (accès au CRUD selon rôle)
    - PAM Linux
    - SSH
    - Authentification Site Web et CRUD

11. **Haute Disponibilité**
    - FortiGate HA
    - HA pour Site Web (Load Balancing)
    - Database Replication
    - Backup

12. **Mots de Passe et Stockage**
    - Hachage bcrypt
    - Mots de passe Site Web et CRUD
    - Password Policy
    - Masking

---

## IV. Sécurité Applicative et Cryptographie

13. **Sessions et HTTPS**
    - TLS 1.3
    - Cookies Site Web (HttpOnly, Secure)
    - Sessions CRUD (timeout, regenerate)
    - CSRF Tokens

14. **Cryptographie**
    - LUKS
    - HTTPS pour Site Web
    - Secrets management
    - Chiffrement téléphones

15. **Sécurité Applicative — Site Web + CRUD (Part 1)**
    - 15.1 Architecture Application
    - 15.2 SQL Injection Prevention
    - 15.3 Cross-Site Scripting (XSS)
    - 15.4 Cross-Site Request Forgery (CSRF)
    - 15.5 Mass Assignment Protection
    - 15.6 Insecure Direct Object Reference (IDOR)
    - 15.7 Upload de Fichiers Sécurisé
    - 15.8 Validation des Entrées
    - 15.9 Logging Sécurisé
    - 15.10 Gestion des Erreurs

16. **Sécurité Base de Données — Site Web + CRUD (Part 2)**
    - 16.1 Schéma Base de Données
    - 16.2 Foreign Keys et Intégrité
    - 16.3 UNIQUE Constraints
    - 16.4 INDEX pour Performance
    - 16.5 Types de Données Sécurisés
    - 16.6 Procédures Stockées Sécurisées
    - 16.7 Privilèges Base de Données
    - 16.8 Chiffrement des Données Sensibles
    - 16.9 Audit Database
    - 16.10 Backup et Restore

---

## V. Infrastructure et Surveillance

17. **Contrôle d'Accès et DNS**
    - IDOR Prevention
    - Directory Listing
    - URL Rewriting (masquage .php pour Site Web)
    - DNS Security

18. **Durcissement Systèmes (Hardening)**
    - Hardening Serveurs Web (Apache/Nginx)
    - Hardening PHP (php.ini)
    - CIS Benchmarks
    - SELinux/AppArmor

19. **Monitoring et Honeypot**
    - Surveillance accès Site Web
    - Logs CRUD (qui a modifié quel employé)
    - Wazuh, Cowrie

---

## VI. Cycle de Vie et DevSecOps

20. **DevSecOps et CI/CD**
    - Git repository pour Site Web et CRUD
    - CI/CD déploiement automatique
    - Tests sécurité (ZAP sur Site Web)

21. **Tests d'Intrusion**
    - Pentest Site Web (ZAP, Burp)
    - Test CRUD (IDOR, privilèges)
    - Rapports de vulnérabilités

---

## VII. Clôture du Projet

22. **Conclusion**
    - Bilan
    - Difficultés
    - Perspectives

23. **Annexes**
    - Configurations
    - Code Source Site Web et CRUD
    - Logs

---

## Liste des Figures

- *Figure 1 : Schéma de l'infrastructure réseau actuelle*
- *Figure 2 : Topologie du Pare-feu Fortigate*

## Liste des Tableaux

- *Tableau 1 : Matrice des Risques*
- *Tableau 2 : Plan d'Action de Remédiation*

## Glossaire

Définition des termes techniques : IAM, PAM, IDOR, CI/CD, SIEM, DevSecOps, CVSS, RBAC, LUKS, TLS.