// generate-ecosystem.mjs
// Ecosystem Builder — Step 3 (GENERATE): turn the research JSON into a
// personalized, hostable demo chatbot — the "already built for you" wow that
// closes the pitch.
//
// Uses an OpenAI-compatible LLM. Default = xAI Grok. Configure in .env:
//   LLM_API_KEY   (required)   — your Grok/xAI key (or any OpenAI-compatible key)
//   LLM_BASE_URL  (optional)   — default https://api.x.ai/v1
//   LLM_MODEL     (optional)   — default grok-4  (set "sonar" to reuse Perplexity, etc.)
//
// Usage:
//   node --env-file=.env research-business.mjs "Joe's Plumbing" "joesplumbing.com" > joe.json
//   node --env-file=.env generate-ecosystem.mjs joe.json ./out/joe
// Produces ./out/joe/spec.json  and  ./out/joe/demo.html
//
// Requires Node 20+.

import { readFileSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const BASE_URL = process.env.LLM_BASE_URL ?? "https://api.x.ai/v1";
const MODEL = process.env.LLM_MODEL ?? "grok-4";

/** Ask the LLM to design a demo chatbot for this business. */
export async function generateSpec(research) {
  const key = process.env.LLM_API_KEY;
  if (!key) {
    throw new Error(
      "LLM_API_KEY is not set. Add it to .env (see .env.example).",
    );
  }

  const prompt =
    `You are designing a demo AI assistant for a real business so we can pitch ` +
    `them a turnkey "AI ecosystem." Here is research about them as JSON:\n\n` +
    `${JSON.stringify(research, null, 2)}\n\n` +
    `Return ONLY a JSON object with these keys:\n` +
    `  business_name   — best display name for the business\n` +
    `  brand_color     — a hex color that fits their vibe (e.g. "#0B7285")\n` +
    `  greeting        — the assistant's first message to a visitor (1-2 sentences)\n` +
    `  system_prompt   — the production system prompt for this assistant\n` +
    `  faq             — array of 6 {q, a} pairs a real customer would ask, ` +
    `answered in the business's voice using the research\n` +
    `  recommended_engine — one of: "booking", "lead-capture", "faq-support", "quote"\n` +
    `  cta             — the call-to-action line the assistant closes with\n` +
    `Make it specific to THIS business. Valid JSON only, no markdown.`;

  const res = await fetch(`${BASE_URL}/chat/completions`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [
        {
          role: "system",
          content: "You are a senior conversation designer. Output valid JSON only.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.5,
    }),
  });

  if (!res.ok) {
    throw new Error(`LLM API ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  const content = data.choices?.[0]?.message?.content ?? "";
  const cleaned = content.replace(/^```(?:json)?/i, "").replace(/```$/i, "").trim();
  return JSON.parse(cleaned);
}

const esc = (s) =>
  String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

/** Render a self-contained, hostable demo page. Answers are pre-baked (no live
 *  key needed), so it's safe to host per prospect on Ganesh.guru. */
export function renderDemoHtml(spec) {
  const color = /^#[0-9a-f]{6}$/i.test(spec.brand_color ?? "") ? spec.brand_color : "#0B7285";
  const faq = Array.isArray(spec.faq) ? spec.faq : [];
  // Data embedded for the client-side keyword matcher.
  const payload = JSON.stringify({
    greeting: spec.greeting ?? "Hi! How can I help you today?",
    cta: spec.cta ?? "Want to book? Tap here.",
    faq,
  });

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>${esc(spec.business_name)} — AI Assistant (demo)</title>
<style>
  :root { --brand: ${color}; }
  * { box-sizing: border-box; }
  body { margin:0; font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
         background:#f4f5f7; color:#1a1a1a; }
  .wrap { max-width:440px; margin:24px auto; background:#fff; border-radius:16px;
          overflow:hidden; box-shadow:0 8px 30px rgba(0,0,0,.12); }
  .head { background:var(--brand); color:#fff; padding:16px 18px; }
  .head h1 { margin:0; font-size:16px; }
  .head p { margin:2px 0 0; font-size:12px; opacity:.85; }
  .demo-tag { font-size:10px; text-transform:uppercase; letter-spacing:.08em;
              background:rgba(255,255,255,.2); padding:2px 6px; border-radius:6px; }
  .log { height:380px; overflow-y:auto; padding:14px; display:flex; flex-direction:column; gap:8px; }
  .msg { max-width:80%; padding:9px 12px; border-radius:14px; font-size:14px; line-height:1.35; }
  .bot { background:#eef1f4; align-self:flex-start; border-bottom-left-radius:4px; }
  .user { background:var(--brand); color:#fff; align-self:flex-end; border-bottom-right-radius:4px; }
  .chips { display:flex; flex-wrap:wrap; gap:6px; padding:0 14px 10px; }
  .chip { font-size:12px; border:1px solid #dcdfe3; background:#fff; border-radius:14px;
          padding:6px 10px; cursor:pointer; }
  .chip:hover { border-color:var(--brand); }
  .bar { display:flex; gap:8px; padding:12px 14px; border-top:1px solid #eee; }
  .bar input { flex:1; border:1px solid #dcdfe3; border-radius:10px; padding:10px; font-size:14px; }
  .bar button { background:var(--brand); color:#fff; border:0; border-radius:10px;
                padding:0 16px; font-weight:600; cursor:pointer; }
  .foot { text-align:center; font-size:11px; color:#8a8f98; padding:8px; }
</style>
</head>
<body>
  <div class="wrap">
    <div class="head">
      <span class="demo-tag">Live demo</span>
      <h1>${esc(spec.business_name)} Assistant</h1>
      <p>Answering your customers 24/7</p>
    </div>
    <div class="log" id="log"></div>
    <div class="chips" id="chips"></div>
    <div class="bar">
      <input id="in" placeholder="Ask a question…" autocomplete="off" />
      <button id="send">Send</button>
    </div>
    <div class="foot">Demo built for ${esc(spec.business_name)} · recommended engine: ${esc(spec.recommended_engine)}</div>
  </div>
<script>
  const DATA = ${payload};
  const log = document.getElementById("log");
  const chips = document.getElementById("chips");
  const input = document.getElementById("in");
  const stop = new Set("the a an is are do you your i we to for of and or in on at how what can with".split(" "));
  function add(text, who) {
    const d = document.createElement("div");
    d.className = "msg " + who;
    d.textContent = text;
    log.appendChild(d);
    log.scrollTop = log.scrollHeight;
  }
  function answer(q) {
    const words = q.toLowerCase().replace(/[^a-z0-9 ]/g," ").split(" ").filter(w=>w&&!stop.has(w));
    let best=null, score=0;
    for (const item of DATA.faq) {
      const hay = (item.q + " " + item.a).toLowerCase();
      let s = 0; for (const w of words) if (hay.includes(w)) s++;
      if (s > score) { score = s; best = item; }
    }
    return score > 0 && best ? best.a : DATA.cta;
  }
  function ask(q) { add(q,"user"); setTimeout(()=>add(answer(q),"bot"), 350); }
  document.getElementById("send").onclick = () => { const v=input.value.trim(); if(v){ask(v);input.value="";} };
  input.addEventListener("keydown", e => { if(e.key==="Enter") document.getElementById("send").click(); });
  // seed
  add(DATA.greeting, "bot");
  DATA.faq.slice(0,3).forEach(item => {
    const c = document.createElement("div"); c.className="chip"; c.textContent=item.q;
    c.onclick = () => ask(item.q); chips.appendChild(c);
  });
</script>
</body>
</html>`;
}

// ---- CLI -------------------------------------------------------------------
if (import.meta.url === `file://${process.argv[1]}`) {
  const [, , researchPath, outDir = "./out/demo"] = process.argv;
  if (!researchPath) {
    console.error('Usage: node --env-file=.env generate-ecosystem.mjs <research.json> [outDir]');
    process.exit(1);
  }
  const research = JSON.parse(readFileSync(researchPath, "utf8"));
  generateSpec(research)
    .then((spec) => {
      mkdirSync(outDir, { recursive: true });
      writeFileSync(join(outDir, "spec.json"), JSON.stringify(spec, null, 2));
      writeFileSync(join(outDir, "demo.html"), renderDemoHtml(spec));
      console.log(`Wrote ${join(outDir, "spec.json")} and ${join(outDir, "demo.html")}`);
    })
    .catch((err) => { console.error("Error:", err.message); process.exit(1); });
}
