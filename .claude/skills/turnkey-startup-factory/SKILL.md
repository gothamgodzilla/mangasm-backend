---
name: turnkey-startup-factory
description: Generate, research, score, rank, and package startup businesses from keyword lists. Use for daily startup generation, keyword-to-business ideation, turnkey launch kits, 30/60/90-day revenue plans, landing-page or MVP briefs, multi-agent business workflows, and evaluations of whether an idea can make money, become popular, and be easy to use or learn.
---

# Turnkey Startup Factory

Turn a keyword pool into evidence-aware startup candidates, select the strongest one, and produce a practical launch package. Treat scores and forecasts as decision-support estimates, not guarantees.

## Choose the Operating Mode

Select one mode from the request. Default to `launch_kit` when unspecified.

| Mode | Produce |
| --- | --- |
| `screen` | Four candidate concepts, evidence notes, scorecards, and ranking |
| `launch_kit` | Screen output plus a complete package for the winner |
| `landing_page` | Launch kit plus responsive page copy and a website build brief or project |
| `mvp` | Launch kit plus technical specification and a working minimum product after scope confirmation |
| `daily_run` | Repeatable run record, four candidates, one winner, and the selected build-mode output |

## Follow the Workflow

1. **Normalize inputs.** Capture the keyword pool, audience, geography, budget, build mode, output destination, excluded sectors, and prior-run history. Infer safe defaults when missing and disclose them at delivery.
2. **Create four diverse keyword bundles.** Combine a customer or market, a painful job, a delivery mechanism, and a business-model or differentiation keyword. Avoid bundles used recently.
3. **Generate one concept per bundle.** Give each a clear buyer, urgent problem, product promise, payment logic, acquisition wedge, and defensible distinction.
4. **Check evidence.** Research customer pain, existing alternatives, pricing precedent, market activity, and reachable channels when current evidence is needed. Separate sourced facts, calculations, and assumptions. Never invent demand or market data.
5. **Score independently.** Read `references/scoring-and-gates.md`. Assign 1–10 ratings for **Profit Potential**, **Popularity Potential**, and **Ease of Use/Learning**, plus a confidence level and strongest counterargument.
6. **Rank consistently.** Save candidate scores as JSON and run `scripts/rank_concepts.py`. Do not let the composite hide a weak category.
7. **Apply the build gate.** Build the winner only if it clears all gates. Otherwise create a seven-day validation sprint instead of calling it launch-ready.
8. **Create the requested package.** Read `references/output-standards.md` and use the matching template in `templates/`.
9. **Add operating controls.** Apply the 1-2-3 approval tiers in `references/scoring-and-gates.md`. Require explicit approval for public, financial, legal, or destructive actions.
10. **Record the run.** Save the date, inputs, bundles, evidence, scores, confidence, ranking, winner, assumptions, output files, and next test. Make reruns idempotent and avoid duplicate concepts.

## Build a Turnkey Launch Package

For a qualifying winner, include the following sections in a single coherent package:

| Section | Required Content |
| --- | --- |
| Business | Name, one-line position, target customer, purchase trigger, problem, promise, and differentiation |
| Offer | Core product, four useful skills or capabilities, four integrations or plugins when relevant, pricing, guarantee, and upsell path |
| Demand | Customer evidence, competitors or substitutes, acquisition channels, shareability, and retention logic |
| Experience | First-use journey, time to value, onboarding, accessibility, support, and learning burden |
| Economics | Unit economics, key assumptions, break-even logic, and a three-year management-case operating summary |
| Brand | Four direction options—dark, light, rainbow, and pastel cotton candy—then select one based on audience fit |
| Conversion | Landing-page headline, subheadline, benefits, objections, proof plan, and one primary call to action |
| Execution | MVP scope, operating workflow, 30/60/90-day revenue plan, seven-day validation sprint, metrics, risks, and kill/continue rule |

Do not equate an operating cash proxy with EBITDA, net income, or free cash flow. Label every forecast as management-based and unaudited. Show formulas or driver relationships for calculated outputs.

## Use Multi-Agent Decomposition Carefully

For independent candidate generation or research, assign one worker per keyword bundle and require the same output schema. Keep final scoring calibration, ranking, and approval decisions centralized so candidates are comparable.

When a GANESH-style orchestrator is requested, use this pattern:

> Subscription or request → orchestrator → specialist agent with selected skills and integrations → evidence and scorecard → approval tier → launch asset or validation task

Use parallel work only for independent candidates. Do not parallelize sequential approval, publication, payment, or final quality control.

## Apply Daily Automation Rules

For one judgment-heavy run per day, prefer a simple scheduled AI task. Keep results inside the workspace unless the user requests another destination. Track prior keywords and outputs in durable storage.

For a growing system that needs editable keywords, history, team review, multiple daily runs, or a dashboard, build a managed web application with a background schedule. Present both approaches with tradeoffs, cost shape, and setup complexity before implementation. Never enable a recurring schedule without the user's requested time and timezone.

Use isolated runs when each day should be independent. Reuse history when duplicate avoidance and longitudinal learning matter. Require human approval before publishing, purchasing, sending outreach, collecting sensitive data, or submitting to an app store.

## Enforce Quality Rules

- Distinguish facts, calculations, assumptions, and recommendations.
- Reserve scores of 9–10 for unusually strong supporting evidence.
- Mark unsupported decision-critical metrics `TBD`; lower confidence rather than filling gaps.
- Include one positive signal and one counter-signal for each category.
- Use vertical-specific metrics: recurring revenue and retention for SaaS, liquidity and take rate for marketplaces, and COGS, inventory, returns, and fulfillment for physical products.
- Reject ideas with no named buyer, no payment trigger, unavoidable regulatory exposure, commodity positioning, or an MVP that cannot be tested cheaply.
- Prefer a concrete validation plan over false certainty.
- Never promise profit, popularity, virality, funding, or product-market fit.

## Read Resources Selectively

- Read `references/scoring-and-gates.md` for rating definitions, forecast discipline, build gates, and approval tiers.
- Read `references/output-standards.md` for exact candidate, launch-kit, forecast, and run-record structures.
- Use `templates/daily-run.md` for recurring output.
- Use `templates/launch-kit.md` for the winning concept.
- Use `templates/keyword-pool.csv` as the starter input schema.
- Run `scripts/rank_concepts.py --help` before first use or when the score JSON format is unclear.
