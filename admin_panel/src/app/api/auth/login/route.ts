import { NextRequest, NextResponse } from 'next/server';

// CORS headers — allow the Vite dev origin and any production domain.
// In prod the Vite proxy is not used, so the web app origin makes a
// direct cross-origin call to this endpoint.
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

// POST /api/auth/login
// ─────────────────────────────────────────────────────────────────────────────
// Accepts { email, password } from the web app and authenticates the user
// against PocketBase **server-side**.
//
// Why server-side?
//   • The browser's network tab only shows "POST /api/auth/login" going to
//     your own server — the PocketBase URL and the raw auth endpoint are
//     completely hidden from DevTools.
//   • The password travels over your own server's connection to PocketBase
//     (Node.js → PocketBase) instead of directly from the browser.
//   • In production (HTTPS) the browser→server leg is TLS-encrypted.
//
export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => null);
    const email: string = (body?.email ?? '').trim();
    const password: string = body?.password ?? '';

    if (!email || !password) {
      return NextResponse.json(
        { error: 'Email and password are required.' },
        { status: 400, headers: corsHeaders }
      );
    }

    const pbUrl = process.env.POCKETBASE_URL || 'http://127.0.0.1:8091';

    // Server-to-server call — never visible in the browser's network tab
    const pbRes = await fetch(
      `${pbUrl}/api/collections/users/auth-with-password`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ identity: email, password }),
      }
    );

    const data = await pbRes.json().catch(() => ({}));

    if (!pbRes.ok) {
      // Return a generic message so the browser error never leaks internal details
      return NextResponse.json(
        { error: 'Invalid email or password.' },
        { status: 401, headers: corsHeaders }
      );
    }

    // Return only what the client needs — token + public record fields
    return NextResponse.json(
      { token: data.token, record: data.record },
      { headers: corsHeaders }
    );
  } catch {
    return NextResponse.json(
      { error: 'Authentication service unavailable. Please try again.' },
      { status: 503, headers: corsHeaders }
    );
  }
}
