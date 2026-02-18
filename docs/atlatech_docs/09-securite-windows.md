---
title: Sécurité Windows
sidebar_label: "Sécurité Windows"
sidebar_position: 9
---

# 9. Sécurité Windows

## Périmètre et Architecture

**Ce chapitre traite exclusivement du durcissement des postes Windows (Endpoint Security Layer).**

La segmentation réseau est documentée au **Chapitre 8** et la correction applicative au **Chapitre 15**.

L'infrastructure de sécurité AtlasTech Solutions repose sur **3 couches défensives complémentaires:**

1. **Endpoint Layer (Chapitre 9)** ← **Vous êtes ici**
   - Hardening système (SysHardener)
   - Politiques de sécurité locales (GPO)
   - Pare-feu Windows local

2. **Network Layer (Chapitre 8)**
   - Segmentation VLAN (FortiGate)
   - Politiques de filtrage inter-VLAN

3. **Application Layer (Chapitre 15)**
   - Code PHP sécurisé (requêtes préparées)
   - Validation des entrées

---

## Vue d'ensemble

Ce chapitre documente l'implémentation complète de la sécurité sur les postes de travail Windows 10 de l'infrastructure AtlasTech Solutions.

**Objectif:**
Durcir les 25 postes Windows en appliquant:
- Désactivation des fonctionnalités vulnérables (SysHardener)
- Politiques de mots de passe robustes (GPO)
- Règles de pare-feu locales (Windows Defender Firewall)

**Environnement:**
```
Machine type: Windows 10 Pro 
Nombre de postes: 25
Machine exemple: WIN-DA9HK0109ND
```

---

## 9.1 Rappel du problème

Les vulnérabilités **V01 (SQL Injection)** et **V03 (IDOR)** ont été analysées en détail au **Chapitre 6**. 

Ce chapitre traite uniquement des mesures de sécurisation au niveau des postes Windows (Endpoint Layer).

---

## 9.2 Objectif de sécurité

**Sécurité système:**
- Désactiver 15+ fonctionnalités non nécessaires (AutoRun, PowerShell v2, Remote Desktop, SMBv1)
- Activer les protections matérielles disponibles

**Politiques de sécurité (GPO):**
- Mots de passe: 12 caractères minimum, complexité activée, historique 24
- Verrouillage: 5 tentatives maximum, durée 30 minutes
- Audit: Connexions, accès objets, modifications politiques

**Pare-feu Windows:**
- Bloquer les ports de base de données (3306, 5432)
- Autoriser les applications métier spécifiques
- Activer la journalisation complète

---

## 9.3 Hardening Windows avec SysHardener

### 9.3.1 Présentation de l'outil

**Outil:** NoVirusThanks SysHardener v3.0.0.0

**Qu'est-ce que c'est:**
Outil de durcissement système Windows (version trial utilisée) qui désactive des fonctionnalités non sécurisées via une interface graphique.

**Rôle:**
- Désactiver les vecteurs d'attaque courants
- Activer les protections matérielles
- Bloquer les fonctionnalités rarement utilisées mais vulnérables

### 9.3.2 Installation

**Machine:** Windows 10 (WIN-DA9HK0109ND)  
**Utilisateur:** Administrator

**Téléchargement:**
```
Site: https://novirusthanks.org/products/syshardener/
Fichier: SysHardener_Setup.exe
```

