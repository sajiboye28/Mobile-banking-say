import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, verifyAdmin } from "@/lib/pocketbase";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

const CONFIG_COLLECTION = "systemConfig";
const CONFIG_ID_FILTER = `configKey="global"`;

// GET /api/config — returns current system config
export async function GET(req: NextRequest) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401, headers: corsHeaders });
  }

  try {
    const pb = await getAdminPb();

    let data: Record<string, any> = {};
    try {
      const records = await pb.collection(CONFIG_COLLECTION).getFullList({
        filter: CONFIG_ID_FILTER,
      });
      if (records.length > 0) data = records[0];
    } catch {
      // Collection may not exist yet — return defaults
    }

    const config = {
      maintenanceMode: data.maintenanceMode ?? false,
      maintenanceMessage:
        data.maintenanceMessage ??
        "We are currently performing scheduled maintenance. Please check back soon.",
      dailySendLimit: data.dailySendLimit ?? 10000,
      maxSingleTransaction: data.maxSingleTransaction ?? 5000,
      minTransaction: data.minTransaction ?? 1,
      maxDepositPerDay: data.maxDepositPerDay ?? 50000,
      minDeposit: data.minDeposit ?? 10,
      kycRequiredAbove: data.kycRequiredAbove ?? 1000,
      autoApproveKyc: data.autoApproveKyc ?? false,
      welcomeMessage:
        data.welcomeMessage ?? "Welcome to STCU! Your account is ready.",
      transactionSuccessMessage:
        data.transactionSuccessMessage ??
        "Your transaction was completed successfully.",
      kycApprovedMessage:
        data.kycApprovedMessage ??
        "Your identity has been verified. You now have full access to all banking features.",
      appName: data.appName ?? "STCU",
      allowNewRegistrations: data.allowNewRegistrations ?? true,
      defaultBalance: data.defaultBalance ?? 0,
      minTransactionAmount: data.minTransactionAmount ?? 1,
      maxTransactionAmount: data.maxTransactionAmount ?? 100000,
      transactionFeePercent: data.transactionFeePercent ?? 0,
      supportEmail: data.supportEmail ?? "support@realbanking.com",
      supportPhone: data.supportPhone ?? "+1 (555) 000-0000",
      announcement: data.announcement ?? "",
      announcementActive: data.announcementActive ?? false,
    };

    return NextResponse.json({ config }, { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error("GET /api/config error:", error);
    return NextResponse.json(
      { error: "Failed to fetch configuration." },
      { status: 500, headers: corsHeaders }
    );
  }
}

// POST /api/config — updates config fields
// Body: Partial config object to merge
export async function POST(req: NextRequest) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401, headers: corsHeaders });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400, headers: corsHeaders });
  }

  if (!body || typeof body !== "object") {
    return NextResponse.json(
      { error: "Request body must be an object." },
      { status: 400, headers: corsHeaders }
    );
  }

  // Validate numeric fields if present
  const numericFields = [
    "dailySendLimit",
    "maxSingleTransaction",
    "minTransaction",
    "maxDepositPerDay",
    "minDeposit",
    "kycRequiredAbove",
    "defaultBalance",
    "minTransactionAmount",
    "maxTransactionAmount",
    "transactionFeePercent",
  ];

  for (const field of numericFields) {
    if (field in body) {
      const val = Number(body[field]);
      if (isNaN(val) || val < 0) {
        return NextResponse.json(
          { error: `Invalid value for ${field}: must be a non-negative number.` },
          { status: 400, headers: corsHeaders }
        );
      }
      body[field] = val;
    }
  }

  // Validate boolean fields if present
  const booleanFields = [
    "maintenanceMode",
    "autoApproveKyc",
    "allowNewRegistrations",
    "announcementActive",
  ];
  for (const field of booleanFields) {
    if (field in body && typeof body[field] !== "boolean") {
      body[field] = Boolean(body[field]);
    }
  }

  try {
    const pb = await getAdminPb();

    // Upsert: find the global config record or create it
    const existing = await pb
      .collection(CONFIG_COLLECTION)
      .getFullList({ filter: CONFIG_ID_FILTER })
      .catch(() => [] as any[]);

    const payload = { ...body, configKey: "global", updatedBy: adminUid };

    if (existing.length > 0) {
      await pb.collection(CONFIG_COLLECTION).update(existing[0].id, payload);
    } else {
      await pb.collection(CONFIG_COLLECTION).create(payload);
    }

    return NextResponse.json(
      { success: true, message: "Configuration updated successfully." },
      { status: 200, headers: corsHeaders }
    );
  } catch (error) {
    console.error("POST /api/config error:", error);
    return NextResponse.json(
      { error: "Failed to update configuration." },
      { status: 500, headers: corsHeaders }
    );
  }
}
