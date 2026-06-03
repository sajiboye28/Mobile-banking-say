import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, getUserIdFromToken } from "@/lib/pocketbase";
import { sendOtpEmail } from "@/lib/email";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

function generateOtp(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let otp = "";
  for (let i = 0; i < 6; i++) otp += chars[Math.floor(Math.random() * chars.length)];
  return otp;
}

function maskEmail(email: string): string {
  const [local, domain] = email.split("@");
  if (!domain) return email;
  return `${local.charAt(0)}***@${domain}`;
}

export async function POST(req: NextRequest) {
  // ── 1. Verify PocketBase user token ───────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return NextResponse.json(
      { error: "Unauthorized. No token provided." },
      { status: 401, headers: corsHeaders }
    );
  }

  const userId = getUserIdFromToken(authHeader.substring(7));
  if (!userId) {
    return NextResponse.json(
      { error: "Unauthorized. Invalid or expired token." },
      { status: 401, headers: corsHeaders }
    );
  }

  try {
    const pb = await getAdminPb();

    // ── 2. Get user document ────────────────────────────────────────────────
    const userRecord = await pb.collection("users").getOne(userId);
    const user = userRecord as unknown as {
      email: string;
      fullName: string;
    };

    if (!user.email) {
      return NextResponse.json(
        { error: "No email address on file." },
        { status: 400, headers: corsHeaders }
      );
    }

    // ── 3. Generate OTP + store in PocketBase ─────────────────────────────
    const code = generateOtp();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    // Invalidate all previous unused OTPs so only the latest code is valid
    const oldOtps = await pb.collection("transaction_otps").getFullList({
      filter: `userId="${userId}" && used=false`,
    });
    await Promise.all(
      oldOtps.map((otp) => pb.collection("transaction_otps").update(otp.id, { used: true }))
    );

    await pb.collection("transaction_otps").create({
      userId,
      code,
      expiresAt,
      used: false,
    });

    // Sync to user.tccCode so the admin panel always shows the latest active code
    await pb.collection("users").update(userId, { tccCode: code });

    // ── 6. Send email ──────────────────────────────────────────────────────
    const emailResult = await sendOtpEmail({
      to: user.email,
      fullName: user.fullName || "Valued Customer",
      otpCode: code,
      expiresInMinutes: 10,
    });

    if (!emailResult.success) {
      console.error("[request-otp] email failed:", emailResult.error);
      return NextResponse.json(
        {
          success: true,
          email: maskEmail(user.email),
          expiresIn: 600,
          emailWarning:
            "Code generated but email delivery failed. Please contact support.",
        },
        { status: 200, headers: corsHeaders }
      );
    }

    return NextResponse.json(
      {
        success: true,
        email: maskEmail(user.email),
        expiresIn: 600,
        provider: emailResult.provider,
      },
      { status: 200, headers: corsHeaders }
    );
  } catch (e: any) {
    if (e?.status === 404) {
      return NextResponse.json(
        { error: "User not found." },
        { status: 404, headers: corsHeaders }
      );
    }
    console.error("[request-otp]", e);
    return NextResponse.json(
      { error: e.message || "Internal error." },
      { status: 500, headers: corsHeaders }
    );
  }
}
