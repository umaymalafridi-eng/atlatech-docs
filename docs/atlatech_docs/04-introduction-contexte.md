---
title: Introduction et Contexte
sidebar_position: 4
---

# Introduction et Contexte

## Présentation d'AtlasTech Solutions

**AtlasTech Solutions** est une entreprise opérant dans le secteur des services numériques et du développement web. Avec un effectif de **25 employés**, l'entreprise s'est positionnée comme un acteur fiable pour les petites et moyennes entreprises (PME) en quête de solutions web professionnelles.

L'entreprise propose une gamme complète de services incluant :
- La création de sites vitrines
- Le développement de plateformes e-commerce
- La maintenance applicative
- L'hébergement web

Cette diversité de services implique une manipulation quotidienne de **données à caractère sensible**, notamment les informations clients, les données relatives aux ressources humaines, les informations financières et le code source propriétaire des applications développées.

## Structure Organisationnelle

L'entreprise est structurée autour de **six départements distincts**, chacun jouant un rôle spécifique dans la chaîne de valeur :

### 1. Direction Générale (1 employé)
Pilotage stratégique de l'entreprise et prise de décisions clés concernant l'évolution de l'infrastructure IT.

### 2. Département Informatique (3 employés)
Trois administrateurs systèmes et réseaux responsables de la gestion, de la maintenance et de la sécurité de l'infrastructure technique. Ce département constitue le pilier technique de l'organisation et joue un rôle central dans la mise en œuvre du projet de sécurisation.

### 3. Département Développement (6 employés)
Conception, développement et maintenance des applications web destinées aux clients. Ce département manipule quotidiennement le code source et les environnements de développement.

### 4. Département Ressources Humaines (3 employés)
Gestion de l'ensemble des aspects liés au personnel, incluant le recrutement, la gestion administrative et le suivi des employés via l'application CRUD dédiée.

### 5. Département Finance et Comptabilité (3 employés)
Gestion financière, facturation clients et suivi comptable de l'entreprise.

### 6. Département Commercial et Marketing (8 employés)
Force commerciale de l'entreprise, en charge de l'acquisition clients, de la gestion de la relation client et des activités marketing.

## Infrastructure Actuelle

L'infrastructure informatique actuelle repose sur une architecture simple et centralisée :

### Serveurs Linux

**Serveur Linux Principal :**
- Héberge le serveur web Apache
- Application web commerciale (publique)
- Application CRUD Ressources Humaines (interne)
- Bases de données MariaDB/MySQL (clients + RH)

**Serveur de Sauvegarde :**
- Assure la sauvegarde des données critiques

### Équipements Réseau
- Routeur jouant le rôle de pare-feu
- Switch central (Core Switch)
- Réseau local unique (LAN) non segmenté

### Postes de Travail Windows

L'infrastructure compte **25 postes de travail** répartis entre les différents départements :

**Répartition par département :**
- Direction Générale : 1 poste
- Département IT : 3 postes (hybrides Windows/Linux)
- Département Développement : 6 postes
- Département RH : 3 postes
- Département Finance/Comptabilité : 3 postes
- Département Commercial/Marketing : 8 postes

**Caractéristiques :**
- Systèmes d'exploitation : Windows
- Les administrateurs IT disposent de postes hybrides capables d'exécuter Windows et Linux
- Accès aux serveurs Linux via SSH (pour les administrateurs uniquement)
- Tous les postes opèrent sur le même réseau non segmenté

## Applications Critiques

### 1. Application Web Commerciale

**Fonction :** Vitrine publique de l'entreprise

**Caractéristiques :**
- Présentation des services
- Vente de packs de développement web
- Prise de contact avec les prospects
- Gestion basique des commandes

