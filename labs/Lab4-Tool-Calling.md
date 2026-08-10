# Lab 4: Tool Calling — Remote MCP Server

**Duration:** 60 minutes  
**Objective:** Connect your agent to a pre-configured **Remote MCP Server** exposed through Azure API Management. You'll learn how enterprise-grade tool calling works with MCP protocol, API governance, and observability through Azure API Center.

[← Back to Main Page](../README.md) | [Previous: Lab 3](Lab3-Foundry-IQ-Knowledge.md) | [Next: Lab 5 →](Lab5-Hosted-Agent-Deployment.md)

---

## Architecture Overview

```
┌─────────────────┐       ┌──────────────────┐       ┌─────────────────────┐
│  Foundry Agent  │──MCP──│  Azure API Mgmt  │──HTTP──│  Azure Function     │
│  (gpt-5-mini)   │       │  (MCP Gateway)   │       │  (Pharma Tools)     │
└─────────────────┘       └──────────────────┘       └─────────────────────┘
                                    │
                          ┌─────────┴──────────┐
                          │  Azure API Center  │
                          │  (API Catalog)     │
                          └────────────────────┘
```

**Why this architecture?**
- **APIM as MCP Gateway:** Centralized auth, rate limiting, and monitoring for all tool calls
- **Azure Functions:** Serverless compute hosting pharma-specific business logic
- **API Center:** Discover, govern, and document all available MCP tools across your organization

---

## Part A: Explore the Pre-configured MCP Endpoint

Your lab environment includes a pre-deployed MCP server with three pharma tools. Your admin has configured this via the setup script.

### 4A.1 — Understand the Available Tools

The MCP server exposes these tools:

| Tool | Description | Parameters |
|------|-------------|------------|
| `check_drug_interaction` | Checks for known drug-drug interactions between two medications | `drug_a`, `drug_b` |
| `get_pipeline_status` | Returns current development status for a drug | `drug_name` |
| `calculate_revenue_forecast` | Projects revenue for a therapeutic area | `therapeutic_area`, `quarters_ahead` |

### 4A.2 — View the API in Azure API Center

1. In the **Azure Portal**, navigate to your resource group (`rg-foundry-lab-shared`)
2. Open the **API Center** resource (`apic-foundry-lab`)
3. Browse **APIs** → you'll see `pharma-mcp-tools` registered
4. Click on it to see:
   - API definition (OpenAPI spec)
   - Available operations (the 3 tools above)
   - Environments and deployment info
   - Governance compliance status

> **💡 Enterprise Value:** API Center gives your governance team visibility into all MCP tools used by AI agents across the organization — essential for pharma compliance and audit trails.

---

## Part B: Connect the MCP Server to Your Agent

### 4B.1 — Add the MCP Tool to Your Agent

1. In the Foundry portal, go to **Agents** → Select `ZavaCommOpsAnalyst`
2. Under **Tools**, click **Add** → **+ Add tool**
3. In the **"Select a tool"** dialog, click the **Custom** tab
4. Select **Model Context Protocol (MCP)**

   > You'll see three options under Custom: OpenAPI tool, Model Context Protocol (MCP), and Agent2agent (A2A). Select MCP.

5. Configure the MCP connection:

| Setting | Value |
|---------|-------|
| **Name** | `pharma-mcp-tools` |
| **Server URL** | `https://apim-foundry-lab-<suffix>.azure-api.net/mcp` |
| **Authentication** | API Key |
| **API Key Header** | `Ocp-Apim-Subscription-Key` |
| **API Key Value** | *(provided by your lab admin — check your lab info sheet)* |

> **📋 Where to find your MCP URL and key:** Check the lab info sheet distributed by your admin. The URL and subscription key are listed under "MCP Endpoint" in the output CSV.

> **🔒 Security Note:** In production, you'd use Managed Identity instead of API keys. The lab uses APIM subscription keys for simplicity. APIM authenticates to the backend Function App using its own Managed Identity — no secrets stored.

6. Click **Create**

### 4B.2 — Verify Tool Discovery

After connecting, the agent should automatically discover the tools exposed by the MCP server:

1. In the agent's **Tools** panel, you should see `pharma-mcp-tools` listed
2. The MCP protocol auto-discovers the tools at connection time via the `/mcp/list-tools` endpoint
3. You should see three tools available:
   - `check_drug_interaction`
   - `get_pipeline_status`
   - `calculate_revenue_forecast`

If tools don't appear, verify the URL ends with `/mcp` and the API key is correct.

---

## Part C: Test Tool Calling

### 4C.1 — Drug Interaction Check

In the Agent Playground, ask:

> *"A physician is considering adding Zelvorix to a patient already on Warfarin. Are there any drug interactions I should be aware of?"*

