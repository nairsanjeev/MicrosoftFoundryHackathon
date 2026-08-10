# Lab 1B: Deploy a Model

**Duration:** 15 minutes  
**Objective:** Deploy your own GPT-5-mini model in the Foundry portal. You'll use this model for all subsequent labs.

[← Back to Main Page](../README.md) | [Previous: Lab 1](Lab1-Explore-Foundry-Portal.md) | [Next: Lab 2 →](Lab2-Create-Prompt-Agent.md)

---

## 1B.1 — Navigate to Deployments

1. In the Foundry portal, open your project
2. In the left navigation, click **Deployments**
3. You'll see any existing model deployments (e.g., `gpt-4.1` pre-deployed by your admin)

---

## 1B.2 — Deploy GPT-5-mini

1. Click **+ Deploy model** → **Deploy base model**
2. In the model catalog, search for **`gpt-5-mini`**
3. Select it and click **Confirm**
4. Configure the deployment:

| Setting | Value |
|---------|-------|
| **Deployment name** | `gpt-5-mini` |
| **Deployment type** | Global Standard |
| **Tokens per Minute Rate Limit** | `10K` (sufficient for lab) |

5. Click **Deploy**

> **⏱️ Note:** Deployment typically completes in under a minute for Global Standard.

---

## 1B.3 — Verify the Deployment

1. After deployment completes, you'll see `gpt-5-mini` listed under **Deployments**
2. Note the **Status** shows **Succeeded**
3. Click on the deployment to see details:
   - Model name and version
   - Endpoint URL
   - Rate limits
   - Content filter configuration

---

## 1B.4 — Test the Model in the Playground

1. Click **Open in playground** (or go to **Playground** in the left nav)
2. Ensure `gpt-5-mini` is selected as the model
3. Send a test message: *"Explain the difference between Phase 2 and Phase 3 clinical trials in under 50 words."*
4. Verify you receive a coherent response

---

## 1B.5 — Why GPT-5-mini?

| Model | Best For | Cost | Latency |
|-------|----------|------|---------|
| **gpt-5-mini** | Fast reasoning, tool calling, agent workflows | Low | ~2-4s |
| gpt-4.1 | Complex analysis, long documents | Medium | ~5-8s |
| gpt-5 | Maximum capability, research-grade tasks | High | ~8-15s |

For the remaining labs, we'll use **gpt-5-mini** as the agent's model — it provides the best balance of speed and capability for interactive agent scenarios.

---

## Checkpoint

✅ You deployed your own `gpt-5-mini` model  
✅ You verified it's accessible in the Playground  
✅ You understand the tradeoffs between model options  

> **📝 Remember:** In Lab 2, when creating your agent, select `gpt-5-mini` as the model instead of `gpt-4.1`.

---

[← Back to Main Page](../README.md) | [Previous: Lab 1](Lab1-Explore-Foundry-Portal.md) | [Next: Lab 2 — Create Agent →](Lab2-Create-Prompt-Agent.md)
