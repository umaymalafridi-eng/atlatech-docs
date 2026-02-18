---
title: Durcissement Systèmes
sidebar_label: "18. Hardening"
sidebar_position: 18
---

# 18. Durcissement Systèmes (Hardening)

## Vue d'ensemble

Le durcissement des systèmes consiste à réduire la surface d'attaque en appliquant les meilleures pratiques de sécurité sur les serveurs web, PHP, et le système d'exploitation.

## Sections

### 18.1 Hardening Serveurs Web (Apache)
Configuration sécurisée d'Apache selon les benchmarks CIS.

### 18.2 Hardening PHP (php.ini)
Sécurisation de PHP : désactivation de fonctions dangereuses, limites de ressources.

### 18.3 CIS Benchmarks
Application des recommandations CIS pour Ubuntu Server.

### 18.4 SELinux/AppArmor
Contrôle d'accès mandataire pour isolation des processus.

## Objectifs de sécurité

- Réduire la surface d'attaque
- Appliquer le principe du moindre privilège
- Conformité aux standards industriels (CIS, NIST)
- Protection contre les exploits connus

## Documents de référence

- CIS Apache HTTP Server 2.4 Benchmark
- CIS PHP Benchmark
- CIS Ubuntu Linux 24.04 Benchmark
- OWASP Secure Configuration Guide

## Conformité

- ISO 27001 A.12.6.1 (Gestion des vulnérabilités techniques)
- PCI-DSS 2.2 (Durcissement des systèmes)
- NIST SP 800-123 (Guide de sécurité des serveurs)