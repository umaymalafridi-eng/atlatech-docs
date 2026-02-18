---
id: rapport-atlatech
title: Projet AtlasTech - Infrastructure et Sécurité
sidebar_label: Rapport AtlasTech
sidebar_position: 1
---

# Projet Final Cybersécurité : Infrastructure Réseau et Sécurité - AtlasTech Solutions

## 1. Executive Summary

### Vue d'ensemble du projet

Le présent projet s'inscrit dans le cadre de la transformation digitale et sécuritaire d'AtlasTech Solutions, une entreprise spécialisée dans les services numériques et le développement web. Face à une croissance commerciale soutenue et à une sensibilité accrue des données manipulées, l'entreprise se trouve confrontée à la nécessité impérieuse de revoir intégralement son infrastructure informatique.

### Problématique identifiée

L'infrastructure actuelle d'AtlasTech Solutions repose sur une architecture simple et centralisée, inadaptée aux enjeux de sécurité contemporains. L'augmentation du volume de clients et la manipulation de données sensibles (informations clients, ressources humaines, données financières et code source applicatif) exposent l'entreprise à des risques majeurs en matière de confidentialité, d'intégrité et de disponibilité.

### Objectif principal

Concevoir et déployer une infrastructure réseau sécurisée, fiable et évolutive, capable de supporter la croissance de l'entreprise tout en garantissant la protection des actifs informationnels critiques.

### Résultats attendus

Le projet vise à atteindre trois objectifs stratégiques majeurs :

1. Sécurisation des communications web via l'implémentation du protocole HTTPS avec durcissement TLS et application de headers de sécurité avancés.

2. Segmentation réseau par VLANs et mise en place d'une zone démilitarisée (DMZ) pour isoler les services exposés publiquement et protéger les ressources internes.

3. Introduction de pratiques DevOps modernes avec gestion sécurisée du code source via GitHub ou GitLab, incluant versioning et intégration continue.

### Périmètre et livrables

Le projet englobe l'analyse de l'infrastructure existante, l'identification des vulnérabilités, la proposition d'une architecture améliorée conforme aux principes de la norme ISO/IEC 27001, et la documentation technique complète justifiant chaque choix architectural.

### Contraintes et limites

Les informations relatives au budget et à la durée d'exécution du projet n'ont pas été formellement définies dans le cahier des charges initial. Ces éléments devront être précisés lors de la phase de planification détaillée.

## 2. Contexte du Projet

### Présentation de l'entreprise AtlasTech Solutions

AtlasTech Solutions est une entreprise opérant dans le secteur des services numériques et du développement web. Avec un effectif de 25 employés, l'entreprise s'est positionnée comme un acteur fiable pour les petites et moyennes entreprises (PME) en quête de solutions web professionnelles.

L'entreprise propose une gamme complète de services incluant la création de sites vitrines, le développement de plateformes e-commerce, la maintenance applicative et l'hébergement web. Cette diversité de services implique une manipulation quotidienne de données à caractère sensible, notamment les informations clients, les données relatives aux ressources humaines, les informations financières et le code source propriétaire des applications développées.

### Structure organisationnelle

L'entreprise est structurée autour de six départements distincts, chacun jouant un rôle spécifique dans la chaîne de valeur :

**Direction Générale** : Un directeur général assurant le pilotage stratégique de l'entreprise et la prise de décisions clés concernant l'évolution de l'infrastructure IT.

**Département Informatique** : Trois administrateurs systèmes et réseaux responsables de la gestion, de la maintenance et de la sécurité de l'infrastructure technique. Ce département constitue le pilier technique de l'organisation et joue un rôle central dans la mise en oeuvre du projet de sécurisation.

**Département Développement** : Six développeurs en charge de la conception, du développement et de la maintenance des applications web destinées aux clients. Ce département manipule quotidiennement le code source et les environnements de développement.

