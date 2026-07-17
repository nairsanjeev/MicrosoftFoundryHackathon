# ============================================================================
# Microsoft Foundry Lab - Environment Setup Script
# ============================================================================
# This script pre-creates all Azure resources needed for the Microsoft Foundry
# Pharma Hands-On Lab. Run this as a subscription Owner BEFORE the lab day.
#
# Prerequisites:
#   - Azure CLI installed (az --version)
#   - Owner role on the target Azure subscription
#   - Logged in: az login
#
# Usage:
#   ./setup-lab-environment.ps1 -SubscriptionId "<sub-id>" -Location "eastus2" -UsersFile "./users.csv"
#
# The users.csv file should have columns: UserPrincipalName,DisplayName
# Example:
#   UserPrincipalName,DisplayName
#   user1@contoso.com,Lab User 1
#   user2@contoso.com,Lab User 2
# ============================================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus2",

    [Parameter(Mandatory = $true)]
    [string]$UsersFile,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupPrefix = "rg-foundry-lab",

    [Parameter(Mandatory = $false)]
    [string]$FoundryResourceName = "",

    [Parameter(Mandatory = $false)]
    [string]$SearchServiceName = "",

    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName = "",

    [Parameter(Mandatory = $false)]
    [string]$AppInsightsName = "appi-foundry-lab",

    [Parameter(Mandatory = $false)]
    [string]$LogAnalyticsName = "log-foundry-lab"
)

# ============================================================================
# Configuration
# ============================================================================
$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = "./setup-log-$timestamp.txt"

# Generate a short random suffix for globally-unique resource names
$randomSuffix = -join ((97..122) | Get-Random -Count 5 | ForEach-Object { [char]$_ })

# Apply suffix to globally-unique names if not explicitly provided
if (-not $FoundryResourceName) { $FoundryResourceName = "ai-foundry-lab-$randomSuffix" }
if (-not $SearchServiceName) { $SearchServiceName = "search-foundry-lab-$randomSuffix" }
if (-not $StorageAccountName) { $StorageAccountName = "stfoundrylab$randomSuffix" }

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $entry = "[$Level] $(Get-Date -Format 'HH:mm:ss') - $Message"
    Write-Host $entry -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARN") { "Yellow" } else { "Green" })
    Add-Content -Path $logFile -Value $entry
}

function Test-AzCliInstalled {
    try {
        $null = az --version 2>&1
        return $true
    }
    catch {
        return $false
    }
}

# ============================================================================
# Validate Prerequisites
# ============================================================================
Write-Log "============================================"
Write-Log "Microsoft Foundry Lab - Environment Setup"
Write-Log "============================================"
Write-Log "Subscription: $SubscriptionId"
Write-Log "Location: $Location"
Write-Log "Users File: $UsersFile"
Write-Log ""

if (-not (Test-AzCliInstalled)) {
    Write-Log "Azure CLI is not installed. Please install it first: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli" "ERROR"
    exit 1
}

if (-not (Test-Path $UsersFile)) {
    Write-Log "Users file not found: $UsersFile" "ERROR"
    exit 1
}

# Read users
$users = Import-Csv -Path $UsersFile
$userCount = $users.Count
Write-Log "Found $userCount users to onboard"

# Set subscription
Write-Log "Setting subscription..."
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    Write-Log "Failed to set subscription. Are you logged in? Run: az login" "ERROR"
    exit 1
}

# ============================================================================
# Register Required Providers
# ============================================================================
Write-Log "Registering required resource providers..."
$providers = @(
    "Microsoft.CognitiveServices",
    "Microsoft.Search",
    "Microsoft.Storage",
    "Microsoft.OperationalInsights",
    "Microsoft.Insights",
    "Microsoft.ContainerRegistry"
)

foreach ($provider in $providers) {
    Write-Log "  Registering $provider..."
    az provider register --namespace $provider --wait 2>&1 | Out-Null
}

