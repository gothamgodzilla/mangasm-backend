# Mangasm — Revenue Workflow

How money reaches the bank account, what runs on its own, and the short list
of steps only the account owner can do.

## The two rails

| Rail | Who pays | Processor | Payout |
| ---- | -------- | --------- | ------ |
| **Apple IAP** (`Mangasm.storekit` in the iOS repo) | iOS users in-app | Apple (15–30% cut) | Apple → bank, ~monthly, needs App Store Connect banking + tax forms |
| **Stripe web** (this repo: `0007_billing.sql`, `stripe-checkout`, `stripe-webhook`) | Anyone on mangasm.app | Stripe (~2.9% + 30¢) | Stripe → bank, rolling daily payouts |

Both rails land in `billing_subscriptions`; a trigger keeps
`profiles.membership` in sync, and every existing `is_premium()` gate
(event hosting, video rooms, AI matchmaking, premium photo visibility)
becomes the paywall automatically.

Pricing (mirrors StoreKit):

| Plan | Price | Sandbox Stripe price id |
| ---- | ----- | ----------------------- |
| Mangasm+ Monthly | $9.99 / month | `price_1TyJDiGxbhrlkJVl4YOUgZat` |
| Mangasm+ 3-Month | $24.99 / 3 months | `price_1TyJDsGxbhrlkJVlHDwNtO1Y` |

Product: `prod_UyFittLfGcnbZQ` (currently in the **test-mode sandbox**
`acct_1TxDaGGxbhrlkJVl` — no real money moves until go-live below).

## What runs autonomously once deployed

1. Member taps "Get Mangasm+" (web or steered from iOS where policy allows) →
   `stripe-checkout` returns a hosted payment page.
2. Stripe charges the card, and re-charges every cycle.
3. `stripe-webhook` records every lifecycle event; the DB trigger grants or
   revokes `plus` with a grace window for failed-payment retries (`past_due`
   until the paid-through date).
4. Stripe Smart Retries + customer emails handle dunning (enable in
   Dashboard → Settings → Subscriptions and emails).
5. Stripe pays out to the linked bank on a rolling schedule.

No human in that loop. Humans are only needed for the go-live gate and for
growth decisions.

## Go-live checklist (owner-only, ~1 hour + Stripe review)

- [ ] Activate a **live** Stripe account: business details, identity (KYC),
      **bank account link** — this is the "USD to my bank" step; no tool can
      do it for you. Note: dating services are a Stripe restricted category —
      have real terms/privacy/support pages live (already at
      mangasm.app/terms, /privacy) before applying.
- [ ] Recreate the product + 2 prices in live mode (copy of the sandbox ones).
- [ ] `supabase secrets set STRIPE_SECRET_KEY=sk_live_… STRIPE_WEBHOOK_SECRET=whsec_… STRIPE_PRICE_MONTHLY=… STRIPE_PRICE_QUARTERLY=…`
- [ ] `supabase db push` (applies `0007_billing.sql`)
- [ ] `supabase functions deploy stripe-checkout` and
      `supabase functions deploy stripe-webhook --no-verify-jwt`
- [ ] Add a Stripe webhook endpoint →
      `https://<project-ref>.functions.supabase.co/stripe-webhook`
      with the four `customer.subscription.*` / `invoice.payment_failed` events.
- [ ] Add a `/plus` pricing page in the web repo that calls `stripe-checkout`.
- [ ] For Apple payouts: App Store Connect → Agreements, Tax, Banking.

## Sandbox test (works today, no KYC)

Deploy with the sandbox key + the price ids above, pay with test card
`4242 4242 4242 4242`, and watch `profiles.membership` flip to `plus`.

## Growth loop (deliberately gated)

Revenue = the rail above × people reaching it. Automatable next steps, each
needing an explicit owner go-ahead because they act on real people:

- **Recurring revenue report** — a scheduled session that reads Stripe
  MRR/churn/failed payments weekly and emails a digest. Safe to automate;
  ask Claude to set up the Routine once live keys exist.
- **Prospecting (vpai)** — useful for B2B sides of the product (venue/event
  partners, advertisers), not for consumer signups. List-building can run
  autonomously; outreach sends stay human-approved.
- **App Store launch** — the largest lever; blocked on the owner-side
  signing/notarization steps in the iOS repo, not on this backend.
