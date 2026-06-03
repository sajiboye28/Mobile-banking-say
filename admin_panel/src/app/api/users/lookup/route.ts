import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, getUserIdFromToken } from "@/lib/pocketbase";

// Allow requests from the web app and mobile app
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

/**
 * GET /api/users/lookup?q=<account_number_or_email>
 *
 * Resolves a recipient by account number or email address.
 * Uses the server-side admin token so collection rules do not apply.
 * Returns only the three fields safe to expose to any authenticated caller.
 *
 * Requires a valid PocketBase user Bearer token (any authenticated user).
 */
export async function GET(req: NextRequest) {
  // ── Verify caller is a logged-in user ────────────────────────────────────
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  const callerId = getUserIdFromToken(token);
  if (!callerId) {
    return NextResponse.json(
      { error: "Unauthorized." },
      { status: 401, headers: corsHeaders }
    );
  }

  // ── Parse query ──────────────────────────────────────────────────────────
  const q = (req.nextUrl.searchParams.get("q") ?? "").trim();
  if (!q) {
    return NextResponse.json(
      { error: "Query parameter 'q' is required." },
      { status: 400, headers: corsHeaders }
    );
  }

  try {
    const pb = await getAdminPb();

    // Try account number first, then email
    const isEmail = q.includes("@");
    const filter = isEmail
      ? `email="${q.toLowerCase()}"`
      : `accountNumber="${q}"`;

    const records = await pb.collection("users").getFullList({
      filter,
      perPage: 1,
    });

    if (records.length === 0) {
      return NextResponse.json(
        {
          error: isEmail
            ? "No account found with that email address."
            : "No account found with that account number.",
        },
        { status: 404, headers: corsHeaders }
      );
    }

    const u = records[0];
    // Return only the minimum fields needed to display + send to a recipient
    return NextResponse.json(
      {
        id: u.id,
        fullName: u.fullName || u.name || "Account Holder",
        accountNumber: u.accountNumber || "",
      },
      { status: 200, headers: corsHeaders }
    );
  } catch (err: any) {
    console.error("[users/lookup]", err);
    return NextResponse.json(
      { error: "Lookup failed. Please try again." },
      { status: 500, headers: corsHeaders }
    );
  }
}
