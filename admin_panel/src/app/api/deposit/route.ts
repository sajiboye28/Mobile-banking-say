import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, getUserIdFromToken } from "@/lib/pocketbase";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function POST(req: NextRequest) {
  // ── 1. Verify PocketBase user token ──────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return NextResponse.json(
      { error: "Unauthorized." },
      { status: 401, headers: corsHeaders }
    );
  }

  const uid = getUserIdFromToken(authHeader.substring(7));
  if (!uid) {
    return NextResponse.json(
      { error: "Invalid or expired token." },
      { status: 401, headers: corsHeaders }
    );
  }

  let body: { amount: number; source?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json(
      { error: "Invalid request body." },
      { status: 400, headers: corsHeaders }
    );
  }

  const { amount, source = "External Bank Account" } = body;

  if (typeof amount !== "number" || amount <= 0 || amount > 50000) {
    return NextResponse.json(
      { error: "Amount must be between $0.01 and $50,000." },
      { status: 400, headers: corsHeaders }
    );
  }

  try {
    const pb = await getAdminPb();

    // Fetch the user
    const userRecord = await pb.collection("users").getOne(uid);

    if (userRecord.accountStatus !== "active") {
      return NextResponse.json(
        { error: "Your account is not active. Contact support." },
        { status: 422, headers: corsHeaders }
      );
    }

    const currentBalance: number =
      typeof userRecord.balance === "number" ? userRecord.balance : 0;
    const newBalance = currentBalance + amount;

    // Update balance
    await pb.collection("users").update(uid, { balance: newBalance });

    // Create transaction record
    const newTx = await pb.collection("transactions").create({
      userId: uid,
      amount,
      type: "Credit",
      description: `Deposit from ${source}`,
      status: "Success",
      relatedUserId: null,
      relatedUserName: source,
    });

    // Create notification
    await pb.collection("notifications").create({
      userId: uid,
      title: "Deposit Successful",
      message: `$${amount.toFixed(2)} has been added to your account from ${source}.`,
      type: "credit",
      isRead: false,
      data: JSON.stringify({ transactionId: newTx.id }),
    });

    return NextResponse.json(
      { success: true, newBalance, transactionId: newTx.id },
      { status: 200, headers: corsHeaders }
    );
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Deposit failed.";
    return NextResponse.json({ error: message }, { status: 422, headers: corsHeaders });
  }
}
