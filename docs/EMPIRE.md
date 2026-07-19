# EMPIRE.md — the portfolio plan

Six ventures under `gothamgodzilla` / Mangasm Enterprises. Goals, in order:
(1) smarter, (2) faster to operate, (3) easier to make revenue.

Default model for every tool below: **Grok 4.5 (xAI)**. The tool is the body;
the model is the brain.

---

## 0. Priority — where the money actually is

Not all six move at once. Rank by *how fast AI turns it into cash* vs *risk/capital*:

| Tier | Venture | Why |
|------|---------|-----|
| 🟢 **Do first** | **Helping.LLC** | Has no customers; getting customers is exactly what AI is good at. Fastest dollar. |
| 🟢 Do first | **Mangasm.app** | Already built — AI adds upsell + safety. |
| 🟢 Do first | **Nostalgia.sh** | Shippable as the text-coach; visuals later. |
| 🟡 Next | **slay.llc** | Outreach/pitch automation supports the others. |
| 🔴 Moonshot (R&D) | **Rambo INK** | Robot arm on human skin = safety-critical, capital-heavy. |
| 🔴 Moonshot (R&D) | **Diabolic** | Legal + scope blockers (see its section). |

## 0.1 What AI can and can't build for you

```
AI as COPILOT (you drive, it does each task)      → reliable TODAY
AI as AGENT   (chains tasks, you supervise)       → narrow digital jobs only:
                                                     research, content, code scaffolding,
                                                     automations, pitch decks ✅
AI as AUTONOMOUS BUILDER of a whole game/robot    → NOT real yet ❌
```
Point autonomy at Helping.LLC, Nostalgia, Mangasm, slay. Use AI as a *copilot*
(not an autonomous builder) on Rambo INK and Diabolic.

## 0.2 Tool stack (don't run all five)

| Tool | Use as | When |
|------|--------|------|
| **AnythingLLM** | Brain / knowledge base, one workspace per brand | Start |
| **Sim Studio** | Automation wiring (agentic Zapier) | Start |
| **Dify** | Customer-facing AI features + monitoring | When shipping a feature |
| **AutoAgent** | Research sprints | In bursts |
| **LangChain OAP** | Technical multi-agent (Supabase-backed) | Later |

---

## 1. Helping.LLC — handyman / task service (🟢 fastest revenue)

**Problem:** real service, **zero customer traffic.** This is a marketing problem,
and marketing is where AI pays off fastest.

- **Smarter:** AI qualifies leads and writes instant, accurate quotes.
- **Faster:** Sim flow — inquiry (form/text) → AI quote → booking link → reminder.
- **Revenue:** local SEO content, Google Business posts, review-request texts,
  abandoned-quote follow-ups. All automatable.
- **First task:** a Dify chatbot on the site: "Describe your job" → AI asks 3
  questions → gives a ballpark price + booking link.
- **Grok prompt:** *"You are the intake assistant for a local handyman service.
  Given a customer's job description, ask at most 3 clarifying questions, then
  give a price range and a booking CTA. Friendly, local, no jargon."*

## 2. Mangasm.app — 18+ LGBTQ+ social/dating (🟢 built)

- **Smarter:** Dify moderation assistant reading `file-report` +
  `recalculate-score` to flag bad actors faster.
- **Faster:** Sim flow — new signup → AI welcome DM + 3 nearby events.
- **Revenue:** AI concierge upselling **Plus** (matchmaking) + explaining the
  **MGC token** wallet. This is the money path.
- **First task:** Dify concierge with the Plus/MGC docs as knowledge.

## 3. Nostalgia.sh — AI astrology life-coach (🟢 shippable)

Ganesh.Guru = the coach avatar / front door of this product.

**Make-or-break rule: split MATH from SOUL.**
```
LAYER 1 — FACTS (deterministic, NEVER the LLM)
  natal chart  → ephemeris library / astrology API (Swiss Ephemeris)
  Chinese sign → lookup from birth year
  life path #  → numerology formula
  live context → weather API, GPS, USGS/NWS emergencies, Google Calendar
  memory       → Supabase (past tasks + productivity signals)
        ⬇ handed as facts to...
LAYER 2 — SOUL (Grok 4.5 + RAG knowledge base of astrology/numerology/cards)
  writes the warm, uplifting daily task.
```
The LLM must never *calculate* the chart (it guesses math and breaks trust);
it *interprets* the exact numbers the engines produce.

