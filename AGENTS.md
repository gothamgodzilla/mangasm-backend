# AGENTS.md — shared context for any AI working in this repo

> This file is the **handshake** between AI assistants (Claude Code, Grok CLI,
> and the no-code agent tools). Read it first, every session. It is the shared
> brain so two different models stay in sync through the repo instead of talking
> to each other directly.

## Who owns what

- **Owner:** `gothamgodzilla` ("Mangasm Enterprises").
- **This repo:** `gothamgodzilla/mangasm-backend` — the Supabase data + server
  layer for Mangasm. See `README.md` and `MANGASM_MAP.md` for specifics.

## The empire (6 ventures)

| Venture | Domain | What it is | Tier |
|---------|--------|-----------|------|
| **Helping.LLC** | Helping.LLC | Handyman/task service, needs customers | 🟢 fastest revenue |
| **Mangasm** | Mangasm.app | 18+ LGBTQ+ social/dating (Supabase, this repo) | 🟢 built |
| **Nostalgia** | Nostalgia.sh | AI astrology life-coach; Ganesh.Guru = avatar | 🟢 shippable |
| **slay.llc** | slay.llc | Email pitch-deck / outreach engine | 🟡 support |
| **Rambo INK** | rambo.ink | Autonomous tattoo booth, robot arm + artist | 🔴 moonshot |
| **Diabolic** | — | Original dark ARPG in Unreal (see legal note) | 🔴 moonshot |

Full per-venture plans, priority, and Grok prompts: **`docs/EMPIRE.md`**.

Full strategy, tool choices, and starter tasks live in **`docs/EMPIRE.md`**.

## Operating rules for AI agents

1. **Plan in plain English first**, then the exact steps/code, then how to test
   and what "done" looks like. The owner is semi-technical and wants the
   simplest thing that works.
2. **Never mix data between brands.** One workspace/project per brand.
3. **Never commit real secrets.** Keys live in gitignored files
   (`Config.xcconfig`, `supabase/.env.local`). See the Security TODO in
   `MANGASM_MAP.md` — rotate leaked keys before shipping new features.
4. **The model is the brain; the tool is the body.** Grok 4.5 (xAI) is the
   default model plugged into every no-code tool (AnythingLLM, Sim, Dify).
5. **Commit small, push often.** The next AI only sees what you pushed.

## How the two terminals stay linked

```
CLAUDE (web) ──push──► GitHub repo ◄──push── GROK CLI (local)
                          │
             AGENTS.md + docs/EMPIRE.md = shared context
```

- Claude Code (web) works on branch `claude/grok-empire-systems-setup-x4bdg3`.
- Grok CLI clones the same repo, reads this file + `docs/EMPIRE.md`, and
  continues. Whoever pushes, the other pulls. That is the whole link.