**Installation interactive:**
1. Double-cliquer sur `SysHardener_Setup.exe`
2. Accepter la licence
3. Chemin par défaut: `C:\Program Files\NoVirusThanks\SysHardener\`
4. Cliquer sur "Install"

**Validation:**
```powershell
Test-Path "C:\Program Files\NoVirusThanks\SysHardener\SysHardener.exe"
# Résultat attendu: True
```

### 9.3.3 Configuration des règles

**Lancement:**
```powershell
Start-Process "C:\Program Files\NoVirusThanks\SysHardener\SysHardener.exe" -Verb RunAs
```

**Règles appliquées (15 règles):**

| # | Règle | Niveau | Justification |
|---|-------|--------|---------------|
| 1 | Disable and Block Autorun.inf File | Low | Prévient l'infection par USB |
| 2 | Disable Autoplay for Any Drive | Low | Réduit le risque de malware |
| 3 | Disable Camera Access from Lock Screen | Low | Protection vie privée |
| 4 | Disable Clipboard History | Low | Évite la fuite de données |
| 5 | Disable Loading of DLLs via AppInit_DLLs | Low | Protection contre rootkits |
| 6 | Disable PowerShell Script Execution | Low | Prévient attaques par scripts |
| 7 | Disable PowerShell v2.0 Engine | Low | Élimine vecteur d'attaque connu |
| 8 | Disable Preview Pane in File Explorer | Low | Évite exécution accidentelle |
| 9 | Disable Remote Desktop Connections | Low | Réduit surface d'attaque |
| 10 | Disable Sidebar and Desktop Gadgets | Low | Élimine fonctionnalités vulnérables |
| 11 | Disable SMBv1 | Low | Protocole obsolète (EternalBlue) |
| 12 | Disable Support for 16-bit Processes | Low | Élimine vecteur legacy |
| 13 | Disable Windows Remote Assistance | Low | Réduit risques accès non autorisé |
| 14 | Disable Windows Script Host | Low | Prévient scripts malveillants |
| 15 | Disable Windows Subsystem for Linux | Low | Réduit surface d'attaque |

**Application:**
1. Cocher toutes les règles listées ci-dessus
2. Cliquer sur "Apply Selected"
3. Confirmer l'application
4. Redémarrer le système

```powershell
Restart-Computer -Force
```
![SysHardener - Règles appliquées](\img\09\hardening-windows.jpeg)


*Figure 9-X – Règles de durcissement appliquées avec succès.*

### 9.3.4 Validation technique

**Test 1: PowerShell v2 désactivé**
```powershell
powershell.exe -Version 2
# Résultat attendu: Erreur "version 2.0 is not supported"
```

**Test 2: SMBv1 désactivé**
```powershell
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
# Résultat attendu: State : Disabled
```

**Test 3: Remote Desktop désactivé**
```powershell
Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections"
# Résultat attendu: fDenyTSConnections : 1
```

**Test 4: AutoPlay désactivé**
```powershell
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay"
# Résultat attendu: DisableAutoplay : 1
```

---

## 9.4 Configuration des Politiques Locales (GPO)

### 9.4.1 Politique des mots de passe

**Outil:** gpedit.msc (Local Group Policy Editor)

**Ouverture:**
```powershell
gpedit.msc
```

**Navigation:**
```
Computer Configuration
└── Windows Settings
    └── Security Settings
        └── Account Policies
            └── Password Policy
```

**Configuration:**

**Paramètre 1: Enforce password history**
- Valeur: `24` mots de passe mémorisés
- Empêche la réutilisation des 24 derniers mots de passe

**Paramètre 2: Maximum password age**
- Valeur: `90` jours
- Les mots de passe expirent après 90 jours

**Paramètre 3: Minimum password age**
- Valeur: `1` jour
- Empêche le changement immédiat (contournement historique)

**Paramètre 4: Minimum password length**
- Valeur: `12` caractères
- Résistance accrue au brute force

**Paramètre 5: Password must meet complexity requirements**
- Valeur: `Enabled`
- Exige 3 des 4 catégories: majuscules, minuscules, chiffres, symboles

**Paramètre 6: Store passwords using reversible encryption**
- Valeur: `Disabled`
- **CRITIQUE:** Ne jamais activer (équivaut au stockage en clair)

**Application:**
```powershell
gpupdate /force
```

### 9.4.2 Verrouillage des comptes

**Navigation:**
```
Computer Configuration
└── Windows Settings
    └── Security Settings
        └── Account Policies
            └── Account Lockout Policy
```

**Configuration:**

**Paramètre 1: Account lockout threshold**
- Valeur: `5` tentatives
- Le compte se verrouille après 5 échecs

**Paramètre 2: Account lockout duration**
- Valeur: `30` minutes
- Durée du verrouillage automatique

**Paramètre 3: Reset account lockout counter after**
- Valeur: `30` minutes
- Remise à zéro du compteur d'échecs

### 9.4.3 Audit et journalisation

**Navigation:**
```
Computer Configuration
└── Windows Settings
    └── Security Settings
        └── Local Policies
            └── Audit Policy
