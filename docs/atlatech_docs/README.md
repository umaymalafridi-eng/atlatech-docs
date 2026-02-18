# Documentation AtlasTech - Structure

## Structure des fichiers

```
atlatech_docs/
├── _category_.json
├── 01-page-de-garde.md
├── 02-table-des-matieres.md
├── 03-executive-summary.md
├── 04-introduction-contexte.md
├── 05-analyse-infrastructure-actuelle.md
├── 06-identification-vulnerabilites.md
├── 07-analyse-detaillee-domaine.md
├── 08-securite-reseau-fortigate.md
├── 09-securite-windows.md
├── 10-iam-pam.md
├── 11-haute-disponibilite.md
├── 12-mots-de-passe-stockage.md
├── 13-sessions-https.md
├── 14-cryptographie.md
├── 15-securite-applicative.md
├── 16-securite-base-donnees.md
├── 17-controle-acces-dns.md
├── 18-durcissement-systemes.md
├── 19-monitoring-honeypot.md
├── 20-devsecops-cicd.md
├── 21-tests-intrusion.md
├── 22-conclusion.md
└── 23-annexes.md
```

## Installation dans Docusaurus

### Étape 1: Copier le dossier

```powershell
# Copier tout le dossier atlatech_docs vers le dossier docs de Docusaurus
cp -r atlatech_docs C:\Users\oumay\my-website\docs\
```

### Étape 2: Lancer Docusaurus

```powershell
cd C:\Users\oumay\my-website
npm start
```

### Étape 3: Accéder à la documentation

Ouvrir: `http://localhost:3002/docs/page-de-garde`

## Pages avec captures d'écran requises

Les pages suivantes nécessitent des captures d'écran (marquées ✅ dans le tableau):

- 04. Introduction et Contexte
- 05. Analyse Infrastructure Actuelle
- 06. Identification Vulnérabilités
- 07. Analyse Détaillée par Domaine
- 08. Sécurité Réseau (FortiGate)
- 09. Sécurité Windows
- 10. IAM & PAM
- 11. Haute Disponibilité
- 12. Mots de Passe & Stockage
- 13. Sessions & HTTPS
- 14. Cryptographie
- 15. Sécurité Applicative (10 sous-sections)
- 16. Sécurité Base de Données (10 sous-sections)
- 17. Contrôle d'Accès & DNS
- 18. Durcissement Systèmes
- 19. Monitoring & Honeypot
- 20. DevSecOps & CI/CD
- 21. Tests d'Intrusion
- 23. Annexes

## Comment ajouter des captures d'écran

1. Placer les images dans: `C:\Users\oumay\my-website\static\img\atlatech\`

2. Référencer dans les fichiers .md:

```markdown
![Description](../../static/img/atlatech/nom-image.png)
```

## Ordre de remplissage recommandé

1. Page de Garde (01)
2. Executive Summary (03)
3. Introduction et Contexte (04)
4. Analyse Infrastructure (05)
5. Identification Vulnérabilités (06)
6. Sections techniques (07-21)
7. Conclusion (22)
8. Annexes (23)
9. Table des Matières (02) - en dernier
