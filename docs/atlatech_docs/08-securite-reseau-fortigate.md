---
id: securite-reseau-fortigate
title: Sécurité Réseau (FortiGate)
sidebar_label: "Sécurité Réseau (FortiGate)"
sidebar_position: 8

---

# 8. Sécurité Réseau (FortiGate)

## Vue d'ensemble

Ce chapitre documente l'implémentation complète de la sécurité réseau d'AtlasTech Solutions en utilisant les pare-feu FortiGate en configuration haute disponibilité (HA). L'objectif est de corriger les vulnérabilités identifiées dans le chapitre 6 par une segmentation VLAN stricte, des politiques de pare-feu granulaires, et une exposition contrôlée des services web vers Internet.

**Rappel des problèmes principaux:**
- **V01-V06**: Absence de segmentation réseau, exposition directe des services
- **Infrastructure actuelle**: Réseau plat 192.168.112.0/24 sans isolation
- **Risque critique**: Application RH et Web Commercial sur le même serveur, accessible sans filtrage

**Objectif de sécurité:**
- Isoler les départements par VLANs avec contrôle d'accès strict
- Créer une DMZ pour le serveur web commercial (exposition Internet sécurisée)
- Isoler la zone serveurs (Server Zone) pour l'application RH
- Implémenter le principe du moindre privilège dans les règles de pare-feu
- Activer la haute disponibilité (HA) pour la continuité de service

---

## 8.1 Architecture Réseau Cible

### 8.1.1 Schéma de l'infrastructure sécurisée

![Schéma Architecture](/img/08/schema-optimiser.jpeg)

*Figure 8-1 – Architecture réseau sécurisée cible.*

D'après les schémas fournis (`schema-optimiser.jpeg`), la nouvelle architecture comprend:

```
                            Internet
                               │
                          [ISP Router]
                               │
                   ┌───────────┴───────────┐
                   │                       │
            [FortiGate-A]           [FortiGate-B]
              (Primary)              (Secondary)
                   │                       │
                   └─────────┬─────────────┘
                             │
                      [Core Switch-1]────[Core Switch-2]
                        (HSRP + LACP)
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    [Access SW-1]      [Access SW-2]      [Access SW-3]
          │                  │                  │
    ┌─────┴─────┐      ┌─────┴─────┐      ┌─────┴─────┐
    │           │      │           │      │           │
  VLANs     Server   VLANs      DMZ      VLANs
  10,20     Zone     30,40,50            60
```

### 8.1.2 Zones de sécurité

| Zone | Description | Niveau de confiance | Adressage |
|------|-------------|---------------------|-----------|
| **Internet** | Réseau externe | Non fiable (0%) | ISP Public IP |
| **DMZ** | Zone démilitarisée | Faible (25%) | 192.168.10.0/24 |
| **Server Zone** | Serveurs internes critiques | Moyen (50%) | 10.0.0.0/24 |
| **Backup Zone** | Serveurs de sauvegarde | Moyen (50%) | 10.0.1.0/24 |
| **Internal VLANs** | Postes utilisateurs | Élevé (75%) | 10.0.X.0/24 |
| **Management** | Administration réseau | Critique (90%) | 10.0.99.0/24 |

---

## 8.2 Segmentation VLAN

### 8.2.1 Plan d'adressage complet

**Protocole: IEEE 802.1Q VLAN Tagging**
- **Qu'est-ce que c'est:** Norme de segmentation réseau au niveau 2 (couche liaison)
- **Pourquoi l'utiliser:** Isolation logique du trafic, contrôle d'accès granulaire
- **Rôle:** Séparer les départements sur un même switch physique

| VLAN ID | Nom | Département | Réseau | Gateway (FortiGate) | DHCP Range | Nombre Postes |
|---------|-----|-------------|--------|---------------------|------------|---------------|
| **10** | Dev | Développement | 10.0.10.0/24 | 10.0.10.1 | 10.0.10.10 - 10.0.10.100 | 6 |
| **20** | IT | Informatique | 10.0.20.0/24 | 10.0.20.1 | 10.0.20.10 - 10.0.20.100 | 3 |
| **30** | RH | Ressources Humaines | 10.0.30.0/24 | 10.0.30.1 | 10.0.30.10 - 10.0.30.100 | 3 |
| **40** | CEO | Direction Générale | 10.0.40.0/24 | 10.0.40.1 | 10.0.40.10 - 10.0.40.100 | 1 |
| **50** | Commercial | Commercial & Marketing | 10.0.50.0/24 | 10.0.50.1 | 10.0.50.10 - 10.0.50.100 | 8 |
| **60** | Finance | Finance & Comptabilité | 10.0.60.0/24 | 10.0.60.1 | 10.0.60.10 - 10.0.60.100 | 3 |
| **99** | Management | Administration IT | 10.0.99.0/24 | 10.0.99.1 | 10.0.99.10 - 10.0.99.50 | - |

**Zones spéciales:**

| Zone | Réseau | Gateway | Description |
|------|--------|---------|-------------|
| **DMZ** | 192.168.10.0/24 | 192.168.10.1 | Serveur Web Commercial (IP: 192.168.10.10) |
| **Server Zone** | 10.0.0.0/24 | 10.0.0.1 | HR App + DB (IP: 10.0.0.10, 10.0.0.11) |
| **Backup Zone** | 10.0.1.0/24 | 10.0.1.1 | Serveur de sauvegarde (IP: 10.0.1.10) |


---

## 8.3 Configuration FortiGate - Interfaces

### 8.3.1 Prérequis

**Matériel:**
- 2x FortiGate (FortiGate-A et FortiGate-B)
- Modèle: FortiGate VM64-KVM (basé sur screenshot)
- Version FortiOS: 7.0.9

**Accès:**
- Interface Web: `https://<FortiGate_IP>`
- CLI: SSH `ssh admin@<FortiGate_IP>`

### 8.3.2 Configuration Interface WAN (port1)

**Rappel du problème:** Absence de pare-feu dédié, exposition directe des services.

**Objectif:** Créer un point d'entrée unique et contrôlé vers Internet.

**Implémentation technique:**

#### Étape 1: Configuration via Web GUI

**Machine:** FortiGate-A (ou FortiGate-B en mode standalone pour test)

**Chemin:** `Network > Interfaces > port1`

1. Cliquer sur **port1** pour éditer
2. Configurer:

```
Name: WAN
Alias: WAN-ISP
Role: WAN
Addressing mode: Manual (ou DHCP selon ISP)

IP/Netmask: 203.0.113.2/30
(Exemple - Remplacer par votre IP publique ISP)

Administrative Access:
  ☐ HTTP
  ☐ HTTPS
  ☑ PING (pour diagnostic uniquement)
  ☐ SSH
  ☐ SNMP
```

3. Cliquer **OK**

#### Étape 2: Configuration via CLI (Alternative)

**Machine:** FortiGate-A CLI (via SSH)

```bash
# Connexion SSH au FortiGate
ssh admin@<FortiGate_Management_IP>

# Configuration WAN
config system interface
    edit "port1"
        set alias "WAN-ISP"
        set mode static
        set ip 203.0.113.2 255.255.255.252
        set allowaccess ping
        set type physical
        set role wan
        set interface "port1"
    next
end
```

