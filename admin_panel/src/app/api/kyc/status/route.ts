import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, getUserIdFromToken } from "@/lib/pocketbase";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

// GET /api/kyc/status — called by mobile app to check own KYC status
// Validates user token (not admin), returns their KYC doc + user profile fields
export async function GET(req: NextRequest) {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401, headers: cors });
  }

  const uid = getUserIdFromToken(authHeader.substring(7));
  if (!uid) {
    return NextResponse.json({ error: "Invalid or expired token" }, { status: 401, headers: cors });
  }

  try {
    const pb = await getAdminPb();

    // Fetch user profile
    const userRecord = await pb.collection("users").getOne(uid);
    const profile = {
      fullName: userRecord.fullName ?? userRecord.name ?? "",
      email: userRecord.email ?? "",
      kycStatus: userRecord.kycStatus ?? "not_started",
    };

    // Try to fetch KYC submission for this user (filter by userId)
    let kycRecords: any[] = [];
    try {
      kycRecords = await pb.collection("kyc_verifications").getFullList({
        filter: `userId="${uid}"`,
        sort: "-created",
      });
    } catch {
      kycRecords = [];
    }

    if (kycRecords.length === 0) {
      // No submission yet — return profile so the form can be pre-filled
      return NextResponse.json(
        { kyc: null, profile },
        { status: 200, headers: cors }
      );
    }

    // Return the most recent submission (already sorted by -created)
    const kycRecord = kycRecords[0];

    return NextResponse.json(
      {
        kyc: kycRecord,
        profile: {
          ...profile,
          kycStatus: userRecord.kycStatus ?? kycRecord.status ?? "not_started",
        },
      },
      { status: 200, headers: cors }
    );
  } catch (e: any) {
    console.error("[GET /api/kyc/status]", e);
    return NextResponse.json(
      { error: e.message || "Failed to fetch KYC status" },
      { status: 500, headers: cors }
    );
  }
}
