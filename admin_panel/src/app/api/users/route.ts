import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, verifyAdmin } from "@/lib/pocketbase";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, PATCH, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

// GET /api/users?page=1&limit=10&status=all&search=
export async function GET(req: NextRequest) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401, headers: corsHeaders });
  }

  const { searchParams } = new URL(req.url);
  const page = Math.max(1, parseInt(searchParams.get("page") || "1", 10));
  const pageSize = Math.min(50, Math.max(1, parseInt(searchParams.get("limit") || "10", 10)));
  const statusFilter = searchParams.get("status") || "all";
  const search = (searchParams.get("search") || "").toLowerCase().trim();

  try {
    const pb = await getAdminPb();

    // Build filter
    const filters: string[] = [];
    if (statusFilter !== "all") {
      filters.push(`accountStatus="${statusFilter}"`);
    }
    if (search) {
      filters.push(
        `(fullName~"${search}" || email~"${search}" || accountNumber~"${search}" || id~"${search}")`
      );
    }
    const filter = filters.join(" && ");

    // Fetch all matching users (PocketBase doesn't have full-text ranking, so we
    // retrieve and paginate server-side for the admin panel use-case)
    const allRecords = await pb.collection("users").getFullList({
      sort: "-created",
      filter: filter || undefined,
    });

    const users = allRecords.map((r) => {
      const rec = r as unknown as Record<string, any>;
      return {
        uid: r.id,
        fullName: rec.fullName || "",
        email: rec.email || "",
        accountNumber: rec.accountNumber || rec.tccCode || "",
        balance: rec.balance || 0,
        accountStatus: rec.accountStatus || "pending",
        kycStatus: rec.kycStatus || "not_submitted",
        createdAt: r.created || null,
        photoURL: rec.photoURL || null,
        phone: rec.phone || null,
        address: rec.address || null,
        tccCode: rec.tccCode || null,
        canTransact: rec.canTransact ?? false,
      };
    });

    const total = users.length;
    const totalPages = Math.ceil(total / pageSize);
    const start = (page - 1) * pageSize;
    const paginatedUsers = users.slice(start, start + pageSize);

    return NextResponse.json(
      {
        users: paginatedUsers,
        pagination: { total, page, pageSize, totalPages },
      },
      { status: 200, headers: corsHeaders }
    );
  } catch (error) {
    console.error("GET /api/users error:", error);
    return NextResponse.json({ error: "Failed to fetch users." }, { status: 500, headers: corsHeaders });
  }
}

// PATCH /api/users — update user status or send notification
export async function PATCH(req: NextRequest) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401, headers: corsHeaders });
  }

  let body: { uid: string; action: "suspend" | "activate" | "reset_password" };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400, headers: corsHeaders });
  }

  const { uid, action } = body;
  if (!uid || !action) {
    return NextResponse.json({ error: "uid and action are required." }, { status: 400, headers: corsHeaders });
  }

  try {
    const pb = await getAdminPb();

    const userRecord = await pb.collection("users").getOne(uid);

    if (action === "suspend") {
      await pb.collection("users").update(uid, { accountStatus: "suspended", canTransact: false });
      // Create notification for user
      await pb.collection("notifications").create({
        userId: uid,
        title: "Account Suspended",
        message: "Your account has been suspended. Please contact support for assistance.",
        type: "account",
        isRead: false,
      });
      return NextResponse.json({ success: true, message: "Account suspended." }, { status: 200, headers: corsHeaders });
    }

    if (action === "activate") {
      await pb.collection("users").update(uid, { accountStatus: "active", canTransact: true });
      await pb.collection("notifications").create({
        userId: uid,
        title: "Account Activated",
        message: "Your account has been activated. You can now use all banking features.",
        type: "account",
        isRead: false,
      });
      return NextResponse.json({ success: true, message: "Account activated." }, { status: 200, headers: corsHeaders });
    }

    if (action === "reset_password") {
      // PocketBase does not have a Firebase-style password reset link.
      // Return the user email so the caller can trigger a password reset flow.
      const email = userRecord.email;
      if (!email) {
        return NextResponse.json({ error: "User has no email address." }, { status: 400, headers: corsHeaders });
      }
      // Request PocketBase to send a password reset email to the user
      await pb.collection("users").requestPasswordReset(email);
      return NextResponse.json(
        { success: true, message: `Password reset email sent to ${email}` },
        { status: 200, headers: corsHeaders }
      );
    }

    return NextResponse.json({ error: "Invalid action." }, { status: 400, headers: corsHeaders });
  } catch (error: any) {
    if (error?.status === 404) {
      return NextResponse.json({ error: "User not found." }, { status: 404, headers: corsHeaders });
    }
    console.error("PATCH /api/users error:", error);
    return NextResponse.json({ error: "Operation failed." }, { status: 500, headers: corsHeaders });
  }
}
