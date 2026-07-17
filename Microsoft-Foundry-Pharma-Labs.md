# Microsoft Foundry Hands-On Lab Series
## Pharma Commercial Operations AI — From Exploration to Production

---

### Lab Overview

Welcome to the **Microsoft Foundry Pharma AI Lab Series**! In these labs, you will build an end-to-end AI agent solution for a pharmaceutical commercial operations team. You'll progress from exploring the Foundry platform through creating intelligent agents that can answer questions about drug pipeline data, perform data analysis, call external tools, and be monitored in production.

**Industry Context:** As a data scientist or AI engineer at a leading pharmaceutical company, you need to build AI agents that can help commercial operations teams with:
- Answering questions about drug portfolios, clinical trial statuses, and revenue forecasts
- Analyzing quarterly financial results across therapeutic areas
- Retrieving regulatory compliance information
- Generating visual reports on sales performance

**What You'll Build:** A "Pharma Commercial Operations AI Analyst" — an intelligent agent grounded in your company's proprietary data, equipped with tools for data analysis and custom actions, deployed as a production-grade hosted agent with full observability.

---

### Prerequisites (Pre-configured for You)

The following have been set up in your lab environment:

| Resource | Details |
|----------|---------|
| Azure Subscription | Provided with necessary RBAC roles |
| Microsoft Foundry Project | `proj-pharma-ops` at `https://ai.azure.com` |
| Model Deployments | `gpt-4.1` (Global Standard), `gpt-4.1-mini` |
| Azure AI Search | Service provisioned for Foundry IQ |
| Azure Storage Account | For uploading pharma datasets |
| Application Insights | Connected to Foundry project for tracing |
| Azure Developer CLI (azd) | Pre-installed with Foundry extension |

---

## Lab 1: Explore Microsoft Foundry Portal & Capabilities

**Duration:** 30 minutes  
**Objective:** Gain a comprehensive understanding of Microsoft Foundry's unified platform for AI development, and explore all key capabilities relevant to building pharma AI solutions.

### 1.1 — Sign in to Microsoft Foundry

1. Open your browser and navigate to **https://ai.azure.com**
2. Sign in with your lab credentials
3. Ensure the **"New Foundry"** toggle in the top banner is set to **ON**
4. Select your project: **`proj-pharma-ops`**

You should see the Foundry portal landing page with your project selected.

### 1.2 — Explore the Foundry Portal Navigation

Navigate through each section of the left navigation panel and take note of what's available:

#### Create Section
| Area | What It Does | Pharma Relevance |
|------|-------------|------------------|
| **Agents** | Build, configure, and version AI agents | Create commercial ops analyst agents |
| **Models** | Browse 1,900+ models from Microsoft, OpenAI, Meta, etc. | Select optimal models for different tasks (reasoning vs. speed) |
| **Tools** | Discover 1,400+ tools in the Tool Catalog | Connect to data sources, APIs, code execution |
| **Knowledge** | Foundry IQ knowledge bases for grounding | Ground agents in drug pipeline data, SOPs |
| **Guardrails** | Content safety and responsible AI controls | Ensure compliance with pharma regulations |
| **Data** | Manage datasets for evaluations | Clinical trial data, sales performance data |

#### Optimize Section
| Area | What It Does | Pharma Relevance |
|------|-------------|------------------|
| **Evaluations** | Assess agent quality with built-in evaluators | Validate accuracy of drug information responses |
| **Fine-tune** | Customize models for your domain | Optimize for pharma-specific terminology |

### 1.3 — Explore the Model Catalog

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

### 1.4 — Explore the Tool Catalog

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

### 1.5 — Explore the Playground

1. Click **Agents** → Select the pre-created agent or click **+ New Agent**
2. In the Playground area (right panel), select the **Chat** tab
3. Try a simple prompt: *"What are the top 5 therapeutic areas by revenue in the pharmaceutical industry?"*
4. Switch to the **YAML** tab to see the agent definition structure
5. Click the **Metrics** dropdown to see available monitoring options

### 1.6 — Review Key Capabilities Summary

Before moving to the next lab, review the key differentiators you explored:

| Capability | What Makes Foundry Unique |
|-----------|--------------------------|
| **Unified Platform** | Agents + Models + Tools under single RBAC and networking |
| **1,900+ Models** | Multi-provider catalog (OpenAI, Meta, Anthropic, Mistral, etc.) |
| **1,400+ Tools** | Public + private catalogs with central auth management |
| **Foundry IQ** | Managed knowledge layer with citation-backed answers |
| **Built-in Evaluators** | Quality, safety, and agent-specific evaluations |
| **Enterprise Controls** | RBAC, networking, Azure Policy, AI Gateway integration |

