import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, verifyAdmin } from "@/lib/pocketbase";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, PATCH, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function GET(req: NextRequest, { params }: { params: { uid: string } }) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) return NextResponse.json({ error: "Unauthorized" }, { status: 401, headers: cors });

  const { uid } = params;
  if (!uid) return NextResponse.json({ error: "uid required" }, { status: 400, headers: cors });

  try {
    const pb = await getAdminPb();

    const [userRecord, transactions, notifications, otpRecords] = await Promise.all([
      pb.collection("users").getOne(uid),
      pb.collection("transactions").getFullList({
        filter: `userId="${uid}"`,
        sort: "-created",
      }),
      pb.collection("notifications").getFullList({
        filter: `userId="${uid}"`,
        sort: "-created",
      }),
      pb.collection("transaction_otps").getFullList({
        filter: `userId="${uid}" && used=false`,
        sort: "-created",
        perPage: 1,
      }),
    ]);

    // Map PocketBase `id` to `uid` for front-end compatibility
    const userData = { uid: userRecord.id, ...userRecord };

    const txList = transactions.map((t) => ({ transactionId: t.id, ...t }));
    const notifList = notifications.map((n) => ({ ...n }));
    const latestOtp = otpRecords[0] ?? null;

    return NextResponse.json({ user: userData, transactions: txList, notifications: notifList, latestOtp }, { headers: cors });
  } catch (e: any) {
    if (e?.status === 404) {
      return NextResponse.json({ error: "User not found" }, { status: 404, headers: cors });
    }
    return NextResponse.json({ error: e.message || "Server error" }, { status: 500, headers: cors });
  }
}

// Allowed updatable fields for PATCH
const ALLOWED_FIELDS = new Set([
  "fullName",
  "phone",
  "address",
  "city",
  "country",
  "postalCode",
  "accountType",
  "accountStatus",
  "canTransact",
  "tccCode",
  "kycStatus",
  "balance",
  "two_fa_enabled",
  "login_alerts_enabled",
  "email",
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

  // Filter to only allowed fields
  const updates: Record<string, any> = {};
  for (const key of Object.keys(body)) {
    if (ALLOWED_FIELDS.has(key)) {
      updates[key] = body[key];
    }
  }

  if (Object.keys(updates).length === 0) {
    return NextResponse.json({ error: "No valid fields to update" }, { status: 400, headers: cors });
  }

  try {
    const pb = await getAdminPb();

    // Verify user exists
    await pb.collection("users").getOne(uid);

    // Auto-set canTransact based on accountStatus changes
    if ("accountStatus" in updates) {
      const newStatus = updates.accountStatus;
      if (newStatus === "suspended" || newStatus === "closed" || newStatus === "frozen") {
        updates.canTransact = false;
      } else if (newStatus === "active") {
        if (!("canTransact" in body)) {
          updates.canTransact = true;
        }
      }
    }

    const updatedRecord = await pb.collection("users").update(uid, updates);

    // Map id to uid for compatibility
    const updatedUser = { uid: updatedRecord.id, ...updatedRecord };

    return NextResponse.json({ success: true, user: updatedUser }, { headers: cors });
  } catch (e: any) {
    if (e?.status === 404) {
      return NextResponse.json({ error: "User not found" }, { status: 404, headers: cors });
    }
    return NextResponse.json({ error: e.message || "Server error" }, { status: 500, headers: cors });
  }
}

async function deleteCollectionRecords(
  pb: Awaited<ReturnType<typeof getAdminPb>>,
  collectionName: string,
  field: string,
  uid: string
): Promise<number> {
  try {
    const records = await pb.collection(collectionName).getFullList({
      filter: `${field}="${uid}"`,
    });
    await Promise.all(records.map((r) => pb.collection(collectionName).delete(r.id)));
    return records.length;
  } catch {
    return 0;
  }
}

export async function DELETE(req: NextRequest, { params }: { params: { uid: string } }) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) return NextResponse.json({ error: "Unauthorized" }, { status: 401, headers: cors });

  const { uid } = params;
  if (!uid) return NextResponse.json({ error: "uid required" }, { status: 400, headers: cors });

  // Prevent self-deletion
  if (uid === adminUid) {
    return NextResponse.json({ error: "Cannot delete your own account" }, { status: 400, headers: cors });
  }

  try {
    const pb = await getAdminPb();
    const results: Record<string, number> = {};

    const collections: { name: string; field: string }[] = [
      { name: "transactions", field: "userId" },
      { name: "virtual_cards", field: "userId" },
      { name: "notifications", field: "userId" },
      { name: "savings_goals", field: "userId" },
      { name: "bill_payments", field: "userId" },
      { name: "loans", field: "userId" },
      { name: "support_tickets", field: "userId" },
      { name: "kyc_verifications", field: "userId" },
      { name: "scheduled_payments", field: "userId" },
      { name: "payment_requests", field: "fromUserId" },
    ];

    for (const col of collections) {
      results[col.name] = await deleteCollectionRecords(pb, col.name, col.field, uid);
    }

    // Delete user record
    await pb.collection("users").delete(uid);
    results["users"] = 1;

    return NextResponse.json({ success: true, deleted: results }, { headers: cors });
  } catch (e: any) {
    if (e?.status === 404) {
      return NextResponse.json({ error: "User not found" }, { status: 404, headers: cors });
    }
    return NextResponse.json({ error: e.message || "Server error" }, { status: 500, headers: cors });
  }
}