**Expected behavior:**
1. Agent recognizes this requires a drug interaction check
2. Calls `check_drug_interaction` with `drug_a: "Zelvorix"`, `drug_b: "Warfarin"`
3. Receives: High severity, risk of bleeding events
4. Synthesizes a clinical recommendation: reduce warfarin dose by 25%, monitor INR weekly

### 4C.2 — Pipeline Status

> *"What's the current development status of ZV-4521 in our pipeline?"*

**Expected:** Agent calls `get_pipeline_status` and returns:
- Phase 3, Non-Small Cell Lung Cancer
- Expected approval: Q2 2027
- Revenue forecast: $2.4B

### 4C.3 — Revenue Forecast

> *"Project the oncology therapeutic area revenue for the next 4 quarters."*

**Expected:** Agent calls `calculate_revenue_forecast` with `therapeutic_area: "Oncology"` and `quarters_ahead: 4`, returns projected figures.

### 4C.4 — Multi-Tool Scenario

> *"I need a complete briefing on Zelvorix: its pipeline status, any interactions with Revumab, and projected oncology revenue for the next 2 quarters."*

**Expected:** Agent makes 3 separate MCP tool calls and synthesizes a comprehensive executive briefing.

---

## Part D: Observe MCP Tool Call Details

### 4D.1 — View Tool Call Traces

1. In the Playground response, click on the **numbered badges** (e.g., `1`, `2`) next to `mcp://`
2. Observe:
   - **Tool name** called via MCP
   - **Parameters** sent (JSON)
   - **Response** received from the backend
   - **Latency** of each call (includes APIM + Function execution)

### 4D.2 — Compare: Direct Function vs. MCP via APIM

| Aspect | Direct Azure Function | MCP via APIM |
|--------|----------------------|--------------|
| **Discovery** | Manual configuration | Auto-discovery via MCP protocol |
| **Auth** | Function-level key | APIM subscription + backend MI |
| **Rate Limiting** | None (or custom) | APIM policies (per-user, per-agent) |
| **Monitoring** | Function logs only | APIM Analytics + App Insights |
| **Governance** | Ad-hoc | API Center catalog + compliance |
| **Multi-tool** | Separate configs per function | Single MCP endpoint, all tools |

### 4D.3 — Check APIM Analytics (Optional)

1. In Azure Portal → API Management (`apim-foundry-lab-<suffix>`) → **Analytics**
2. View:
   - Total API calls from your agent
   - Response times (P50, P95)
   - Error rates
   - Per-operation breakdown

> **💡 Enterprise Value:** APIM provides request logging, throttling, and circuit-breaking — preventing a misbehaving agent from overwhelming backend systems. In pharma, this audit trail is essential for 21 CFR Part 11 compliance.

---

## Part E: Code Interpreter (Bonus)

If time permits, also enable Code Interpreter for data visualization:

1. Under **Tools** → **Add** → Select **Code Interpreter** from the Configured tab
2. Upload `quarterly_revenue.csv` to the agent's files
3. Ask: *"Create a pie chart showing market share by therapeutic area for Q3 2026"*
4. The agent writes and executes Python code (pandas + matplotlib) in a sandboxed environment

---

## Checkpoint

✅ You connected a remote MCP server to your agent via APIM  
✅ You tested drug interaction, pipeline status, and revenue forecast tools  
✅ You observed multi-tool orchestration in a single query  
✅ You understand how APIM provides governance and observability for MCP tool calls  
✅ (Optional) You explored the API catalog in Azure API Center  

---

## Key Takeaways

| Concept | What You Learned |
|---------|-----------------|
| **MCP Protocol** | Standard interface for agents to discover and invoke tools dynamically |
| **APIM as MCP Gateway** | Centralized auth, rate limits, logging, and circuit-breaking for all tool calls |
| **API Center** | Enterprise catalog of all MCP tools for governance and discoverability |
| **Multi-tool orchestration** | Agent autonomously decides which tools to invoke based on the query |
| **Pharma compliance** | Audit trail of every tool call via APIM logs (21 CFR Part 11 ready) |

---

## References

- [Model Context Protocol (MCP) Tool](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/tools/model-context-protocol)
- [Azure API Management Overview](https://learn.microsoft.com/en-us/azure/api-management/api-management-key-concepts)
- [Azure API Center Overview](https://learn.microsoft.com/en-us/azure/api-center/overview)
- [Tool Catalog Overview](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/tool-catalog)

---

[← Back to Main Page](../README.md) | [Previous: Lab 3](Lab3-Foundry-IQ-Knowledge.md) | [Next: Lab 5 — Hosted Agent Deployment →](Lab5-Hosted-Agent-Deployment.md)