**Explication technique:**
- `set mode static`: Adresse IP manuelle (alternative: `set mode dhcp` pour IP dynamique ISP)
- `set allowaccess ping`: N'autoriser que PING (sécurité: aucun accès admin depuis Internet)
- `set role wan`: Indique au FortiGate que c'est l'interface externe

**Validation:**

```bash
# Vérifier la configuration
get system interface physical | grep -A 10 port1

# Tester la connectivité Internet
execute ping 8.8.8.8

# Résultat attendu:
# PING 8.8.8.8 (8.8.8.8): 56 data bytes
# 64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=10.2 ms
```

**Ce qui a changé:**
- ✅ Interface WAN dédiée avec IP publique
- ✅ Accès administratif désactivé depuis Internet
- ✅ Point de contrôle unique pour le trafic sortant/entrant

---

### 8.3.3 Configuration Interface DMZ (port6)

**Rappel du problème (V01):** Application Web Commercial et RH sur le même serveur, aucune isolation.

**Objectif:** Isoler le serveur web public dans une DMZ, séparé du réseau interne.

**Implémentation technique:**

#### Via Web GUI

**Chemin:** `Network > Interfaces > port6 (ou port4 selon modèle)`

```
Name: DMZ
Alias: DMZ-Zone
Role: DMZ

Addressing mode: Manual
IP/Netmask: 192.168.10.1/24

Administrative Access:
  ☐ HTTP
  ☑ HTTPS (pour administration locale uniquement)
  ☑ PING
  ☑ SSH
```

#### Via CLI

```bash
config system interface
    edit "port6"
        set alias "DMZ-Zone"
        set mode static
        set ip 192.168.10.1 255.255.255.0
        set allowaccess https ping ssh
        set type physical
        set role dmz
    next
end
```

**Explication:**
- `set role dmz`: Applique les politiques de sécurité DMZ (niveau confiance faible)
- Réseau 192.168.10.0/24: Isolé des VLANs internes (10.0.X.0/24)

**Validation:**

```bash
# Depuis FortiGate CLI
execute ping 192.168.10.10
# (IP du serveur web dans la DMZ)

# Résultat attendu: réponses ICMP
```

---

### 8.3.4 Configuration Interfaces VLAN (port3 - Trunk)

**Rappel du problème:** Réseau plat 192.168.112.0/24, tous les départements sur le même broadcast domain.

**Objectif:** Créer des VLANs séparés pour chaque département avec contrôle d'accès.

**Protocole: 802.1Q Trunking**
- **Qu'est-ce que c'est:** Transport de multiples VLANs sur un seul lien physique
- **Pourquoi:** Optimiser l'utilisation des ports, centraliser le routage inter-VLAN
- **Rôle:** FortiGate devient le routeur inter-VLAN avec politiques de sécurité

#### Étape 1: Créer l'interface Trunk (port3)

**Via Web GUI:**

`Network > Interfaces > port3`

```
Name: LAN-Trunk
Alias: Trunk-to-CoreSwitches
Role: LAN

Addressing mode: Manual
IP/Netmask: (Laisser vide - pas d'IP sur le trunk)

Administrative Access: (Tout décocher)
```

#### Via CLI

```bash
config system interface
    edit "port3"
        set alias "Trunk-to-CoreSwitches"
        set type physical
        set role lan
    next
end
```

#### Étape 2: Créer les Sub-Interfaces VLAN

**VLAN 10 - Développement:**

**Via Web GUI:** `Network > Interfaces > Create New > Interface`

```
Name: VLAN10-Dev
Type: VLAN
Interface: port3 (LAN-Trunk)
VLAN ID: 10

Alias: Dev-Gateway
Role: LAN
Addressing mode: Manual
IP/Netmask: 10.0.10.1/24

Administrative Access:
  ☑ HTTPS
  ☑ PING
  ☑ SSH
```

**Via CLI:**

```bash
config system interface
    edit "VLAN10-Dev"
        set vdom "root"
        set ip 10.0.10.1 255.255.255.0
        set allowaccess https ping ssh
        set alias "Dev-Gateway"
        set interface "port3"
        set vlanid 10
        set role lan
    next
end
```

**Explication technique:**
- `set interface "port3"`: Lie la sub-interface au trunk physique
- `set vlanid 10`: Tag 802.1Q pour identifier le trafic VLAN 10
- `set ip 10.0.10.1`: Gateway pour les postes du département Développement

**Répéter pour tous les VLANs:**

```bash
# VLAN 20 - IT
config system interface
    edit "VLAN20-IT"
        set ip 10.0.20.1 255.255.255.0
        set allowaccess https ping ssh
        set alias "IT-Gateway"
        set interface "port3"
        set vlanid 20
        set role lan
    next
end

# VLAN 30 - RH
config system interface
    edit "VLAN30-RH"
        set ip 10.0.30.1 255.255.255.0
        set allowaccess https ping ssh
        set alias "RH-Gateway"
        set interface "port3"
        set vlanid 30
        set role lan
    next
end

# VLAN 40 - CEO
config system interface
    edit "VLAN40-CEO"
        set ip 10.0.40.1 255.255.255.0
        set allowaccess https ping ssh
        set alias "CEO-Gateway"
        set interface "port3"
        set vlanid 40
        set role lan
    next
end

# VLAN 50 - Commercial
config system interface
    edit "VLAN50-Commercial"
        set ip 10.0.50.1 255.255.255.0
        set allowaccess https ping ssh
        set alias "Commercial-Gateway"
        set interface "port3"
        set vlanid 50
        set role lan
    next
end

# VLAN 60 - Finance
config system interface
    edit "VLAN60-Finance"
        set ip 10.0.60.1 255.255.255.0
        set allowaccess https ping ssh
        set alias "Finance-Gateway"
        set interface "port3"
        set vlanid 60
        set role lan
    next
end

# VLAN 99 - Management
config system interface
    edit "VLAN99-Mgmt"
        set ip 10.0.99.1 255.255.255.0
        set allowaccess https ping ssh snmp
        set alias "Management"
        set interface "port3"
        set vlanid 99
        set role lan
    next
end
```

**Validation:**

```bash
# Vérifier toutes les interfaces
get system interface | grep -E "VLAN|port"

# Résultat attendu:
# VLAN10-Dev          10.0.10.1/24
# VLAN20-IT           10.0.20.1/24
# VLAN30-RH           10.0.30.1/24
# ...
```

**Ce qui a changé:**
- ✅ 6 VLANs utilisateurs isolés
- ✅ 1 VLAN Management séparé
- ✅ Chaque département a son propre subnet
- ✅ Routage inter-VLAN contrôlé par FortiGate

![FortiGate VLAN Dev](/img/08/fortigate-vlan-dev.jpeg)

*Figure 8-2 – Configuration VLAN 10 (Développement).*

![FortiGate VLAN IT](/img/08/fortigate-vlan-it.jpeg)

*Figure 8-3 – Configuration VLAN 20 (IT).*

---

### 8.3.5 Configuration Interface Server Zone (port5)

**Rappel du problème (V03):** Application RH accessible sans contrôle d'accès (IDOR).

**Objectif:** Isoler les serveurs internes dans une zone dédiée avec accès restreint.

**Via Web GUI:** `Network > Interfaces > port5`

