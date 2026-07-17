# Lab 4: Tool Calling — Azure Functions & Code Interpreter

**Duration:** 60 minutes  
**Objective:** Extend your agent with real-world capabilities by adding tool calling. You'll create an Azure Function for a custom pharma action and use Code Interpreter for data analysis and visualization.

[← Back to Main Page](../README.md) | [Previous: Lab 3](Lab3-Foundry-IQ-Knowledge.md) | [Next: Lab 5 →](Lab5-Hosted-Agent-Deployment.md)

---

## Part A: Code Interpreter — Pharma Data Visualization

### 4A.1 — Enable Code Interpreter on Your Agent

1. In the Foundry portal, go to **Build** → **Agents** → Select `ZavaCommOpsAnalyst`
2. Under **Tools**, click **+ Add Tool**
3. Select **Code Interpreter**
4. **Save** a new version of the agent

---

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

---

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

---

## Part B: Azure Functions — Custom Pharma Tool Call

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

---

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

---

### 4B.3 — Test Tool Calling in the Playground

Ask questions that trigger tool calls:

1. *"A physician is considering adding Zelvorix to a patient already on Warfarin. Are there any drug interactions I should be aware of?"*

   **Expected:** Agent calls `check_drug_interaction`, receives the High severity response, and provides the clinical recommendation.

2. *"Check if Revumab and Methotrexate can be used together safely."*

   **Expected:** Agent calls the function and reports the Moderate interaction with monitoring recommendations.

3. *"Our commercial team needs a summary of all known interaction profiles for Zelvorix. Check interactions with Revumab, Warfarin, and Methotrexate."*

   **Expected:** Agent makes multiple tool calls and synthesizes a comprehensive interaction profile.

---

### 4B.4 — Observe Tool Calling Behavior

In the Playground, click on the **response details** to see:
- Which tools were called
- The parameters sent to each tool
- The tool's response
- How the agent incorporated the tool output into its answer

---

## Checkpoint

✅ You enabled Code Interpreter for data analysis and visualization  
✅ You created an Azure Function for drug interaction checking  
✅ You added the function as a tool to your agent  
✅ You tested multi-tool scenarios in the Playground  
✅ You observed how the agent decides when and how to call tools  

---

## References

- [Tool Catalog Overview](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/tool-catalog#all-built-in-tools)
- [Code Interpreter Tool](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/tools/code-interpreter?tabs=prompt-agents&pivots=python)
- [Azure Functions Tool](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/tools/azure-functions)
- [Function Calling](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/tools/function-calling)

---

[← Back to Main Page](../README.md) | [Previous: Lab 3](Lab3-Foundry-IQ-Knowledge.md) | [Next: Lab 5 — Hosted Agent Deployment →](Lab5-Hosted-Agent-Deployment.md)
