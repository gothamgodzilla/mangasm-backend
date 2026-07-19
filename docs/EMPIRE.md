# EMPIRE.md — the 4-brand AI plan

The shared strategy for **Mangasm · Diabolic · Nostalgia · Rambo INK**.
Goals, in order: (1) smarter, (2) faster to operate, (3) easier to make revenue.

---

## 1. The tool stack (don't run all five)

Five open-source agent platforms were evaluated. Use only what earns its place:

| Tool | Use it as your… | When |
|------|-----------------|------|
| **AnythingLLM** | Brain / knowledge base (one workspace per brand) | Start here |
| **Sim Studio** | Automation wiring (agentic Zapier) | Start here |
| **Dify** | AI features *inside* your apps, with monitoring | When shipping a customer-facing feature |
| **AutoAgent** | Research sprints (market, competitors, trends) | In bursts |
| **LangChain OAP** | Technical multi-agent, Supabase-backed | Later, when you outgrow the above |

**Default model for all of them: Grok 4.5 (xAI).** The tool is the body; the
model is the brain.

## 2. How the pieces fit

```
        GROK 4.5  (the model — plugged into every tool)
   ┌─────────┼──────────────┬─────────────────┐
AnythingLLM   Sim Studio      Dify            AutoAgent
(the brain)   (automations)  (app AI feature) (research)
        └── one workspace / project per brand, never mixed ──┘
```

## 3. Per-brand plans

### Mangasm — 18+ LGBTQ+ social/dating (known)
- **Smarter:** Dify safety/moderation assistant reading `file-report` +
  `recalculate-score` outputs to flag bad actors faster.
- **Faster:** Sim flow — new signup → AI welcome DM + 3 nearby event suggestions.
- **Revenue:** AI concierge that upsells the **Plus** tier and explains the
  **MGC token** wallet. This is the money path.

### Diabolic — _confirm what it is_
- Smarter: AnythingLLM workspace holding brand voice.
- Faster: Sim flow — idea → product copy + social posts → approve.
- Revenue: automated abandoned-cart / re-engagement messages.

### Nostalgia — _confirm what it is_
- Smarter: weekly AutoAgent research on trending retro niches.
- Faster: batch-generate themed content collections.
- Revenue: AI-curated "drops" tied to nostalgia moments.

### Rambo INK — _confirm what it is_
- Smarter: AI design-brief taker (customer idea → structured brief).
- Faster: Sim flow — inquiry → AI quote + booking link.
- Revenue: print-on-demand upsells on every design.

## 4. Grok 4.5 build prompts

**Master prompt (paste first each session):**

> You are my lead build engineer for a 4-brand company: Mangasm (18+ LGBTQ+
> social/dating app, Supabase backend), Diabolic, Nostalgia, and Rambo INK. My
> goals, in order: (1) make each brand smarter, (2) faster to operate, (3)
> easier to generate revenue. I am semi-technical and want the simplest thing
> that works. For every task: give me the plan in plain English first, then the
> exact steps or code, then how to test it and what "done" looks like. Never mix
> data between brands. Ask a question only if you genuinely cannot proceed.

**Per-system prompt (fill the brackets):**

> Brand: [Mangasm]. System: [concierge that upsells Plus + explains the MGC
> wallet]. Built in [Dify] using Grok 4.5 as the model. Give me: (1) the exact
> system prompt, (2) the 5 knowledge documents to upload, (3) the step-by-step
> build in the tool, (4) 3 test messages + correct responses, (5) one metric
> that proves it makes money. Keep it to what a beginner finishes in one sitting.

## 5. Starter tasks — the basics of each system (one sitting each)

**AnythingLLM — Day 1:** install → make workspace `Mangasm` → upload README +
`MANGASM_MAP.md` + a brand-voice page → ask "What is Mangasm and who is it for?"

**Sim Studio — Day 2:** blank canvas → Start → Agent → output → "type a product
idea, get 3 captions" → run it live once.

**Dify — Day 3:** new Chatbot app → set Grok 4.5 → paste system prompt → upload
brand docs → test 3 questions → copy the embed snippet.

**AutoAgent — when needed:** run in Docker, pick Grok → "Research the top 5
competitors to [brand] and how they make money."

Repeat Days 1–3 for each brand with a fresh workspace.

## 6. How to use the LLMs

- Put the Grok API key in each tool's **model/provider** setting once.
- **Give it your knowledge**, not just questions (upload brand docs).
- **One job per agent** (moderation agent ≠ upsell agent).
- **Human-in-the-loop** on money-touching flows for the first ~2 weeks.
- **Watch cost + quality** weekly (that's what Dify's monitoring is for).

## 7. Before revenue — security

`MANGASM_MAP.md` lists an open TODO: **rotate the leaked GitHub token +
Supabase keys (anon + service-role).** For an 18+ app, one leak ends the
business. Do this before wiring in new AI features.
