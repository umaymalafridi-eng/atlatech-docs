---
title: Contrôle d'Accès & DNS
sidebar_label: "17. Contrôle d'Accès"
sidebar_position: 17
---

# 17. Contrôle d'Accès & DNS

## Vue d'ensemble

Ce chapitre couvre les mécanismes de contrôle d'accès et la sécurité DNS pour AtlasTech Solutions, incluant la prévention IDOR, la désactivation du Directory Listing, l'URL Rewriting et la sécurisation DNS.

## Sections

### 17.1 IDOR Prevention
Protection contre l'accès non autorisé aux ressources via manipulation d'identifiants.

### 17.2 Directory Listing
Désactivation de l'indexation automatique des répertoires Apache.

### 17.3 URL Rewriting
Masquage des extensions .php pour améliorer la sécurité et l'esthétique.

### 17.4 DNS Security
Sécurisation du serveur DNS et protection contre les attaques DNS.

## Objectifs de sécurité

- Empêcher l'accès non autorisé aux ressources
- Masquer la structure des répertoires
- Améliorer l'obscurité de la technologie utilisée
- Sécuriser les résolutions DNS

## Conformité

- OWASP Top 10 - A01:2021 (Broken Access Control)
- CIS Apache HTTP Server Benchmark
- ISO 27001 A.9.4.1 (Restriction d'accès à l'information)