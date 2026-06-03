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
  if (!adminUid) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401, headers: cors });
  }

  const { uid } = params;
  if (!uid) {
    return NextResponse.json({ error: "uid required" }, { status: 400, headers: cors });
  }

  try {
    const pb = await getAdminPb();

    // Verify user exists
    await pb.collection("users").getOne(uid);

    // PocketBase does not have a global refresh-token revocation API for regular
    // collections. The practical equivalent is to rotate the user's password hash
    // token salt by issuing a password reset, or to set a custom `sessionRevoked`
    // flag that the mobile app checks on startup. We set the flag here.
    await pb.collection("users").update(uid, { sessionRevoked: true });

    // Create an in-app security notification for the user
    await pb.collection("notifications").create({
      userId: uid,
      title: "Security Alert",
      message: "All active sessions have been terminated by an administrator. Please sign in again.",
      isRead: false,
      type: "security",
    });

    return NextResponse.json({ success: true }, { headers: cors });
  } catch (e: any) {
    if (e?.status === 404) {
      return NextResponse.json({ error: "User not found" }, { status: 404, headers: cors });
    }
    return NextResponse.json({ error: e.message || "Server error" }, { status: 500, headers: cors });
  }
}
