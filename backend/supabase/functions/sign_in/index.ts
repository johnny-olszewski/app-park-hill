// sign_in: email and password sign-in owned by the backend (specs/AUTH.md 5.5).
// The backend decides the outcome and the message the user reads, and limits
// password guessing per email and per client address.
//
// Never log or store the request body: passwords pass through this code.
// Logs carry only the outcome code; emails are stored only as keyed hashes.

// Attempt limiting. Tune here.
const LIMITS = {
  windowMinutes: 15,
  failuresPerEmail: 5,
  failuresPerAddress: 20,
};

const MAX_EMAIL_LENGTH = 254;
const MAX_PASSWORD_LENGTH = 1024;

// Last resort when even the message lookup fails.
const FALLBACK_MESSAGE = "Something went wrong. Please try again.";

type ErrorCode =
  | "invalid_credentials"
  | "account_disabled"
  | "too_many_attempts"
  | "invalid_request"
  | "unknown";

// Spec 5.5: failures use 400, 401, 403 or 429 only.
const STATUS: Record<ErrorCode, number> = {
  invalid_credentials: 401,
  account_disabled: 403,
  too_many_attempts: 429,
  invalid_request: 400,
  unknown: 400,
};

type Outcome = "success" | "failure" | "disabled" | "limited";

const env = {
  url: Deno.env.get("SUPABASE_URL")!,
  anonKey: Deno.env.get("SUPABASE_ANON_KEY")!,
  serviceKey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
};

interface SignInRequest {
  email: string;
  password: string;
  locale: string;
}

Deno.serve(async (req) => {
  let locale = "en";
  try {
    const parsed = await parseRequest(req);
    if (!parsed) return await fail("invalid_request", locale);
    locale = parsed.locale;
    return await signIn(parsed, clientAddress(req));
  } catch (error) {
    log("unknown", error instanceof Error ? error.name : "error");
    return await fail("unknown", locale);
  }
});

async function signIn(request: SignInRequest, address: string): Promise<Response> {
  const emailHash = await hashEmail(request.email);
  const since = new Date(Date.now() - LIMITS.windowMinutes * 60_000).toISOString();
  const counts = await rpc<{ email: number; address: number }>("sign_in_failure_counts", {
    p_email_hash: emailHash,
    p_client_address: address,
    p_since: since,
  });

  if (counts.email >= LIMITS.failuresPerEmail || counts.address >= LIMITS.failuresPerAddress) {
    await record(emailHash, address, "limited");
    return await fail("too_many_attempts", request.locale);
  }

  const auth = await fetch(`${env.url}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: { apikey: env.anonKey, "Content-Type": "application/json" },
    body: JSON.stringify({ email: request.email, password: request.password }),
  });
  const body = await auth.json().catch(() => ({}));

  if (auth.ok && body.access_token) {
    await record(emailHash, address, "success");
    log("ok");
    return json(200, {
      status: "ok",
      session: {
        access_token: body.access_token,
        refresh_token: body.refresh_token,
        expires_at: body.expires_at,
        user_id: body.user?.id,
      },
    });
  }

  switch (body.error_code) {
    case "user_banned":
      await record(emailHash, address, "disabled");
      return await fail("account_disabled", request.locale);
    case "over_request_rate_limit":
      return await fail("too_many_attempts", request.locale);
    case "invalid_credentials":
    case "email_not_confirmed":
      await record(emailHash, address, "failure");
      return await fail("invalid_credentials", request.locale);
    default:
      if (auth.status >= 400 && auth.status < 500 && auth.status !== 429) {
        await record(emailHash, address, "failure");
        return await fail("invalid_credentials", request.locale);
      }
      throw new Error(`auth status ${auth.status}`);
  }
}

async function parseRequest(req: Request): Promise<SignInRequest | null> {
  if (req.method !== "POST") return null;
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return null;
  }
  if (typeof body !== "object" || body === null) return null;
  const { email, password, locale } = body as Record<string, unknown>;
  if (typeof email !== "string" || typeof password !== "string") return null;
  const trimmed = email.trim();
  if (!trimmed.includes("@") || trimmed.length > MAX_EMAIL_LENGTH) return null;
  if (password.length === 0 || password.length > MAX_PASSWORD_LENGTH) return null;
  if (locale !== undefined && typeof locale !== "string") return null;
  return { email: trimmed, password, locale: locale || "en" };
}

// The first X-Forwarded-For entry is the original client.
function clientAddress(req: Request): string {
  const forwarded = req.headers.get("x-forwarded-for");
  return forwarded?.split(",")[0]?.trim() || "unknown";
}

// HMAC-SHA256 of the normalized email, keyed with the service role key, so
// stored hashes cannot be reversed by hashing a list of addresses.
async function hashEmail(email: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(env.serviceKey),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(email.toLowerCase()));
  return Array.from(new Uint8Array(signature), (b) => b.toString(16).padStart(2, "0")).join("");
}

async function record(emailHash: string, address: string, outcome: Outcome): Promise<void> {
  await rpc("record_sign_in_attempt", {
    p_email_hash: emailHash,
    p_client_address: address,
    p_outcome: outcome,
  });
}

async function fail(code: ErrorCode, locale: string): Promise<Response> {
  log(code);
  let message: string;
  try {
    message = await rpc<string>("sign_in_error_message", { p_code: code, p_locale: locale });
  } catch {
    if (code !== "unknown") return await fail("unknown", locale);
    message = FALLBACK_MESSAGE;
  }
  return json(STATUS[code], { status: "error", code, message });
}

async function rpc<T>(fn: string, params: Record<string, unknown>): Promise<T> {
  const response = await fetch(`${env.url}/rest/v1/rpc/${fn}`, {
    method: "POST",
    headers: {
      apikey: env.serviceKey,
      Authorization: `Bearer ${env.serviceKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(params),
  });
  if (!response.ok) throw new Error(`rpc ${fn} failed with ${response.status}`);
  const text = await response.text();
  return (text ? JSON.parse(text) : null) as T;
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function log(outcome: string, detail?: string): void {
  console.log(JSON.stringify({ fn: "sign_in", outcome, ...(detail ? { detail } : {}) }));
}