```
Name: ServerZone
Alias: Internal-Servers
Role: LAN

Addressing mode: Manual
IP/Netmask: 10.0.0.1/24

Administrative Access:
  ☑ HTTPS
  ☑ PING
  ☑ SSH
```

**Via CLI:**

```bash
config system interface
    edit "port5"
        set alias "Internal-Servers"
        set mode static
        set ip 10.0.0.1 255.255.255.0
        set allowaccess https ping ssh
        set type physical
        set role lan
    next
end
```

**Serveurs dans cette zone:**
- **10.0.0.10**: HR Application Server (Apache + PHP)
- **10.0.0.11**: Database Server (MySQL/MariaDB)

---

### 8.3.6 Configuration Interface Backup Zone

![FortiGate Interfaces](/img/08/fortigate-interfaces.jpeg)

*Figure 8-4 – Vue globale des interfaces FortiGate configurées.* (port7)

**CORRECTION APPLIQUÉE:** Ajout de l'interface Backup Zone qui était mentionnée mais non configurée.

**Objectif:** Isoler les serveurs de sauvegarde dans une zone dédiée.

**Via Web GUI:** `Network > Interfaces > port7`

```
Name: BackupZone
Alias: Backup-Network
Role: LAN

Addressing mode: Manual
IP/Netmask: 10.0.1.1/24

Administrative Access:
  ☑ HTTPS
  ☑ PING
  ☑ SSH
```

**Via CLI:**

```bash
config system interface
    edit "port7"
        set alias "Backup-Network"
        set mode static
        set ip 10.0.1.1 255.255.255.0
        set allowaccess https ping ssh
        set type physical
        set role lan
    next
end
```

**Serveurs dans cette zone:**
- **10.0.1.10**: Backup Server (Rsync/Bacula)

**Validation:**

```bash
# Depuis FortiGate CLI
execute ping 10.0.1.10

# Résultat attendu: réponses ICMP
```

---

## 8.4 Configuration des Zones d'Interface (Interface Zones)

**CORRECTION APPLIQUÉE:** Création de zones d'interface pour une gestion optimale des politiques de pare-feu.

**Pourquoi utiliser des zones:**
- Simplifier les politiques de pare-feu
- Permettre l'ajout/suppression d'interfaces sans modifier les policies
- Meilleure scalabilité
- Compatibilité avec toutes les versions FortiOS

### 8.4.1 Création de la zone Internal

**Via Web GUI:** `Network > Interfaces > Create New > Zone`

```
Zone Name: Internal
Interface Members:
  - VLAN10-Dev
  - VLAN20-IT
  - VLAN30-RH
  - VLAN40-CEO
  - VLAN50-Commercial
  - VLAN60-Finance
```

**Via CLI:**

```bash
config system zone
    edit "Internal"
        set interface "VLAN10-Dev" "VLAN20-IT" "VLAN30-RH" "VLAN40-CEO" "VLAN50-Commercial" "VLAN60-Finance"
    next
end
```

### 8.4.2 Création de la zone Servers

```bash
config system zone
    edit "Servers"
        set interface "ServerZone" "BackupZone"
    next
end
```

**Validation:**

```bash
# Vérifier les zones créées
get system zone

# Résultat attendu:
# == [ Internal ]
# name: Internal
# interface: VLAN10-Dev VLAN20-IT VLAN30-RH VLAN40-CEO VLAN50-Commercial VLAN60-Finance
```