**Département Ressources Humaines** : Trois collaborateurs gérant l'ensemble des aspects liés au personnel, incluant le recrutement, la gestion administrative et le suivi des employés via l'application CRUD dédiée.

**Département Finance et Comptabilité** : Trois collaborateurs assurant la gestion financière, la facturation clients et le suivi comptable de l'entreprise.

**Département Commercial et Marketing** : Huit collaborateurs constituant la force commerciale de l'entreprise, en charge de l'acquisition clients, de la gestion de la relation client et des activités marketing.

### Contexte et motivations du projet

La décision de revoir l'infrastructure informatique d'AtlasTech Solutions découle de plusieurs facteurs convergents. La croissance soutenue de l'activité commerciale s'est traduite par une augmentation significative du nombre de clients servis, entraînant une multiplication des données sensibles à protéger. Parallèlement, les exigences réglementaires en matière de protection des données personnelles (RGPD) et les standards de sécurité attendus par les clients professionnels imposent un niveau de sécurité que l'infrastructure actuelle ne peut garantir.

L'entreprise n'a pas fait l'objet d'un incident de sécurité majeur documenté. Toutefois, la direction a pris conscience de manière proactive de la sensibilité croissante des données manipulées et des risques potentiels liés à une infrastructure non segmentée et insuffisamment protégée. Cette approche préventive témoigne d'une maturité en matière de gouvernance de la sécurité de l'information.

### Défis sécuritaires identifiés

L'analyse préliminaire a permis d'identifier plusieurs défis majeurs :

**Absence de segmentation réseau** : L'ensemble des ressources informatiques opère sur un même réseau plat, augmentant considérablement la surface d'attaque et facilitant les mouvements latéraux en cas de compromission.

**Hébergement mixte critique** : L'application commerciale publique et l'application RH interne sont hébergées sur le même serveur, constituant une faiblesse architecturale critique qui ne respecte pas le principe de séparation des environnements selon leur niveau de sensibilité.

**Absence de zone démilitarisée (DMZ)** : Le réseau interne est exposé directement aux menaces provenant d'Internet, sans filtrage intermédiaire ou isolation des services publics.

**Contrôle d'accès insuffisant** : Les mécanismes de contrôle d'accès actuels, bien que basés sur les rôles, manquent de granularité et ne respectent pas pleinement le principe du moindre privilège.

**Configuration HTTPS à durcir** : La configuration HTTPS actuelle, bien que présente, nécessite un durcissement significatif pour répondre aux standards de sécurité modernes (désactivation de protocoles obsolètes, application de headers de sécurité, etc.).

### Clientèle et impact métier

AtlasTech Solutions sert une clientèle composée de petites et moyennes entreprises, sans que le nombre exact de clients soit formellement documenté. Cette clientèle fait confiance à l'entreprise pour héberger et maintenir des applications critiques pour leur activité. Toute compromission de la sécurité pourrait avoir des impacts catastrophiques tant sur la réputation de l'entreprise que sur la continuité d'activité des clients servis.

### Alignement stratégique

Le projet de sécurisation s'inscrit dans une vision stratégique à moyen terme visant à positionner AtlasTech Solutions comme un acteur de confiance sur le marché des services numériques. L'amélioration de la sécurité constitue un avantage concurrentiel différenciant et répond aux attentes croissantes des clients en matière de protection de leurs données.

## 3. Architecture Actuelle

### Vue d'ensemble de l'infrastructure existante

L'infrastructure informatique actuelle d'AtlasTech Solutions repose sur une architecture simple et centralisée, caractérisée par un réseau local unique (LAN) interconnectant l'ensemble des ressources de l'entreprise. Cette approche, bien qu'initialement fonctionnelle pour une petite structure, présente aujourd'hui des limites significatives face aux enjeux de sécurité et de croissance.

### Composants de l'infrastructure réseau

L'architecture réseau s'articule autour des éléments suivants :

**Connectivité Internet** : L'entreprise dispose d'une connexion Internet unique constituant le point d'entrée et de sortie pour l'ensemble des communications externes.

