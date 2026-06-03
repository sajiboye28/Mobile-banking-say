import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, verifyAdmin } from "@/lib/pocketbase";
import { sendOtpEmail } from "@/lib/email";

export async function POST(req: NextRequest) {
  try {
    // ── 1. Verify admin token ──────────────────────────────────────────────
    const adminUid = await verifyAdmin(req);
    if (!adminUid) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

    // ── 2. Parse body ──────────────────────────────────────────────────────
    const { uid, tccCode } = (await req.json()) as { uid: string; tccCode: string };
    if (!uid || !tccCode) {
      return NextResponse.json({ error: "uid and tccCode are required" }, { status: 400 });
    }

    const pb = await getAdminPb();

    // ── 3. Get user info ───────────────────────────────────────────────────
    const userRecord = await pb.collection("users").getOne(uid);
    const user = userRecord as unknown as { email: string; fullName: string };

    if (!user.email) {
      return NextResponse.json({ error: "User has no email address" }, { status: 400 });
    }

    // ── 4. Save TCC to PocketBase ──────────────────────────────────────────
    await pb.collection("users").update(uid, {
      tccCode,
      tccUpdatedAt: new Date().toISOString(),
    });

    // Invalidate all previous unused OTPs so only the admin-set code is valid
    const oldOtps = await pb.collection("transaction_otps").getFullList({
      filter: `userId="${uid}" && used=false`,
    });
    await Promise.all(
      oldOtps.map((otp) => pb.collection("transaction_otps").update(otp.id, { used: true }))
    );

    // Create a transaction_otps entry so the user can actually use this code
    // Admin-issued codes have a 24-hour window (user is being helped by support)
    await pb.collection("transaction_otps").create({
      userId: uid,
      code: tccCode,
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      used: false,
    });

    // ── 5. Send TCC email ──────────────────────────────────────────────────
    const emailResult = await sendOtpEmail({
      to: user.email,
      fullName: user.fullName || "Valued Customer",
      otpCode: tccCode,
    });

    // ── 6. In-app notification ─────────────────────────────────────────────
    await pb.collection("notifications").create({
      userId: uid,
      title: "New TCC Code Issued",
      message: `Your Transaction Confirmation Code has been updated by your administrator. Check your email (${user.email}) for the new code.`,
      type: "security",
      isRead: false,
    });

    return NextResponse.json({
      success: true,
      emailSent: emailResult.success,
      provider: emailResult.provider,
      warning: emailResult.success ? undefined : emailResult.error,
    });
  } catch (err: any) {
    if (err?.status === 404) {
      return NextResponse.json({ error: "User not found" }, { status: 404 });
    }
    console.error("[send-tcc]", err);
    return NextResponse.json({ error: err.message ?? "Internal error" }, { status: 500 });
  }
}
