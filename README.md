# Microsoft Foundry Hands-On Lab Series

## Pharma Commercial Operations AI — From Exploration to Production

![Microsoft Foundry](https://img.shields.io/badge/Microsoft%20Foundry-2026-blue) ![Labs](https://img.shields.io/badge/Labs-6-green) ![Duration](https://img.shields.io/badge/Duration-5.5%20Hours-orange) ![Industry](https://img.shields.io/badge/Industry-Pharma-purple)

---

## Welcome

In this hands-on lab series, you will build an **end-to-end AI agent solution** for a pharmaceutical commercial operations team using **Microsoft Foundry**. You'll progress from exploring the platform through creating intelligent agents, grounding them in enterprise data, adding tools, deploying to production, and setting up monitoring — all using a real-world pharma use case.

---

## What You'll Build

A **"Pharma Commercial Operations AI Analyst"** — an intelligent agent that can:

- Answer questions about drug portfolios, clinical trial statuses, and revenue forecasts
- Retrieve and cite data from your proprietary enterprise knowledge base
- Generate visualizations of quarterly financial data using Code Interpreter
- Check drug-drug interactions via custom Azure Function tool calls
- Run as a production-grade hosted agent with full observability and continuous evaluation

---

## What Attendees Will Get Out of This Lab

By the end of this lab series, you will:

| # | Outcome | Skills Gained |
|---|---------|---------------|
| 1 | **Understand the Foundry platform end-to-end** | Navigate Models, Tools, Knowledge, Agents, and Evaluations |
| 2 | **Build AI agents declaratively and via code** | Foundry Portal UI + Python SDK (`azure-ai-projects`) |
| 3 | **Ground agents in enterprise data** | Foundry IQ knowledge bases with citation-backed, permission-aware retrieval |
| 4 | **Extend agents with tools** | Code Interpreter for data analysis + Azure Functions for custom actions |
| 5 | **Deploy production-grade agents** | Microsoft Agent Framework + Azure Developer CLI (`azd`) |
| 6 | **Monitor and evaluate agents in production** | Distributed tracing, Agent Dashboard, continuous evaluation with built-in evaluators |

### Key Differentiators You'll Experience

- **Unified Platform** — Agents + Models + Tools + Knowledge under single RBAC and networking
- **1,900+ Models** — Multi-provider catalog (OpenAI, Meta, Anthropic, Mistral, DeepSeek, etc.)
- **Foundry IQ** — Citation-backed answers critical for regulatory compliance
- **1,400+ Tools** — Public + private catalogs with central auth management
- **Enterprise-Grade Observability** — Full audit trail of every agent decision (essential for GxP)

---

## Schedule

| Time | Lab | Topic | Duration |
|------|-----|-------|----------|
| 9:00 AM | [Lab 1](labs/Lab1-Explore-Foundry-Portal.md) | Explore Microsoft Foundry Portal & Capabilities | 30 min |
| 9:30 AM | [Lab 2](labs/Lab2-Create-Prompt-Agent.md) | Create a Pharma Commercial Operations Agent | 45 min |
| 10:15 AM | — | *Break* | 15 min |
| 10:30 AM | [Lab 3](labs/Lab3-Foundry-IQ-Knowledge.md) | Connect with Foundry IQ Knowledge Base | 60 min |
| 11:30 AM | — | *Break* | 15 min |
| 11:45 AM | [Lab 4](labs/Lab4-Tool-Calling.md) | Tool Calling — Azure Functions & Code Interpreter | 60 min |
| 12:45 PM | — | *Lunch* | 45 min |
| 1:30 PM | [Lab 5](labs/Lab5-Hosted-Agent-Deployment.md) | Deploy a Hosted Agent with Microsoft Agent Framework | 60 min |
| 2:30 PM | — | *Break* | 15 min |
| 2:45 PM | [Lab 6](labs/Lab6-Monitoring-Evaluation.md) | Monitoring, Evaluation & Observability | 60 min |
| 3:45 PM | — | Wrap-up & Q&A | 15 min |

**Total Duration:** ~5.5 hours (including breaks)

---

## Prerequisites (Pre-configured for You)

The following have been set up in your lab environment:

| Resource | Details |
|----------|---------|
| Azure Subscription | Provided with necessary RBAC roles |
| Microsoft Foundry Project | `proj-pharma-ops` at [ai.azure.com](https://ai.azure.com) |
| Model Deployments | `gpt-4.1` (Global Standard), `gpt-4.1-mini` |
| Azure AI Search | Service provisioned for Foundry IQ |
| Azure Storage Account | For uploading pharma datasets |
| Application Insights | Connected to Foundry project for tracing |
| Azure Developer CLI (azd) | Pre-installed with Foundry extension |

> **🛠️ Lab Organizers:** Use the [setup scripts](scripts/) to pre-create all resources and onboard users. See [scripts/README.md](scripts/README.md) for full instructions.

---

## Lab Links

| Lab | Title | What You'll Do |
|-----|-------|----------------|
| [Lab 1](labs/Lab1-Explore-Foundry-Portal.md) | **Explore Microsoft Foundry** | Tour the portal — Models, Tools, Knowledge, Playground |
| [Lab 2](labs/Lab2-Create-Prompt-Agent.md) | **Create a Prompt Agent** | Build your pharma analyst agent (UI + Python) |
| [Lab 3](labs/Lab3-Foundry-IQ-Knowledge.md) | **Foundry IQ Knowledge** | Upload data, create knowledge base, get cited answers |
| [Lab 4](labs/Lab4-Tool-Calling.md) | **Tool Calling** | Code Interpreter charts + Azure Function drug interactions |
| [Lab 5](labs/Lab5-Hosted-Agent-Deployment.md) | **Hosted Agent Deployment** | Agent Framework → local test → `azd deploy` |
| [Lab 6](labs/Lab6-Monitoring-Evaluation.md) | **Monitoring & Evaluation** | Tracing, dashboards, continuous evaluation |

---

## Your Journey

```
Lab 1: Explore          → Understand the unified platform
       │
Lab 2: Create Agent     → Build a pharma AI analyst (declarative)
       │
Lab 3: Ground in Data   → Connect to enterprise knowledge (Foundry IQ)
       │
Lab 4: Add Tools        → Extend with Code Interpreter + Azure Functions
       │
Lab 5: Go Production    → Deploy as hosted agent (Microsoft Agent Framework)
       │
Lab 6: Observe & Eval   → Production monitoring + continuous quality gates
```

---

## Industry Context

As a data scientist or AI engineer at a leading pharmaceutical company, you need AI agents that are:

- **Accurate** — Drug information must be grounded in data, not hallucinated
- **Auditable** — Every response must be traceable with citations for regulatory compliance
- **Secure** — Patient data and trade secrets must never leak
- **Monitored** — Continuous quality gates to catch issues before they reach end users
- **Scalable** — Enterprise-grade deployment for thousands of commercial ops users

Microsoft Foundry delivers all of this in a unified platform.

---

*Lab Version: 1.0 | Platform: Microsoft Foundry (New) | Last Updated: July 2026*
