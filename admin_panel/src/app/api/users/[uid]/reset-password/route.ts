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

  // Optional body: { sendEmail?: boolean }
  let sendEmailFlag = false;
  try {
    const body = await req.json().catch(() => ({}));
    if (typeof body.sendEmail === "boolean") sendEmailFlag = body.sendEmail;
  } catch {
    // Body is optional; ignore parse errors
  }

  try {
    const pb = await getAdminPb();

    const userRecord = await pb.collection("users").getOne(uid);
    const email: string | undefined = userRecord.email;

    if (!email) {
      return NextResponse.json(
        { error: "User has no email address on record" },
        { status: 400, headers: cors }
      );
    }

    // Request PocketBase to send a password reset email to the user
    await pb.collection("users").requestPasswordReset(email);

    if (sendEmailFlag) {
      console.log(`[reset-password] Password reset email sent to ${email}`);
    }

    return NextResponse.json({ success: true, email }, { headers: cors });
  } catch (e: any) {
    if (e?.status === 404) {
      return NextResponse.json({ error: "User not found" }, { status: 404, headers: cors });
    }
    return NextResponse.json({ error: e.message || "Server error" }, { status: 500, headers: cors });
  }
}