```

**Politiques à activer:**

| Politique | Configuration | Justification |
|-----------|---------------|---------------|
| Audit account logon events | Success, Failure | Connexions de comptes |
| Audit account management | Success, Failure | Création/modification comptes |
| Audit logon events | Success, Failure | Connexions locales |
| Audit object access | Failure | Tentatives d'accès échouées |
| Audit policy change | Success, Failure | Modifications de politiques |
| Audit system events | Success, Failure | Événements système |

**Pour chaque paramètre:**
1. Double-cliquer
2. Cocher "Define these policy settings"
3. Cocher Success et/ou Failure selon tableau
4. Cliquer OK

**Application:**
```powershell
gpupdate /force
```

### 9.4.4 Validation technique

**Test: Politique mots de passe**
```powershell
net accounts
```

**Résultat attendu:**
```
Minimum password length:                              12
Maximum password age (days):                          90
Minimum password age (days):                          1
Length of password history maintained:                24
Lockout threshold:                                    5
Lockout duration (minutes):                           30
```

**Comparaison avant/après:**

| Paramètre | Avant | Après |
|-----------|-------|-------|
| Longueur min. | 0 | 12 |
| Historique | 0 | 24 |
| Verrouillage | Never | 5 tentatives |

---

## 9.5 Configuration du Pare-feu Windows Defender

### 9.5.1 Vérification des profils

**Commande:**
```powershell
Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction
```

**Résultat attendu:**
```
Name    Enabled DefaultInboundAction DefaultOutboundAction
----    ------- -------------------- ---------------------
Domain  True    Block                Allow
Private True    Block                Allow
Public  True    Block                Allow
```

### 9.5.2 Activation du logging

**Configuration:**
```powershell
Set-NetFirewallProfile -Profile Domain,Private,Public `
  -LogAllowed True `
  -LogBlocked True `
  -LogFileName "%systemroot%\system32\LogFiles\Firewall\pfirewall.log" `
  -LogMaxSizeKilobytes 4096
```

**Emplacement log:**
```
C:\Windows\System32\LogFiles\Firewall\pfirewall.log
```

### 9.5.3 Règles personnalisées

**Règle 1: Block-MySQL-Direct**
```powershell
New-NetFirewallRule -DisplayName "Block-MySQL-Direct" `
  -Direction Outbound `
  -Action Block `
  -Protocol TCP `
  -RemotePort 3306 `
  -Profile Private,Domain,Public `
  -Description "Bloquer acces direct au port MySQL (3306) - Mesure de réduction du risque d'accès direct aux bases de données"
```

**Règle 2: Block-PostgreSQL-Direct**
```powershell
New-NetFirewallRule -DisplayName "Block-PostgreSQL-Direct" `
  -Direction Outbound `
  -Action Block `
  -Protocol TCP `
  -RemotePort 5432 `
  -Profile Private,Domain,Public `
  -Description "Bloquer acces direct au port PostgreSQL (5432)"
```

**Règle 3: Allow-HR-App**
```powershell
New-NetFirewallRule -DisplayName "Allow-HR-App" `
  -Direction Outbound `
  -Action Allow `
  -Protocol TCP `
  -RemotePort 8080 `
  -RemoteAddress 10.0.0.10 `
  -Profile Private,Domain `
  -Description "Autoriser acces application RH (port 8080)"
```

**Règle 4: Allow-Web-Commercial**
```powershell
New-NetFirewallRule -DisplayName "Allow-Web-Commercial" `
  -Direction Outbound `
  -Action Allow `
  -Protocol TCP `
  -RemotePort 80,443 `
  -RemoteAddress 192.168.10.10 `
  -Profile Private,Domain `
  -Description "Autoriser acces site web commercial (DMZ)"
```

**Règle 5: Allow-Internet-HTTP-HTTPS**
```powershell
New-NetFirewallRule -DisplayName "Allow-Internet-HTTP-HTTPS" `
  -Direction Outbound `
  -Action Allow `
  -Protocol TCP `
  -RemotePort 80,443 `
  -Profile Private,Domain `
  -Description "Autoriser navigation Internet (HTTP/HTTPS)"
```

**Règle 6: Allow-DNS**
```powershell
New-NetFirewallRule -DisplayName "Allow-DNS" `
  -Direction Outbound `
  -Action Allow `
  -Protocol UDP `
  -RemotePort 53 `
  -Profile Private,Domain,Public `
  -Description "Autoriser requetes DNS"
