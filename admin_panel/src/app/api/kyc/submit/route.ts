import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, getUserIdFromToken } from "@/lib/pocketbase";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

// POST /api/kyc/submit — called by mobile app to submit KYC documents
export async function POST(req: NextRequest) {
  // ── 1. Verify user token (not admin — regular user) ──────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401, headers: cors });
  }

  const uid = getUserIdFromToken(authHeader.substring(7));
  if (!uid) {
    return NextResponse.json({ error: "Invalid or expired token" }, { status: 401, headers: cors });
  }
  // PocketBase v0.37.5 JWTs no longer include email; we fall back to the DB record below
  const userEmail: string | undefined = undefined;

  // ── 2. Parse body ────────────────────────────────────────────────────────
  let body: Record<string, any>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400, headers: cors });
  }

  // ── 3. Validate required fields ──────────────────────────────────────────
  const required = ["fullName", "documentType", "documentNumber"];
  for (const field of required) {
    if (!body[field]?.toString().trim()) {
      return NextResponse.json({ error: `${field} is required` }, { status: 400, headers: cors });
    }
  }

  try {
    const pb = await getAdminPb();

    // ── 4. Check for existing approved or pending submission ─────────────────
    const existingRecords = await pb.collection("kyc_verifications").getFullList({
      filter: `userId="${uid}"`,
      sort: "-created",
    });

    if (existingRecords.length > 0) {
      const existingStatus = existingRecords[0].status;
      if (existingStatus === "approved") {
        return NextResponse.json(
          { error: "Your identity is already verified." },
          { status: 409, headers: cors }
        );
      }
      if (existingStatus === "pending") {
        return NextResponse.json(
          { error: "You already have a pending verification. Please wait for review." },
          { status: 409, headers: cors }
        );
      }
    }

    // ── 5. Get user info for denormalised fields ──────────────────────────────
    const userRecord = await pb.collection("users").getOne(uid);
    const resolvedEmail = userEmail ?? userRecord.email ?? "";
    const resolvedName = body.fullName?.trim() || userRecord.fullName || "";

    // ── 6. Write KYC submission ───────────────────────────────────────────────
    const kycData = {
      userId: uid,
      userName: resolvedName,
      fullName: resolvedName,
      userEmail: resolvedEmail,
      email: resolvedEmail,
      documentType: body.documentType?.trim(),
      documentNumber: body.documentNumber?.trim(),
      documentExpiry: body.documentExpiry ?? null,
      dateOfBirth: body.dateOfBirth ?? null,
      nationality: body.nationality ?? null,
      address: body.address ?? null,
      city: body.city ?? null,
      country: body.country ?? null,
      postalCode: body.postalCode ?? null,
      // Image URLs — support both naming conventions
      documentFrontUrl: body.documentFrontUrl ?? body.frontImageUrl ?? null,
      documentBackUrl: body.documentBackUrl ?? body.backImageUrl ?? null,
      documentFront: body.documentFrontUrl ?? body.frontImageUrl ?? null,
      documentBack: body.documentBackUrl ?? body.backImageUrl ?? null,
      selfieUrl: body.selfieUrl ?? null,
      selfie: body.selfieUrl ?? null,
      status: "pending",
      submittedAt: new Date().toISOString(),
      rejectionReason: null,
      reviewedAt: null,
      reviewedBy: null,
    };

    await pb.collection("kyc_verifications").create(kycData);

    // ── 7. Update user's kycStatus to pending ────────────────────────────────
    await pb.collection("users").update(uid, { kycStatus: "pending" });

    // ── 8. Notify user of successful submission ───────────────────────────────
    await pb.collection("notifications").create({
      userId: uid,
      title: "KYC Submitted",
      message: "Your identity verification documents have been submitted and are under review. We'll notify you once reviewed.",
      type: "kyc",
      isRead: false,
    });

    return NextResponse.json(
      { success: true, message: "KYC submitted successfully. Pending admin review." },
      { status: 200, headers: cors }
    );
  } catch (e: any) {
    console.error("[POST /api/kyc/submit]", e);
    return NextResponse.json(
      { error: e.message || "Failed to submit KYC" },
      { status: 500, headers: cors }
    );
  }
}
