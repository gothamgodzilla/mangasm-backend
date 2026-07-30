// send-outreach.mjs
// Ecosystem Builder — Step 4 (PITCH): send HERALD-approved drafts via Resend,
// safely. Defaults to DRY RUN; sends only with an explicit --send flag.
//
// Safety rails (non-negotiable, enforced in code):
//   1. CAN-SPAM: refuses to send unless FROM_EMAIL, PHYSICAL_ADDRESS are set,
//      and every email gets an identity + opt-out footer automatically.
//   2. Warmup throttle: hard daily cap (DAILY_SEND_CAP, default 10) tracked in
//      a local send log. Blasting a fresh domain = blacklist; the cap is the cure.
//   3. Suppression list: addresses in optout.txt are never emailed again.
//   4. Draft-approval flow: only sends files from the drafts/approved/ folder —
//      HERALD writes to drafts/pending/, a human moves them to approved/.
//
// Setup:  cp .env.example .env   → add RESEND_API_KEY etc. (gitignored)
// Usage:
//   node --env-file=.env send-outreach.mjs drafts/approved/joe.json           # DRY RUN
//   node --env-file=.env send-outreach.mjs drafts/approved/joe.json --send    # real send
//
// Draft JSON shape (HERALD produces this):
//   { "to": "owner@business.com", "subject": "...", "body_text": "...",
//     "prospect": "Joe's Plumbing", "hook": "the 5-star reviews detail" }
//
// Requires Node 20+.

import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const LOG_PATH = join(HERE, "outreach-log.json");     // gitignored
const OPTOUT_PATH = join(HERE, "optout.txt");          // gitignored
const DAILY_CAP = Number(process.env.DAILY_SEND_CAP ?? 10);

function readLog() {
  try { return JSON.parse(readFileSync(LOG_PATH, "utf8")); } catch { return []; }
}

function sentToday(log, today) {
  return log.filter((e) => e.date === today).length;
}

function readOptouts() {
  try {
    return new Set(readFileSync(OPTOUT_PATH, "utf8").split("\n").map(s => s.trim().toLowerCase()).filter(Boolean));
  } catch { return new Set(); }
}

function requireEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`${name} is not set — add it to .env (see .env.example). Refusing to send.`);
  return v;
}

export async function sendOutreach(draftPath, { send = false, today } = {}) {
  const draft = JSON.parse(readFileSync(draftPath, "utf8"));
  for (const field of ["to", "subject", "body_text"]) {
    if (!draft[field]) throw new Error(`Draft missing required field: ${field}`);
  }
  if (!draftPath.includes("approved")) {
    throw new Error("Draft is not in an approved/ folder. HERALD drafts to pending/; a human moves approved drafts. Refusing.");
  }

  const fromEmail = requireEnv("FROM_EMAIL");            // e.g. "Mangasm Enterprises <hello@slay.llc>"
  const address = requireEnv("PHYSICAL_ADDRESS");        // CAN-SPAM: real postal address
  const optouts = readOptouts();
  if (optouts.has(draft.to.trim().toLowerCase())) {
    return { skipped: true, reason: "recipient on opt-out list" };
  }

  const log = readLog();
  const day = today ?? new Date().toISOString().slice(0, 10);
  if (sentToday(log, day) >= DAILY_CAP) {
    return { skipped: true, reason: `daily warmup cap reached (${DAILY_CAP}). Try tomorrow or raise DAILY_SEND_CAP gradually.` };
  }
  if (log.some((e) => e.to === draft.to && e.status === "sent")) {
    return { skipped: true, reason: "already emailed this recipient — no repeat first-touches" };
  }

  // CAN-SPAM footer: identity + postal address + working opt-out, always appended.
  const footer =
    `\n\n—\n${fromEmail.replace(/<.*>/, "").trim()}\n${address}\n` +
    `If you'd rather not hear from us, reply "unsubscribe" and we won't email again.`;
  const text = draft.body_text + footer;

  if (!send) {
    return { dryRun: true, to: draft.to, subject: draft.subject, preview: text.slice(0, 400) };
  }

  const key = requireEnv("RESEND_API_KEY");
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { "Authorization": `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({ from: fromEmail, to: [draft.to], subject: draft.subject, text }),
  });
  if (!res.ok) throw new Error(`Resend API ${res.status}: ${await res.text()}`);
  const data = await res.json();

  log.push({ date: day, to: draft.to, subject: draft.subject, prospect: draft.prospect ?? null, id: data.id, status: "sent" });
  writeFileSync(LOG_PATH, JSON.stringify(log, null, 2));
  return { sent: true, id: data.id, to: draft.to, sentTodayCount: sentToday(log, day) };
}

// ---- CLI -------------------------------------------------------------------
if (import.meta.url === `file://${process.argv[1]}`) {
  const [, , draftPath, flag] = process.argv;
  if (!draftPath) {
    console.error("Usage: node --env-file=.env send-outreach.mjs drafts/approved/<draft>.json [--send]");
    process.exit(1);
  }
  mkdirSync(join(HERE, "drafts", "pending"), { recursive: true });
  mkdirSync(join(HERE, "drafts", "approved"), { recursive: true });
  sendOutreach(draftPath, { send: flag === "--send" })
    .then((r) => console.log(JSON.stringify(r, null, 2)))
    .catch((e) => { console.error("Error:", e.message); process.exit(1); });
}