```

**Lister les règles créées:**
```powershell
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "Allow-*" -or $_.DisplayName -like "Block-*"} | Select-Object DisplayName, Direction, Action, Enabled | Format-Table
```

### 9.5.4 Validation technique

**Test 1: MySQL bloqué**
```powershell
Test-NetConnection -ComputerName 10.0.0.11 -Port 3306
# Résultat attendu: TcpTestSucceeded : False
```

**Test 2: Vérification logs**
```powershell
Get-Content C:\Windows\System32\LogFiles\Firewall\pfirewall.log | Select-String "3306" | Select-Object -Last 5
```

**Résultat attendu:**
```
2026-02-15 12:34:56 DROP TCP 192.168.112.137 10.0.0.11 49152 3306 ...
```

**Test 3: Internet accessible**
```powershell
Test-NetConnection -ComputerName 8.8.8.8 -Port 443
# Résultat attendu: TcpTestSucceeded : True
```

---

## 9.6 Tests de validation

### Test 1: Politique mots de passe - Mot de passe faible refusé

```powershell
net user testuser weak /add
# Résultat attendu: Erreur "password does not meet requirements"
```

### Test 2: Verrouillage après 5 tentatives

1. Créer utilisateur de test
2. Tenter connexion avec mauvais mot de passe 5 fois
3. Vérifier le verrouillage

```powershell
net user testlockout | Select-String "locked"
# Résultat attendu: Account locked : Yes
```

### Test 3: Audit des connexions

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4624,4625} -MaxEvents 10
```

### Test 4: Pare-feu - Log des connexions bloquées

```powershell
Get-Content C:\Windows\System32\LogFiles\Firewall\pfirewall.log | Select-String "DROP" | Select-Object -Last 10
```

### Test 5: Validation complète - Script automatique

```powershell
$Tests = @(
    @{ Name = "MySQL Blocked"; IP = "10.0.0.11"; Port = 3306; Expected = $false },
    @{ Name = "PostgreSQL Blocked"; IP = "10.0.0.11"; Port = 5432; Expected = $false },
    @{ Name = "Internet HTTPS"; IP = "8.8.8.8"; Port = 443; Expected = $true },
)

foreach ($Test in $Tests) {
    Write-Host "`nTest: $($Test.Name)" -ForegroundColor Cyan
    $Result = Test-NetConnection -ComputerName $Test.IP -Port $Test.Port -WarningAction SilentlyContinue
    
    if ($Result.TcpTestSucceeded -eq $Test.Expected) {
        Write-Host "  PASSE" -ForegroundColor Green
    } else {
        Write-Host "  ECHEC" -ForegroundColor Red
    }
}
```

---

## 9.7 Résultat final

### Tableau récapitulatif - Avant/Après

| Aspect | Avant | Après |
|--------|-------|-------|
| **Services inutiles** | 50+ actifs | ~35 (15+ désactivés) |
| **PowerShell v2** | Actif | Désactivé |
| **SMBv1** | Actif | Désactivé |
| **Remote Desktop** | Actif | Désactivé |
| **AutoRun/AutoPlay** | Actif | Désactivé |
| **Mot de passe min.** | 0 caractères | **12 caractères** |
| **Complexité** |  Désactivée | Activée |
| **Historique** | 0 | **24** |
| **Verrouillage** | Jamais | **5 tentatives, 30 min** |
| **Audit connexions** |  Désactivé | Actif |
| **Pare-feu logging** |  Désactivé | Actif |
| **Port MySQL (3306)** | Accessible |  **Bloqué** |
| **Port PostgreSQL (5432)** | Accessible |  **Bloqué** |

---

## Conclusion

L'implémentation de la sécurité Windows a transformé les 25 postes AtlasTech en endpoints durcis.

**Résultat Endpoint Layer:**
- 15+ fonctionnalités vulnérables désactivées
- Politique mots de passe robuste (12 car., complexité, historique 24)
- Verrouillage compte (5 tentatives, 30 min)
- Audit complet activé
- Pare-feu Windows: 6 règles + logging
- Ports BD bloqués localement (3306, 5432)



**Note:** Les adresses IP et configurations utilisées sont basées sur l'audit fourni et l'architecture réseau du Chapitre 8.
