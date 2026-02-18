# === CONFIG ===
$File = "docs/atlatech_docs/08-securite-reseau-fortigate.md"

# === FUNCTION ===
function Insert-After {
    param (
        [string]$SearchText,
        [string]$InsertText
    )

    $content = Get-Content $File -Raw

    if ($content -match [regex]::Escape($SearchText)) {
        $content = $content -replace ([regex]::Escape($SearchText)),
            "$SearchText`r`n`r`n$InsertText"
        Set-Content $File $content
        Write-Host "Inserted after: $SearchText"
    }
    else {
        Write-Host "Text not found: $SearchText"
    }
}

# === INSERTIONS ===

Insert-After "8.1.1 Schéma de l'infrastructure sécurisée" @"
![Schéma Architecture](/img/08/schema-optimiser.png)

*Figure 8-1 – Architecture réseau sécurisée cible.*
"@

Insert-After "Routage inter-VLAN contrôlé par FortiGate" @"
![FortiGate VLAN Dev](/img/08/fortigate-vlan-dev.png)

*Figure 8-2 – Configuration VLAN 10 (Développement).*

![FortiGate VLAN IT](/img/08/fortigate-vlan-it.png)

*Figure 8-3 – Configuration VLAN 20 (IT).*
"@

Insert-After "Backup Zone" @"
![FortiGate Interfaces](/img/08/fortigate-interface.png)

*Figure 8-4 – Vue globale des interfaces FortiGate configurées.*
"@

Insert-After "Les politiques ont été réorganisées manuellement" @"
![FortiGate Policy](/img/08/fortigate-policy.png)

*Figure 8-5 – Politiques de pare-feu appliquées (ordre logique).*
"@

Insert-After "Mode Active-Passive avec session pickup" @"
![FortiGate HA Config](/img/08/fortigate-ha-config.png)

*Figure 8-6 – Configuration du cluster HA.*

![FortiGate HA Cluster](/img/08/fortigate-ha-cluster.png)

*Figure 8-7 – État du cluster HA (Primary/Secondary).*
"@

Insert-After "Failover automatique en cas de panne" @"
![FortiGate HA Status](/img/08/fortigate-ha-status.png)

*Figure 8-8 – Statut et synchronisation du cluster HA.*
"@

Write-Host "Insertion completed."
