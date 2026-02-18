---
title: Sécurité Base de Données
sidebar_label: Vue d'ensemble
sidebar_position: 1
---

# 16. Sécurité Base de Données

## Introduction

Ce chapitre présente la sécurisation complète de la base de données MariaDB pour AtlasTech Solutions. Après avoir identifié les vulnérabilités critiques dans le chapitre 7.6, nous implémentons maintenant les solutions concrètes pour garantir l'intégrité, la confidentialité et la disponibilité des données.

### Contexte

AtlasTech gère deux types de données critiques :

**1. Site Web Commercial**
- Tables : `produits`, `commandes`, `clients`
- Accès : Public (lecture) + Administrateurs (écriture)
- Volume : ~1000 produits, ~500 commandes/mois

**2. Application CRUD Ressources Humaines**
- Tables : `employes`, `departements`, `conges`, `salaires`
- Accès : Département RH uniquement
- Volume : 25 employés, ~100 congés/an

### Vulnérabilités critiques corrigées

| ID | Vulnérabilité | CVSS | Solution (Chapitre 16) |
|----|---------------|------|------------------------|
| VUL-01 | Mots de passe en clair | 9.8 | 16.8 Chiffrement AES-256 |
| VUL-04 | Privilèges MySQL excessifs | 9.1 | 16.7 Privilèges granulaires |
| VUL-14 | Vues SQL exposant données | 7.7 | 16.6 Procédures sécurisées |
| N/A | Absence Foreign Keys | 7.5 | 16.2 Intégrité référentielle |
| N/A | Pas d'audit DB | 8.0 | 16.9 MySQL Audit Plugin |

### Structure du chapitre

Ce chapitre est divisé en 10 sections techniques :

| Section | Sujet | Complexité |
|---------|-------|------------|
| **16.1** | Schéma Base de Données | Fondamental |
| **16.2** | Foreign Keys & Intégrité | Fondamental |
| **16.3** | UNIQUE Constraints | Fondamental |
| **16.4** | INDEX pour Performance | Intermédiaire |
| **16.5** | Types de Données Sécurisés | Intermédiaire |
| **16.6** | Procédures Stockées | Avancé |
| **16.7** | Privilèges Granulaires | Avancé |
| **16.8** | Chiffrement Données Sensibles | Avancé |
| **16.9** | Audit Database | Avancé |
| **16.10** | Backup & Restore | Intermédiaire |

### Architecture cible

```
┌─────────────────────────────────────────────────────────┐
│                    APPLICATIONS                         │
├─────────────────────────────────────────────────────────┤
│  Site Web Commercial  │  Application CRUD RH            │
│  (Apache + PHP)       │  (Apache + PHP)                 │
└───────────┬───────────┴─────────────┬───────────────────┘
            │                         │
            │ user: web_app_user      │ user: hr_app_user
            │ privileges: SELECT,     │ privileges: SELECT,
            │ INSERT, UPDATE          │ INSERT, UPDATE, DELETE
            │                         │
┌───────────▼─────────────────────────▼───────────────────┐
│              MariaDB 10.11 (Sécurisé)                   │
├─────────────────────────────────────────────────────────┤
│  Database: atlastech_db                                 │
│                                                         │
│  Tables Site Web:        Tables CRUD RH:                │
│  ├─ produits            ├─ employes (avec FK)           │
│  ├─ commandes           ├─ departements                 │
│  ├─ clients             ├─ conges (avec FK)             │
│  └─ (avec INDEX)        └─ salaires (chiffrés)          │
│                                                         │
│  Sécurité:                                              │
│  ├─ Foreign Keys activées                               │
│  ├─ UNIQUE Constraints                                  │
│  ├─ INDEX optimisés                                     │
│  ├─ Procédures stockées sécurisées                      │
│  ├─ Audit Plugin activé                                 │
│  └─ Backups chiffrés quotidiens                         │
└─────────────────────────────────────────────────────────┘
            │
            │ Réplication
            ▼
┌─────────────────────────────────────────────────────────┐
│         MariaDB Slave (Backup Server)                   │
│         - Read Replicas                                 │
│         - Point-in-Time Recovery                        │
└─────────────────────────────────────────────────────────┘
```

### Principes de sécurité appliqués

**1. Défense en profondeur**
- Plusieurs couches de sécurité (contraintes DB + privilèges + chiffrement)

**2. Principe du moindre privilège**
- Chaque utilisateur a uniquement les droits nécessaires

**3. Séparation des responsabilités**
- Utilisateurs DB distincts pour Site Web et CRUD RH

**4. Auditabilité**
- Traçabilité complète de toutes les modifications

### Conformité normative

| Standard | Exigence | Section |
|----------|----------|---------|
| **OWASP ASVS V5** | Data Protection | 16.8 Chiffrement |
| **CIS MariaDB Benchmark** | Least Privilege | 16.7 Privilèges |
| **ISO 27001 A.8.10** | Information Deletion | 16.2 Foreign Keys CASCADE |
| **NIST SP 800-53** | Audit and Accountability | 16.9 Audit |
| **RGPD Article 32** | Security of Processing | 16.8 Chiffrement |

### Lecture recommandée

**Pour les débutants :** Commencer par 16.1, 16.2, 16.3 (concepts fondamentaux)

**Pour les développeurs :** Sections 16.4, 16.5, 16.6 (performance et procédures)

**Pour les DBA :** Sections 16.7, 16.8, 16.9, 16.10 (administration avancée)

**Pour les auditeurs :** Sections 16.9 (audit) et 16.10 (backup)

---

## Prochaines sections

Cliquez sur une section ci-dessous pour accéder aux détails techniques :

- [16.1 - Schéma Base de Données](./16.1-schema-database.md)
- [16.2 - Foreign Keys & Intégrité](./16.2-foreign-keys.md)
- [16.3 - UNIQUE Constraints](./16.3-unique-constraints.md)
- [16.4 - INDEX pour Performance](./16.4-index-performance.md)
- [16.5 - Types de Données Sécurisés](./16.5-types-donnees.md)
- [16.6 - Procédures Stockées](./16.6-procedures-stockees.md)
- [16.7 - Privilèges Base de Données](./16.7-privileges.md)
- [16.8 - Chiffrement Données Sensibles](./16.8-chiffrement.md)
- [16.9 - Audit Database](./16.9-audit.md)
- [16.10 - Backup & Restore](./16.10-backup.md)