**Technologies :**
- Linux, Apache, PHP, MariaDB/MySQL
- Accessible publiquement via Internet
- HTTPS avec certificat TLS (Let's Encrypt ou auto-signé)
- Redirection automatique HTTP → HTTPS

### 2. Application Web CRUD – Ressources Humaines

**Fonction :** Gestion interne du personnel

**Opérations :**
- Ajouter un employé
- Consulter la liste des employés
- Modifier les informations d'un employé
- Supprimer un employé

**Technologies :**
- Linux, Apache, PHP, MariaDB/MySQL
- **Application strictement interne** (ne doit pas être accessible depuis Internet)

:::warning Problème de Sécurité
L'application RH est actuellement hébergée sur le même serveur que l'application publique, sans isolation réseau adéquate.
:::

## Enjeux de Sécurité

Face à la croissance de l'activité commerciale et à l'augmentation de la sensibilité des données manipulées, plusieurs enjeux critiques ont été identifiés :

### Données Sensibles à Protéger
- **Données clients** : informations personnelles, coordonnées, commandes
- **Ressources humaines** : informations employés, contrats, données personnelles
- **Informations financières** : facturation, comptabilité
- **Code source** : propriété intellectuelle, applications développées

### Risques Identifiés
- **Confidentialité** : exposition potentielle de données sensibles
- **Intégrité** : modification non autorisée des données
- **Disponibilité** : interruption des services critiques

### Exigences Réglementaires
- Conformité RGPD (Règlement Général sur la Protection des Données)
- Standards de sécurité attendus par les clients professionnels
- Bonnes pratiques ISO/IEC 27001

## Périmètre du Projet

Le projet englobe les volets suivants :

### 1. Analyse de l'Infrastructure Existante
- Cartographie complète de l'architecture actuelle
- Identification des composants critiques
- Documentation de l'état des lieux

### 2. Identification des Vulnérabilités
- Analyse des faiblesses de sécurité
- Évaluation des risques
- Priorisation des menaces

### 3. Proposition d'Architecture Améliorée
- Segmentation réseau par VLANs
- Mise en place d'une DMZ
- Isolation des services critiques
- Durcissement de la sécurité

### 4. Alignement avec les Normes
- Conformité aux principes ISO/IEC 27001
- Application des meilleures pratiques de sécurité
- Documentation technique complète

### 5. Pratiques DevOps
- Gestion du code source (GitHub/GitLab)
- Versioning et intégration continue
- Automatisation des déploiements

## Méthodologie de Travail

Pour mener à bien ce projet de sécurisation, nous avons adopté une approche structurée en **quatre phases** :

### Phase 1 : Analyse de l'Existant
**Objectif :** Comprendre l'infrastructure actuelle et son fonctionnement

**Activités :**
- Étude documentaire du cahier des charges
- Analyse de l'architecture réseau existante
- Cartographie des flux de données
- Identification des actifs critiques

**Livrable :** Documentation complète de l'état actuel

### Phase 2 : Identification des Vulnérabilités
**Objectif :** Détecter les failles et risques de sécurité

**Activités :**
- Analyse de risques par domaine
- Évaluation des menaces potentielles
- Application du modèle CIA (Confidentialité, Intégrité, Disponibilité)
- Priorisation des vulnérabilités selon leur criticité

**Livrable :** Rapport d'analyse des vulnérabilités

### Phase 3 : Conception de l'Architecture Cible
**Objectif :** Proposer une infrastructure sécurisée et évolutive

**Activités :**
- Conception de l'architecture réseau améliorée
- Définition de la segmentation réseau (VLANs, DMZ)
- Spécification des mesures de sécurité
- Élaboration des règles de pare-feu
- Planification de la haute disponibilité

**Livrable :** Schémas d'architecture et spécifications techniques

### Phase 4 : Recommandations et Plan d'Action
**Objectif :** Fournir un plan de mise en œuvre opérationnel

**Activités :**
- Rédaction des recommandations détaillées
- Priorisation des actions de sécurisation
- Alignement avec les standards ISO/IEC 27001
- Documentation technique complète

**Livrable :** Plan d'action et recommandations priorisées

### Outils et Référentiels Utilisés

**Normes et Standards :**
- ISO/IEC 27001 (Système de Management de la Sécurité de l'Information)
- ISO/IEC 27002 (Code de bonnes pratiques)
- OWASP Top 10 (Vulnérabilités applicatives web)
- CIS Controls (Center for Internet Security)

**Méthodologies :**
- Analyse de risques basée sur la triade CIA
- Principe du moindre privilège
- Défense en profondeur (Defense in Depth)
- Séparation des environnements

**Technologies et Solutions :**
- Pare-feu FortiGate (Fortinet)
- Segmentation réseau par VLANs
- Solutions de haute disponibilité
- Outils DevSecOps (GitHub/GitLab CI/CD)

## Contexte et Motivations

La décision de revoir l'infrastructure informatique d'AtlasTech Solutions découle de plusieurs facteurs convergents :

**Croissance de l'Activité :**  
L'augmentation significative du nombre de clients a entraîné une multiplication des données sensibles à protéger.

**Exigences Réglementaires :**  
Les standards de sécurité RGPD et les attentes des clients professionnels imposent un niveau de sécurité que l'infrastructure actuelle ne peut garantir.

**Approche Proactive :**  
Bien qu'aucun incident de sécurité majeur n'ait été documenté, la direction a pris conscience de manière préventive des risques potentiels liés à une infrastructure non segmentée et insuffisamment protégée.

**Vision Stratégique :**  
Le projet s'inscrit dans une vision à moyen terme visant à positionner AtlasTech Solutions comme un acteur de confiance sur le marché des services numériques. L'amélioration de la sécurité constitue un avantage concurrentiel différenciant.

## Défis Sécuritaires Principaux

L'analyse préliminaire a permis d'identifier plusieurs défis majeurs :

### Sécurité Réseau
- **Absence de segmentation réseau** : augmentation de la surface d'attaque
- **Hébergement mixte critique** : application publique et RH sur le même serveur
- **Absence de DMZ** : exposition directe aux menaces Internet
- **Contrôle d'accès insuffisant** : principe du moindre privilège non respecté
- **Configuration HTTPS à durcir** : protocoles et headers de sécurité à améliorer

### Sécurité des Postes Windows
- **25 postes de travail Windows** nécessitant une sécurisation
- Gestion des correctifs de sécurité (Windows Update)
- Protection antivirus et anti-malware
- Politique de mots de passe à renforcer
- Contrôle d'accès basé sur les rôles (RBAC)
- Chiffrement des données sensibles
- Gestion centralisée des postes (Active Directory potentiel)

Ces défis constituent le point de départ de notre analyse et guident les propositions d'amélioration présentées dans ce rapport.