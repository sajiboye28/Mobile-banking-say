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

const VALID_STATUSES = ["active", "pending", "suspended", "closed", "frozen"] as const;
type AccountStatus = (typeof VALID_STATUSES)[number];

export async function POST(req: NextRequest, { params }: { params: { uid: string } }) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) return NextResponse.json({ error: "Unauthorized" }, { status: 401, headers: cors });

  const { uid } = params;
  if (!uid) return NextResponse.json({ error: "uid required" }, { status: 400, headers: cors });

  let body: { status: AccountStatus; canTransact?: boolean };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400, headers: cors });
  }

  const { status, canTransact } = body;

  if (!status || !(VALID_STATUSES as readonly string[]).includes(status)) {
    return NextResponse.json(
      { error: `status must be one of: ${VALID_STATUSES.join(", ")}` },
      { status: 400, headers: cors }
    );
  }

  try {
    const pb = await getAdminPb();

    // Verify user exists
    await pb.collection("users").getOne(uid);

    // Determine canTransact value based on status
    let resolvedCanTransact: boolean;
    if (typeof canTransact === "boolean") {
      // Caller explicitly provided canTransact, but still enforce safety for suspended/closed/frozen
      resolvedCanTransact = ["suspended", "closed", "frozen"].includes(status) ? false : canTransact;
    } else {
      // Auto-derive from status
      resolvedCanTransact = status === "active";
    }

    await pb.collection("users").update(uid, {
      accountStatus: status,
      canTransact: resolvedCanTransact,
    });

    return NextResponse.json(
      { success: true, accountStatus: status, canTransact: resolvedCanTransact },
      { headers: cors }
    );
  } catch (e: any) {
    if (e?.status === 404) {
      return NextResponse.json({ error: "User not found" }, { status: 404, headers: cors });
    }
    return NextResponse.json({ error: e.message || "Server error" }, { status: 500, headers: cors });
  }
}
