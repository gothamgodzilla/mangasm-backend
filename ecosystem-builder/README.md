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

## Where it fits

```
SOURCE (registry)  ->  [ ENRICH: this script ]  ->  GENERATE demo  ->  PITCH (slay.llc)
```

Feed `suggested_pitch_angle` + `personalization_hooks` into the cold email, and
`gaps` into which demo engine you auto-build (chatbot / booking / follow-up).

## Notes
- Requires Node 20+ (for `--env-file`). Node 18/19: load the env yourself or use `dotenv`.
- `researchBusiness()` is also importable from other scripts:
  `import { researchBusiness } from "./research-business.mjs"`.
- Compliance reminder (see EMPIRE.md §4): research for *targeting* is fine, but
  make first contact via public channels and follow CAN-SPAM.
