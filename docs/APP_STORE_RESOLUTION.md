# App Store Resolution — Mangasm

Copy-paste replies + steps for the four rejection items. Order matters: **4.3(b)
is the one that can sink the submission**, so lead with it.

---

## Guideline 4.3(b) — Design · Spam  🔴 (appeal — no code fix)

Apple thinks Mangasm is "just another dating app." You win this by proving a
distinct experience and a specific underserved audience. Paste this into the
Resolution Center reply:

> Thank you for the review. We respectfully believe Mangasm is not a duplicative
> dating app, and we'd like to clarify what makes it a distinct experience.
>
> Mangasm is a **safety-first social platform for the LGBTQ+ community**, not a
> swipe-based dating app. Its core is a real-time, location-aware **map feed**
> of members and **member-hosted events** (with RSVPs and capacity) — the
> primary use is discovering people and gatherings nearby *right now*, not
> one-to-one matching. Features that do not exist together in other apps:
>
> - A **behaviour-based reputation and vouch system** that gates who can host
>   events and surfaces trustworthy members — built specifically to protect a
>   vulnerable community from bad actors.
> - **Privacy zones** that disguise a member's home location by default, a
>   safety feature for LGBTQ+ users who may face harassment.
> - **Member-hosted live events** with a hosting gate (verified, established
>   accounts only) and address reveal only shortly before start.
> - A **token economy (MGC)** supporting creators and community activity.
> - **Group video rooms** for community connection.
>
> The audience — the LGBTQ+ community seeking safe, local, event-driven social
> connection — is specifically underserved by mainstream dating apps. We have
> invested heavily in moderation and safety (see our Guideline 1.2 response) to
> serve that community responsibly.
>
> We're glad to walk through any specific concern. We believe the combination of
> a live map, hosted events, a reputation/safety layer, and a creator economy is
> a materially different experience from existing apps.

**Also do in App Store Connect** (metadata reinforces the appeal): make the
subtitle/description lead with *map + events + safety*, not "dating/matching."

---

## Guideline 1.2 — Safety · User-Generated Content  🟢 (code shipped)

Backend support is implemented in `supabase/migrations/0008_ugc_safety.sql`.
Reply once the iOS app wires the two UI pieces (EULA gate + report/block
buttons):

> Mangasm implements all required UGC precautions:
> 1. **Terms/EULA with zero tolerance** for objectionable content and abusive
>    users, agreed to before account creation (recorded server-side in
>    `terms_acceptances`).
> 2. **A method to flag objectionable content**, at both the user and individual
>    content level (`reports` with `content_type`/`content_id`).
> 3. **A method to block abusive users**, which hides them from the reporter in
>    both directions immediately (`blocks` + `is_blocked_between`).
> 4. **Developer action within 24 hours**: reports enter a queue
>    (`reports_open_sla`, with an overdue flag at 24h); our tooling calls
>    `action_report()` to remove the offending content and eject the user, with
>    every action recorded in `moderation_actions` for auditability.

**iOS app to-do (separate repo):** show the EULA before registration and insert
a `terms_acceptances` row on accept; add Report and Block buttons on profiles,
messages, and events.

---

## Guideline 2.3.6 — Age Rating / Advertising  ⬜ (App Store Connect setting)

No code. In App Store Connect → your app → **Age Rating → Edit**:
- Answer **"Yes"** to the **Advertising** question (the app shows ads).
- Save; the age rating updates. Then reply confirming it's set.

---

## Guideline 5.1.2 — Tracking / ATT  ⬜ (iOS app, separate repo)

If the app (or its ad SDK) tracks users across apps/sites:
1. Add `NSUserTrackingUsageDescription` to `Info.plist` with a clear reason.
2. Call `ATTrackingManager.requestTrackingAuthorization` **before** any tracking
   and respect the user's choice.
3. In App Store Connect, complete the **App Privacy** answers to match (declare
   what's collected and whether it's used to track).
If you do **not** track, set the ad SDK to non-personalized and declare "no
tracking" — then say so in the reply.

---

## Submit order
1. Ship the iOS EULA gate + report/block UI (uses the 0008 backend).
2. Flip the 2.3.6 Advertising answer + App Privacy (5.1.2) in App Store Connect.
3. Reply to all guidelines in one Resolution Center message, **leading with the
   4.3(b) differentiation** above.