**Routeur pare-feu** : Un routeur joue simultanément le rôle de passerelle Internet et de pare-feu périphérique. Cette double fonction, bien que courante dans les petites infrastructures, présente des limitations en termes de granularité des règles de filtrage et de séparation des fonctions.

**Commutateur central (Core Switch)** : Un switch central assure l'interconnexion de l'ensemble des équipements sur un réseau local unique, sans segmentation par VLANs. Cette configuration crée un domaine de broadcast unique et ne permet pas d'isoler les flux selon leur sensibilité.

**Réseau local non segmenté** : L'intégralité des postes de travail, serveurs et équipements réseaux opèrent sur le même segment réseau, sans distinction entre les différents départements ou niveaux de sensibilité des ressources.

### Infrastructure serveur

L'infrastructure serveur se compose de deux éléments principaux :

**Serveur Linux principal** : Ce serveur constitue le coeur de l'infrastructure applicative et héberge simultanément plusieurs composants critiques. Il exécute le serveur web Apache configuré pour servir à la fois l'application web commerciale publique et l'application CRUD des ressources humaines. Les bases de données MariaDB/MySQL pour les données clients et RH sont également hébergées sur ce même serveur. Cette concentration de services et de données sur un unique serveur constitue un point de défaillance unique (Single Point of Failure) et viole le principe de séparation des environnements.

**Serveur de sauvegarde** : Un serveur dédié assure la fonction de sauvegarde des données critiques. Les modalités précises de sauvegarde (fréquence, rétention, type de sauvegarde) ne sont pas documentées dans l'état actuel.

### Postes de travail

L'infrastructure compte 25 postes de travail, majoritairement équipés de systèmes d'exploitation Windows, répartis entre les différents départements. Les administrateurs IT disposent de postes hybrides capables d'exécuter à la fois Windows et Linux, leur permettant d'administrer l'infrastructure serveur via SSH.

La répartition des postes s'établit comme suit : un poste pour la direction générale, trois postes pour le département IT, six postes pour le développement, trois postes pour les ressources humaines, trois postes pour la finance et la comptabilité, et huit postes pour le département commercial et marketing.

### Services applicatifs déployés

Deux applications web principales sont actuellement en production :

**Application Web Commerciale** : Cette application constitue la vitrine publique de l'entreprise et permet la présentation des services, la vente de packs de développement web, la prise de contact avec les prospects et la gestion basique des commandes. Développée en PHP et s'appuyant sur une base de données MariaDB/MySQL, elle est accessible publiquement via Internet. Le serveur Apache est configuré pour utiliser HTTPS, avec un certificat TLS auto-signé ou Let's Encrypt, assurant le chiffrement des communications. Une redirection automatique de HTTP vers HTTPS a été implémentée.

**Application Web CRUD Ressources Humaines** : Cette application interne est réservée au département RH et permet les opérations classiques de gestion du personnel (création, consultation, modification et suppression des enregistrements employés). Bien que cette application soit de nature strictement interne et ne doive pas être exposée sur Internet, elle est actuellement hébergée sur le même serveur que l'application publique, sans isolation réseau adéquate. Elle utilise également la stack Apache/PHP/MariaDB.

### Politique de gestion des accès

La gestion des accès repose sur un modèle basé sur les rôles (Role-Based Access Control), avec une matrice d'accès définissant les permissions par département :

**Le Directeur Général** dispose d'un accès limité à l'application CRUD RH en consultation, ainsi qu'à l'application web commerciale, mais n'a pas d'accès direct aux serveurs Linux ni à la documentation technique.

**Les Administrateurs IT** bénéficient de privilèges étendus incluant l'accès SSH aux serveurs Linux, l'accès aux deux applications web, l'accès complet à l'application CRUD RH, et l'accès à la documentation technique IT via des adresses IP restreintes.

**Les Développeurs** ont accès à l'application web commerciale et à une partie de la documentation IT, mais ne disposent pas d'accès direct aux serveurs de production ni à l'application RH.

