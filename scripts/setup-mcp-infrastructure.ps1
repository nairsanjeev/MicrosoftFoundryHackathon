# ============================================================================
# Microsoft Foundry Lab - MCP Infrastructure Setup Script
# ============================================================================
# This script provisions the MCP (Model Context Protocol) infrastructure for
# Lab 4: Tool Calling. It creates:
#   1. Azure Function App with pharma tool functions
#   2. Azure API Management (APIM) instance exposing the function as MCP endpoint
#   3. Azure API Center for API governance and discoverability
#
# Run this AFTER the main setup-lab-environment.ps1 script.
#
# Prerequisites:
#   - Azure CLI installed and logged in
#   - Main lab setup already completed (resource group exists)
#   - Owner/Contributor on the resource group
#
# Usage:
#   ./setup-mcp-infrastructure.ps1 -SubscriptionId "<sub-id>" -ResourceGroup "rg-foundry-lab-shared"
#
# ============================================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = "rg-foundry-lab-shared",

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus2",

    [Parameter(Mandatory = $false)]
    [string]$FunctionAppName = "",

    [Parameter(Mandatory = $false)]
    [string]$ApimName = "",

    [Parameter(Mandatory = $false)]
    [string]$ApiCenterName = "",

    [Parameter(Mandatory = $false)]
    [string]$AdminEmail = "admin@contoso.com",

    [Parameter(Mandatory = $false)]
    [string]$UsersFile = ""
)

# ============================================================================
# Configuration
# ============================================================================
$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = "./setup-mcp-log-$timestamp.txt"

# Generate short random suffix for globally-unique names (used only if no existing resources found)
$randomSuffix = -join ((97..122) | Get-Random -Count 5 | ForEach-Object { [char]$_ })

# Name defaults are applied AFTER resource discovery (see below)
if (-not $ApiCenterName) { $ApiCenterName = "apic-foundry-lab" }

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $entry = "[$Level] $(Get-Date -Format 'HH:mm:ss') - $Message"
    Write-Host $entry -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARN") { "Yellow" } else { "Green" })
    Add-Content -Path $logFile -Value $entry
}

Write-Log "============================================"
Write-Log "MCP Infrastructure Setup"
Write-Log "============================================"
Write-Log "Subscription: $SubscriptionId"
Write-Log "Resource Group: $ResourceGroup"
Write-Log "Location: $Location"
Write-Log ""

# Set subscription
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    Write-Log "Failed to set subscription. Run: az login" "ERROR"
    exit 1
}

# Verify resource group exists
$rgExists = az group exists --name $ResourceGroup -o tsv
if ($rgExists -ne "true") {
    Write-Log "Resource group '$ResourceGroup' not found. Run setup-lab-environment.ps1 first." "ERROR"
    exit 1
}

# ============================================================================
# Discover existing MCP resources (for idempotent re-runs)
# ============================================================================
# Look for existing Function App matching our naming pattern in the RG
if (-not $FunctionAppName) {
    $allFuncApps = @(az functionapp list --resource-group $ResourceGroup --query "[].name" -o tsv 2>$null)
    $existingFuncApp = $allFuncApps | Where-Object { $_ -like "func-pharma-mcp*" } | Select-Object -First 1
    if ($existingFuncApp) {
        $FunctionAppName = $existingFuncApp
        Write-Log "Discovered existing Function App: $FunctionAppName"
    } else {
        $FunctionAppName = "func-pharma-mcp-$randomSuffix"
    }
}

# Look for existing APIM instance in the RG
if (-not $ApimName) {
    $existingApimInstance = az apim list --resource-group $ResourceGroup --query "[0].name" -o tsv 2>$null
    if ($existingApimInstance) {
        $ApimName = $existingApimInstance
        Write-Log "Discovered existing APIM: $ApimName"
    } else {
        $ApimName = "apim-foundry-lab-$randomSuffix"
    }
}

