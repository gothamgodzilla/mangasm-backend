// stripe-checkout
// Authenticated member asks for a Mangasm+ Checkout Session and gets back a
// Stripe-hosted payment URL. Reuses the member's Stripe customer if one
// exists; otherwise creates it and records the mapping in billing_customers.
//
// Body:    { "plan": "monthly" | "quarterly" }
// Returns: { "url": "https://checkout.stripe.com/…" }
//
// Env (supabase secrets set …):
//   STRIPE_SECRET_KEY        sk_test_… now, sk_live_… at go-live
//   STRIPE_PRICE_MONTHLY     price id for $9.99/mo
//   STRIPE_PRICE_QUARTERLY   price id for $24.99/3mo
//   CHECKOUT_SUCCESS_URL     e.g. https://mangasm.app/plus/success
//   CHECKOUT_CANCEL_URL      e.g. https://mangasm.app/plus
//
// Local run:  supabase functions serve stripe-checkout
// Deploy:     supabase functions deploy stripe-checkout

import Stripe from "https://esm.sh/stripe@14.25.0?target=denonext";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const PRICES: Record<string, string | undefined> = {
  monthly: Deno.env.get("STRIPE_PRICE_MONTHLY"),
  quarterly: Deno.env.get("STRIPE_PRICE_QUARTERLY"),
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { error: "POST only" });

  // Caller identity from the Supabase JWT.
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  const { data: userData, error: authError } = await supabase.auth.getUser(token);
  if (authError || !userData?.user) return json(401, { error: "Not signed in" });
  const user = userData.user;

  const { plan = "monthly" } = await req.json().catch(() => ({}));
  const price = PRICES[plan];
  if (!price) return json(400, { error: `Unknown plan '${plan}'` });

  // Banned members don't get to pay.
  const { data: profile } = await supabase
    .from("profiles").select("is_banned").eq("id", user.id).single();
  if (profile?.is_banned) return json(403, { error: "Account unavailable" });

  // Find or create the Stripe customer for this member.
  const { data: existing } = await supabase
    .from("billing_customers")
    .select("stripe_customer_id").eq("user_id", user.id).maybeSingle();

  let customerId = existing?.stripe_customer_id;
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: user.email ?? undefined,
      metadata: { mangasm_user_id: user.id },
    });
    customerId = customer.id;
    await supabase.from("billing_customers")
      .insert({ user_id: user.id, stripe_customer_id: customerId });
  }

  // Optional: pin Checkout to a Stripe payment method configuration (pmc_…).
  // Account-scoped, so it lives in an env var — the sandbox and live accounts
  // have different pmc ids.
  const pmc = Deno.env.get("STRIPE_PAYMENT_METHOD_CONFIGURATION");

  const session = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer: customerId,
    line_items: [{ price, quantity: 1 }],
    allow_promotion_codes: true,
    ...(pmc ? { payment_method_configuration: pmc } : {}),
    success_url: Deno.env.get("CHECKOUT_SUCCESS_URL") ?? "https://mangasm.app/plus/success",
    cancel_url: Deno.env.get("CHECKOUT_CANCEL_URL") ?? "https://mangasm.app/plus",
    subscription_data: { metadata: { mangasm_user_id: user.id } },
  });

  return json(200, { url: session.url });
});