**Le département Ressources Humaines** accède aux deux applications web, avec des privilèges complets sur l'application CRUD dédiée, mais sans accès à l'infrastructure technique sous-jacente.

**Les départements Finance/Comptabilité et Commercial/Marketing** disposent uniquement d'un accès à l'application web commerciale, sans autres privilèges sur l'infrastructure.

### Configuration de sécurité web

La sécurisation des communications web constitue une première étape vers une infrastructure plus sécurisée. Le serveur Apache a été configuré pour utiliser le protocole HTTPS avec les mesures suivantes :

- Implémentation d'un certificat TLS, soit auto-signé pour les environnements de test, soit délivré par Let's Encrypt pour les environnements de production.

- Redirection automatique de l'ensemble du trafic HTTP vers HTTPS, garantissant que toutes les communications transitent par un canal chiffré.

- Activation du chiffrement des communications entre les navigateurs clients et le serveur web.

Toutefois, cette configuration initiale présente plusieurs axes d'amélioration : l'absence de durcissement TLS (désactivation de protocoles et suites de chiffrement obsolètes), l'absence de headers de sécurité HTTP (HSTS, CSP, X-Frame-Options, etc.), et l'absence de mécanismes de détection et de prévention des attaques applicatives.

### Gestion du code source

La gestion du code source de l'application web commerciale est prévue via un dépôt GitHub ou GitLab. Cette approche permet le versioning du code, la collaboration entre développeurs, et constitue une première étape vers l'adoption de pratiques DevOps. Le dépôt doit contenir le code source complet de l'application, la documentation technique, et un fichier README descriptif.

L'implémentation de pratiques d'intégration continue (CI) est envisagée pour automatiser les tests et les déploiements, améliorant ainsi la qualité et la sécurité du code déployé en production.

### Éléments non documentés

Plusieurs aspects de l'infrastructure actuelle restent non documentés ou non spécifiés dans l'état des lieux initial :

- La présence ou l'absence d'un annuaire Active Directory pour la gestion centralisée des identités et des accès.

- L'existence et la configuration d'un réseau WiFi, ainsi que les mesures de sécurité associées (chiffrement, segmentation, authentification).

- La solution antivirus déployée sur les postes de travail et serveurs.

- La politique de mots de passe en vigueur (complexité, durée de vie, historique).

- Les mécanismes de monitoring et de supervision de l'infrastructure réseau et des services.

- Les procédures de sauvegarde détaillées (fréquence, type, rétention, tests de restauration).

- Les mécanismes de journalisation (logs) et de corrélation d'événements de sécurité.

### Vulnérabilités architecturales identifiées

L'analyse de l'architecture actuelle permet d'identifier plusieurs vulnérabilités majeures qui seront détaillées dans les sections ultérieures du rapport :

**Absence de segmentation réseau** : Tous les équipements opèrent sur le même réseau plat, facilitant la propagation latérale en cas de compromission d'un poste.

**Absence de DMZ** : L'application web publique est exposée directement depuis le réseau interne, sans zone tampon entre Internet et les ressources internes.

**Concentration des services** : L'hébergement de l'application publique et de l'application RH interne sur le même serveur viole le principe de séparation et augmente le risque de compromission transversale.

**Exposition potentielle de l'application RH** : Bien que destinée à un usage interne, l'application RH pourrait être accessible depuis Internet en raison de l'absence de segmentation et de règles de filtrage granulaires.

**Pare-feu monolithique** : Le routeur jouant le rôle de pare-feu unique constitue un point de défaillance unique et ne permet pas une défense en profondeur.

**Absence de redondance** : L'architecture ne présente aucune redondance au niveau des composants critiques, compromettant la disponibilité en cas de défaillance matérielle.

Ces vulnérabilités constituent le point de départ de l'analyse de risques et guideront les propositions d'amélioration de l'infrastructure dans les phases ultérieures du projet.
