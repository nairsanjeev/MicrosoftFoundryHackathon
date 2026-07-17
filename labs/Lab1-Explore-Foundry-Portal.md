# Lab 1: Explore Microsoft Foundry Portal & Capabilities

**Duration:** 30 minutes  
**Objective:** Gain a comprehensive understanding of Microsoft Foundry's unified platform for AI development, and explore all key capabilities relevant to building pharma AI solutions.

[← Back to Main Page](../README.md) | [Next: Lab 2 →](Lab2-Create-Prompt-Agent.md)

---

## 1.1 — Sign in to Microsoft Foundry

1. Open your browser and navigate to **https://ai.azure.com**
2. Sign in with your lab credentials
3. Ensure the **"New Foundry"** toggle in the top banner is set to **ON**
4. Select your project: **`proj-pharma-ops`**

You should see the Foundry portal landing page with your project selected.

---

## 1.2 — Explore the Foundry Portal Navigation

Navigate through each section of the left navigation panel and take note of what's available:

### Create Section

| Area | What It Does | Pharma Relevance |
|------|-------------|------------------|
| **Agents** | Build, configure, and version AI agents | Create commercial ops analyst agents |
| **Models** | Browse 1,900+ models from Microsoft, OpenAI, Meta, etc. | Select optimal models for different tasks (reasoning vs. speed) |
| **Tools** | Discover 1,400+ tools in the Tool Catalog | Connect to data sources, APIs, code execution |
| **Knowledge** | Foundry IQ knowledge bases for grounding | Ground agents in drug pipeline data, SOPs |
| **Guardrails** | Content safety and responsible AI controls | Ensure compliance with pharma regulations |
| **Data** | Manage datasets for evaluations | Clinical trial data, sales performance data |

### Optimize Section

| Area | What It Does | Pharma Relevance |
|------|-------------|------------------|
| **Evaluations** | Assess agent quality with built-in evaluators | Validate accuracy of drug information responses |
| **Fine-tune** | Customize models for your domain | Optimize for pharma-specific terminology |

---

## 1.3 — Explore the Model Catalog

1. Click **Models** in the left navigation
2. Browse the available model families:
   - **GPT-4.1** — Best balance of capability and cost for production workloads
   - **GPT-4.1 mini** — Fastest for low-latency, high-throughput scenarios
   - **Phi-4** — Small language models for resource-constrained environments
   - **Meta Llama** — Open models for customization and fine-tuning
   - **DeepSeek-R1** — Open-weight reasoning at scale
3. Click on **gpt-4.1** → Review the model card, pricing, and capabilities
4. Note the deployment that's already configured: `gpt-4.1` (Global Standard)

> **💡 Pharma Value:** Different tasks need different models. Use GPT-4.1 for complex reasoning about drug interactions, GPT-4.1 mini for high-volume commercial queries, and smaller models for on-device compliance checks.

---

## 1.4 — Explore the Tool Catalog

1. Click **Tools** in the left navigation
2. Browse the **Built-in Tools**:
   - **Web Search** — Real-time information retrieval with citations
   - **Code Interpreter** — Python code execution for data analysis
   - **File Search** — Vector search over proprietary documents
   - **Azure AI Search** — Ground agents with enterprise search indexes
   - **Azure Functions** — Custom actions via serverless functions
3. Browse the **Custom Tools** section:
   - **Model Context Protocol (MCP)** — Connect to external MCP servers
   - **OpenAPI** — Connect to any REST API with an OpenAPI spec
   - **Agent-to-Agent (A2A)** — Cross-agent communication

> **💡 Pharma Value:** The Tool Catalog means your agent can search PubMed via web search, analyze clinical data via Code Interpreter, query your internal document repository via File Search, and trigger regulatory submission workflows via Azure Functions — all from a single agent.

---

## 1.5 — Explore the Playground

1. Click **Agents** → Select the pre-created agent or click **+ New Agent**
2. In the Playground area (right panel), select the **Chat** tab
3. Try a simple prompt: *"What are the top 5 therapeutic areas by revenue in the pharmaceutical industry?"*
4. Switch to the **YAML** tab to see the agent definition structure
5. Click the **Metrics** dropdown to see available monitoring options

---

## 1.6 — Review Key Capabilities Summary

Before moving to the next lab, review the key differentiators you explored:

| Capability | What Makes Foundry Unique |
|-----------|--------------------------|
| **Unified Platform** | Agents + Models + Tools under single RBAC and networking |
| **1,900+ Models** | Multi-provider catalog (OpenAI, Meta, Anthropic, Mistral, etc.) |
| **1,400+ Tools** | Public + private catalogs with central auth management |
| **Foundry IQ** | Managed knowledge layer with citation-backed answers |
| **Built-in Evaluators** | Quality, safety, and agent-specific evaluations |
| **Enterprise Controls** | RBAC, networking, Azure Policy, AI Gateway integration |

---

## Checkpoint

✅ You signed in to the Microsoft Foundry portal  
✅ You explored the Model Catalog (1,900+ models from multiple providers)  
✅ You browsed the Tool Catalog (built-in + custom tools)  
✅ You tested the Agent Playground  
✅ You understand Foundry's key capabilities and pharma relevance  

---

## References

- [What is Microsoft Foundry?](https://learn.microsoft.com/en-us/azure/foundry/what-is-foundry?tabs=python#key-capabilities)
- [Foundry Models Overview](https://learn.microsoft.com/en-us/azure/foundry/concepts/foundry-models-overview)
- [Agent Tools Overview](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/tool-catalog)

---

[← Back to Main Page](../README.md) | [Next: Lab 2 — Create a Prompt Agent →](Lab2-Create-Prompt-Agent.md)