# ============================================================================
# Create Shared Resource Group
# ============================================================================
$sharedRg = "$ResourceGroupPrefix-shared"
Write-Log "Creating shared resource group: $sharedRg"
az group create --name $sharedRg --location $Location --output none

# ============================================================================
# Create Log Analytics Workspace (shared)
# ============================================================================
Write-Log "Creating Log Analytics workspace: $LogAnalyticsName"
az monitor log-analytics workspace create `
    --resource-group $sharedRg `
    --workspace-name $LogAnalyticsName `
    --location $Location `
    --output none

$logAnalyticsId = az monitor log-analytics workspace show `
    --resource-group $sharedRg `
    --workspace-name $LogAnalyticsName `
    --query id -o tsv

# ============================================================================
# Create Application Insights (shared)
# ============================================================================
Write-Log "Creating Application Insights: $AppInsightsName"
az monitor app-insights component create `
    --app $AppInsightsName `
    --location $Location `
    --resource-group $sharedRg `
    --workspace $logAnalyticsId `
    --output none

$appInsightsConnectionString = az monitor app-insights component show `
    --app $AppInsightsName `
    --resource-group $sharedRg `
    --query connectionString -o tsv

$appInsightsId = az monitor app-insights component show `
    --app $AppInsightsName `
    --resource-group $sharedRg `
    --query id -o tsv

Write-Log "Application Insights created: $AppInsightsName"

# ============================================================================
# Create Azure AI Search (shared)
# ============================================================================
Write-Log "Creating Azure AI Search: $SearchServiceName (Standard tier for Foundry IQ)"
$searchCreated = $false
$searchAttempt = 0
$searchNameCandidate = $SearchServiceName

while (-not $searchCreated -and $searchAttempt -lt 3) {
    $searchAttempt++
    try {
        $searchResult = az search service create `
            --name $searchNameCandidate `
            --resource-group $sharedRg `
            --sku standard `
            --location $Location `
            --identity-type SystemAssigned `
            --output none 2>&1
        if ($LASTEXITCODE -eq 0) {
            $searchCreated = $true
            $SearchServiceName = $searchNameCandidate
        } else {
            throw $searchResult
        }
    }
    catch {
        $retrySuffix = -join ((97..122) | Get-Random -Count 4 | ForEach-Object { [char]$_ })
        $searchNameCandidate = "search-lab-$retrySuffix"
        Write-Log "  Name '$SearchServiceName' unavailable, retrying with '$searchNameCandidate' (attempt $searchAttempt/3)..." "WARN"
    }
}

if (-not $searchCreated) {
    Write-Log "Failed to create Azure AI Search after 3 attempts. Try a different -SearchServiceName." "ERROR"
    exit 1
}