> **📖 Reference:** [What is Microsoft Foundry?](https://learn.microsoft.com/en-us/azure/foundry/what-is-foundry?tabs=python#key-capabilities)

---

## Lab 2: Create a Pharma Commercial Operations Agent

**Duration:** 45 minutes  
**Objective:** Create a prompt agent via the Foundry Portal UI and optionally via Python SDK. This agent will serve as your "Pharma Commercial Operations Analyst."

### 2.1 — Create the Agent via Foundry Portal UI

1. In the Foundry portal, go to **Build** → **Agents**
2. Click **+ New Agent**
3. Configure the agent:

| Setting | Value |
|---------|-------|
| **Agent Name** | `ZavaCommOpsAnalyst` |
| **Model** | `gpt-4.1` (Global Standard deployment) |
| **Instructions** | *(see below)* |

4. In the **Instructions** field, paste the following:

```
You are the Zava Commercial Operations AI Analyst — an advanced reasoning agent powered by Foundry IQ.

You answer business questions by combining:
- Deep knowledge of pharmaceutical commercial operations
- Revenue forecasting and pipeline analysis
- Therapeutic area performance metrics
- Regulatory milestone tracking

Guidelines:
1. Always provide data-driven answers with specific numbers when available
2. Cite your sources when referencing uploaded documents
3. Flag any information that may be outdated (>6 months old)
4. For financial projections, clearly state assumptions
5. When discussing drugs, always note their approval status and therapeutic area
6. Maintain compliance — never provide medical advice or make claims about drug efficacy not supported by data
```

5. Click **Save** to create Version 1 of your agent

### 2.2 — Test the Agent in the Playground

In the Chat panel on the right side:

1. **First message:** *"What factors typically drive commercial success for a newly launched biologic in oncology?"*
2. **Follow-up:** *"How would you structure a quarterly business review for a pharma commercial team?"*
3. **Test multi-turn:** *"Can you create a template agenda for that QBR?"*

Observe how the agent:
- Maintains conversation context across turns
- Provides structured, business-relevant responses
- Follows the instruction guidelines

### 2.3 — (Optional) Create the Agent via Python SDK

Open a terminal and run the following:

```bash
pip install azure-ai-projects>=2.3.0
az login
```

Create a file `create_agent.py`:

```python
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import PromptAgentDefinition

# Your Foundry project endpoint (from portal Overview page)
PROJECT_ENDPOINT = "https://<your-resource>.ai.azure.com/api/projects/<your-project>"
AGENT_NAME = "ZavaCommOpsAnalyst"

# Create project client
project = AIProjectClient(
    endpoint=PROJECT_ENDPOINT,
    credential=DefaultAzureCredential(),
)

# Create the agent
agent = project.agents.create_version(
    agent_name=AGENT_NAME,
    definition=PromptAgentDefinition(
        model="gpt-4.1",
        instructions="""You are the Zava Commercial Operations AI Analyst — an advanced reasoning agent powered by Foundry IQ.

You answer business questions by combining:
- Deep knowledge of pharmaceutical commercial operations
- Revenue forecasting and pipeline analysis
- Therapeutic area performance metrics
- Regulatory milestone tracking

Guidelines:
1. Always provide data-driven answers with specific numbers when available
2. Cite your sources when referencing uploaded documents
3. Flag any information that may be outdated (>6 months old)
4. For financial projections, clearly state assumptions
5. When discussing drugs, always note their approval status and therapeutic area
6. Maintain compliance — never provide medical advice or make claims about drug efficacy not supported by data""",
    ),
)

print(f"✅ Agent created: {agent.name} (version: {agent.version}, id: {agent.id})")
```

### 2.4 — Chat with the Agent via Python SDK

Create a file `chat_agent.py`:

```python
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient

PROJECT_ENDPOINT = "https://<your-resource>.ai.azure.com/api/projects/<your-project>"
AGENT_NAME = "ZavaCommOpsAnalyst"

project = AIProjectClient(
    endpoint=PROJECT_ENDPOINT,
    credential=DefaultAzureCredential(),
)
openai = project.get_openai_client(agent_name=AGENT_NAME)

# Create a conversation
conversation = openai.conversations.create()

# Ask a pharma commercial question
response = openai.responses.create(
    conversation=conversation.id,
    input="What are the key metrics a pharma commercial ops team should track for a newly launched immunology drug?",
)
print(f"Agent: {response.output_text}")

# Follow-up question (maintains conversation context)
response = openai.responses.create(
    conversation=conversation.id,
    input="How would you benchmark those metrics against industry standards?",
)
print(f"\nAgent: {response.output_text}")
```

Run the script:
```bash
python chat_agent.py
```

### 2.5 — Checkpoint

✅ You have created a Pharma Commercial Operations AI Analyst agent  
✅ You tested it in the Foundry Playground  
✅ (Optional) You created and tested it via Python SDK  

> **📖 Reference:** [Quickstart: Create a prompt agent](https://learn.microsoft.com/en-us/azure/foundry/agents/quickstarts/prompt-agent?tabs=python)

---

## Lab 3: Connect with Foundry IQ Knowledge Base

**Duration:** 60 minutes  
**Objective:** Upload pharma-relevant data to Azure Storage, create a Foundry IQ knowledge base, and ground your agent's responses in proprietary enterprise data — experiencing citation-backed, permission-aware retrieval.

### 3.1 — Understand Foundry IQ

**Foundry IQ** is the managed knowledge layer that transforms enterprise content into reusable, permission-aware knowledge bases. Key differentiators:

- **Agentic Retrieval:** AI-powered query planning that understands intent, not just keywords
- **Citation-Backed Answers:** Every response includes source citations for auditability
- **Permission-Aware:** Respects document-level access controls
- **Multi-Source:** Combines data from blob storage, SharePoint, databases, and web sources

### 3.2 — Download Pharma Data Files

The sample data files are pre-created and available in the [`data/`](data/) folder of this repository. Download all three files to your local machine:

| File | Description | Download |
|------|-------------|----------|
| `drug_pipeline.csv` | Pipeline drugs across therapeutic areas with phase, indication, and revenue forecasts | [Download](data/drug_pipeline.csv) |
| `quarterly_revenue.csv` | Q1-Q3 2026 revenue, units sold, and market share by product | [Download](data/quarterly_revenue.csv) |
| `regulatory_milestones.csv` | FDA/EMA regulatory milestones and statuses | [Download](data/regulatory_milestones.csv) |

**To download all files at once**, clone the repo or download the `data/` folder:
```bash
git clone https://github.com/nairsanjeev/MicrosoftFoundryHackathon.git
cd MicrosoftFoundryHackathon/data
```

**What's in the data:**
- **Drug Pipeline** — 8 drugs across 6 therapeutic areas in various clinical phases
- **Quarterly Revenue** — 3 quarters of revenue data for 4 marketed products
- **Regulatory Milestones** — FDA and EMA approval timelines and upcoming PDUFA dates

### 3.3 — Upload Data to Azure Storage

1. In the **Azure Portal** (portal.azure.com), navigate to your Storage Account
2. Go to **Containers** → Create a new container: `pharma-commercial-data`
3. Upload all three CSV files to this container
4. Verify the files are accessible

Alternatively, use Azure CLI:
```bash
az storage blob upload-batch \
  --account-name <your-storage-account> \
  --destination pharma-commercial-data \
  --source ./data/ \
  --auth-mode login
```

### 3.4 — Create a Knowledge Source in Azure AI Search

The knowledge source connects Azure AI Search to your blob storage data.

1. In the **Foundry portal**, go to **Knowledge** in the left navigation
2. Click **+ New Knowledge Base**
3. Configure:

| Setting | Value |
|---------|-------|
| **Name** | `pharma-commercial-kb` |
| **Knowledge Source** | Azure Blob Storage |
| **Container** | `pharma-commercial-data` |
| **Model for Synthesis** | `gpt-4.1` |

4. Set **Output Mode** to **Answer Synthesis** — this enables the LLM to synthesize responses from retrieved data
5. Add **Retrieval Instructions**:
```
Use this knowledge base for questions about drug pipeline, revenue performance, 
market share, and regulatory milestones. Always cite specific data points 
including quarter, therapeutic area, and drug names.
```
6. Add **Answer Instructions**:
```
Provide concise, data-driven answers. Include specific numbers from the data.
Format financial figures in millions. Always state the quarter or time period 
for any metrics cited.
```
7. Click **Create**

### 3.5 — Connect the Knowledge Base to Your Agent

1. Go to **Build** → **Agents** → Select `ZavaCommOpsAnalyst`
2. In the agent configuration, add the **Foundry IQ** knowledge base:
   - Under **Tools**, click **+ Add Tool**
   - Select **Azure AI Search** or **Foundry IQ Knowledge**
   - Select `pharma-commercial-kb`
3. **Save** a new version of the agent

### 3.6 — Test Knowledge-Grounded Responses

In the Agent Playground, ask questions that require the uploaded data:

1. *"What is our top-performing oncology product and how has its market share trended over the last 3 quarters?"*
   
   **Expected:** The agent should cite Zelvorix with specific market share percentages (23.5% → 24.1% → 25.3%)

2. *"Which drugs in our pipeline are closest to FDA approval? What are the expected revenue impacts?"*
   
   **Expected:** Should reference ZV-9901 (Q4 2026), ZV-4521 and ZV-2245 (Q1 2027) with revenue forecasts

3. *"Summarize the regulatory status of Revumab across all regions."*
   
   **Expected:** Should cite BLA submission, advisory committee date, and PDUFA information

4. *"Compare Q1 vs Q3 2026 total revenue across all therapeutic areas."*
   
   **Expected:** Should calculate totals from the quarterly_revenue data with specific figures

### 3.7 — Observe the Foundry IQ Difference

Notice how the responses:
- ✅ Include **citations** pointing to specific data files
- ✅ Contain **specific numbers** from your uploaded CSVs
- ✅ Synthesize across **multiple documents** when needed
- ✅ Decline to answer when data **isn't available** (no hallucination)

> **💡 Pharma Value:** In pharma, accuracy is non-negotiable. Foundry IQ ensures your agent's answers are grounded in actual company data with full auditability — critical for regulatory compliance and executive decision-making.

### 3.8 — Checkpoint

✅ You uploaded pharma commercial data to Azure Storage  
✅ You created a Foundry IQ knowledge base with agentic retrieval  
✅ You grounded your agent in proprietary enterprise data  
✅ You verified citation-backed, accurate responses  

> **📖 Reference:** [Create a knowledge base in Azure AI Search](https://learn.microsoft.com/en-us/azure/search/agentic-retrieval-how-to-create-knowledge-base?tabs=rbac%2C2026-05-01-preview&pivots=csharp) | [What is Foundry IQ?](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/what-is-foundry-iq)

---

## Lab 4: Tool Calling — Azure Functions & Code Interpreter

**Duration:** 60 minutes  
**Objective:** Extend your agent with real-world capabilities by adding tool calling. You'll create an Azure Function for a custom pharma action and use Code Interpreter for data analysis and visualization.

### Part A: Code Interpreter — Pharma Data Visualization

### 4A.1 — Enable Code Interpreter on Your Agent

1. In the Foundry portal, go to **Build** → **Agents** → Select `ZavaCommOpsAnalyst`
2. Under **Tools**, click **+ Add Tool**
3. Select **Code Interpreter**
4. **Save** a new version of the agent

### 4A.2 — Upload Data for Analysis

Upload the `quarterly_revenue.csv` file to the agent's Code Interpreter:

**Via Python SDK:**
```python
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    PromptAgentDefinition,
    CodeInterpreterTool,
    AutoCodeInterpreterToolParam,
)

PROJECT_ENDPOINT = "https://<your-resource>.ai.azure.com/api/projects/<your-project>"

project = AIProjectClient(
    endpoint=PROJECT_ENDPOINT,
    credential=DefaultAzureCredential(),
)
openai = project.get_openai_client()

# Upload the quarterly revenue CSV
file = openai.files.create(
    purpose="assistants",
    file=open("quarterly_revenue.csv", "rb"),
)
print(f"File uploaded: {file.id}")

# Create agent with Code Interpreter
agent = project.agents.create_version(
    agent_name="ZavaCommOpsAnalyst",
    definition=PromptAgentDefinition(
        model="gpt-4.1",
        instructions="""You are the Zava Commercial Operations AI Analyst with data visualization capabilities.
        
When asked to analyze data:
1. Load the uploaded CSV files
2. Perform the requested analysis using pandas
3. Generate clear, publication-quality charts using matplotlib
4. Always include axis labels, titles, and legends
5. Use the company color scheme: #0078D4 (blue), #50E6FF (light blue), #00BCF2 (cyan)""",
        tools=[CodeInterpreterTool(container=AutoCodeInterpreterToolParam(file_ids=[file.id]))],
    ),
)
print(f"Agent with Code Interpreter: {agent.name} v{agent.version}")
```

### 4A.3 — Test Data Analysis in the Playground

Ask the agent to perform analysis:

1. *"Analyze the quarterly revenue data and create a bar chart showing revenue by therapeutic area for each quarter. Highlight the top performer."*

2. *"Calculate the quarter-over-quarter growth rate for each product and generate a line chart showing the trend."*

3. *"Create a pie chart showing market share distribution across therapeutic areas for Q3 2026."*

4. *"Run a statistical analysis: which therapeutic area shows the strongest growth trajectory? Show your calculations."*

The agent will:
- Write Python code using pandas and matplotlib
- Execute it in the sandboxed environment
- Generate PNG chart files you can download
- Provide text explanation of findings

### Part B: Azure Functions — Custom Pharma Tool Call

### 4B.1 — Create an Azure Function for Drug Interaction Check

This function simulates a drug interaction checking service that your agent can call.

Create the Azure Function in the portal or via CLI:

```bash
# Create Function App
az functionapp create \
  --name pharma-tools-func \
  --resource-group <your-rg> \
  --runtime python \
  --runtime-version 3.11 \
  --functions-version 4 \
  --storage-account <your-storage> \
  --os-type Linux
```

**Function code (`drug_interaction_check/__init__.py`):**

```python
import json
import azure.functions as func

# Simulated drug interaction database
INTERACTIONS = {
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
}

def main(req: func.HttpRequest) -> func.HttpResponse:
    try:
        body = req.get_json()
        drug_a = body.get("drug_a", "").strip()
        drug_b = body.get("drug_b", "").strip()
        
        if not drug_a or not drug_b:
            return func.HttpResponse(
                json.dumps({"error": "Both drug_a and drug_b are required"}),
                status_code=400,
                mimetype="application/json"
            )
        
        # Check both orderings
        key = (drug_a, drug_b) if (drug_a, drug_b) in INTERACTIONS else (drug_b, drug_a)
        
        if key in INTERACTIONS:
            result = INTERACTIONS[key]
            result["drug_a"] = drug_a
            result["drug_b"] = drug_b
            result["interaction_found"] = True
        else:
            result = {
                "drug_a": drug_a,
                "drug_b": drug_b,
                "interaction_found": False,
                "description": f"No known interaction between {drug_a} and {drug_b}.",
                "recommendation": "Standard monitoring applies."
            }
        
        return func.HttpResponse(
            json.dumps(result),
            mimetype="application/json"
        )
    except Exception as e:
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500,
            mimetype="application/json"
        )
```

### 4B.2 — Add the Azure Function as a Tool

1. In the Foundry portal, go to **Build** → **Tools**
2. Click **+ Add Tool** → Select **Azure Functions**
3. Configure:

| Setting | Value |
|---------|-------|
| **Name** | `check_drug_interaction` |
| **Function App** | `pharma-tools-func` |
| **Function** | `drug_interaction_check` |
| **Description** | Checks for known drug-drug interactions between two medications and returns severity, description, and clinical recommendations |

4. Define the function parameters:
```json
{
  "type": "object",
  "properties": {
    "drug_a": {
      "type": "string",
      "description": "First drug name to check for interactions"
    },
    "drug_b": {
      "type": "string",
      "description": "Second drug name to check for interactions"
    }
  },
  "required": ["drug_a", "drug_b"]
}
```

5. Add this tool to your `ZavaCommOpsAnalyst` agent and save a new version

### 4B.3 — Test Tool Calling in the Playground

Ask questions that trigger tool calls:

1. *"A physician is considering adding Zelvorix to a patient already on Warfarin. Are there any drug interactions I should be aware of?"*

   **Expected:** Agent calls `check_drug_interaction`, receives the High severity response, and provides the clinical recommendation.

2. *"Check if Revumab and Methotrexate can be used together safely."*

   **Expected:** Agent calls the function and reports the Moderate interaction with monitoring recommendations.

3. *"Our commercial team needs a summary of all known interaction profiles for Zelvorix. Check interactions with Revumab, Warfarin, and Methotrexate."*

   **Expected:** Agent makes multiple tool calls and synthesizes a comprehensive interaction profile.

### 4B.4 — Observe Tool Calling Behavior

In the Playground, click on the **response details** to see:
- Which tools were called
- The parameters sent to each tool
- The tool's response
- How the agent incorporated the tool output into its answer

### 4.5 — Checkpoint

✅ You enabled Code Interpreter for data analysis and visualization  
✅ You created an Azure Function for drug interaction checking  
✅ You added the function as a tool to your agent  
✅ You tested multi-tool scenarios in the Playground  
✅ You observed how the agent decides when and how to call tools  

> **📖 References:**  
> - [Tool Catalog Overview](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/tool-catalog#all-built-in-tools)  
> - [Code Interpreter Tool](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/tools/code-interpreter?tabs=prompt-agents&pivots=python)

---

## Lab 5: Deploy a Hosted Agent with Microsoft Agent Framework

**Duration:** 60 minutes  
**Objective:** Take your agent from a playground prototype to a production-grade hosted agent using the Microsoft Agent Framework and Azure Developer CLI (azd). This is the path to enterprise deployment.

### 5.1 — Understand Hosted Agents

**Prompt Agents** (Labs 2-4) are declarative and run server-side in Foundry. **Hosted Agents** are containerized applications you write with the Microsoft Agent Framework, giving you:

- Full control over agent logic and orchestration
- Custom tool implementations in your code
- Local testing and debugging before deployment
- Container-based deployment with auto-scaling
- Production-grade observability with OpenTelemetry

### 5.2 — Initialize the Hosted Agent Project

Open a terminal and create a new directory:

```bash
mkdir pharma-hosted-agent && cd pharma-hosted-agent
```

Initialize from the Agent Framework sample:

```bash
azd ai agent init -m "https://github.com/microsoft-foundry/foundry-samples/blob/main/samples/python/hosted-agents/agent-framework/responses/01-basic/azure.yaml" --deploy-mode code
```

When prompted:
| Prompt | Your Selection |
|--------|---------------|
| **Agent name** | `pharma-ops-agent` |
| **Foundry Project** | Use existing → `proj-pharma-ops` |
| **Model** | `gpt-4.1` |
| **Model SKU** | GlobalStandard |
| **Deployment capacity** | 10 |

After initialization:
```bash
cd pharma-ops-agent
```

### 5.3 — Customize the Agent Code

Edit `main.py` to implement your Pharma Commercial Operations agent:

```python
import os
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
from microsoft.agents.framework import Agent, AgentBuilder
from microsoft.agents.framework.tools import tool

PROJECT_ENDPOINT = os.environ["AZURE_AI_PROJECT_ENDPOINT"]
MODEL_DEPLOYMENT = os.environ.get("AZURE_AI_MODEL_DEPLOYMENT_NAME", "gpt-4.1")


@tool
def get_pipeline_status(therapeutic_area: str) -> str:
    """Get the current pipeline status for a therapeutic area.
    
    Args:
        therapeutic_area: The therapeutic area to query (e.g., Oncology, Immunology)
    """
    pipeline_data = {
        "Oncology": "2 drugs in Phase 3 (ZV-4521: NSCLC, ZV-3390: Pancreatic Cancer), revenue forecast $3.9B",
        "Immunology": "1 drug Phase 2 (ZV-8832: RA), 1 Phase 3 (ZV-2245: PsA), forecast $3.0B",
        "Neurology": "1 drug Phase 3 (ZV-1104: Alzheimer's), forecast $3.2B — highest single-asset value",
        "Cardiovascular": "1 drug Phase 2 (ZV-6677: Heart Failure), forecast $950M",
        "Rare Disease": "1 drug Phase 3 (ZV-9901: SMA), approval expected Q4 2026, forecast $800M",
    }
    return pipeline_data.get(therapeutic_area, f"No pipeline data found for {therapeutic_area}")


@tool
def calculate_market_share_trend(product: str) -> str:
    """Calculate market share trend for a product over recent quarters.
    
    Args:
        product: The product name to analyze
    """
    trends = {
        "Zelvorix": "Q1: 23.5% → Q2: 24.1% → Q3: 25.3% | Growth: +1.8pp over 3 quarters | Trajectory: Strong upward",
        "Revumab": "Q1: 18.2% → Q2: 19.0% → Q3: 19.8% | Growth: +1.6pp over 3 quarters | Trajectory: Steady growth",
        "Cognivex": "Q1: 12.8% → Q2: 13.5% → Q3: 14.1% | Growth: +1.3pp over 3 quarters | Trajectory: Moderate growth",
        "Cardivant": "Q1: 9.4% → Q2: 9.7% → Q3: 10.1% | Growth: +0.7pp over 3 quarters | Trajectory: Slow growth",
    }
    return trends.get(product, f"No market share data found for {product}")


def build_agent() -> Agent:
    return (
        AgentBuilder()
        .with_model(MODEL_DEPLOYMENT)
        .with_instructions("""You are the Zava Pharma Commercial Operations AI Analyst — a production-grade hosted agent.

You help commercial operations teams with:
- Pipeline status and revenue forecasting
- Market share analysis and competitive intelligence
- Regulatory milestone tracking
- Quarterly business review preparation

Always be data-driven, cite specific numbers, and flag uncertainties.""")
        .with_tools([get_pipeline_status, calculate_market_share_trend])
        .build()
    )


agent = build_agent()
```

### 5.4 — Provision Azure Resources

```bash
azd provision
```

This creates:
- Container Registry for your agent image
- Application Insights for tracing
- Managed identity with appropriate RBAC roles

### 5.5 — Test Locally

```bash
azd ai agent run
```

This:
1. Creates a Python virtual environment
2. Installs dependencies
3. Launches the agent locally
4. Opens the **Agent Inspector** in your browser

In the Agent Inspector, test your agent:
- *"What's the pipeline status for Oncology?"*
- *"Show me the market share trend for Zelvorix"*
- *"Prepare a summary comparing all therapeutic areas by revenue potential"*

### 5.6 — Deploy to Foundry Agent Service

When satisfied with local testing:

```bash
azd deploy
```

The output provides:
```
Deploying services (azd deploy)

  Done: Deploying service pharma-ops-agent
  - Agent playground (portal): https://ai.azure.com/.../build/agents/pharma-ops-agent/build?version=1
  - Agent endpoint: https://ai-account-<name>.services.ai.azure.com/api/projects/<project>/agents/pharma-ops-agent/versions/1
```

### 5.7 — Invoke the Deployed Agent

Test the production deployment:

```bash
azd ai agent invoke "What is the current pipeline status for our Oncology therapeutic area and how does Zelvorix's market share compare to last quarter?"
```

### 5.8 — Test from the Foundry Portal Playground

1. Open the Agent playground link from the deploy output
2. Navigate to **Build** → **Agents** → `pharma-ops-agent`
3. In the **Chat** panel, send test messages
4. Verify tool calls execute correctly in the hosted environment

### 5.9 — Checkpoint

✅ You initialized a hosted agent project with Azure Developer CLI  
✅ You customized the agent with pharma-specific tools  
✅ You tested locally with the Agent Inspector  
✅ You deployed to Foundry Agent Service  
✅ You invoked the agent both via CLI and the portal Playground  

> **📖 Reference:** [Quickstart: Deploy your first hosted agent](https://learn.microsoft.com/en-us/azure/foundry/agents/quickstarts/quickstart-hosted-agent?pivots=azd)

---

## Lab 6: Monitoring, Evaluation & Observability

**Duration:** 60 minutes  
**Objective:** Set up production-grade monitoring, distributed tracing, and continuous evaluation for your deployed agent. This is what separates a prototype from a production system.

### 6.1 — View Traces for Your Hosted Agent

Your hosted agent already emits traces via the integrated Microsoft OpenTelemetry distro. Let's view them.

1. Generate trace data by invoking the agent:
```bash
azd ai agent invoke "Summarize our complete pharma portfolio performance including all therapeutic areas, top products, and pipeline outlook."
```

2. In the **Foundry portal**, go to **Build** → **Agents**
3. Select the **Traces** tab at the top
4. Find your trace in the list (you can search by time range)

### 6.2 — Analyze the Trace Waterfall

Click on a trace to see the **Trajectory** view:

- **Root span:** The full agent invocation (HTTP request → response)
- **Child spans:** Model inference calls, tool executions, token usage
- **Input/Output:** See exact prompts sent to the model and responses received
- **Latency breakdown:** Identify bottlenecks (model inference vs. tool execution)

Observe:
- How long each tool call takes
- Token counts for input/output
- The complete reasoning chain

### 6.3 — Open the Agent Monitoring Dashboard

1. Go to **Build** → **Agents** → Select your agent
2. Click the **Monitor** tab
3. Review the dashboard:

| Metric | What to Look For |
|--------|-----------------|
| **Token Usage** | Total tokens consumed — optimize verbose prompts |
| **Latency** | Response time — should be < 10s for interactive use |
| **Run Success Rate** | Target > 95% for production |
| **Evaluation Metrics** | Quality scores from continuous evaluation |

### 6.4 — Set Up Continuous Evaluation

Now set up automated quality checks that run on every agent response.

```bash
pip install "azure-ai-projects>=2.0.0" python-dotenv
```

Create `setup_continuous_eval.py`:

```python
import os
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    PromptAgentDefinition,
    EvaluationRule,
    ContinuousEvaluationRuleAction,
    EvaluationRuleFilter,
    EvaluationRuleEventType,
)

load_dotenv()

endpoint = os.environ["AZURE_AI_PROJECT_ENDPOINT"]
agent_name = os.environ.get("AZURE_AI_AGENT_NAME", "pharma-ops-agent")
model_name = os.environ.get("AZURE_AI_MODEL_DEPLOYMENT_NAME", "gpt-4.1")

credential = DefaultAzureCredential()
project_client = AIProjectClient(endpoint=endpoint, credential=credential)
openai_client = project_client.get_openai_client()

# Define evaluation criteria for pharma use case
# Using multiple evaluators relevant to pharma compliance
testing_criteria = [
    # Safety: Detect any violent or harmful content
    {"type": "azure_ai_evaluator", "name": "violence_check", "evaluator_name": "builtin.violence"},
    # Quality: Ensure responses are grounded in provided data
    {"type": "azure_ai_evaluator", "name": "groundedness_check", "evaluator_name": "builtin.groundedness"},
    # Quality: Ensure responses are relevant to the query
    {"type": "azure_ai_evaluator", "name": "relevance_check", "evaluator_name": "builtin.relevance"},
]

# Create the evaluation definition
data_source_config = {"type": "azure_ai_source", "scenario": "responses"}
eval_object = openai_client.evals.create(
    name="Pharma Agent Continuous Evaluation",
    data_source_config=data_source_config,
    testing_criteria=testing_criteria,
)
print(f"✅ Evaluation created: {eval_object.id} ({eval_object.name})")

# Create continuous evaluation rule
continuous_eval_rule = project_client.evaluation_rules.create_or_update(
    id="pharma-agent-continuous-eval",
    evaluation_rule=EvaluationRule(
        display_name="Pharma Ops Agent Quality Gate",
        description="Continuous evaluation for groundedness, relevance, and safety on all agent responses",
        action=ContinuousEvaluationRuleAction(
            eval_id=eval_object.id,
            max_hourly_runs=100,
        ),
        event_type=EvaluationRuleEventType.RESPONSE_COMPLETED,
        filter=EvaluationRuleFilter(agent_name=agent_name),
        enabled=True,
    ),
)
print(f"✅ Continuous evaluation rule created: {continuous_eval_rule.id}")
print(f"   Rule: {continuous_eval_rule.display_name}")
print(f"   Evaluators: Violence, Groundedness, Relevance")
print(f"   Max hourly runs: 100")
```

Run it:
```bash
python setup_continuous_eval.py
```

### 6.5 — Generate Traffic and Verify Evaluation Results

Send several queries to generate evaluation data:

```bash
azd ai agent invoke "What is the revenue forecast for ZV-4521?"
azd ai agent invoke "Compare Zelvorix market share trends over the last 3 quarters"
azd ai agent invoke "What regulatory milestones are pending for Revumab?"
azd ai agent invoke "Create a risk assessment for our neurology pipeline"
```

### 6.6 — Review Evaluation Results

1. In the Foundry portal, go to **Build** → **Agents** → Select your agent → **Monitor** tab
2. After a few minutes, evaluation charts should populate:
   - **Groundedness scores** — Are responses backed by data?
   - **Relevance scores** — Are responses on-topic?
   - **Safety scores** — Are responses free of harmful content?

3. Check evaluation runs programmatically:

```python
eval_run_list = openai_client.evals.runs.list(
    eval_id=eval_object.id,
    order="desc",
    limit=10,
)

for run in eval_run_list.data:
    print(f"Run: {run.id} | Status: {run.status} | Created: {run.created_at}")
    if run.report_url:
        print(f"  Report: {run.report_url}")
```

### 6.7 — Understand Built-in Evaluators for Pharma

Review the evaluators most relevant for a pharma AI agent:

| Evaluator Category | Evaluator | Pharma Importance |
|-------------------|-----------|-------------------|
| **RAG Quality** | Groundedness | Critical — drug info must be grounded in data, not hallucinated |
| **RAG Quality** | Relevance | High — responses must address the actual clinical/business question |
| **RAG Quality** | Retrieval | High — ensure the right documents are being retrieved |
| **Safety** | Violence | Required — must not generate harmful medical content |
| **Safety** | Protected Materials | Required — must not expose copyrighted clinical data |
| **Safety** | Sensitive Data Leakage | Critical — must not expose patient data or trade secrets |
| **Agent Quality** | Tool Call Accuracy | High — drug interaction checks must use correct parameters |
| **Agent Quality** | Task Adherence | Medium — agent should follow pharma compliance guidelines |
| **Agent Quality** | Intent Resolution | Medium — correctly interpret commercial ops questions |

### 6.8 — Stream Live Logs (Optional)

Monitor the agent in real-time:

```bash
azd ai agent monitor --follow
```

This streams container logs as requests come in, showing:
- Incoming requests
- Tool call decisions
- Model inference calls
- Response generation

### 6.9 — Checkpoint

✅ You viewed distributed traces for your hosted agent  
✅ You analyzed the trace waterfall to understand agent behavior  
✅ You explored the Agent Monitoring Dashboard  
✅ You set up continuous evaluation with quality and safety evaluators  
✅ You generated traffic and verified evaluation results  
✅ You understand which evaluators are critical for pharma compliance  

> **📖 References:**  
> - [Monitor Agents Dashboard](https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/how-to-monitor-agents-dashboard?tabs=python)  
> - [Trace Your Hosted Agent](https://learn.microsoft.com/en-us/azure/foundry/observability/quickstarts/quickstart-tracing-hosted-agent?tabs=azd)  
> - [Built-in Evaluators Reference](https://learn.microsoft.com/en-us/azure/foundry/concepts/built-in-evaluators)

---

## Summary: The Microsoft Foundry Value Proposition

Congratulations! You've completed the full lab series. Here's what you built and the platform capabilities you experienced:

### Your Journey

```
Lab 1: Explore          → Understood the unified platform
Lab 2: Create Agent     → Built a pharma AI analyst (declarative)
Lab 3: Ground in Data   → Connected to enterprise knowledge (Foundry IQ)
Lab 4: Add Tools        → Extended with Code Interpreter + Azure Functions
Lab 5: Go Production    → Deployed as hosted agent (Microsoft Agent Framework)
Lab 6: Observe & Eval   → Production monitoring + continuous quality gates
```

### Microsoft Foundry Differentiated Value for Pharma

| Capability | Pharma Value |
|-----------|-------------|
| **Unified Platform** | Single pane of glass for all AI operations — simplifies governance in regulated environments |
| **1,900+ Models** | Choose the right model for each task — reasoning for drug interactions, speed for commercial queries |
| **Foundry IQ** | Citation-backed answers critical for regulatory compliance and audit trails |
| **Tool Catalog (1,400+)** | Connect to clinical systems, ERP, regulatory databases without custom integration |
| **Code Interpreter** | On-demand data analysis for quarterly reviews, pipeline forecasting, market analysis |
| **Hosted Agents** | Production-grade deployment with auto-scaling for enterprise workloads |
| **Built-in Evaluators** | Continuous quality monitoring — catch hallucinations, safety issues, compliance violations |
| **Enterprise Controls** | RBAC, networking, Azure Policy — meets pharma security and compliance requirements |
| **Tracing & Observability** | Full audit trail of every agent decision — essential for GxP compliance |

### Next Steps

- **Publish to Teams:** Share your agent with commercial ops teams via Microsoft 365
- **Add Guardrails:** Configure content safety filters for pharma compliance
- **Multi-Agent Workflows:** Create specialized agents (regulatory, commercial, medical) that collaborate
- **Fine-Tune:** Customize a model on your pharma-specific terminology
- **Red Teaming:** Run adversarial tests to validate safety before production launch

---

*Lab Version: 1.0 | Platform: Microsoft Foundry (New) | Last Updated: July 2026*