# Look for existing function storage account (stmcpfunc*)
$allStorageAccounts = @(az storage account list --resource-group $ResourceGroup --query "[].name" -o tsv 2>$null)
$existingFuncStorageAccount = $allStorageAccounts | Where-Object { $_ -like "stmcpfunc*" } | Select-Object -First 1
if ($existingFuncStorageAccount) {
    $funcStorageName = $existingFuncStorageAccount
    Write-Log "Discovered existing function storage: $funcStorageName"
} else {
    $funcStorageName = "stmcpfunc$randomSuffix"
}

# Ensure function storage has public network access (Consumption plan requirement)
# Subscription policies may have restricted network access on the storage account
Write-Log "Ensuring function storage allows public network access..."
az storage account update `
    --name $funcStorageName `
    --resource-group $ResourceGroup `
    --public-network-access Enabled `
    --default-action Allow `
    --output none 2>$null

# Create dedicated storage account for the Function App if not found
# (The shared lab storage may have network restrictions incompatible with Consumption plan)
$existingFuncStorage = az storage account show --name $funcStorageName --resource-group $ResourceGroup --query name -o tsv 2>$null
if ($existingFuncStorage) {
    Write-Log "Function storage account already exists: $funcStorageName (skipping)"
} else {
    Write-Log "Creating dedicated storage account for Function App: $funcStorageName"
    az storage account create `
        --name $funcStorageName `
        --resource-group $ResourceGroup `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --allow-blob-public-access false `
        --public-network-access Enabled `
        --default-action Allow `
        --output none 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Log "Failed to create function storage account" "ERROR"
        exit 1
    }
}
Write-Log "Function storage account ready: $funcStorageName"

# ============================================================================
# Step 1: Create Azure Function App with Pharma MCP Tools
# ============================================================================
Write-Log ""
Write-Log "============================================"
Write-Log "Step 1: Azure Function App (MCP Backend)"
Write-Log "============================================"

$existingFunc = az functionapp show --name $FunctionAppName --resource-group $ResourceGroup --query name -o tsv 2>$null
if ($existingFunc) {
    Write-Log "Function App already exists: $FunctionAppName (skipping creation)"
    $skipDeploy = $true
} else {
    $skipDeploy = $false
    Write-Log "Creating Function App: $FunctionAppName"
    az functionapp create `
        --name $FunctionAppName `
        --resource-group $ResourceGroup `
        --storage-account $funcStorageName `
        --runtime python `
        --runtime-version 3.11 `
        --functions-version 4 `
        --os-type Linux `
        --consumption-plan-location $Location `
        --output none 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Log "Consumption plan failed (likely storage network restrictions). Trying Flex Consumption..." "WARN"
        az functionapp create `
            --name $FunctionAppName `
            --resource-group $ResourceGroup `
            --storage-account $funcStorageName `
            --runtime python `
            --runtime-version 3.11 `
            --functions-version 4 `
            --os-type Linux `
            --flexconsumption-location $Location `
            --output none 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to create Function App (both Consumption and Flex plans failed)" "ERROR"
            exit 1
        }
    }
    Write-Log "Function App created: $FunctionAppName"

    # Enable system-assigned managed identity
    az functionapp identity assign `
        --name $FunctionAppName `
        --resource-group $ResourceGroup `
        --output none 2>$null
}