$searchId = az search service show `
    --name $SearchServiceName `
    --resource-group $sharedRg `
    --query id -o tsv

Write-Log "Azure AI Search created: $SearchServiceName"

# ============================================================================
# Create Storage Account (shared for pharma data)
# ============================================================================
# Storage account names must be lowercase, 3-24 chars, numbers and lowercase letters only
$storageNameClean = ($StorageAccountName -replace '[^a-z0-9]', '').ToLower()
if ($storageNameClean.Length -gt 24) { $storageNameClean = $storageNameClean.Substring(0, 24) }

Write-Log "Creating Storage Account: $storageNameClean"
$storageCreated = $false
$storageAttempt = 0
$storageCandidate = $storageNameClean

while (-not $storageCreated -and $storageAttempt -lt 3) {
    $storageAttempt++
    try {
        $storageResult = az storage account create `
            --name $storageCandidate `
            --resource-group $sharedRg `
            --location $Location `
            --sku Standard_LRS `
            --kind StorageV2 `
            --output none 2>&1
        if ($LASTEXITCODE -eq 0) {
            $storageCreated = $true
            $storageNameClean = $storageCandidate
        } else {
            throw $storageResult
        }
    }
    catch {
        $retrySuffix = -join ((97..122) | Get-Random -Count 4 | ForEach-Object { [char]$_ })
        $storageCandidate = "stlab$retrySuffix"
        Write-Log "  Name '$storageNameClean' unavailable, retrying with '$storageCandidate' (attempt $storageAttempt/3)..." "WARN"
    }
}

if (-not $storageCreated) {
    Write-Log "Failed to create Storage Account after 3 attempts. Try a different -StorageAccountName." "ERROR"
    exit 1
}

Write-Log "Storage Account created: $storageNameClean"

# Create the pharma data container
Write-Log "Creating blob container: pharma-commercial-data"
az storage container create `
    --name pharma-commercial-data `
    --account-name $storageNameClean `
    --auth-mode login `
    --output none

# Upload sample data files if they exist locally
$dataDir = Join-Path $PSScriptRoot "..\data"
if (Test-Path $dataDir) {
    Write-Log "Uploading sample CSV data files..."
    $csvFiles = Get-ChildItem -Path $dataDir -Filter "*.csv"
    foreach ($csv in $csvFiles) {
        Write-Log "  Uploading $($csv.Name)..."
        az storage blob upload `
            --account-name $storageNameClean `
            --container-name pharma-commercial-data `
            --file $csv.FullName `
            --name $csv.Name `
            --auth-mode login `
            --overwrite `
            --output none
    }
    Write-Log "Sample data uploaded successfully"
}
else {
    Write-Log "Data directory not found at $dataDir - skipping sample data upload" "WARN"
}

$storageId = az storage account show `
    --name $storageNameClean `
    --resource-group $sharedRg `
    --query id -o tsv

# ============================================================================
# Create Microsoft Foundry Resource (AI Services)
# ============================================================================
Write-Log "Creating Microsoft Foundry resource: $FoundryResourceName"
$foundryCreated = $false
$foundryAttempt = 0
$foundryCandidate = $FoundryResourceName

while (-not $foundryCreated -and $foundryAttempt -lt 3) {
    $foundryAttempt++
    try {
        $foundryResult = az cognitiveservices account create `
            --name $foundryCandidate `
            --resource-group $sharedRg `
            --kind AIServices `
            --sku S0 `
            --location $Location `
            --custom-domain $foundryCandidate `
            --output none 2>&1
        if ($LASTEXITCODE -eq 0) {
            $foundryCreated = $true
            $FoundryResourceName = $foundryCandidate
        } else {
            throw $foundryResult
        }
    }
    catch {
        $retrySuffix = -join ((97..122) | Get-Random -Count 4 | ForEach-Object { [char]$_ })
        $foundryCandidate = "ai-foundry-lab-$retrySuffix"
        Write-Log "  Name '$FoundryResourceName' unavailable, retrying with '$foundryCandidate' (attempt $foundryAttempt/3)..." "WARN"
    }
}

if (-not $foundryCreated) {
    Write-Log "Failed to create Foundry resource after 3 attempts. Try a different -FoundryResourceName." "ERROR"
    exit 1
}

$foundryId = az cognitiveservices account show `
    --name $FoundryResourceName `
    --resource-group $sharedRg `
    --query id -o tsv

$foundryEndpoint = az cognitiveservices account show `
    --name $FoundryResourceName `
    --resource-group $sharedRg `
    --query "properties.endpoint" -o tsv

Write-Log "Foundry resource created: $FoundryResourceName ($foundryEndpoint)"

# ============================================================================
# Deploy Models (shared across all projects)
# ============================================================================
Write-Log "Deploying model: gpt-4.1 (Global Standard)"
az cognitiveservices account deployment create `
    --name $FoundryResourceName `
    --resource-group $sharedRg `
    --deployment-name "gpt-4.1" `
    --model-name "gpt-4.1" `
    --model-version "2025-04-14" `
    --model-format OpenAI `
    --sku-capacity 10 `
    --sku-name "GlobalStandard" `
    --output none 2>&1 | Out-Null

Write-Log "Deploying model: gpt-4.1-mini (Global Standard)"
az cognitiveservices account deployment create `
    --name $FoundryResourceName `
    --resource-group $sharedRg `
    --deployment-name "gpt-4.1-mini" `
    --model-name "gpt-4.1-mini" `
    --model-version "2025-04-14" `
    --model-format OpenAI `
    --sku-capacity 10 `
    --sku-name "GlobalStandard" `
    --output none 2>&1 | Out-Null

