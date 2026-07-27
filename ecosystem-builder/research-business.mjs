// research-business.mjs
// Ecosystem Builder — Step 2 (ENRICH): research one business with Perplexity so
// the pitch can be personalized ("here's YOUR AI assistant, already built").
//
// The API key is read from the environment — NEVER hard-code it, never commit it.
//   1. cp .env.example .env
//   2. put your real key in .env  (that file is gitignored)
//   3. run:  node --env-file=.env research-business.mjs "Business Name" "website.com"
//
// Requires Node 18+ (built-in fetch) — Node 20+ for the --env-file flag.

const API_URL = "https://api.perplexity.ai/chat/completions";
const MODEL = process.env.PERPLEXITY_MODEL ?? "sonar"; // sonar | sonar-pro

/**
 * Research a business and return a structured object the pitch step can use.
 * @param {{name: string, website?: string}} biz
 * @returns {Promise<object>}
 */
export async function researchBusiness({ name, website }) {
  const key = process.env.PERPLEXITY_API_KEY;
  if (!key) {
    throw new Error(
      "PERPLEXITY_API_KEY is not set. Copy .env.example to .env and add your key.",
    );
  }

  const question =
    `Research this business: "${name}"` +
    (website ? ` (website: ${website})` : "") +
    `. Return ONLY a JSON object with these keys:\n` +
    `  what_they_do        — one sentence, plain language\n` +
    `  online_presence     — website/social summary; note if none found\n` +
    `  gaps                — array of things they likely lack that AI could add ` +
    `(e.g. no website chatbot, no online booking, slow lead response)\n` +
    `  personalization_hooks — array of specific, true details to open a cold email with\n` +
    `  suggested_pitch_angle — one sentence: which AI "engine" to lead the pitch with\n` +
    `Base it on real, current, public info. If you can't verify something, say so.`;

  const res = await fetch(API_URL, {
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
          content:
            "You are a B2B sales researcher. Be accurate, cite nothing you " +
            "cannot verify, and output valid JSON only — no prose, no markdown.",
        },
        { role: "user", content: question },
      ],
      temperature: 0.2,
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Perplexity API ${res.status}: ${body}`);
  }

  const data = await res.json();
  const content = data.choices?.[0]?.message?.content ?? "";

  // The model is asked for pure JSON, but strip accidental ```json fences just in case.
  const cleaned = content.replace(/^```(?:json)?/i, "").replace(/```$/i, "").trim();
  try {
    return JSON.parse(cleaned);
  } catch {
    // If it didn't return clean JSON, hand back the raw text so nothing is lost.
    return { raw: content, parse_error: true };
  }
}

// ---- CLI entry point -------------------------------------------------------
// Run directly:  node --env-file=.env research-business.mjs "Name" "website.com"
if (import.meta.url === `file://${process.argv[1]}`) {
  const [, , name, website] = process.argv;
  if (!name) {
    console.error(
      'Usage: node --env-file=.env research-business.mjs "Business Name" "website.com"',
    );
    process.exit(1);
  }
  researchBusiness({ name, website })
    .then((result) => console.log(JSON.stringify(result, null, 2)))
    .catch((err) => {
      console.error("Error:", err.message);
      process.exit(1);
    });
}
