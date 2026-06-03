import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, verifyAdmin } from "@/lib/pocketbase";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function POST(req: NextRequest, { params }: { params: { uid: string } }) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) return NextResponse.json({ error: "Unauthorized" }, { status: 401, headers: cors });

  const { uid } = params;
  if (!uid) return NextResponse.json({ error: "uid required" }, { status: 400, headers: cors });

  let body: { action: "add" | "subtract" | "set"; amount: number; note?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400, headers: cors });
  }

  const { action, amount, note } = body;

  if (!action || !["add", "subtract", "set"].includes(action)) {
    return NextResponse.json({ error: "action must be 'add', 'subtract', or 'set'" }, { status: 400, headers: cors });
  }

  if (typeof amount !== "number" || amount < 0) {
    return NextResponse.json({ error: "amount must be a non-negative number" }, { status: 400, headers: cors });
  }

  try {
    const pb = await getAdminPb();

    const userRecord = await pb.collection("users").getOne(uid);
    const currentBalance: number = typeof userRecord.balance === "number" ? userRecord.balance : 0;

    let newBalance: number;
    let txType: "Credit" | "Debit" | null = null;
    let txDescription = note || "";

    if (action === "add") {
      newBalance = currentBalance + amount;
      txType = "Credit";
      txDescription = txDescription || `Admin credit: +${amount}`;
    } else if (action === "subtract") {
      newBalance = currentBalance - amount;
      if (newBalance < 0) {
        return NextResponse.json(
          { error: `Insufficient balance. Current: ${currentBalance}, requested deduction: ${amount}` },
          { status: 400, headers: cors }
        );
      }
      txType = "Debit";
      txDescription = txDescription || `Admin debit: -${amount}`;
    } else {
      // action === "set"
      newBalance = amount;
      // No transaction record for a direct balance set
    }

    // Update user balance
    await pb.collection("users").update(uid, { balance: newBalance });

    // Create a transaction record for add/subtract actions
    if (txType !== null) {
      await pb.collection("transactions").create({
        userId: uid,
        amount,
        type: txType,
        description: txDescription,
        status: "Success",
        createdBy: adminUid,
        source: "admin_balance_adjustment",
      });
    }

    return NextResponse.json({ success: true, newBalance }, { headers: cors });
  } catch (e: any) {
    if (e?.status === 404) {
      return NextResponse.json({ error: "User not found" }, { status: 404, headers: cors });
    }
    return NextResponse.json({ error: e.message || "Server error" }, { status: 500, headers: cors });
  }
}
