# Lab 5: Deploy a Hosted Agent with Microsoft Agent Framework

**Duration:** 60 minutes  
**Objective:** Take your agent from a playground prototype to a production-grade hosted agent using the Microsoft Agent Framework and Azure Developer CLI (azd). This is the path to enterprise deployment.

[← Back to Main Page](../README.md) | [Previous: Lab 4](Lab4-Tool-Calling.md) | [Next: Lab 6 →](Lab6-Monitoring-Evaluation.md)

---

## 5.1 — Understand Hosted Agents

**Prompt Agents** (Labs 2-4) are declarative and run server-side in Foundry. **Hosted Agents** are containerized applications you write with the Microsoft Agent Framework, giving you:

- Full control over agent logic and orchestration
- Custom tool implementations in your code
- Local testing and debugging before deployment
- Container-based deployment with auto-scaling
- Production-grade observability with OpenTelemetry

---

## 5.2 — Initialize the Hosted Agent Project

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

---

## 5.3 — Customize the Agent Code

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

---

## 5.4 — Provision Azure Resources

```bash
azd provision
```

This creates:
- Container Registry for your agent image
- Application Insights for tracing
- Managed identity with appropriate RBAC roles

---

## 5.5 — Test Locally

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

---

## 5.6 — Deploy to Foundry Agent Service

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

---

## 5.7 — Invoke the Deployed Agent

Test the production deployment:

```bash
azd ai agent invoke "What is the current pipeline status for our Oncology therapeutic area and how does Zelvorix's market share compare to last quarter?"
```

---

## 5.8 — Test from the Foundry Portal Playground

1. Open the Agent playground link from the deploy output
2. Navigate to **Build** → **Agents** → `pharma-ops-agent`
3. In the **Chat** panel, send test messages
4. Verify tool calls execute correctly in the hosted environment

---

## Checkpoint

✅ You initialized a hosted agent project with Azure Developer CLI  
✅ You customized the agent with pharma-specific tools  
✅ You tested locally with the Agent Inspector  
✅ You deployed to Foundry Agent Service  
✅ You invoked the agent both via CLI and the portal Playground  

---

## References

- [Quickstart: Deploy your first hosted agent](https://learn.microsoft.com/en-us/azure/foundry/agents/quickstarts/quickstart-hosted-agent?pivots=azd)
- [What are hosted agents?](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/hosted-agents)
- [Agent Development Lifecycle](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/development-lifecycle)
- [Python hosted agent samples](https://github.com/microsoft-foundry/foundry-samples/tree/main/samples/python/hosted-agents)

---

[← Back to Main Page](../README.md) | [Previous: Lab 4](Lab4-Tool-Calling.md) | [Next: Lab 6 — Monitoring & Evaluation →](Lab6-Monitoring-Evaluation.md)
