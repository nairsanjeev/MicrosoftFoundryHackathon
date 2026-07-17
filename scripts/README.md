# Lab Environment Setup Scripts

## Overview

These scripts automate the creation of all Azure resources needed for the Microsoft Foundry Pharma Hands-On Lab. Run them **before lab day** as a subscription Owner.

## Prerequisites

- **Azure CLI** installed ([Install guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- **Owner role** on the target Azure subscription
- **Logged in**: `az login`

## Quick Start

### 1. Prepare your users list

Edit `users-sample.csv` (or create your own `users.csv`) with the Entra ID UPNs of lab attendees:

```csv
UserPrincipalName,DisplayName
john.doe@yourcompany.com,John Doe
jane.smith@yourcompany.com,Jane Smith
```

### 2. Run the setup script

```powershell
cd scripts

./setup-lab-environment.ps1 `
  -SubscriptionId "your-subscription-id" `
  -Location "eastus2" `
  -UsersFile "./users-sample.csv"
```

### 3. Optional parameters

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
| **Cognitive Services User** | Foundry resource | Call model endpoints |
| **Storage Blob Data Contributor** | Storage account | Upload/download pharma data |
| **Search Index Data Contributor** | Search service | Query knowledge bases |
| **Search Service Contributor** | Search service | Create knowledge bases |
| **Reader** | Resource group | View resources in portal |
| **Log Analytics Reader** | Application Insights | View traces and monitoring data |

### Explicitly NOT Assigned (restricted)

| Role | Why Restricted |
|------|---------------|
| Cognitive Services Contributor | Cannot create/delete model deployments |
| Owner / Contributor | Cannot modify infrastructure |
| Azure AI Account Owner | Cannot manage Foundry resource settings |

## Cleanup After Lab

To delete all resources after the lab is complete:

```powershell
az group delete --name rg-foundry-lab-shared --yes --no-wait
```

> ⚠️ This permanently deletes all resources including model deployments, search indexes, storage data, and traces.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "SubscriptionNotRegistered" | The script registers providers automatically. If it fails, manually run: `az provider register --namespace Microsoft.CognitiveServices` |
| Model deployment fails | Check quota in the selected region. Try `eastus2`, `westus3`, or `swedencentral` |
| User not found | Ensure the UPN in users.csv matches the Entra ID exactly |
| Storage name conflict | Storage account names are globally unique. Change `-StorageAccountName` parameter |
