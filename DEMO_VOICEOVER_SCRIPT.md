# Insurance AI Hub — Demo Voice-Over Script

> Duration: ~75 seconds | Pace: Natural, confident | Tone: Executive demo

---

**[SCREEN: Snowsight — show INSURANCE_AI_HUB database objects]**

"This is the Insurance AI Hub — a full-stack intelligence platform built entirely on Snowflake, using over twenty native platform features.

At its core, we have eighteen tables across three schemas — Analytics, Documents, and Data Quality — all governed with PII tags, dynamic masking policies, and six database roles in a least-privilege hierarchy."

**[SCREEN: Switch to CoWork or React Dashboard — show AI Assistant page]**

"The heart of the platform is our five Cortex Agents. Here's the Unified Enterprise Agent — it combines seven tools in one conversational interface: five Cortex Analyst connections backed by Semantic Views with twenty-five verified queries, a Cortex Search service for RAG over policy documents, and a data-to-chart tool for instant visualizations.

Let me ask it a question..."

**[TYPE or VOICE: "What is the total premium revenue by policy type?"]**

"The agent routes this to the insurance operations analyst, generates SQL through the Semantic View, and returns grounded results with source citations — no hallucination."

**[SCREEN: Show voice mic button — click it and speak in Spanish or Hindi]**

"We also support voice input in any language. I'll speak in Spanish — the browser captures speech, Snowflake's AI Translate auto-detects the language, translates to English, and sends it to the agent. All parameterized — zero SQL injection risk."

**[SCREEN: Show Jira integration or mention MCP]**

"When the agent finds an issue — say, a pricing gap or a data quality failure — it can create a Jira ticket directly through our Atlassian MCP connector. Insight to action, in one conversation."

**[SCREEN: Show Tasks/Streams or Governance Dashboard]**

"Behind the scenes, three CDC streams and three automated tasks monitor for high-fraud claims and data quality failures in real time. An alert fires every twelve hours if any table's quality score drops below seventy percent.

And all of this is protected by resource monitors and budgets capping AI costs — so it's production-ready from day one."

**[SCREEN: Show deploy.sh or CI/CD]**

"The entire solution deploys in one command — twenty-one SQL scripts, a Cortex Project with eleven YAML artifacts, a fourteen-page React dashboard, and a GitHub Actions CI/CD pipeline. Everything is modular, rollback-safe, and documented."

**[CLOSING — look at camera or pause]**

"Insurance AI Hub. Twenty-two Snowflake features. Five agents. One platform. Built for production."

---

## Timing Guide

| Section | Duration | Cumulative |
|---------|----------|------------|
| Database + governance intro | ~12s | 0:12 |
| Agent architecture | ~15s | 0:27 |
| Live query demo | ~10s | 0:37 |
| Voice + translate demo | ~12s | 0:49 |
| MCP / Jira | ~8s | 0:57 |
| Automation + cost control | ~10s | 1:07 |
| Deployment | ~8s | 1:15 |
| Closing tagline | ~5s | 1:20 |

**Total: ~1 minute 20 seconds**

## Tips

- Practice the agent query beforehand so it responds quickly on camera
- For voice demo, use a short Spanish phrase like "Cual es el ingreso total por tipo de poliza"
- Keep cursor movement deliberate — pause on each screen for 2-3 seconds before speaking
- The closing tagline lands best with a brief pause before "Built for production"
