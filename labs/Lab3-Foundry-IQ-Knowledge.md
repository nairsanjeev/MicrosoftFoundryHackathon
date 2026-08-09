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

You need to upload the pharma data files to Azure Blob Storage so Foundry IQ can index them.

### Step 1: Open the Storage Account

1. In the **Azure Portal** (portal.azure.com), navigate to your resource group `rg-foundry-lab-shared`
2. Click on the **Storage Account** (name starts with `st...`)

### Step 2: Create the Container

1. In the left menu, click **Containers** (under Data storage)
2. Click **+ Container**
3. Set the name to: `pharma-commercial-data`
4. Leave access level as **Private**
5. Click **Create**

### Step 3: Upload the CSV Files

1. Click on the newly created `pharma-commercial-data` container
2. Click **Upload**
3. Browse and select all three CSV files you downloaded in Step 3.2:
   - `drug_pipeline.csv`
   - `quarterly_revenue.csv`
   - `regulatory_milestones.csv`
4. Click **Upload**
5. Verify all three files appear in the container

> **💡 Tip:** You can also upload via Azure CLI if you prefer:
> ```bash
> az storage blob upload-batch \
>   --account-name <your-storage-account> \
>   --destination pharma-commercial-data \
>   --source ./data/ \
>   --auth-mode login
> ```

---

## 3.4 — Create a Knowledge Base with Foundry IQ

Your lab environment has a **pre-created Foundry IQ resource** (Azure AI Search) with Managed Identity already configured for secure, keyless authentication.

### Step 1: Connect to the Search Resource

1. In the **Foundry portal** (ai.azure.com), open your project (e.g., `proj-pharma-john-doe`)
2. In the left navigation, click **Knowledge**
3. Click **+ New knowledge base**
4. In the **Foundry IQ resource** dropdown, select the pre-created resource (name starts with `srch...`)

   > **⚠️ Important:** Do NOT click "Create new resource" — use the existing one to avoid capacity issues.

5. In the **Auth Type** dropdown, select **Managed Identity**

   > **🔒 Why Managed Identity?** There are three auth options:
   > - **API Key** — simple but less secure (keys can leak)
   > - **Entra ID** — user-based auth (tied to your login session)
   > - **Managed Identity** — the most secure option. The Foundry resource authenticates to Search using its system-assigned identity with no secrets to manage or rotate.

6. Click **Connect**

### Step 2: Configure Basic Settings

| Setting | Value |
|---------|-------|
| **Name** | `pharma-commercial-kb` |
| **Chat completions model** | `gpt-5` (or `gpt-4.1` if available) |
| **Output mode** | Answer synthesis |
| **Retrieval reasoning effort** | Minimal |

Add **Retrieval Instructions**:
```
Use this knowledge base for questions about drug pipeline, revenue performance, 
market share, and regulatory milestones. Always cite specific data points 
including quarter, therapeutic area, and drug names.
```

Add **Answer Instructions**:
```
Provide concise, data-driven answers. Include specific numbers from the data.
Format financial figures in millions. Always state the quarter or time period 
for any metrics cited.
```

### Step 3: Understanding Knowledge Source Types

After basic configuration, you need to add a **Knowledge Source** — this is where your actual data lives. Click **Add sources** to see the available options:

![Knowledge Source Options](../presentations/knowledge-source-options.png)

| Source Type | How It Works | Index Creation | Best For |
|-------------|-------------|----------------|----------|
| **Azure Blob Storage** | Points to a blob container. Foundry IQ **automatically creates** a search index with an indexer pipeline (data source → skillset → indexer → index). | ✅ Auto-created | Raw files in storage (CSV, PDF, DOCX). **Best for this lab.** |
| **Upload files** *(Preview)* | Upload files directly to Azure AI Search. No external storage needed. | ✅ Auto-created | Quick testing with a few files. Limited to smaller datasets. |
| **Azure AI Search Index** | Wraps an **existing** search index that you already created with the proper schema. | ❌ Must pre-exist | Advanced scenarios where you control the index schema, chunking, and vectorization. |
| **Web** | Real-time grounding from Bing. No indexing — queries the web at runtime. | N/A (remote) | Current events, public knowledge not in your data. |
| **Work IQ** *(Preview)* | Organizational intelligence from Microsoft 365 (emails, docs, Teams). | N/A (remote) | Internal company knowledge from M365. |
| **Fabric IQ (OneLake Catalog)** *(Preview)* | Grounds responses from Fabric lakehouses and ontologies. | N/A (remote) | Enterprise data already in Microsoft Fabric. |

> **💡 Key Insight:** The difference between "Azure Blob Storage" and "Azure AI Search Index" is crucial:
> - **Blob Storage** = "here's my raw data, please index it for me" (end-to-end automated)
> - **AI Search Index** = "I already built the index, just query it" (you manage the pipeline)
>
> For this lab, we use **Azure Blob Storage** because our CSV files are already in blob storage and we want Foundry IQ to handle all the indexing automatically.

### Step 4: Add Azure Blob Storage as Knowledge Source

1. Click **Add sources** → select **Azure Blob Storage**
2. Configure the knowledge source:

| Setting | Value |
|---------|-------|
| **Name** | `ks-pharma-blob` (or keep the auto-generated name) |
| **Description** | `Pharmaceutical commercial data: drug pipeline, revenue, regulatory milestones` |
| **Storage account** | Select the lab storage account (starts with `st...`) |
| **Container name** | `pharma-commercial-data` |
| **Authentication type** | Managed Identity |
| **Content extraction mode** | Minimal |
| **Embedding model** | *(leave empty — not required for CSV data)* |
| **Chat completions model** | *(leave empty or select gpt-5)* |

3. Click **Create**

> **⏱️ Note:** After creation, Foundry IQ will automatically build an indexer pipeline and begin indexing your CSV files. This may take 1-2 minutes. The status will show "Active" when complete.

### Step 5: Save the Knowledge Base

1. Verify your knowledge source shows **Active** status in the list
2. Click **Save knowledge base** (top-right corner)

---

## 3.5 — Connect the Knowledge Base to Your Agent

1. Go to **Agents** in the left navigation → Select your `ZavaCommOpsAnalyst` agent
2. In the agent configuration panel, scroll to the **Knowledge** section
3. Click **+ Add knowledge base**
4. Select `pharma-commercial-kb` from the list
5. Click **Save** to update the agent

> **💡 Tip:** The Knowledge section may also appear under the "Tools" panel depending on your portal version. Look for either "Knowledge" or "Foundry IQ" as the tool type.

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

✅ You uploaded pharma commercial data to Azure Blob Storage  
✅ You created a Foundry IQ knowledge base using the pre-created search resource  
✅ You grounded your agent in proprietary enterprise data  
✅ You verified citation-backed, accurate responses  

---

## References

- [Create a knowledge base in Azure AI Search](https://learn.microsoft.com/en-us/azure/search/agentic-retrieval-how-to-create-knowledge-base?tabs=rbac%2C2026-05-01-preview&pivots=csharp)
- [What is Foundry IQ?](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/what-is-foundry-iq)
- [Agentic Retrieval Overview](https://learn.microsoft.com/en-us/azure/search/agentic-retrieval-overview)

---

[← Back to Main Page](../README.md) | [Previous: Lab 2](Lab2-Create-Prompt-Agent.md) | [Next: Lab 4 — Tool Calling →](Lab4-Tool-Calling.md)
