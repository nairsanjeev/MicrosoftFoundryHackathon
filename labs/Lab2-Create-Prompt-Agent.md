# Lab 2: Create a Pharma Commercial Operations Agent

**Duration:** 45 minutes  
**Objective:** Create a prompt agent via the Foundry Portal UI and optionally via Python SDK. This agent will serve as your "Pharma Commercial Operations Analyst."

[← Back to Main Page](../README.md) | [Previous: Lab 1](Lab1-Explore-Foundry-Portal.md) | [Next: Lab 3 →](Lab3-Foundry-IQ-Knowledge.md)

---

## 2.1 — Create the Agent via Foundry Portal UI

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

---

## 2.2 — Test the Agent in the Playground

In the Chat panel on the right side:

1. **First message:** *"What factors typically drive commercial success for a newly launched biologic in oncology?"*
2. **Follow-up:** *"How would you structure a quarterly business review for a pharma commercial team?"*
3. **Test multi-turn:** *"Can you create a template agenda for that QBR?"*

Observe how the agent:
- Maintains conversation context across turns
- Provides structured, business-relevant responses
- Follows the instruction guidelines

---

## 2.3 — (Optional) Create the Agent via Python SDK

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

---

## 2.4 — Chat with the Agent via Python SDK

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

---

## 2.5 — Checkpoint

✅ You have created a Pharma Commercial Operations AI Analyst agent  
✅ You tested it in the Foundry Playground  
✅ (Optional) You created and tested it via Python SDK  

---

## References

- [Quickstart: Create a prompt agent](https://learn.microsoft.com/en-us/azure/foundry/agents/quickstarts/prompt-agent?tabs=python)
- [Agent Development Lifecycle](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/development-lifecycle)
- [What is Foundry Agent Service?](https://learn.microsoft.com/en-us/azure/foundry/agents/overview)

---

[← Back to Main Page](../README.md) | [Previous: Lab 1](Lab1-Explore-Foundry-Portal.md) | [Next: Lab 3 — Foundry IQ Knowledge →](Lab3-Foundry-IQ-Knowledge.md)