$funcAppUrl = az functionapp show `
    --name $FunctionAppName `
    --resource-group $ResourceGroup `
    --query "defaultHostName" -o tsv
Write-Log "Function App URL: https://$funcAppUrl"

# Deploy the MCP function code (skip if already deployed on re-run)
if ($skipDeploy) {
    Write-Log "Function App already deployed - skipping code deployment"
} else {
    Write-Log "Deploying pharma MCP tools to Function App..."

$funcCodeDir = Join-Path $PSScriptRoot "mcp-function-app"
if (-not (Test-Path $funcCodeDir)) {
    New-Item -ItemType Directory -Path $funcCodeDir -Force | Out-Null
}

# Create the function code files
$hostJson = @'
{
  "version": "2.0",
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true
      }
    }
  },
  "extensions": {
    "http": {
      "routePrefix": ""
    }
  }
}
'@

$requirementsTxt = @'
azure-functions
'@

# Main MCP handler - implements MCP protocol over HTTP (Streamable HTTP transport)
$mcpHandlerCode = @'
import json
import logging
import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

# ============================================================================
# Pharma Tool Implementations
# ============================================================================

DRUG_INTERACTIONS = {
    ("Zelvorix", "Revumab"): {
        "severity": "Low",
        "description": "No clinically significant interaction. May use concurrently with standard monitoring.",
        "recommendation": "Monitor liver function tests quarterly."
    },
    ("Zelvorix", "Warfarin"): {
        "severity": "High",
        "description": "Zelvorix may increase anticoagulant effect. Risk of bleeding events.",
        "recommendation": "Reduce warfarin dose by 25%. Monitor INR weekly for first month."
    },
    ("Revumab", "Methotrexate"): {
        "severity": "Moderate",
        "description": "Combined immunosuppression may increase infection risk.",
        "recommendation": "Monitor for signs of infection. Consider prophylactic antibiotics."
    },
    ("Zelvorix", "Methotrexate"): {
        "severity": "Low",
        "description": "Minimal interaction expected based on differing metabolic pathways.",
        "recommendation": "Standard monitoring. No dose adjustment required."
    },
}

PIPELINE_DATA = {
    "ZV-4521": {"phase": "Phase 3", "therapeutic_area": "Oncology", "indication": "Non-Small Cell Lung Cancer", "expected_approval": "Q2 2027", "revenue_forecast_m": 2400},
    "ZV-8832": {"phase": "Phase 2", "therapeutic_area": "Immunology", "indication": "Rheumatoid Arthritis", "expected_approval": "Q4 2028", "revenue_forecast_m": 1800},
    "ZV-1104": {"phase": "Phase 3", "therapeutic_area": "Neurology", "indication": "Alzheimer's Disease", "expected_approval": "Q1 2027", "revenue_forecast_m": 3200},
    "ZV-6677": {"phase": "Phase 2", "therapeutic_area": "Cardiovascular", "indication": "Heart Failure", "expected_approval": "Q3 2028", "revenue_forecast_m": 950},
    "ZV-3390": {"phase": "Phase 1", "therapeutic_area": "Oncology", "indication": "Pancreatic Cancer", "expected_approval": "Q2 2030", "revenue_forecast_m": 1500},
    "ZV-9901": {"phase": "Phase 3", "therapeutic_area": "Rare Disease", "indication": "Spinal Muscular Atrophy", "expected_approval": "Q4 2026", "revenue_forecast_m": 800},
    "ZV-2245": {"phase": "Phase 3", "therapeutic_area": "Immunology", "indication": "Psoriatic Arthritis", "expected_approval": "Q1 2027", "revenue_forecast_m": 1200},
    "ZV-5578": {"phase": "Phase 2", "therapeutic_area": "Infectious Disease", "indication": "RSV Prophylaxis", "expected_approval": "Q2 2028", "revenue_forecast_m": 2100},
    "Zelvorix": {"phase": "Approved", "therapeutic_area": "Oncology", "indication": "Breast Cancer", "expected_approval": "Approved Q1 2025", "revenue_forecast_m": 4200},
    "Revumab": {"phase": "Approved", "therapeutic_area": "Immunology", "indication": "Ulcerative Colitis", "expected_approval": "Approved Q3 2024", "revenue_forecast_m": 2800},
}

REVENUE_BASELINE = {
    "Oncology": 1850,
    "Immunology": 1200,
    "Neurology": 780,
    "Cardiovascular": 650,
    "Rare Disease": 320,
    "Infectious Disease": 480,
}


def check_drug_interaction(drug_a: str, drug_b: str) -> dict:
    key = (drug_a, drug_b) if (drug_a, drug_b) in DRUG_INTERACTIONS else (drug_b, drug_a)
    if key in DRUG_INTERACTIONS:
        result = DRUG_INTERACTIONS[key].copy()
        result["drug_a"] = drug_a
        result["drug_b"] = drug_b
        result["interaction_found"] = True
    else:
        result = {
            "drug_a": drug_a,
            "drug_b": drug_b,
            "interaction_found": False,
            "severity": "None",
            "description": f"No known interaction between {drug_a} and {drug_b} in our database.",
            "recommendation": "Standard monitoring applies. Check external databases for comprehensive review."
        }
    return result


def get_pipeline_status(drug_name: str) -> dict:
    if drug_name in PIPELINE_DATA:
        result = PIPELINE_DATA[drug_name].copy()
        result["drug_name"] = drug_name
        result["found"] = True
    else:
        result = {
            "drug_name": drug_name,
            "found": False,
            "message": f"Drug '{drug_name}' not found in pipeline database. Available: {', '.join(PIPELINE_DATA.keys())}"
        }
    return result


def calculate_revenue_forecast(therapeutic_area: str, quarters_ahead: int = 4) -> dict:
    area = therapeutic_area.strip().title()
    if area not in REVENUE_BASELINE:
        return {
            "therapeutic_area": therapeutic_area,
            "error": f"Unknown therapeutic area. Available: {', '.join(REVENUE_BASELINE.keys())}"
        }

    baseline = REVENUE_BASELINE[area]
    growth_rates = {"Oncology": 0.08, "Immunology": 0.06, "Neurology": 0.12, "Cardiovascular": 0.04, "Rare Disease": 0.15, "Infectious Disease": 0.07}
    growth = growth_rates.get(area, 0.05)

    forecasts = []
    current = baseline
    for q in range(1, min(quarters_ahead, 8) + 1):
        current = round(current * (1 + growth), 1)
        forecasts.append({"quarter": f"Q+{q}", "revenue_m": current})

    return {
        "therapeutic_area": area,
        "baseline_quarterly_revenue_m": baseline,
        "growth_rate_per_quarter": growth,
        "quarters_forecast": quarters_ahead,
        "forecasts": forecasts,
        "total_forecast_m": round(sum(f["revenue_m"] for f in forecasts), 1)
    }


# ============================================================================
# MCP Protocol Implementation (Streamable HTTP)
# ============================================================================

MCP_TOOLS = [
    {
        "name": "check_drug_interaction",
        "description": "Checks for known drug-drug interactions between two medications and returns severity level, clinical description, and dosing recommendations.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "drug_a": {"type": "string", "description": "First drug name (e.g., Zelvorix, Revumab, Warfarin)"},
                "drug_b": {"type": "string", "description": "Second drug name to check interaction against"}
            },
            "required": ["drug_a", "drug_b"]
        }
    },
    {
        "name": "get_pipeline_status",
        "description": "Returns the current development pipeline status for a drug including phase, indication, expected approval date, and revenue forecast.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "drug_name": {"type": "string", "description": "Drug name or code (e.g., ZV-4521, Zelvorix, Revumab)"}
            },
            "required": ["drug_name"]
        }
    },
    {
        "name": "calculate_revenue_forecast",
        "description": "Calculates projected quarterly revenue for a therapeutic area based on current baseline and growth trajectory.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "therapeutic_area": {"type": "string", "description": "Therapeutic area (Oncology, Immunology, Neurology, Cardiovascular, Rare Disease, Infectious Disease)"},
                "quarters_ahead": {"type": "integer", "description": "Number of quarters to forecast (1-8)", "default": 4}
            },
            "required": ["therapeutic_area"]
        }
    }
]


def handle_mcp_request(body: dict) -> dict:
    """Handle JSON-RPC 2.0 MCP requests."""
    method = body.get("method", "")
    req_id = body.get("id")
    params = body.get("params", {})

    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": "2025-03-26",
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {"name": "pharma-mcp-tools", "version": "1.0.0"}
            }
        }
    elif method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {"tools": MCP_TOOLS}
        }
    elif method == "tools/call":
        tool_name = params.get("name", "")
        arguments = params.get("arguments", {})
        try:
            if tool_name == "check_drug_interaction":
                result = check_drug_interaction(arguments.get("drug_a", ""), arguments.get("drug_b", ""))
            elif tool_name == "get_pipeline_status":
                result = get_pipeline_status(arguments.get("drug_name", ""))
            elif tool_name == "calculate_revenue_forecast":
                result = calculate_revenue_forecast(
                    arguments.get("therapeutic_area", ""),
                    arguments.get("quarters_ahead", 4)
                )
            else:
                return {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "error": {"code": -32601, "message": f"Unknown tool: {tool_name}"}
                }
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "content": [{"type": "text", "text": json.dumps(result, indent=2)}],
                    "isError": False
                }
            }
        except Exception as e:
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "content": [{"type": "text", "text": json.dumps({"error": str(e)})}],
                    "isError": True
                }
            }
    else:
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "error": {"code": -32601, "message": f"Method not found: {method}"}
        }


@app.route(route="mcp", methods=["POST"])
def mcp_endpoint(req: func.HttpRequest) -> func.HttpResponse:
    """MCP Streamable HTTP endpoint - handles JSON-RPC 2.0 requests."""
    try:
        body = req.get_json()
        logging.info(f"MCP request: method={body.get('method')}")
        response = handle_mcp_request(body)
        return func.HttpResponse(
            json.dumps(response),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logging.error(f"MCP error: {e}")
        error_response = {
            "jsonrpc": "2.0",
            "id": None,
            "error": {"code": -32700, "message": f"Parse error: {str(e)}"}
        }
        return func.HttpResponse(
            json.dumps(error_response),
            mimetype="application/json",
            status_code=400
        )


@app.route(route="mcp", methods=["GET"])
def mcp_health(req: func.HttpRequest) -> func.HttpResponse:
    """Health check endpoint."""
    return func.HttpResponse(
        json.dumps({"status": "healthy", "server": "pharma-mcp-tools", "version": "1.0.0", "tools": len(MCP_TOOLS)}),
        mimetype="application/json"
    )
'@

# Write function app files
Set-Content -Path (Join-Path $funcCodeDir "host.json") -Value $hostJson -Encoding UTF8
Set-Content -Path (Join-Path $funcCodeDir "requirements.txt") -Value $requirementsTxt -Encoding UTF8
Set-Content -Path (Join-Path $funcCodeDir "function_app.py") -Value $mcpHandlerCode -Encoding UTF8

Write-Log "Function code written to $funcCodeDir"

# Deploy via zip deploy
$zipFile = Join-Path $PSScriptRoot "mcp-function-app.zip"
if (Test-Path $zipFile) { Remove-Item $zipFile -Force }

# Create zip package
Compress-Archive -Path "$funcCodeDir\*" -DestinationPath $zipFile -Force

Write-Log "Deploying function code via zip deploy..."
az functionapp deployment source config-zip `
    --name $FunctionAppName `
    --resource-group $ResourceGroup `
    --src $zipFile `
    --output none 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Log "Function App deployed successfully"
} else {
    Write-Log "Function zip deploy failed - trying alternative method..." "WARN"
    # Alternative: publish via SCM
    az functionapp deploy `
        --name $FunctionAppName `
        --resource-group $ResourceGroup `
        --src-path $zipFile `
        --type zip `
        --output none 2>&1
}

} # end of deployment block (skip if already deployed)