- **Smarter:** memory notices what boosts your productivity, adapts.
- **Faster:** Sim scheduled flow runs the daily pipeline hands-free.
- **Revenue:** free daily card → **Plus** deep readings + full Ganesh cinematics
  + calendar sync; decks/merch later.
- **Visuals note:** the cinematic animated Ganesh is a **design/animation
  pipeline**, not an LLM output. v1 = a library of pre-rendered Ganesh scenes the
  AI *picks from* by mood. "Generate a new cinematic deity daily" is not reliable/
  affordable yet.
- **First task:** Dify chatbot, Grok 4.5, prompt: *"You are Ganesh, a warm life
  coach. Given birth date, today's date, and today's weather, give one uplifting
  task for today in 3 sentences."* Feed inputs by hand first — prove the vibe.

## 4. slay.llc — email pitch-deck / outreach engine (🟡)

Used to pitch **Luxury-mcp-engine** and Diabolic. _Confirm what Luxury-mcp-engine
is (an MCP server product? concierge?)._

- **Smarter:** AI tailors each pitch deck to the recipient.
- **Faster:** Sim flow — prospect list → AI-personalized deck + email → send.
- **Revenue:** it's a *support* tool — it books meetings for the other ventures.
- **First task:** a Grok prompt that turns a one-line product pitch + a prospect
  name into a 5-slide outline + a cold email.

## 5. Rambo INK — autonomous tattoo booth (🔴 moonshot / R&D)

Mechanical arm + tattoo artist supervising. ("Evil Twin Digital" — _confirm: the
digital-twin / design-gen side of this?_)

- **AI's real role:** the *design* side (customer idea → AI concept art →
  artist-approved stencil) and the *booth software* (intake, consent, booking).
- **Not AI's role:** safe autonomous needle-to-skin motion. That's safety-
  critical robotics + liability + regulation. The supervising artist is the
  safety layer, and v1 should keep a human firmly on the trigger.
- **First AI task (the shippable slice):** an AI tattoo-design generator —
  customer describes an idea → concept images + a clean stencil brief for the
  artist. Sell *that* while the hardware matures.

## 6. Diabolic — dark ARPG in Unreal Engine (🔴 moonshot / R&D)

**Two honest blockers:**
1. **A Diablo 2: LoD "remake" is legally unsellable.** Blizzard/Activision
   enforces hard — name, assets, and "remake" all infringe. You'd get a
   cease-and-desist before revenue. **Fix:** ship an *original* dark isometric
   ARPG — your own name, art, lore, "inspired by the genre." Same feel, zero
   legal fuse.
2. **AI cannot autonomously build the game.** It's a copilot: it drafts Unreal
   C++/Blueprint systems, loot tables, dialogue, tooling — task by task, with you
   driving. Treat it as acceleration, not a build button.
- **First task:** have Grok scaffold ONE system (e.g., an inventory/loot data
  model in Unreal) end to end — that calibrates what "AI-assisted" really buys you.

---

## 7. Grok 4.5 build prompts

**Master (paste first each session):**
> You are my lead build engineer for a 6-venture company: Helping.LLC (handyman
> service), Mangasm (18+ social/dating app, Supabase), Nostalgia.sh (AI astrology
> coach), slay.llc (pitch/outreach engine), Rambo INK (autonomous tattoo booth),
> Diabolic (original dark ARPG in Unreal). Goals in order: smarter, faster,
> revenue. I'm semi-technical and want the simplest thing that works. For every
> task: plan in plain English, then exact steps/code, then how to test and what
> "done" looks like. Never mix data between brands. Split exact math from LLM
> interpretation. Flag legal/safety risk honestly. Ask only if you truly can't
> proceed.

**Per-system (fill brackets):** see the template in each section above.

## 8. How to use the LLMs

- Put the Grok API key in each tool's **model/provider** setting once.
- **Give it your knowledge** (upload brand docs), not just questions.
- **One job per agent.**
- **Human-in-the-loop** on money- and safety-touching flows.
- **Deterministic math stays out of the LLM** (charts, quotes, prices).
- **Watch cost + quality** weekly (Dify monitoring).

## 9. Before revenue — security

`MANGASM_MAP.md` open TODO: **rotate the leaked GitHub token + Supabase keys
(anon + service-role).** For an 18+ app, one leak ends the business. Do this
before wiring in new AI features.
