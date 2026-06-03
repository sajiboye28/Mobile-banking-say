import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, verifyAdmin } from "@/lib/pocketbase";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, PATCH, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

// POST /api/users/[uid]/transaction
// Create a new transaction record for the user (admin-injected).
// Body: { type: "credit"|"debit", amount: number, description: string, status?: string }
export async function POST(req: NextRequest, { params }: { params: { uid: string } }) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) return NextResponse.json({ error: "Unauthorized" }, { status: 401, headers: cors });

  const { uid } = params;
  if (!uid) return NextResponse.json({ error: "uid required" }, { status: 400, headers: cors });

  let body: { type: "credit" | "debit"; amount: number; description: string; status?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400, headers: cors });
  }

  const { type, amount, description, status = "Success" } = body;

  if (!type || !["credit", "debit"].includes(type)) {
    return NextResponse.json({ error: "type must be 'credit' or 'debit'" }, { status: 400, headers: cors });
  }
  if (typeof amount !== "number" || amount <= 0) {
    return NextResponse.json({ error: "amount must be a positive number" }, { status: 400, headers: cors });
  }
  if (!description || typeof description !== "string") {
    return NextResponse.json({ error: "description is required" }, { status: 400, headers: cors });
  }

  try {
    const pb = await getAdminPb();

    // Verify user exists
    await pb.collection("users").getOne(uid);

    const newTx = await pb.collection("transactions").create({
      userId: uid,
      amount,
      type: type === "credit" ? "Credit" : "Debit",
      description: description.trim(),
      status,
      createdBy: adminUid,
      source: "admin_manual",
    });

    return NextResponse.json(
      { success: true, transactionId: newTx.id },
      { status: 201, headers: cors }
    );
  } catch (e: any) {
    if (e?.status === 404) {
      return NextResponse.json({ error: "User not found" }, { status: 404, headers: cors });
    }
    return NextResponse.json({ error: e.message || "Server error" }, { status: 500, headers: cors });
  }
}

// PATCH /api/users/[uid]/transaction
// Update fields on an existing transaction.
// Body: { transactionId: string, ...updatableFields }
const ALLOWED_TX_UPDATE_FIELDS = new Set([
  "type",
  "amount",
  "description",
  "status",
  "timestamp",
  "relatedUserId",
  "relatedUserName",
]);

export async function PATCH(req: NextRequest, { params }: { params: { uid: string } }) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) return NextResponse.json({ error: "Unauthorized" }, { status: 401, headers: cors });

  const { uid } = params;
  if (!uid) return NextResponse.json({ error: "uid required" }, { status: 400, headers: cors });

  let body: Record<string, any>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400, headers: cors });
  }

  const { transactionId, ...rest } = body;

  if (!transactionId) {
    return NextResponse.json({ error: "transactionId is required" }, { status: 400, headers: cors });
  }

  const updates: Record<string, any> = {};
  for (const key of Object.keys(rest)) {
    if (ALLOWED_TX_UPDATE_FIELDS.has(key)) {
      updates[key] = rest[key];
    }
  }

  if (Object.keys(updates).length === 0) {
    return NextResponse.json({ error: "No valid fields to update" }, { status: 400, headers: cors });
  }

  try {
    const pb = await getAdminPb();

    const txRecord = await pb.collection("transactions").getOne(transactionId);

    // Confirm the transaction belongs to this user
    if (txRecord.userId !== uid) {
      return NextResponse.json(
        { error: "Transaction does not belong to this user" },
        { status: 403, headers: cors }
      );
    }

    updates.updatedBy = adminUid;

    const updated = await pb.collection("transactions").update(transactionId, updates);

    return NextResponse.json(
      { success: true, transaction: { transactionId: updated.id, ...updated } },
      { headers: cors }
    );
  } catch (e: any) {
    if (e?.status === 404) {
      return NextResponse.json({ error: "Transaction not found" }, { status: 404, headers: cors });
    }
    return NextResponse.json({ error: e.message || "Server error" }, { status: 500, headers: cors });
  }
}

// DELETE /api/users/[uid]/transaction
// Permanently delete a transaction record.
// Body: { transactionId: string }
export async function DELETE(req: NextRequest, { params }: { params: { uid: string } }) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) return NextResponse.json({ error: "Unauthorized" }, { status: 401, headers: cors });

  const { uid } = params;
  if (!uid) return NextResponse.json({ error: "uid required" }, { status: 400, headers: cors });

  let body: { transactionId: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400, headers: cors });
  }

  const { transactionId } = body;
  if (!transactionId) {
    return NextResponse.json({ error: "transactionId is required" }, { status: 400, headers: cors });
  }

  try {
    const pb = await getAdminPb();

    const txRecord = await pb.collection("transactions").getOne(transactionId);

    // Confirm the transaction belongs to this user
    if (txRecord.userId !== uid) {
      return NextResponse.json(
        { error: "Transaction does not belong to this user" },
        { status: 403, headers: cors }
      );
    }

    await pb.collection("transactions").delete(transactionId);

    return NextResponse.json({ success: true, deleted: transactionId }, { headers: cors });
  } catch (e: any) {
    if (e?.status === 404) {
      return NextResponse.json({ error: "Transaction not found" }, { status: 404, headers: cors });
    }
    return NextResponse.json({ error: e.message || "Server error" }, { status: 500, headers: cors });
  }
}
