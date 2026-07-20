# Project Index: mangasm-backend

Generated: 2026-07-19  
Path: `~/mangasm-backend` · remote: `gothamgodzilla/mangasm-backend`  
Role: **Supabase data + edge layer** (source of truth for DB)

## 📁 Project Structure

```
mangasm-backend/
├── supabase/
│   ├── migrations/
│   │   ├── 0001_initial_schema.sql
│   │   ├── 0002_rls_policies.sql
│   │   ├── 0003_tokens.sql
│   │   ├── 0004_video_rooms.sql
│   │   └── 0005_matchmaking.sql
│   ├── functions/
│   │   ├── recalculate-score/     # reputation
│   │   ├── file-report/           # report + spite-report shield
│   │   ├── generate-daily-matches/
│   │   ├── delete-account/        # GDPR / ASC account deletion
│   │   └── _shared/cors.ts
│   ├── tests/
│   │   ├── shim.sql
│   │   └── ci_smoke.sql
│   ├── seed.sql
│   └── config.toml
├── docs/ARCHITECTURE.md
├── MANGASM_MAP.md                 # accounts / repos / wiring map
├── README.md
└── .github/workflows/db-ci.yml    # migrate + smoke on push
```

**Scale:** small (~20 tracked files) — index is nearly complete map.

## 🚀 Entry Points

| Entry | Path | Purpose |
|-------|------|---------|
| Schema | `supabase/migrations/0001_*` | Core tables, helpers, map RPC, triggers |
| RLS | `0002_rls_policies.sql` | Row-level security |
| Tokens | `0003_tokens.sql` | MGC wallet + ledger |
| Video | `0004_video_rooms.sql` | Rooms (Daily.co) |
| Matchmaking | `0005_matchmaking.sql` | Plus prefs + pgvector |
| Edge | `supabase/functions/*/index.ts` | Deno functions |
| CI | `.github/workflows/db-ci.yml` | Apply migrations + `ci_smoke.sql` |

**Quick start**

```bash
supabase link --project-ref <ref>
supabase db push
supabase functions deploy delete-account
supabase functions deploy file-report
# CI: push → db-ci.yml
```

## 📦 Core surface

### Entities (from ARCHITECTURE)
- `profiles` (+ privacy-adjusted PostGIS `location`)
- `privacy_zones`, `events`, `event_rsvps`
- `messages` (+ Realtime)
- `blocks`, `reports`, `vouches`, `reputation_scores`
- tokens / matchmaking / video rooms (later migrations)

### Edge functions
| Function | Role |
|----------|------|
| `recalculate-score` | Vouches/reports/blocks → 0–100 + tier |
| `file-report` | Report + timing_flag spite shield |
| `generate-daily-matches` | Plus daily matches |
| `delete-account` | Full account deletion (App Store) |

### Client contract
- iOS uses **anon key only** (`SUPABASE_URL` + publishable key in Info.plist / xcconfig)
- **Service role never in app** — edge only
- iOS repo: `~/dev/mangasm/Mangasm` — still **MockChatService** for DMs

## 🔧 Configuration

| File | Purpose |
|------|---------|
| `supabase/config.toml` | CLI / local stack |
| `db-ci.yml` | Migration + smoke CI |
| `.env.example` | Local secrets template (if present; never commit real keys) |

## 🧪 Tests

| File | Purpose |
|------|---------|
| `supabase/tests/ci_smoke.sql` | E2E assertions in CI |
| `supabase/tests/shim.sql` | auth.uid / roles for tests |

## 📚 Documentation

| Doc | Topic |
|-----|--------|
| `README.md` | Layout + deploy |
| `docs/ARCHITECTURE.md` | System shape, RLS gates, iOS wiring |
| `MANGASM_MAP.md` | Apple vs GitHub identities, repos, key placement |

## ⚠️ High-risk notes

1. **Canonical migrations live here** — iOS repo also has `supabase/migrations/*` with different names; reconcile before dual `db push`  
2. **delete-account** must match App Store “delete account” UX  
3. **file-report** timing_flag — safety product claim  
4. Chat/messages schema exists; **iOS live ChatService not wired**  
5. Identities: App Store Apple ID ≠ GitHub `gothamgodzilla` (see `MANGASM_MAP.md`)

## 🔗 Related

| Asset | Path |
|-------|------|
| iOS | `~/dev/mangasm/Mangasm` |
| Goals | `~/dev/mangasm/GOALS.md` |
| Supabase project URL (public) | in iOS `SupabaseConfig.defaultURL` / ASC secrets |

## 📝 Suggested next commands

```text
@backend-architect + /sc:analyze  → migrations vs iOS copy
/sc:implement delete-account E2E   → with iOS AccountDeletion tests
/sc:test                           → db-ci smoke locally if CLI linked
```