# Get the function key for APIM backend auth
Write-Log "Retrieving function host key..."
if (-not $skipDeploy) {
    Start-Sleep -Seconds 10  # Wait for deployment to stabilize on fresh deploy
}
$funcHostKey = az functionapp keys list `
    --name $FunctionAppName `
    --resource-group $ResourceGroup `
    --query "functionKeys.default // masterKey" -o tsv 2>$null

if (-not $funcHostKey) {
    $funcHostKey = az functionapp keys list `
        --name $FunctionAppName `
        --resource-group $ResourceGroup `
        --query "masterKey" -o tsv 2>$null
}

Write-Log "Function App ready: https://$funcAppUrl/mcp"

# ============================================================================
# Step 2: Create Azure API Management (APIM) - MCP Gateway
# ============================================================================
Write-Log ""
Write-Log "============================================"
Write-Log "Step 2: Azure API Management (MCP Gateway)"
Write-Log "============================================"

$existingApim = az apim show --name $ApimName --resource-group $ResourceGroup --query name -o tsv 2>$null
if ($existingApim) {
    Write-Log "APIM already exists: $ApimName - reusing"
} else {
    Write-Log "Creating APIM instance: $ApimName (this may take 10-30 minutes for Consumption tier)..."
    az apim create `
        --name $ApimName `
        --resource-group $ResourceGroup `
        --location $Location `
        --publisher-name "Pharma Lab" `
        --publisher-email $AdminEmail `
        --sku-name Consumption `
        --enable-managed-identity `
        --output none 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Log "APIM creation failed. Trying Standard V2 tier..." "WARN"
        az apim create `
            --name $ApimName `
            --resource-group $ResourceGroup `
            --location $Location `
            --publisher-name "Pharma Lab" `
            --publisher-email $AdminEmail `
            --sku-name StandardV2 `
            --sku-capacity 1 `
            --enable-managed-identity `
            --output none 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Log "APIM creation failed" "ERROR"
            exit 1
        }
    }
    Write-Log "APIM created: $ApimName"
}

$apimGatewayUrl = az apim show --name $ApimName --resource-group $ResourceGroup --query "gatewayUrl" -o tsv
Write-Log "APIM Gateway: $apimGatewayUrl"

# Create the MCP API in APIM
Write-Log "Configuring MCP API in APIM..."

# Create API pointing to Function backend
$backendUrl = "https://$funcAppUrl"

# Check if API already exists
$existingApi = az apim api show --api-id "pharma-mcp" --resource-group $ResourceGroup --service-name $ApimName --query name -o tsv 2>$null
if ($existingApi) {
    Write-Log "MCP API already configured in APIM (skipping)"
} else {
    az apim api create `
        --api-id "pharma-mcp" `
        --resource-group $ResourceGroup `
        --service-name $ApimName `
        --display-name "Pharma MCP Tools" `
        --description "MCP server exposing pharma tools: drug interactions, pipeline status, revenue forecasts" `
        --path "mcp" `
        --service-url "$backendUrl" `
        --protocols https `
        --subscription-required true `
        --output none 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Log "MCP API created in APIM"

        # Add POST operation for MCP JSON-RPC
        az apim api operation create `
            --api-id "pharma-mcp" `
            --resource-group $ResourceGroup `
            --service-name $ApimName `
            --operation-id "mcp-post" `
            --display-name "MCP JSON-RPC" `
            --method POST `
            --url-template "/mcp" `
            --description "MCP Streamable HTTP endpoint - accepts JSON-RPC 2.0 requests" `
            --output none 2>&1

        # Add GET operation for health check
        az apim api operation create `
            --api-id "pharma-mcp" `
            --resource-group $ResourceGroup `
            --service-name $ApimName `
            --operation-id "mcp-health" `
            --display-name "MCP Health Check" `
            --method GET `
            --url-template "/mcp" `
            --description "Health check for MCP server" `
            --output none 2>&1

        Write-Log "MCP API operations configured"
    } else {
        Write-Log "Failed to create MCP API in APIM" "ERROR"
    }
}

# Set backend policy to forward Function key
if ($funcHostKey) {
    Write-Log "Configuring APIM backend policy with Function key..."
    $policyXml = @"
<policies>
    <inbound>
        <base />
        <set-header name="x-functions-key" exists-action="override">
            <value>$funcHostKey</value>
        </set-header>
        <set-backend-service base-url="https://$funcAppUrl" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
"@
    $policyFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $policyFile -Value $policyXml -Encoding UTF8

    az apim api policy create `
        --api-id "pharma-mcp" `
        --resource-group $ResourceGroup `
        --service-name $ApimName `
        --xml-file $policyFile `
        --output none 2>&1

    Remove-Item $policyFile -Force -ErrorAction SilentlyContinue
    Write-Log "APIM backend policy configured"
}