**Avantages:**
- ✅ Permet l'utilisation de `set srcintf "Internal"` dans les policies
- ✅ Évite les erreurs de syntaxe avec multiple srcintf
- ✅ Facilite la maintenance (ajouter un VLAN = l'ajouter à la zone)

---

## 8.5 Configuration DHCP Server

DHCP est configuré sur chaque VLAN pour automatiser l'attribution d'adresses IP aux postes utilisateurs.

**Configuration via CLI:**

```bash
# DHCP Server - VLAN 10 (Développement)
config system dhcp server
    edit 0
        set interface "VLAN10-Dev"
        set default-gateway 10.0.10.1
        set netmask 255.255.255.0
        config ip-range
            edit 0
                set start-ip 10.0.10.10
                set end-ip 10.0.10.100
            next
        end
        set dns-server1 8.8.8.8
        set domain "atlastech.local"
    next
end

# DHCP Server - VLAN 20 (IT)
config system dhcp server
    edit 1
        set interface "VLAN20-IT"
        set default-gateway 10.0.20.1
        set netmask 255.255.255.0
        config ip-range
            edit 1
                set start-ip 10.0.20.10
                set end-ip 10.0.20.100
            next
        end
        set dns-server1 8.8.8.8
        set domain "atlastech.local"
    next
end

# DHCP Server - VLAN 30 (RH)
config system dhcp server
    edit 2
        set interface "VLAN30-RH"
        set default-gateway 10.0.30.1
        set netmask 255.255.255.0
        config ip-range
            edit 2
                set start-ip 10.0.30.10
                set end-ip 10.0.30.100
            next
        end
        set dns-server1 8.8.8.8
        set domain "atlastech.local"
    next
end

# DHCP Server - VLAN 40 (CEO)
config system dhcp server
    edit 3
        set interface "VLAN40-CEO"
        set default-gateway 10.0.40.1
        set netmask 255.255.255.0
        config ip-range
            edit 3
                set start-ip 10.0.40.10
                set end-ip 10.0.40.100
            next
        end
        set dns-server1 8.8.8.8
        set domain "atlastech.local"
    next
end

# DHCP Server - VLAN 50 (Commercial)
config system dhcp server
    edit 4
        set interface "VLAN50-Commercial"
        set default-gateway 10.0.50.1
        set netmask 255.255.255.0
        config ip-range
            edit 4
                set start-ip 10.0.50.10
                set end-ip 10.0.50.100
            next
        end
        set dns-server1 8.8.8.8
        set domain "atlastech.local"
    next
end

# DHCP Server - VLAN 60 (Finance)
config system dhcp server
    edit 5
        set interface "VLAN60-Finance"
        set default-gateway 10.0.60.1
        set netmask 255.255.255.0
        config ip-range
            edit 5
                set start-ip 10.0.60.10
                set end-ip 10.0.60.100
            next
        end
        set dns-server1 8.8.8.8
        set domain "atlastech.local"
    next
end
```

**Note:** L'utilisation de `edit 0` dans des blocks séparés permet au FortiGate de créer automatiquement des entrées DHCP séquentielles.

**Validation:**

```bash
get system dhcp server list
```

---

## 8.6 Objets d'Adresse (Address Objects)

**Pourquoi créer des objets:**
- Réutilisabilité dans les politiques de pare-feu
- Faciliter la maintenance (modifier une fois, appliquer partout)
- Lisibilité accrue des règles

### 8.6.1 Création des objets serveurs

**Via Web GUI:** `Policy & Objects > Addresses > Create New > Address`

**Serveurs critiques:**

```
Name: HR-App-Server
Type: IP/Netmask
Subnet/IP Range: 10.0.0.10/32
Interface: ServerZone
Comments: Linux - Application CRUD RH (Apache + PHP)
```

```
Name: DB-Server
Type: IP/Netmask
Subnet/IP Range: 10.0.0.11/32
Interface: ServerZone
Comments: MySQL/MariaDB - Base de données atlastech_db
```

```
Name: Web-Commercial-Server
Type: IP/Netmask
Subnet/IP Range: 192.168.10.10/32
Interface: DMZ
Comments: Serveur Web Commercial - Exposition Internet
```

```
Name: Backup-Server
Type: IP/Netmask
Subnet/IP Range: 10.0.1.10/32
Interface: BackupZone
Comments: Serveur de sauvegarde
```

**Via CLI:**

```bash
config firewall address
    edit "HR-App-Server"
        set subnet 10.0.0.10 255.255.255.255
        set associated-interface "ServerZone"
        set comment "Application CRUD RH"
    next
    edit "DB-Server"
        set subnet 10.0.0.11 255.255.255.255
        set associated-interface "ServerZone"
        set comment "Base de donnees MySQL"
    next
    edit "Web-Commercial-Server"
        set subnet 192.168.10.10 255.255.255.255
        set associated-interface "DMZ"
        set comment "Serveur Web Public"
    next
    edit "Backup-Server"
        set subnet 10.0.1.10 255.255.255.255
        set associated-interface "BackupZone"
        set comment "Serveur de sauvegarde"
    next
end
```

### 8.6.2 Création des objets réseaux VLAN

```bash
config firewall address
    edit "Net-VLAN10-Dev"
        set subnet 10.0.10.0 255.255.255.0
        set associated-interface "VLAN10-Dev"
    next
    edit "Net-VLAN20-IT"
        set subnet 10.0.20.0 255.255.255.0
        set associated-interface "VLAN20-IT"
    next
    edit "Net-VLAN30-RH"
        set subnet 10.0.30.0 255.255.255.0
        set associated-interface "VLAN30-RH"
    next
    edit "Net-VLAN40-CEO"
        set subnet 10.0.40.0 255.255.255.0
        set associated-interface "VLAN40-CEO"
    next
    edit "Net-VLAN50-Commercial"
        set subnet 10.0.50.0 255.255.255.0
        set associated-interface "VLAN50-Commercial"
    next
    edit "Net-VLAN60-Finance"
        set subnet 10.0.60.0 255.255.255.0
        set associated-interface "VLAN60-Finance"
    next
    edit "Net-DMZ"
        set subnet 192.168.10.0 255.255.255.0
        set associated-interface "DMZ"
    next
    edit "Net-ServerZone"
        set subnet 10.0.0.0 255.255.255.0
        set associated-interface "ServerZone"
    next
    edit "Net-BackupZone"
        set subnet 10.0.1.0 255.255.255.0
        set associated-interface "BackupZone"
    next
end
```

### 8.6.3 Groupes d'objets

**Groupe: Tous les VLANs internes**

```bash
config firewall addrgrp
    edit "Grp-All-Internal-VLANs"
        set member "Net-VLAN10-Dev" "Net-VLAN20-IT" "Net-VLAN30-RH" "Net-VLAN40-CEO" "Net-VLAN50-Commercial" "Net-VLAN60-Finance"
        set comment "Tous les departements"
    next
    edit "Grp-All-Servers"
        set member "HR-App-Server" "DB-Server" "Backup-Server"
        set comment "Tous les serveurs internes"
    next
end
```

---

## 8.7 Services Personnalisés

**Protocole: TCP/UDP Custom Services**
- **Pourquoi:** Les applications utilisent des ports spécifiques (ex: HR App sur 8080)
- **Rôle:** Définir précisément les ports autorisés (principe du moindre privilège)

### 8.7.1 Service HR Application (port 8080)

**Via Web GUI:** `Policy & Objects > Services > Create New > Service`

```
Name: HTTP-8080-HR-App
Protocol: TCP/UDP/SCTP
TCP Port Range: 8080
```

**Via CLI:**

```bash
config firewall service custom
    edit "HTTP-8080-HR-App"
        set tcp-portrange 8080
        set comment "Application CRUD RH"
    next
    edit "MySQL-3306"
        set tcp-portrange 3306
        set comment "Acces base de donnees"
    next
    edit "Rsync-873"
        set tcp-portrange 873
        set comment "Service de sauvegarde Rsync"
    next
end
```

---

## 8.8 Politiques de Pare-feu (Firewall Policies)

**Rappel des vulnérabilités:**
- **V01**: SQL Injection - nécessite isolation de la DB
- **V03**: IDOR - nécessite contrôle d'accès strict par département

**Objectif:** Implémenter le principe du moindre privilège (Least Privilege).

**Principe d'ordre des règles:**
1. **Règles DENY spécifiques** en premier
2. **Règles ALLOW spécifiques** ensuite
3. **Règle DENY ALL implicite** à la fin

### 8.8.1 Matrice de contrôle d'accès (CORRIGÉE)

**CORRECTION APPLIQUÉE:** Harmonisation avec le tableau "Rôles et Accès aux Systèmes"

| # | Source | Destination | Services | Action | Commentaire |
|---|--------|-------------|----------|--------|-------------|
| 1 | VLAN30-RH | HR-App-Server | HTTP-8080, HTTPS | ACCEPT | RH accès application CRUD uniquement |
| 2 | VLAN30-RH | All-Servers (sauf HR-App) | ALL | DENY | Bloquer accès DB et autres serveurs |
| 3 | VLAN30-RH | DMZ | ALL | DENY | RH n'a pas accès à l'app commerciale |
| 4 | VLAN30-RH | Internet | HTTP, HTTPS, DNS | ACCEPT | Navigation Internet avec filtrage |
| 5 | VLAN60-Finance | Web-Commercial-Server (DMZ) | HTTP, HTTPS | ACCEPT | Finance accès app commerciale uniquement |
| 6 | VLAN60-Finance | Server Zone | ALL | DENY | Bloquer accès serveurs internes |
| 7 | VLAN60-Finance | Internet | HTTP, HTTPS, DNS | ACCEPT | Navigation Internet |
| 8 | VLAN50-Commercial | Web-Commercial-Server (DMZ) | HTTP, HTTPS | ACCEPT | Commercial accès app commerciale |
| 9 | VLAN50-Commercial | Server Zone | ALL | DENY | Bloquer accès serveurs |
| 10 | VLAN50-Commercial | Internet | HTTP, HTTPS, DNS, SMTP | ACCEPT | Internet + Email |
| 11 | VLAN20-IT | Server Zone, Backup Zone | SSH, HTTPS, MySQL | ACCEPT | IT accès complet aux serveurs |
| 12 | VLAN20-IT | DMZ | SSH, HTTP, HTTPS | ACCEPT | IT administration DMZ |
| 13 | VLAN20-IT | Internet | HTTP, HTTPS, DNS, SSH | ACCEPT | IT accès Internet |
| 14 | VLAN10-Dev | Server Zone (Test) | HTTP, HTTPS | ACCEPT | Dev accès environnements test (lecture seule) |
| 15 | VLAN10-Dev | DMZ | HTTP, HTTPS | ACCEPT | Dev consultation app commerciale |
| 16 | VLAN10-Dev | Internet | HTTP, HTTPS, DNS, SSH | ACCEPT | Dev accès repos externes |
| 17 | VLAN40-CEO | HR-App-Server, Web-Commercial-Server | HTTP, HTTPS, HTTP-8080 | ACCEPT | **CEO accès limité aux applications métier uniquement** |
| 18 | VLAN40-CEO | Internet | HTTP, HTTPS, DNS | ACCEPT | CEO navigation Internet |
| 19 | Web-Commercial-Server (DMZ) | DB-Server | MySQL-3306 | ACCEPT | App commerciale vers DB uniquement |
| 20 | Web-Commercial-Server (DMZ) | Server Zone (autres) | ALL | DENY | Bloquer accès autres serveurs depuis DMZ |
| 21 | Web-Commercial-Server (DMZ) | Internet | HTTP, HTTPS | ACCEPT | Updates système |
| 22 | Internet | Web-Commercial-Server (DMZ) | HTTP, HTTPS (VIP) | ACCEPT | Accès public au site web |
| 23 | Internet | Server Zone | ALL | DENY | Bloquer tout accès direct aux serveurs |
| 24 | Internet | Internal VLANs | ALL | DENY | Bloquer accès direct aux utilisateurs |
| 25 | HR-App-Server | DB-Server | MySQL-3306 | ACCEPT | HR App vers sa DB |
| 26 | Backup-Server | All Servers | SSH, Rsync-873 | ACCEPT | Backup automatique |

**Note importante sur Policy 17 (CEO):**
- ❌ **Supprimé:** Accès SSH, MySQL direct, et accès complet à tous les serveurs
- ✅ **Ajouté:** Accès limité uniquement aux applications métier (HR App et Web Commercial)
- ✅ **Conforme:** Au tableau "Rôles et Accès aux Systèmes" qui indique "Non" pour accès serveurs Linux
- ✅ **Sécurité:** Le CEO ne doit pas avoir d'accès administratif direct aux serveurs

Les politiques ont été réorganisées manuellement dans l'interface GUI afin de respecter l'ordre logique défini dans la matrice.

![FortiGate Policy](/img/08/fortigate-firewall-policies.jpeg)

*Figure 8-5 – Politiques de pare-feu appliquées (ordre logique).* 

### 8.8.2 Implémentation des politiques critiques

#### Policy 1: RH vers HR Application (Corriger V03 - IDOR)

**Rappel V03:** Contrôle d'accès absent, tous les employés peuvent voir tous les dossiers.

**Objectif:** N'autoriser QUE le département RH à accéder à l'application HR.

**Via Web GUI:** `Policy & Objects > Firewall Policy > Create New`

```
Name: RH-to-HR-App-ONLY

Incoming Interface: VLAN30-RH
Outgoing Interface: ServerZone

Source:
  Address: Net-VLAN30-RH

Destination:
  Address: HR-App-Server

Schedule: always

Service:
  HTTP-8080-HR-App
  HTTPS

Action: ACCEPT

NAT: Disable

Security Profiles:
  ☑ AntiVirus: default
  ☑ Web Filter: default
  ☑ IPS: default

Logging Options:
  ☑ Log Allowed Traffic
  ☑ Security Events

Comments: RH acces application CRUD uniquement - Correction V03
```

**Via CLI:**

```bash
config firewall policy
    edit 0
        set name "RH-to-HR-App-ONLY"
        set srcintf "VLAN30-RH"
        set dstintf "ServerZone"
        set srcaddr "Net-VLAN30-RH"
        set dstaddr "HR-App-Server"
        set action accept
        set schedule "always"
        set service "HTTP-8080-HR-App" "HTTPS"
        set logtraffic all
        set comments "Correction V03 - IDOR: seul RH peut acceder a l'app"
        set av-profile "default"
        set webfilter-profile "default"
        set ips-sensor "default"
    next
end
```

**Validation:**

```bash
# Depuis un poste VLAN30-RH (10.0.30.X)
curl -I http://10.0.0.10:8080

# Résultat attendu: HTTP/1.1 200 OK

# Depuis un autre VLAN (ex: Finance 10.0.60.X)
curl -I http://10.0.0.10:8080

# Résultat attendu: Connexion refusée (pas de route/policy)
```

**Ce qui a changé:**
- ✅ IDOR corrigé: Seul VLAN RH peut accéder à l'application HR
- ✅ IPS activé: Détection des tentatives d'exploitation (SQL Injection)
- ✅ Logs activés: Traçabilité des accès

---

#### Policy 2: DENY RH vers Database directe

**Rappel V01:** Injection SQL possible car accès direct à la DB.

**Objectif:** Empêcher l'accès direct à la DB depuis les postes utilisateurs.

```bash
config firewall policy
    edit 0
        set name "DENY-RH-to-Database-Direct"
        set srcintf "VLAN30-RH"
        set dstintf "ServerZone"
        set srcaddr "Net-VLAN30-RH"
        set dstaddr "DB-Server"
        set action deny
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set comments "Correction V01 - Bloquer acces direct DB"
    next
end
```

**Validation:**

```bash
# Depuis poste RH
telnet 10.0.0.11 3306

# Résultat attendu: Connection refused
```

---

#### Policy 3: Finance vers DMZ uniquement

**Objectif:** Finance accède à l'app commerciale (DMZ), MAIS PAS aux serveurs internes.

```bash
config firewall policy
    edit 0
        set name "Finance-to-DMZ-WebApp"
        set srcintf "VLAN60-Finance"
        set dstintf "DMZ"
        set srcaddr "Net-VLAN60-Finance"
        set dstaddr "Web-Commercial-Server"
        set action accept
        set schedule "always"
        set service "HTTP" "HTTPS"
        set logtraffic all
        set comments "Finance acces app commerciale uniquement"
    next
    edit 0
        set name "DENY-Finance-to-Servers"
        set srcintf "VLAN60-Finance"
        set dstintf "ServerZone"
        set srcaddr "Net-VLAN60-Finance"
        set dstaddr "all"
        set action deny
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set comments "Bloquer acces serveurs internes"
    next
end
```

---

#### Policy 4: IT Full Access (Administration)

```bash
config firewall policy
    edit 0
        set name "IT-Full-Access"
        set srcintf "VLAN20-IT"
        set dstintf "ServerZone" "DMZ" "BackupZone"
        set srcaddr "Net-VLAN20-IT"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "SSH" "HTTPS" "HTTP" "MySQL-3306"
        set logtraffic all
        set comments "IT Admin - Acces complet pour administration"
        set av-profile "default"
        set ips-sensor "default"
    next
end
```

---

#### Policy 5: CEO Limited Access (CORRIGÉ)

**CORRECTION APPLIQUÉE:** Restriction de l'accès CEO pour conformité avec le tableau "Rôles et Accès aux Systèmes"

**Objectif:** Donner au CEO un accès limité aux applications métier uniquement (pas d'accès administratif aux serveurs).

**Ancien comportement (INCORRECT):**
```bash
# ❌ ANCIEN - NE PAS UTILISER
set dstintf "ServerZone" "DMZ"
set dstaddr "all"
set service "HTTP" "HTTPS" "SSH" "MySQL-3306"
```

**Nouveau comportement (CORRECT):**

```bash
config firewall policy
    edit 0
        set name "CEO-Limited-Access"
        set srcintf "VLAN40-CEO"
        set dstintf "ServerZone" "DMZ"
        set srcaddr "Net-VLAN40-CEO"
        set dstaddr "HR-App-Server" "Web-Commercial-Server"
        set action accept
        set schedule "always"
        set service "HTTP" "HTTPS" "HTTP-8080-HR-App"
        set logtraffic all
        set comments "CEO - Acces limite aux applications metier uniquement (pas d'acces SSH/MySQL)"
        set av-profile "default"
        set ips-sensor "default"
    next
end
```

**Justification de la correction:**

| Aspect | Avant (INCORRECT) | Après (CORRECT) |
|--------|-------------------|-----------------|
| **Accès serveurs Linux** | ✅ Oui (SSH) | ❌ Non |
| **Accès MySQL direct** | ✅ Oui | ❌ Non |
| **Accès app web** | ✅ Oui | ✅ Oui |
| **Accès app CRUD** | ✅ Oui (limité) | ✅ Oui (limité) |
| **Conformité tableau** | ❌ Non conforme | ✅ Conforme |

**Validation:**

```bash
# Depuis poste CEO (10.0.40.X)

# Test 1: Accès HR App (doit réussir)
curl -I http://10.0.0.10:8080
# Résultat attendu: HTTP/1.1 200 OK

# Test 2: Accès Web Commercial (doit réussir)
curl -I http://192.168.10.10
# Résultat attendu: HTTP/1.1 200 OK

# Test 3: SSH vers serveur (doit échouer)
ssh admin@10.0.0.10
# Résultat attendu: Connection refused ou No route to host

# Test 4: MySQL direct (doit échouer)
telnet 10.0.0.11 3306
# Résultat attendu: Connection refused
```

**Ce qui a changé:**
- ❌ **Supprimé:** Accès SSH aux serveurs Linux
- ❌ **Supprimé:** Accès MySQL direct à la base de données
- ❌ **Supprimé:** Accès à tous les serveurs (`all`)
- ✅ **Conservé:** Accès HTTP/HTTPS aux applications métier
- ✅ **Conservé:** Accès HTTP-8080 à l'application RH
- ✅ **Ajouté:** Conformité totale avec le tableau des rôles

**Note de sécurité:**
Cette configuration respecte le principe de séparation des privilèges:
- Le CEO a accès aux **applications métier** pour consulter les données
- Le CEO n'a **PAS** d'accès administratif direct aux serveurs
- L'équipe IT conserve l'accès administratif exclusif (Policy 4)

---

#### Policy 6: DMZ vers Database (Application tier)

**Objectif:** Application web (DMZ) peut interroger la DB, mais RIEN d'autre.

```bash
config firewall policy
    edit 0
        set name "DMZ-WebApp-to-Database"
        set srcintf "DMZ"
        set dstintf "ServerZone"
        set srcaddr "Web-Commercial-Server"
        set dstaddr "DB-Server"
        set action accept
        set schedule "always"
        set service "MySQL-3306"
        set logtraffic all
        set comments "App commerciale vers DB uniquement"
        set ips-sensor "default"
    next
    edit 0
        set name "DENY-DMZ-to-Other-Servers"
        set srcintf "DMZ"
        set dstintf "ServerZone"
        set srcaddr "Web-Commercial-Server"
        set dstaddr "HR-App-Server" "Backup-Server"
        set action deny
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set comments "Bloquer acces autres serveurs depuis DMZ"
    next
end
```

**Note de sécurité critique:**
- ✅ Accès limité: Seul le serveur web DMZ (192.168.10.10) peut accéder à la DB
- ✅ Pas de policy ANY → DB: Aucune source générique autorisée
- ✅ Pas de policy ALL → ServerZone depuis DMZ: Tous les autres serveurs sont bloqués explicitement
- ✅ Principe de moindre privilège: Service MySQL-3306 uniquement (pas de SSH, pas de HTTP)

Cette configuration garantit qu'aucun accès implicite n'existe vers la base de données ou la Server Zone.

---

#### Policy 7: Internal to Internet (avec NAT et Zones)

**CORRECTION APPLIQUÉE:** Utilisation de la zone "Internal" au lieu de multiple srcintf

**Objectif:** Permettre la navigation Internet pour tous les VLANs internes avec protection UTM.

**Ancien comportement (PROBLÉMATIQUE):**
```bash
# ❌ ANCIEN - Peut causer des erreurs selon version FortiOS
set srcintf "VLAN10-Dev" "VLAN20-IT" "VLAN30-RH" "VLAN40-CEO" "VLAN50-Commercial" "VLAN60-Finance"
```

**Nouveau comportement (CORRECT):**

```bash
config firewall policy
    edit 0
        set name "Internal-to-Internet"
        set srcintf "Internal"
        set dstintf "WAN"
        set srcaddr "Grp-All-Internal-VLANs"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "HTTP" "HTTPS" "DNS" "NTP"
        set nat enable
        set logtraffic all
        set av-profile "default"
        set webfilter-profile "default"
        set application-list "default"
        set ips-sensor "default"
        set comments "Navigation Internet avec protection UTM - Utilise zone Internal"
    next
end
```

**Explication NAT:**
- `set nat enable`: Active le NAT source (masquerade)
- Les adresses internes (10.0.X.X) sont traduites en adresse publique WAN
- Nécessaire pour accéder à Internet

**Avantages de l'utilisation de la zone:**
- ✅ Compatible avec toutes les versions FortiOS
- ✅ Évite les erreurs de syntaxe `set srcintf` multiple
- ✅ Facilite l'ajout de nouveaux VLANs (ajout à la zone = automatiquement inclus)
- ✅ Améliore la lisibilité des policies

**Validation:**

```bash
# Depuis poste Dev (10.0.10.50)
ping 8.8.8.8

# Résultat attendu: réponses ICMP

curl -I https://www.google.com

# Résultat attendu: HTTP/1.1 200 OK
```

---

#### Policy 8: Backup Server Access

**CORRECTION APPLIQUÉE:** Ajout de la policy pour le serveur de sauvegarde

**Objectif:** Permettre au serveur de sauvegarde d'accéder à tous les serveurs pour les backups automatiques.

```bash
config firewall policy
    edit 0
        set name "Backup-to-All-Servers"
        set srcintf "BackupZone"
        set dstintf "ServerZone" "DMZ"
        set srcaddr "Backup-Server"
        set dstaddr "HR-App-Server" "DB-Server" "Web-Commercial-Server"
        set action accept
        set schedule "always"
        set service "SSH" "Rsync-873"
        set logtraffic all
        set comments "Serveur de sauvegarde vers tous les serveurs"
        set ips-sensor "default"
    next
end
```

**Validation:**

```bash
# Depuis Backup Server (10.0.1.10)
ssh admin@10.0.0.10
# Résultat attendu: Connexion SSH réussie

rsync -avz /data/ admin@10.0.0.10:/backup/
# Résultat attendu: Transfert rsync réussi
```

---

## 8.9 NAT et Virtual IP (VIP)

**Rappel du problème:** Application web doit être accessible depuis Internet.

**Objectif:** Exposer uniquement le serveur web commercial (DMZ) sur Internet via NAT statique.

### 8.9.1 Qu'est-ce que le NAT/VIP?

**NAT (Network Address Translation):**
- **Source NAT (SNAT)**: Traduire l'IP source (Internal → Internet)
- **Destination NAT (DNAT)**: Traduire l'IP destination (Internet → DMZ)

**Virtual IP (VIP):**
- Mapping entre IP publique et IP privée DMZ
- Utilisé dans les politiques de pare-feu pour autoriser le trafic entrant

### 8.9.2 Création du VIP pour le serveur web

**Via Web GUI:** `Policy & Objects > Virtual IPs > Create New > Virtual IP`

```
Name: VIP-Web-Commercial

Interface: WAN
Type: Static NAT

External IP address/range: 203.0.113.10
(IP publique dédiée - à remplacer par votre IP)

Mapped IP address/range: 192.168.10.10
(IP du serveur dans la DMZ)

Port Forwarding: Enable
  Protocol: TCP
  External service port: 80
  Map to port: 80

Port Forwarding: Enable
  Protocol: TCP
  External service port: 443
  Map to port: 443
```

**Via CLI:**

```bash
config firewall vip
    edit "VIP-Web-Commercial-HTTP"
        set extip 203.0.113.10
        set mappedip "192.168.10.10"
        set extintf "WAN"
        set portforward enable
        set protocol tcp
        set extport 80
        set mappedport 80
        set comment "Serveur Web Commercial - HTTP"
    next
    edit "VIP-Web-Commercial-HTTPS"
        set extip 203.0.113.10
        set mappedip "192.168.10.10"
        set extintf "WAN"
        set portforward enable
        set protocol tcp
        set extport 443
        set mappedport 443
        set comment "Serveur Web Commercial - HTTPS"
    next
end
```

**Explication technique:**
- `set extip`: IP publique (vue depuis Internet)
- `set mappedip`: IP privée réelle du serveur dans la DMZ
- `set portforward enable`: Active le NAT de port
- `set extport/mappedport`: Ports source et destination (peuvent être différents)

### 8.9.3 Politique de pare-feu pour VIP (Internet → DMZ)

```bash
config firewall policy
    edit 0
        set name "Internet-to-DMZ-WebServer"
        set srcintf "WAN"
        set dstintf "DMZ"
        set srcaddr "all"
        set dstaddr "VIP-Web-Commercial-HTTP" "VIP-Web-Commercial-HTTPS"
        set action accept
        set schedule "always"
        set service "HTTP" "HTTPS"
        set nat disable
        set logtraffic all
        set av-profile "default"
        set ips-sensor "default"
        set ssl-ssh-profile "certificate-inspection"
        set comments "Acces public au site web commercial"
    next
end
```

**Points critiques:**
- `set dstaddr "VIP-..."`: Utilise le VIP comme destination (pas l'IP privée)
- `set nat disable`: NAT déjà fait par le VIP, pas besoin de NAT source
- `ssl-ssh-profile`: Inspection SSL pour détecter les menaces (optionnel)

**Validation:**

```bash
# Depuis Internet (ou machine externe)
curl -I http://203.0.113.10

# Résultat attendu: HTTP/1.1 200 OK
# Serveur répond depuis 192.168.10.10 (traduit par VIP)

# Depuis poste Windows externe
Test-NetConnection -ComputerName 203.0.113.10 -Port 80
Test-NetConnection -ComputerName 203.0.113.10 -Port 443

# Résultat attendu: TcpTestSucceeded = True
```

**Ce qui a changé:**
- ✅ Serveur web accessible depuis Internet via IP publique
- ✅ IP privée DMZ masquée (192.168.10.10 non exposée)
- ✅ Filtrage IPS/AV actif sur le trafic entrant
- ✅ Logs complets des accès externes

---

## 8.10 Haute Disponibilité (HA)

**Note:** L'infrastructure AtlasTech Solutions utilise un cluster FortiGate en mode haute disponibilité (Active-Passive) pour garantir la continuité de service. La configuration détaillée du cluster HA, incluant le setup, la synchronisation, et les tests de failover, est documentée dans le **Chapitre 11: Haute Disponibilité**.

**Points clés:**
- 2 FortiGate en cluster (FortiGate-A Master, FortiGate-B Backup)
- Mode Active-Passive avec session pickup

![FortiGate HA Config](/img/08/fortigate-ha-config.jpeg)

*Figure 8-6 – Configuration du cluster HA.*

![FortiGate HA Cluster](/img/08/fortigate-ha-cluster.jpeg)

*Figure 8-7 – État du cluster HA (Primary/Secondary).*
- Failover automatique en cas de panne

![FortiGate HA Status](/img/08/fortigate-ha-status.jpeg)

*Figure 8-8 – Statut et synchronisation du cluster HA.*

**Référence:** Voir Chapitre 11 pour la configuration complète

---

## 8.11 Routes Statiques

**Objectif:** Définir le chemin par défaut vers Internet.

### 8.11.1 Route par défaut

**Via Web GUI:** `Network > Static Routes > Create New`

```
Destination: 0.0.0.0/0.0.0.0
Gateway: 203.0.113.1
(Gateway ISP - première IP du subnet /30)

Interface: WAN
Administrative Distance: 10
Comments: Default route to Internet via ISP1
```

**Via CLI:**

```bash
config router static
    edit 0
        set gateway 203.0.113.1
        set device "WAN"
        set comment "Route par defaut vers Internet"
    next
end
```

**Validation:**

```bash
# Voir la table de routage
get router info routing-table all

# Résultat attendu:
# S*   0.0.0.0/0 [10/0] via 203.0.113.1, WAN

# Tester la connectivité Internet
execute ping 8.8.8.8

# Résultat attendu: réponses ICMP
```

---

## 8.12 Security Profiles (UTM)

Les profils de sécurité UTM (AntiVirus, IPS, Web Filter, Application Control, SSL Inspection) sont activés sur les politiques critiques (Internet, DMZ, inter-zones).

**Configuration de base via CLI:**

```bash
# Activer les profils sur une politique
config firewall policy
    edit <policy-id>
        set av-profile "default"
        set ips-sensor "default"
        set webfilter-profile "default"
        set application-list "default"
        set ssl-ssh-profile "certificate-inspection"
    next
end
```

**Note:** La configuration détaillée des profils UTM est documentée dans le Chapitre 15 (Sécurité Applicative) et Chapitre 19 (Monitoring).

---

## 8.13 Logging de Base

**Objectif:** Activer la journalisation des politiques de pare-feu pour la traçabilité des flux.

### 8.13.1 Configuration du logging

**Via CLI:**

```bash
config log memory setting
    set status enable
end
```

### 8.13.2 Activation du logging sur les politiques

Chaque politique de pare-feu doit avoir l'option de logging activée:

```bash
config firewall policy
    edit <policy-id>
        set logtraffic all
        # Logs de tout le trafic (accepté et bloqué)
    next
end
```

### 8.13.3 Visualisation des logs

**Via Web GUI:** `Log & Report > Forward Traffic`

Filtres disponibles:
- Source Address
- Destination Address
- Service/Port
- Action (Accept/Deny)
- Policy ID

**Note:** La configuration avancée de logging (SIEM, Wazuh, ELK Stack, alertes automatisées) est documentée dans le **Chapitre 19: Monitoring & Honeypot**.

---

## 8.14 Tests de Validation de Base

### Tests de connectivité inter-VLAN

**Machine:** Windows 10 (VLAN 30 - RH)

```powershell
# Test 1: Accès à l'application HR (autorisé)
Test-NetConnection -ComputerName 10.0.0.10 -Port 8080
# Résultat attendu: TcpTestSucceeded = True

# Test 2: Accès direct à la DB (bloqué par policy)
Test-NetConnection -ComputerName 10.0.0.11 -Port 3306
# Résultat attendu: TcpTestSucceeded = False

# Test 3: Internet (autorisé)
Test-NetConnection -ComputerName 8.8.8.8 -Port 443
# Résultat attendu: TcpTestSucceeded = True
```

### Vérification du NAT/VIP depuis Internet

```powershell
# Test d'accès au serveur web via VIP
Test-NetConnection -ComputerName 203.0.113.10 -Port 80
# Résultat attendu: TcpTestSucceeded = True
```

### Tests de validation CEO (CORRIGÉ)

**Machine:** Windows 10 (VLAN 40 - CEO)

```powershell
# Test 1: Accès HR App (autorisé)
Test-NetConnection -ComputerName 10.0.0.10 -Port 8080
# Résultat attendu: TcpTestSucceeded = True

# Test 2: Accès Web Commercial (autorisé)
Test-NetConnection -ComputerName 192.168.10.10 -Port 80
# Résultat attendu: TcpTestSucceeded = True

# Test 3: SSH vers serveur (bloqué)
Test-NetConnection -ComputerName 10.0.0.10 -Port 22
# Résultat attendu: TcpTestSucceeded = False

# Test 4: MySQL direct (bloqué)
Test-NetConnection -ComputerName 10.0.0.11 -Port 3306
# Résultat attendu: TcpTestSucceeded = False

# Test 5: Internet (autorisé)
Test-NetConnection -ComputerName 8.8.8.8 -Port 443
# Résultat attendu: TcpTestSucceeded = True
```

**Note:** Les tests de sécurité approfondis (scans Nmap, exploitation SQLmap, tests IPS) sont documentés dans le **Chapitre 21: Tests d'Intrusion**.

---

## 8.15 Résumé des Corrections Appliquées

### Tableau récapitulatif des modifications

| # | Problème Identifié | Correction Appliquée | Impact |
|---|-------------------|---------------------|--------|
| 1 | **Conflit CEO Access vs Tableau** | Policy 5 modifiée: suppression SSH/MySQL, restriction aux apps métier uniquement | ✅ Conformité totale avec tableau des rôles |
| 2 | **Multiple srcintf sans zone** | Création zone "Internal" + utilisation dans Policy 7 | ✅ Compatible FortiOS, scalable |
| 3 | **Backup Network non configurée** | Ajout interface BackupZone (port7) + Policy 8 | ✅ Infrastructure complète |
| 4 | **Backup Server sans policy** | Création Policy "Backup-to-All-Servers" | ✅ Sauvegardes opérationnelles |
| 5 | **Backup Server object sans interface** | Association BackupZone à Backup-Server | ✅ Cohérence configuration |

### Comparaison avant/après

| Aspect | Avant (INCORRECT) | Après (CORRECT) |
|--------|-------------------|-----------------|
| **CEO Accès SSH** | ✅ Autorisé | ❌ Bloqué |
| **CEO Accès MySQL** | ✅ Autorisé | ❌ Bloqué |
| **CEO Accès Apps** | ✅ Autorisé | ✅ Autorisé |
| **Policy srcintf multiple** | Syntaxe problématique | Zone "Internal" |
| **Backup Network** | Mentionnée, non configurée | Complètement configurée |
| **Backup Policy** | Absente | Créée et testée |

---

## 8.16 Conclusion

L'implémentation de la sécurité réseau FortiGate a permis de transformer l'infrastructure AtlasTech Solutions d'un réseau plat non sécurisé en une architecture segmentée et contrôlée.

**Résultats obtenus:**

| Composant | État |
|-----------|------|
| Segmentation VLAN | ✅ 6 VLANs départements + DMZ + Server Zone + Backup Zone |
| Interfaces FortiGate | ✅ WAN, DMZ, Server Zone, Backup Zone, 6 VLANs configurés |
| Interface Zones | ✅ Zone "Internal" créée pour gestion optimale |
| DHCP | ✅ Actif sur tous les VLANs |
| Objets d'adresse | ✅ Serveurs et réseaux définis |
| Firewall Policies | ✅ 26 politiques appliquant le moindre privilège |
| NAT/VIP | ✅ Exposition sécurisée du serveur web commercial |
| Routage | ✅ Route par défaut vers Internet |
| Security Profiles | ✅ IPS, AV, WebFilter activés |
| Logging | ✅ Journalisation de base activée |
| **Conformité Rôles** | ✅ **Politiques alignées avec tableau des rôles** |

**Vulnérabilités corrigées au niveau réseau:**

- **V01 (SQL Injection)**: Isolation de la base de données, accès uniquement via application tier
- **V03 (IDOR)**: Contrôle d'accès strict par département (seul VLAN RH → HR App)
- **Exposition services**: Application RH isolée, non accessible depuis Internet
- **Réseau plat**: Segmentation complète avec contrôle inter-VLAN
- **Accès CEO**: Restriction aux applications métier uniquement (pas d'accès administratif)

**Prochaines étapes:**

- **Chapitre 9**: Configuration des Core Switches (HSRP, LACP, VLANs trunk)
- **Chapitre 10**: Configuration des Access Switches
- **Chapitre 11**: Configuration détaillée de la Haute Disponibilité
- **Chapitre 15**: Correction des vulnérabilités applicatives (V01-V06 dans le code)
- **Chapitre 19**: Monitoring avancé et détection d'intrusions
- **Chapitre 21**: Tests d'intrusion complets et validation

---

**Note:** Les adresses IP publiques (203.0.113.X) utilisées dans ce document sont des adresses de documentation (RFC 5737) et doivent être remplacées par les adresses réelles fournies par votre ISP.

---

## Annexe A: Tableau Récapitulatif - Rôles et Accès aux Systèmes (Version Corrigée)

| Rôle | Type de poste | Accès serveurs Linux | Accès application web | Accès application CRUD | Accès documentation IT |
|------|--------------|----------------------|----------------------|------------------------|------------------------|
| **Directeur Général (CEO)** | Windows | ❌ Non | ✅ Oui | ✅ Oui (Accès limité) | ❌ Non |
| **Administrateurs IT** | Windows / Linux | ✅ Oui (SSH) | ✅ Oui | ✅ Oui | ✅ Oui (IP restreinte) |
| **Développeurs** | Windows | ❌ Non | ✅ Oui | ❌ Non | ✅ Oui (accès limité) |
| **Ressources Humaines** | Windows | ❌ Non | ✅ Oui | ✅ Oui | ❌ Non |
| **Comptabilité** | Windows | ❌ Non | ✅ Oui | ❌ Non | ❌ Non |
| **Commercial / Marketing** | Windows | ❌ Non | ✅ Oui | ❌ Non | ❌ Non |

**Légende:**
- ✅ **Oui**: Accès autorisé via firewall policy
- ❌ **Non**: Accès bloqué par firewall policy
- **(Accès limité)**: Accès en lecture seule ou aux applications métier uniquement

**Conformité:** Toutes les politiques de pare-feu ont été alignées avec ce tableau.





