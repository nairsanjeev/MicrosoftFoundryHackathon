# Lab 6: Monitoring, Evaluation & Observability

**Duration:** 60 minutes  
**Objective:** Set up production-grade monitoring, distributed tracing, and continuous evaluation for your deployed agent. This is what separates a prototype from a production system.

[← Back to Main Page](../README.md) | [Previous: Lab 5](Lab5-Hosted-Agent-Deployment.md)

---

## 6.1 — View Traces for Your Hosted Agent

Your hosted agent already emits traces via the integrated Microsoft OpenTelemetry distro. Let's view them.

1. Generate trace data by invoking the agent:
```bash
azd ai agent invoke "Summarize our complete pharma portfolio performance including all therapeutic areas, top products, and pipeline outlook."
```

2. In the **Foundry portal**, go to **Build** → **Agents**
3. Select the **Traces** tab at the top
4. Find your trace in the list (you can search by time range)

---

## 6.2 — Analyze the Trace Waterfall

Click on a trace to see the **Trajectory** view:

- **Root span:** The full agent invocation (HTTP request → response)
- **Child spans:** Model inference calls, tool executions, token usage
- **Input/Output:** See exact prompts sent to the model and responses received
- **Latency breakdown:** Identify bottlenecks (model inference vs. tool execution)

Observe:
- How long each tool call takes
- Token counts for input/output
- The complete reasoning chain

---

## 6.3 — Open the Agent Monitoring Dashboard

1. Go to **Build** → **Agents** → Select your agent
2. Click the **Monitor** tab
3. Review the dashboard:

| Metric | What to Look For |
|--------|-----------------|
| **Token Usage** | Total tokens consumed — optimize verbose prompts |
| **Latency** | Response time — should be < 10s for interactive use |
| **Run Success Rate** | Target > 95% for production |
| **Evaluation Metrics** | Quality scores from continuous evaluation |

---

## 6.4 — Set Up Continuous Evaluation

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

---

## 6.5 — Generate Traffic and Verify Evaluation Results

Send several queries to generate evaluation data:

```bash
azd ai agent invoke "What is the revenue forecast for ZV-4521?"
azd ai agent invoke "Compare Zelvorix market share trends over the last 3 quarters"
azd ai agent invoke "What regulatory milestones are pending for Revumab?"
azd ai agent invoke "Create a risk assessment for our neurology pipeline"
```

---

## 6.6 — Review Evaluation Results

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

---

## 6.7 — Understand Built-in Evaluators for Pharma

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

---

## 6.8 — Stream Live Logs (Optional)

Monitor the agent in real-time:

```bash
azd ai agent monitor --follow
```

This streams container logs as requests come in, showing:
- Incoming requests
- Tool call decisions
- Model inference calls
- Response generation

---

## Checkpoint

✅ You viewed distributed traces for your hosted agent  
✅ You analyzed the trace waterfall to understand agent behavior  
✅ You explored the Agent Monitoring Dashboard  
✅ You set up continuous evaluation with quality and safety evaluators  
✅ You generated traffic and verified evaluation results  
✅ You understand which evaluators are critical for pharma compliance  

---

## References

- [Monitor Agents Dashboard](https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/how-to-monitor-agents-dashboard?tabs=python)
- [Trace Your Hosted Agent](https://learn.microsoft.com/en-us/azure/foundry/observability/quickstarts/quickstart-tracing-hosted-agent?tabs=azd)
- [Built-in Evaluators Reference](https://learn.microsoft.com/en-us/azure/foundry/concepts/built-in-evaluators)
- [Agent Tracing Overview](https://learn.microsoft.com/en-us/azure/foundry/observability/concepts/trace-agent-concept)

---

## Summary: The Microsoft Foundry Value Proposition

Congratulations! You've completed the full lab series. Here's what you built:

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

[← Back to Main Page](../README.md) | [Previous: Lab 5](Lab5-Hosted-Agent-Deployment.md)