# Create a subscription key for lab users
Write-Log "Creating APIM subscription for lab users..."
$existingSub = az apim subscription show `
    --resource-group $ResourceGroup `
    --service-name $ApimName `
    --subscription-id "lab-users" `
    --query name -o tsv 2>$null

if ($existingSub) {
    Write-Log "APIM subscription 'lab-users' already exists"
} else {
    az apim subscription create `
        --resource-group $ResourceGroup `
        --service-name $ApimName `
        --subscription-id "lab-users" `
        --display-name "Lab Users - MCP Access" `
        --scope "/apis/pharma-mcp" `
        --state active `
        --output none 2>&1
}

# Get the subscription key
$subscriptionKey = az apim subscription keys list `
    --resource-group $ResourceGroup `
    --service-name $ApimName `
    --subscription-id "lab-users" `
    --query "primaryKey" -o tsv 2>$null

$mcpEndpoint = "$apimGatewayUrl/mcp"
Write-Log "MCP Endpoint: $mcpEndpoint"
Write-Log "Subscription Key: $subscriptionKey"

# ============================================================================
# Step 3: Create Azure API Center (API Governance)
# ============================================================================
Write-Log ""
Write-Log "============================================"
Write-Log "Step 3: Azure API Center (Governance)"
Write-Log "============================================"

# Install API Center CLI extension
az extension add --name apic --yes 2>$null | Out-Null

$existingApic = az apic show --name $ApiCenterName --resource-group $ResourceGroup --query name -o tsv 2>$null
if ($existingApic) {
    Write-Log "API Center already exists: $ApiCenterName - reusing"
} else {
    Write-Log "Creating API Center: $ApiCenterName"
    az apic create `
        --name $ApiCenterName `
        --resource-group $ResourceGroup `
        --location $Location `
        --output none 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Log "API Center creation failed (may not be available in region). Skipping..." "WARN"
    } else {
        Write-Log "API Center created: $ApiCenterName"
    }
}

# Register the MCP API in API Center
$existingApicApi = az apic api show `
    --api-id "pharma-mcp-tools" `
    --resource-group $ResourceGroup `
    --service-name $ApiCenterName `
    --query name -o tsv 2>$null

if ($existingApicApi) {
    Write-Log "API already registered in API Center (skipping)"
} else {
    Write-Log "Registering MCP API in API Center..."
    az apic api create `
        --api-id "pharma-mcp-tools" `
        --resource-group $ResourceGroup `
        --service-name $ApiCenterName `
        --title "Pharma MCP Tools" `
        --description "MCP server with pharma commercial operations tools: drug interaction checking, pipeline status, and revenue forecasting" `
        --type rest `
        --output none 2>&1

    if ($LASTEXITCODE -eq 0) {
        # Register a version
        az apic api version create `
            --api-id "pharma-mcp-tools" `
            --version-id "v1" `
            --resource-group $ResourceGroup `
            --service-name $ApiCenterName `
            --title "v1.0.0" `
            --lifecycle-stage production `
            --output none 2>&1

        Write-Log "API registered in API Center: pharma-mcp-tools v1.0.0"
    } else {
        Write-Log "Failed to register API in API Center" "WARN"
    }
}

# ============================================================================
# Step 4: Update Lab User Info with MCP Endpoint
# ============================================================================
Write-Log ""
Write-Log "============================================"
Write-Log "Step 4: Output & User Distribution"
Write-Log "============================================"

# Export MCP info
$mcpInfoFile = "./mcp-endpoint-info-$timestamp.txt"
$mcpInfo = @"
============================================
MCP ENDPOINT INFORMATION (for Lab 4)
============================================

MCP Server URL:        $mcpEndpoint
APIM Subscription Key: $subscriptionKey
API Key Header Name:   Ocp-Apim-Subscription-Key

Function App:          $FunctionAppName
APIM Instance:         $ApimName
API Center:            $ApiCenterName

Direct Function URL:   https://$funcAppUrl/mcp
(Use the APIM URL above for the lab, not the direct Function URL)

============================================
AGENT CONFIGURATION (copy into Foundry portal)
============================================
Tool Type:             Model Context Protocol (MCP)
Name:                  pharma-mcp-tools
Server URL:            $mcpEndpoint
Authentication:        API Key
API Key Header:        Ocp-Apim-Subscription-Key
API Key Value:         $subscriptionKey

============================================
AVAILABLE TOOLS
============================================
1. check_drug_interaction(drug_a, drug_b)
   - Checks for known drug-drug interactions
   - Returns severity, description, recommendation

2. get_pipeline_status(drug_name)
   - Returns pipeline phase, indication, approval date
   - Drugs: ZV-4521, ZV-8832, ZV-1104, ZV-6677, ZV-3390, ZV-9901, ZV-2245, ZV-5578, Zelvorix, Revumab

3. calculate_revenue_forecast(therapeutic_area, quarters_ahead)
   - Projects quarterly revenue for a therapeutic area
   - Areas: Oncology, Immunology, Neurology, Cardiovascular, Rare Disease, Infectious Disease
"@

Set-Content -Path $mcpInfoFile -Value $mcpInfo -Encoding UTF8
Write-Log "MCP endpoint info saved to: $mcpInfoFile"

# If users file provided, update the lab assignments CSV with MCP info
if ($UsersFile -and (Test-Path $UsersFile)) {
    $users = @(Import-Csv -Path $UsersFile)
    $mcpUserCsv = "./lab-mcp-assignments-$timestamp.csv"
    $mcpUsers = @()
    foreach ($user in $users) {
        $mcpUsers += [PSCustomObject]@{
            DisplayName    = $user.DisplayName
            UPN            = $user.UserPrincipalName
            MCPEndpoint    = $mcpEndpoint
            APIKeyHeader   = "Ocp-Apim-Subscription-Key"
            APIKeyValue    = $subscriptionKey
            APIMInstance   = $ApimName
            APICenterURL   = "https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.ApiCenter/services/$ApiCenterName"
        }
    }
    $mcpUsers | Export-Csv -Path $mcpUserCsv -NoTypeInformation
    Write-Log "User MCP assignments exported to: $mcpUserCsv"
}

# ============================================================================
# Verification
# ============================================================================
Write-Log ""
Write-Log "============================================"
Write-Log "Verification"
Write-Log "============================================"

# Test the function directly
Write-Log "Testing MCP endpoint directly..."
$testBody = '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
$testResult = az rest --method POST `
    --url "https://$funcAppUrl/mcp" `
    --headers "Content-Type=application/json" "x-functions-key=$funcHostKey" `
    --body $testBody `
    --output json 2>$null

if ($LASTEXITCODE -eq 0 -and $testResult) {
    $parsed = $testResult | ConvertFrom-Json
    $toolCount = $parsed.result.tools.Count
    Write-Log "  Direct function test: OK ($toolCount tools discovered)"
} else {
    Write-Log "  Direct function test: FAILED (function may still be deploying)" "WARN"
    Write-Log "  Wait 1-2 minutes and re-test with: curl -X POST https://$funcAppUrl/mcp -H 'x-functions-key: $funcHostKey' -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}'" "WARN"
}

# Test via APIM
if ($subscriptionKey) {
    Write-Log "Testing MCP endpoint via APIM..."
    $apimTestResult = az rest --method POST `
        --url "$mcpEndpoint" `
        --headers "Content-Type=application/json" "Ocp-Apim-Subscription-Key=$subscriptionKey" `
        --body $testBody `
        --output json 2>$null

    if ($LASTEXITCODE -eq 0 -and $apimTestResult) {
        Write-Log "  APIM gateway test: OK"
    } else {
        Write-Log "  APIM gateway test: FAILED (APIM may still be provisioning)" "WARN"
        Write-Log "  APIM Consumption tier can take up to 30 min. Retry later." "WARN"
    }
}

# ============================================================================
# Summary
# ============================================================================
Write-Log ""
Write-Log "============================================"
Write-Log "MCP INFRASTRUCTURE SETUP COMPLETE"
Write-Log "============================================"
Write-Log ""
Write-Log "Resources created:"
Write-Log "  [OK] Azure Function App:  $FunctionAppName (3 pharma MCP tools)"
Write-Log "  [OK] Azure API Management: $ApimName (MCP gateway with subscription key)"
Write-Log "  [OK] Azure API Center:     $ApiCenterName (API governance catalog)"
Write-Log ""
Write-Log "MCP Endpoint for Lab Users:"
Write-Log "  URL:  $mcpEndpoint"
Write-Log "  Key:  $subscriptionKey"
Write-Log ""
Write-Log "Distribute '$mcpInfoFile' to lab attendees."
Write-Log "Full log: $logFile"