Write-Log "Models deployed: gpt-4.1, gpt-4.1-mini"

# ============================================================================
# Create Per-User Projects and Assign Roles
# ============================================================================
Write-Log ""
Write-Log "============================================"
Write-Log "Creating per-user projects and assigning roles..."
Write-Log "============================================"

$userOutputs = @()

foreach ($user in $users) {
    $upn = $user.UserPrincipalName
    $displayName = $user.DisplayName
    $userIndex = [array]::IndexOf($users, $user) + 1
    
    Write-Log ""
    Write-Log "--- User $userIndex/$userCount : $displayName ($upn) ---"

    # Get user's Object ID
    $userObjectId = az ad user show --id $upn --query id -o tsv 2>$null
    if (-not $userObjectId) {
        Write-Log "  User not found in Entra ID: $upn - skipping" "WARN"
        continue
    }

    # Create a project name based on user (sanitized)
    $sanitizedName = ($displayName -replace '[^a-zA-Z0-9]', '-').ToLower().TrimEnd('-')
    $projectName = "proj-pharma-$sanitizedName"
    
    # Create Foundry Project for this user
    Write-Log "  Creating Foundry project: $projectName"
    
    # Create project using REST API (az cognitiveservices doesn't directly support projects yet)
    # We use the AI Foundry project creation via az resource
    $projectResourceName = "$FoundryResourceName/projects/$projectName"
    
    az resource create `
        --resource-group $sharedRg `
        --resource-type "Microsoft.CognitiveServices/accounts/projects" `
        --name $projectResourceName `
        --properties "{}" `
        --output none 2>&1 | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Log "  Note: Project creation via CLI may require portal. Will assign roles to main resource." "WARN"
    }

    # ========================================================================
    # Assign RBAC Roles - Users get LIMITED access (no model creation)
    # ========================================================================
    
    # Foundry User (formerly Azure AI User) - Can use agents, models, tools but NOT create deployments
    Write-Log "  Assigning Foundry User role..."
    az role assignment create `
        --assignee $userObjectId `
        --role "Azure AI User" `
        --scope $foundryId `
        --output none 2>&1 | Out-Null

    # Storage Blob Data Contributor - Can upload/download data for Foundry IQ
    Write-Log "  Assigning Storage Blob Data Contributor..."
    az role assignment create `
        --assignee $userObjectId `
        --role "Storage Blob Data Contributor" `
        --scope $storageId `
        --output none 2>&1 | Out-Null

    # Search Index Data Contributor - Can create/query knowledge bases
    Write-Log "  Assigning Search Index Data Contributor..."
    az role assignment create `
        --assignee $userObjectId `
        --role "Search Index Data Contributor" `
        --scope $searchId `
        --output none 2>&1 | Out-Null

    # Search Service Contributor - Can create knowledge bases
    Write-Log "  Assigning Search Service Contributor..."
    az role assignment create `
        --assignee $userObjectId `
        --role "Search Service Contributor" `
        --scope $searchId `
        --output none 2>&1 | Out-Null

    # Cognitive Services User - Can call model endpoints
    Write-Log "  Assigning Cognitive Services User..."
    az role assignment create `
        --assignee $userObjectId `
        --role "Cognitive Services User" `
        --scope $foundryId `
        --output none 2>&1 | Out-Null

    # Reader on resource group - Can see resources but not modify infrastructure
    Write-Log "  Assigning Reader on resource group..."
    az role assignment create `
        --assignee $userObjectId `
        --role "Reader" `
        --scope "/subscriptions/$SubscriptionId/resourceGroups/$sharedRg" `
        --output none 2>&1 | Out-Null

    # Log Analytics Reader - Can view traces
    Write-Log "  Assigning Log Analytics Reader..."
    az role assignment create `
        --assignee $userObjectId `
        --role "Log Analytics Reader" `
        --scope $appInsightsId `
        --output none 2>&1 | Out-Null

    # Collect output for user info sheet
    $userOutputs += [PSCustomObject]@{
        DisplayName       = $displayName
        UserPrincipalName = $upn
        ProjectName       = $projectName
        ProjectEndpoint   = "https://$FoundryResourceName.ai.azure.com/api/projects/$projectName"
        PortalURL         = "https://ai.azure.com"
        ModelDeployments  = "gpt-4.1, gpt-4.1-mini"
        StorageAccount    = $storageNameClean
        StorageContainer  = "pharma-commercial-data"
        SearchService     = $SearchServiceName
    }

    Write-Log "  ✅ User $displayName onboarded successfully"
}

# ============================================================================
# Grant Search Service access to Foundry resource (for Foundry IQ)
# ============================================================================
Write-Log ""
Write-Log "Configuring service-to-service permissions..."

# Get Search service managed identity
$searchIdentity = az search service show `
    --name $SearchServiceName `
    --resource-group $sharedRg `
    --query "identity.principalId" -o tsv

if ($searchIdentity) {
    Write-Log "  Assigning Cognitive Services User to Search managed identity..."
    az role assignment create `
        --assignee $searchIdentity `
        --role "Cognitive Services User" `
        --scope $foundryId `
        --output none 2>&1 | Out-Null
}

# ============================================================================
# Output Summary
# ============================================================================
Write-Log ""
Write-Log "============================================"
Write-Log "SETUP COMPLETE"
Write-Log "============================================"
Write-Log ""
Write-Log "Shared Resources:"
Write-Log "  Resource Group:      $sharedRg"
Write-Log "  Foundry Resource:    $FoundryResourceName"
Write-Log "  Foundry Endpoint:    $foundryEndpoint"
Write-Log "  Model Deployments:   gpt-4.1, gpt-4.1-mini"
Write-Log "  AI Search:           $SearchServiceName"
Write-Log "  Storage Account:     $storageNameClean"
Write-Log "  Storage Container:   pharma-commercial-data"
Write-Log "  App Insights:        $AppInsightsName"
Write-Log "  Log Analytics:       $LogAnalyticsName"
Write-Log ""
Write-Log "Users Onboarded: $($userOutputs.Count) / $userCount"
Write-Log ""

# Export user info to CSV for distribution
$outputCsv = "./lab-user-assignments-$timestamp.csv"
$userOutputs | Export-Csv -Path $outputCsv -NoTypeInformation
Write-Log "User assignments exported to: $outputCsv"
Write-Log ""
Write-Log "ROLES ASSIGNED PER USER:"
Write-Log "  ✅ Foundry User (Azure AI User) - Use agents, tools, knowledge"
Write-Log "  ✅ Cognitive Services User - Call model endpoints"
Write-Log "  ✅ Storage Blob Data Contributor - Upload/download data"
Write-Log "  ✅ Search Index Data Contributor - Query knowledge bases"
Write-Log "  ✅ Search Service Contributor - Create knowledge bases"
Write-Log "  ✅ Reader (Resource Group) - View resources"
Write-Log "  ✅ Log Analytics Reader - View traces and monitoring"
Write-Log ""
Write-Log "ROLES NOT ASSIGNED (restricted):"
Write-Log "  ❌ Cognitive Services Contributor - Cannot create/delete model deployments"
Write-Log "  ❌ Owner/Contributor - Cannot modify infrastructure"
Write-Log "  ❌ Azure AI Account Owner - Cannot manage Foundry resource"
Write-Log ""
Write-Log "Distribute the file '$outputCsv' to lab attendees with their connection info."
Write-Log "Full log saved to: $logFile"
