import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, verifyAdmin } from "@/lib/pocketbase";

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

export async function POST(req: NextRequest) {
  try {
    const adminUid = await verifyAdmin(req);
    if (!adminUid) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

    const { uid } = (await req.json()) as { uid: string };
    if (!uid) return NextResponse.json({ error: "uid is required" }, { status: 400 });

    // Prevent self-deletion
    if (uid === adminUid) {
      return NextResponse.json({ error: "Cannot delete your own account" }, { status: 400 });
    }

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

    return NextResponse.json({ success: true, deleted: results });
  } catch (err: any) {
    if (err?.status === 404) {
      return NextResponse.json({ error: "User not found" }, { status: 404 });
    }
    console.error("[delete-user]", err);
    return NextResponse.json({ error: err.message ?? "Internal error" }, { status: 500 });
  }
}
