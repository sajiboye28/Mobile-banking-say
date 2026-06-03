import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, verifyAdmin } from "@/lib/pocketbase";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

// POST /api/notify
// Body: { uid: string, title: string, body: string, type: string }
// Requires admin authentication (Bearer token from PocketBase admins collection)
export async function POST(req: NextRequest) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401, headers: corsHeaders });
  }

  // Parse body
  let body: { uid: string; title: string; body: string; type?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400, headers: corsHeaders });
  }

  const { uid, title, body: messageBody, type = "announcement" } = body;

  if (!uid || typeof uid !== "string" || !uid.trim()) {
    return NextResponse.json({ error: "uid is required." }, { status: 400, headers: corsHeaders });
  }
  if (!title || typeof title !== "string" || !title.trim()) {
    return NextResponse.json({ error: "title is required." }, { status: 400, headers: corsHeaders });
  }
  if (!messageBody || typeof messageBody !== "string" || !messageBody.trim()) {
    return NextResponse.json({ error: "body is required." }, { status: 400, headers: corsHeaders });
  }

  try {
    const pb = await getAdminPb();

    // Verify the target user exists
    await pb.collection("users").getOne(uid.trim());

    // Create the notification document
    const notif = await pb.collection("notifications").create({
      userId: uid.trim(),
      title: title.trim(),
      message: messageBody.trim(),
      type: type.trim() || "announcement",
      isRead: false,
      data: JSON.stringify({ sentBy: adminUid }),
    });

    return NextResponse.json(
      { success: true, notificationId: notif.id },
      { status: 201, headers: corsHeaders }
    );
  } catch (error: any) {
    if (error?.status === 404) {
      return NextResponse.json(
        { error: "Target user not found." },
        { status: 404, headers: corsHeaders }
      );
    }
    console.error("POST /api/notify error:", error);
    return NextResponse.json(
      { error: "Failed to create notification." },
      { status: 500, headers: corsHeaders }
    );
  }
}
