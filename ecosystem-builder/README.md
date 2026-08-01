# Ecosystem Builder — business research (Perplexity)

Step 2 (**ENRICH**) of the factory pipeline in [`../docs/EMPIRE.md`](../docs/EMPIRE.md):
turn a scraped business into a personalized pitch angle so a cold email can say
*"here's YOUR AI assistant — already built."*

## Setup (your key stays local, never in chat or git)

```bash
cd ecosystem-builder
cp .env.example .env         # .env is gitignored — safe place for the key
# open .env and paste your real Perplexity key
```

Get a key at https://www.perplexity.ai/settings/api.

## Run it

```bash
node --env-file=.env research-business.mjs "Joe's Plumbing" "joesplumbing.com"
```

Output (example shape):

```json
{
  "what_they_do": "Residential plumbing and drain service in Austin, TX.",
  "online_presence": "Basic one-page site, active Facebook, no online booking.",
  "gaps": ["no website chatbot", "no online booking", "inquiries only by phone"],
  "personalization_hooks": ["5-star Google rating from 200+ reviews", "family-owned since 2009"],
  "suggested_pitch_angle": "Lead with a 24/7 booking chatbot that captures after-hours leads."
}
```

## Step 3 — GENERATE the demo chatbot (the "wow")

`generate-ecosystem.mjs` turns the research JSON into a **personalized, hostable
demo** — a self-contained `demo.html` you can put on Ganesh.guru per prospect,
plus a `spec.json` (system prompt + FAQ + greeting) to drop into Dify/AnythingLLM.

```bash
node --env-file=.env research-business.mjs "Joe's Plumbing" "joesplumbing.com" > joe.json
node --env-file=.env generate-ecosystem.mjs joe.json ./out/joe
# -> ./out/joe/spec.json  and  ./out/joe/demo.html   (open demo.html in a browser)
```

The demo's answers are **pre-baked** from the research, so `demo.html` runs with
no live API key — safe to host and share. Uses Grok by default (set `LLM_*` in
`.env`); point `LLM_BASE_URL`/`LLM_MODEL` at Perplexity or OpenAI to reuse a key.

## Where it fits

```
SOURCE (registry) -> [ ENRICH: research-business ] -> [ GENERATE: generate-ecosystem ] -> PITCH (slay.llc) -> DEMO (Ganesh.guru)
```

Feed `suggested_pitch_angle` + `personalization_hooks` into the cold email, and
link the prospect to their `demo.html`.

## Notes
- Requires Node 20+ (for `--env-file`). Node 18/19: load the env yourself or use `dotenv`.
- `researchBusiness()` is also importable from other scripts:
  `import { researchBusiness } from "./research-business.mjs"`.
- Compliance reminder (see EMPIRE.md §4): research for *targeting* is fine, but
  make first contact via public channels and follow CAN-SPAM.
