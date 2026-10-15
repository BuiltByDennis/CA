// CA — MTN MoMo callback receiver (Phase 7 scaffold).
//
// Deploy when the CA business has an MTN MoMo merchant (API) account:
//   supabase functions deploy momo-callback
//   supabase secrets set CA_CALLBACK_SECRET=<a long random string>
// and register this function's URL as the callback for request-to-pay
// calls whose externalId is the CA payment reference (CA-<receiptNo>).
//
// The function authenticates the caller with the shared-secret header
// (set the same value in the MoMo API portal / API user config) and then
// upserts the outcome into public.momo_payments using the service role.
// Sellers' apps read confirmations from that table on their next Sync
// and mark the matching receipt paid — no polling of MTN needed.
//
// NOTE: MTN also supports callback-state polling; if callbacks prove
// unreliable in production, add a scheduled poller using the same table.

import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const secret = Deno.env.get("CA_CALLBACK_SECRET");
  if (!secret || req.headers.get("x-ca-callback-secret") !== secret) {
    return new Response("unauthorized", { status: 401 });
  }
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response("bad json", { status: 400 });
  }
  // MTN collection callback fields (names per MTN MoMo API docs):
  const reference = String(body.externalId ?? "");
  const status = String(body.status ?? "").toUpperCase();
  if (!reference.startsWith("CA-")) {
    return new Response("unknown reference", { status: 422 });
  }
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const confirmed = status === "SUCCESSFUL";
  const outcome = {
    status: confirmed ? "confirmed" : "failed",
    provider_txn_id: String(body.financialTransactionId ?? ""),
    confirmed_at: confirmed ? new Date().toISOString() : null,
  };
  // The payment-initiation step (whoever calls MTN request-to-pay with
  // MTN credentials) creates the momo_payments row first, WITH the
  // seller's ca_business_id — a bare MTN callback cannot know it. So:
  // update the existing row's outcome; only create a row when the caller
  // also identifies the business.
  const { data: existing } = await supabase
    .from("momo_payments")
    .select("id")
    .eq("request_reference", reference)
    .maybeSingle();
  if (existing) {
    const { error } = await supabase
      .from("momo_payments")
      .update(outcome)
      .eq("request_reference", reference);
    if (error) return new Response(error.message, { status: 500 });
    return new Response("ok");
  }
  const caBusinessId = String(body.caBusinessId ?? "");
  if (!caBusinessId) {
    return new Response("unattributed payment reference", { status: 422 });
  }
  const { error } = await supabase.from("momo_payments").insert({
    request_reference: reference,
    receipt_no: reference.substring(0, reference.lastIndexOf('-')),
    ca_business_id: caBusinessId,
    amount_pesewas: body.amount ? Math.round(Number(body.amount) * 100) : null,
    payer_phone: body.payer ? String((body.payer as any).partyId ?? "") : null,
    ...outcome,
  });
  if (error) return new Response(error.message, { status: 500 });
  return new Response("ok");
});
