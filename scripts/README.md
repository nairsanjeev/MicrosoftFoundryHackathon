# Lab Environment Setup Scripts

## Overview

These scripts automate the creation of all Azure resources needed for the Microsoft Foundry Pharma Hands-On Lab. Run them **before lab day** as a subscription Owner.

## Prerequisites

- **Azure CLI** installed ([Install guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- **Owner role** on the target Azure subscription
- **PowerShell** 5.1 (included with Windows) or PowerShell 7 (`pwsh`)
- **Logged in** to Azure CLI: `az login`

> Run the commands below from **PowerShell**, not by double-clicking the `.ps1` file in File Explorer. If Windows opens the script in Notepad, the file association is being used instead of PowerShell. Use the explicit `powershell -File` or `pwsh -File` command shown below.

## Quick Start

### 1. Prepare your users list

Edit `users-sample.csv` (or create your own `users.csv`) with the Entra ID UPNs of lab attendees:

```csv
UserPrincipalName,DisplayName
john.doe@yourcompany.com,John Doe
jane.smith@yourcompany.com,Jane Smith
```

### 2. Open PowerShell and go to the scripts folder

Open **Windows PowerShell** or **PowerShell** from the Start menu. Then change to the folder that contains the script. For this repository:

```powershell
cd C:\MicrosoftFOundryHackathon\scripts
```

Confirm that the script and CSV are in the current folder:

```powershell
Get-ChildItem .\setup-lab-environment.ps1, .\users-sample.csv
```

### 3. Sign in and select the subscription

Sign in to Azure CLI and verify the subscription ID before starting resource creation:

```powershell
az login
az account list --output table
az account set --subscription "your-subscription-id"
az account show --output table
```

Replace `your-subscription-id` with the actual subscription ID. The signed-in account must have the **Owner** role on that subscription because the script creates resources and assigns roles to lab users.

### 4. Run the setup script

Use one of these explicit PowerShell commands. The `-File` form prevents Windows from opening the `.ps1` file in Notepad.

**Windows PowerShell 5.1:**

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\setup-lab-environment.ps1 `
  -SubscriptionId "your-subscription-id" `
  -Location "eastus2" `
  -UsersFile "./users-sample.csv"
```

**PowerShell 7:**

```powershell
pwsh.exe -File .\setup-lab-environment.ps1 `
  -SubscriptionId "your-subscription-id" `
  -Location "eastus2" `
  -UsersFile ".\users-sample.csv"
```

You can also run the script directly after changing the execution policy for the current PowerShell process:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\setup-lab-environment.ps1 `
  -SubscriptionId "your-subscription-id" `
  -Location "eastus2" `
  -UsersFile ".\users-sample.csv"
```

The backtick (`` ` ``) at the end of each continued line is a PowerShell line-continuation character. Make sure there are no spaces after it. Alternatively, put all parameters on one line:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\setup-lab-environment.ps1 -SubscriptionId "your-subscription-id" -Location "eastus2" -UsersFile ".\users-sample.csv"
```

### 5. Optional parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-SubscriptionId` | *(required)* | Azure subscription ID |
| `-Location` | `eastus2` | Azure region (must support Foundry + GPT-4.1) |
| `-UsersFile` | *(required)* | Path to CSV with user list |
| `-ResourceGroupPrefix` | `rg-foundry-lab` | Prefix for resource groups |
| `-FoundryResourceName` | `ai-foundry-lab` | Name for the Foundry (AI Services) resource |
| `-SearchServiceName` | `search-foundry-lab` | Name for Azure AI Search |
| `-StorageAccountName` | `stfoundrylab` | Name for Storage Account |
| `-AppInsightsName` | `appi-foundry-lab` | Name for Application Insights |

### 4. Distribute credentials

After the script completes, it generates a `lab-user-assignments-<timestamp>.csv` file containing each user's:
- Project name and endpoint
- Portal URL
- Model deployment names
- Storage and search service details

Share this file with attendees before the lab.

## What Gets Created

### Shared Resources (one set for all users)

| Resource | Purpose |
|----------|---------|
| Resource Group | Contains all lab resources |
| Microsoft Foundry Resource (AI Services) | Hosts models and agent service |
| Model: `gpt-4.1` (Global Standard) | Primary model for labs |
| Model: `gpt-4.1-mini` (Global Standard) | Secondary model for speed |
| Azure AI Search (Standard) | Foundry IQ knowledge bases |
| Storage Account + `pharma-commercial-data` container | Sample data for Lab 3 |
| Application Insights + Log Analytics | Tracing and monitoring for Lab 6 |

### Per-User Configuration

| What | Details |
|------|---------|
| Foundry Project | `proj-pharma-<username>` |
| RBAC Roles | See below |

## RBAC Roles Assigned

Users get enough access to complete all labs but **cannot** create/delete model deployments or modify infrastructure:

| Role | Scope | Purpose |
|------|-------|---------|
| **Foundry User** (Azure AI User) | Foundry resource | Create agents, use tools, manage knowledge |
| **Cognitive Services Contributor** | Foundry resource | Create/access Foundry projects and manage deployments |
| **Cognitive Services User** | Foundry resource | Call model endpoints |
| **Storage Blob Data Contributor** | Storage account | Upload/download pharma data |
| **Search Index Data Contributor** | Search service | Query knowledge bases |
| **Search Service Contributor** | Search service | Create knowledge bases |
| **Reader** | Resource group | View resources in portal |
| **Log Analytics Reader** | Application Insights | View traces and monitoring data |

### Explicitly NOT Assigned (restricted)

| Role | Why Restricted |
|------|---------------|
| Owner / Contributor | Cannot modify infrastructure |
| Azure AI Account Owner | Cannot manage Foundry resource settings |

## Cleanup After Lab

To delete all resources after the lab is complete:

```powershell
az group delete --name rg-foundry-lab-shared --yes --no-wait
```

> ⚠️ This permanently deletes all resources including model deployments, search indexes, storage data, and traces.

---

## MCP Infrastructure Setup (Lab 4)

A separate script provisions the MCP (Model Context Protocol) infrastructure needed for Lab 4. Run this **after** the main setup script.

### What it creates

| Resource | Purpose |
|----------|---------|
| Azure Function App | Hosts 3 pharma MCP tools (drug interactions, pipeline status, revenue forecast) |
| Azure API Management (Consumption) | MCP gateway with auth, rate limiting, and logging |
| Azure API Center | API governance catalog for MCP tool discoverability |

### Run the MCP setup

```powershell
.\setup-mcp-infrastructure.ps1 `
  -SubscriptionId "your-subscription-id" `
  -ResourceGroup "rg-foundry-lab-shared" `
  -Location "eastus2" `
  -AdminEmail "your-email@company.com" `
  -UsersFile ".\users-sample.csv"
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-SubscriptionId` | *(required)* | Azure subscription ID |
| `-ResourceGroup` | `rg-foundry-lab-shared` | Existing resource group from main setup |
| `-Location` | `eastus2` | Azure region |
| `-AdminEmail` | `admin@contoso.com` | APIM publisher email |
| `-FunctionAppName` | auto-generated | Name for Function App |
| `-ApimName` | auto-generated | Name for API Management instance |
| `-ApiCenterName` | `apic-foundry-lab` | Name for API Center |
| `-UsersFile` | *(optional)* | Path to users CSV (generates per-user MCP info) |

### Output

The script generates `mcp-endpoint-info-<timestamp>.txt` containing:
- MCP Server URL (APIM gateway endpoint)
- APIM Subscription Key
- Agent configuration values to copy into the Foundry portal

Distribute this to lab attendees for Lab 4.

### Timing

- **Function App:** ~2 minutes
- **APIM (Consumption):** ~10-30 minutes (can take longer on first provision)
- **API Center:** ~2 minutes
- **Total:** ~15-35 minutes

> **💡 Tip:** APIM Consumption tier may take up to 30 minutes to provision. Start this script during a lab break so it's ready before Lab 4 begins.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| The `.ps1` file opens in Notepad | Open PowerShell, run `cd C:\MicrosoftFOundryHackathon\scripts`, and use `powershell.exe -ExecutionPolicy Bypass -File .\setup-lab-environment.ps1 ...`. Do not double-click the file or run it from a file-association prompt. |
| `running scripts is disabled on this system` | Use `powershell.exe -ExecutionPolicy Bypass -File .\setup-lab-environment.ps1 ...`, or run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` before using `.\setup-lab-environment.ps1`. |
| `az` is not recognized | Install Azure CLI, restart PowerShell, and verify with `az --version`. |
| `az account set` fails | Run `az login`, check the subscription with `az account list --output table`, and confirm that the subscription ID is correct. |
| `Users file not found` | Run the command from the `scripts` folder or provide an absolute path, such as `-UsersFile "C:\MicrosoftFOundryHackathon\scripts\users-sample.csv"`. |
| "SubscriptionNotRegistered" | The script registers providers automatically. If it fails, manually run: `az provider register --namespace Microsoft.CognitiveServices` |
| Model deployment fails | Check quota in the selected region. Try `eastus2`, `westus3`, or `swedencentral` |
| User not found | Ensure the UPN in users.csv matches the Entra ID exactly |
| Storage name conflict | Storage account names are globally unique. Change `-StorageAccountName` parameter |
