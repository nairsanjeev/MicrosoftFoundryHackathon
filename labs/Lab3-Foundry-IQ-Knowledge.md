# Lab 3: Connect with Foundry IQ Knowledge Base

**Duration:** 60 minutes  
**Objective:** Upload pharma-relevant data to Azure Storage, create a Foundry IQ knowledge base, and ground your agent's responses in proprietary enterprise data — experiencing citation-backed, permission-aware retrieval.

[← Back to Main Page](../README.md) | [Previous: Lab 2](Lab2-Create-Prompt-Agent.md) | [Next: Lab 4 →](Lab4-Tool-Calling.md)

---

## 3.1 — Understand Foundry IQ

**Foundry IQ** is the managed knowledge layer that transforms enterprise content into reusable, permission-aware knowledge bases. Key differentiators:

- **Agentic Retrieval:** AI-powered query planning that understands intent, not just keywords
- **Citation-Backed Answers:** Every response includes source citations for auditability
- **Permission-Aware:** Respects document-level access controls
- **Multi-Source:** Combines data from blob storage, SharePoint, databases, and web sources

---

## 3.2 — Download Pharma Data Files

The sample data files are pre-created and available in the [`data/`](../data/) folder of this repository. Download all three files to your local machine:

| File | Description | Download |
|------|-------------|----------|
| `drug_pipeline.csv` | Pipeline drugs across therapeutic areas with phase, indication, and revenue forecasts | [Download](../data/drug_pipeline.csv) |
| `quarterly_revenue.csv` | Q1-Q3 2026 revenue, units sold, and market share by product | [Download](../data/quarterly_revenue.csv) |
| `regulatory_milestones.csv` | FDA/EMA regulatory milestones and statuses | [Download](../data/regulatory_milestones.csv) |

**To download all files at once**, clone the repo or download the `data/` folder:
```bash
git clone https://github.com/nairsanjeev/MicrosoftFoundryHackathon.git
cd MicrosoftFoundryHackathon/data
```

### What's in the data?

- **Drug Pipeline** — 8 drugs across 6 therapeutic areas (Oncology, Immunology, Neurology, Cardiovascular, Rare Disease, Infectious Disease) in various clinical phases
- **Quarterly Revenue** — 3 quarters of revenue data for 4 marketed products (Zelvorix, Revumab, Cognivex, Cardivant)
- **Regulatory Milestones** — FDA and EMA approval timelines, submissions, and upcoming PDUFA dates

---

## 3.3 — Upload Data to Azure Storage

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

---

## 3.4 — Create a Knowledge Source in Azure AI Search

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

---

## 3.5 — Connect the Knowledge Base to Your Agent

1. Go to **Build** → **Agents** → Select `ZavaCommOpsAnalyst`
2. In the agent configuration, add the **Foundry IQ** knowledge base:
   - Under **Tools**, click **+ Add Tool**
   - Select **Azure AI Search** or **Foundry IQ Knowledge**
   - Select `pharma-commercial-kb`
3. **Save** a new version of the agent

---

## 3.6 — Test Knowledge-Grounded Responses

In the Agent Playground, ask questions that require the uploaded data:

1. *"What is our top-performing oncology product and how has its market share trended over the last 3 quarters?"*
   
   **Expected:** The agent should cite Zelvorix with specific market share percentages (23.5% → 24.1% → 25.3%)

2. *"Which drugs in our pipeline are closest to FDA approval? What are the expected revenue impacts?"*
   
   **Expected:** Should reference ZV-9901 (Q4 2026), ZV-4521 and ZV-2245 (Q1 2027) with revenue forecasts

3. *"Summarize the regulatory status of Revumab across all regions."*
   
   **Expected:** Should cite BLA submission, advisory committee date, and PDUFA information

4. *"Compare Q1 vs Q3 2026 total revenue across all therapeutic areas."*
   
   **Expected:** Should calculate totals from the quarterly_revenue data with specific figures

---

## 3.7 — Observe the Foundry IQ Difference

Notice how the responses:
- ✅ Include **citations** pointing to specific data files
- ✅ Contain **specific numbers** from your uploaded CSVs
- ✅ Synthesize across **multiple documents** when needed
- ✅ Decline to answer when data **isn't available** (no hallucination)

> **💡 Pharma Value:** In pharma, accuracy is non-negotiable. Foundry IQ ensures your agent's answers are grounded in actual company data with full auditability — critical for regulatory compliance and executive decision-making.

---

## 3.8 — Checkpoint

✅ You uploaded pharma commercial data to Azure Storage  
✅ You created a Foundry IQ knowledge base with agentic retrieval  
✅ You grounded your agent in proprietary enterprise data  
✅ You verified citation-backed, accurate responses  

---

## References

- [Create a knowledge base in Azure AI Search](https://learn.microsoft.com/en-us/azure/search/agentic-retrieval-how-to-create-knowledge-base?tabs=rbac%2C2026-05-01-preview&pivots=csharp)
- [What is Foundry IQ?](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/what-is-foundry-iq)
- [Agentic Retrieval Overview](https://learn.microsoft.com/en-us/azure/search/agentic-retrieval-overview)

---

[← Back to Main Page](../README.md) | [Previous: Lab 2](Lab2-Create-Prompt-Agent.md) | [Next: Lab 4 — Tool Calling →](Lab4-Tool-Calling.md)
