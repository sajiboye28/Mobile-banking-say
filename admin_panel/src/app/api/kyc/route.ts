import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, verifyAdmin } from "@/lib/pocketbase";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

// GET /api/kyc?status=pending|approved|rejected|all
export async function GET(req: NextRequest) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401, headers: corsHeaders });
  }

  const { searchParams } = new URL(req.url);
  const statusFilter = searchParams.get("status") || "all";

  try {
    const pb = await getAdminPb();

    const filter = statusFilter !== "all" ? `status="${statusFilter}"` : undefined;

    const allRecords = await pb.collection("kyc_verifications").getFullList({
      filter: filter || undefined,
      sort: "-created",
    });

    const submissions = allRecords.map((doc) => ({
      id: doc.id,
      userId: doc.userId || "",
      userName: doc.userName || doc.fullName || "",
      userEmail: doc.userEmail || doc.email || "",
      documentType: doc.documentType || "Unknown",
      status: doc.status || "pending",
      submittedAt: doc.submittedAt || doc.created || null,
      reviewedAt: doc.reviewedAt || null,
      rejectionReason: doc.rejectionReason || null,
      // Document fields
      firstName: doc.firstName || null,
      lastName: doc.lastName || null,
      dateOfBirth: doc.dateOfBirth || null,
      address: doc.address || null,
      city: doc.city || null,
      country: doc.country || null,
      postalCode: doc.postalCode || null,
      documentNumber: doc.documentNumber || null,
      documentExpiry: doc.documentExpiry || null,
      // Image URLs
      documentFrontUrl: doc.documentFrontUrl || doc.documentFront || null,
      documentBackUrl: doc.documentBackUrl || doc.documentBack || null,
      selfieUrl: doc.selfieUrl || doc.selfie || null,
    }));

    // Count totals per status
    const allForCounts = statusFilter !== "all"
      ? await pb.collection("kyc_verifications").getFullList({ fields: "status" })
      : allRecords;

    const counts = { pending: 0, approved: 0, rejected: 0, all: allForCounts.length };
    allForCounts.forEach((doc) => {
      const s = doc.status || "pending";
      if (s === "pending") counts.pending++;
      else if (s === "approved") counts.approved++;
      else if (s === "rejected") counts.rejected++;
    });

    return NextResponse.json({ submissions, counts }, { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error("GET /api/kyc error:", error);
    return NextResponse.json({ error: "Failed to fetch KYC submissions." }, { status: 500, headers: corsHeaders });
  }
}

// POST /api/kyc — approve or reject a KYC submission
// Body: { id: string, action: "approve" | "reject", reason?: string }
export async function POST(req: NextRequest) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401, headers: corsHeaders });
  }

  let body: { id: string; action: "approve" | "reject"; reason?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400, headers: corsHeaders });
  }

  const { id, action, reason } = body;
  if (!id || !action) {
    return NextResponse.json({ error: "id and action are required." }, { status: 400, headers: corsHeaders });
  }

  if (action === "reject" && !reason?.trim()) {
    return NextResponse.json({ error: "Rejection reason is required." }, { status: 400, headers: corsHeaders });
  }

  try {
    const pb = await getAdminPb();

    const kycRecord = await pb.collection("kyc_verifications").getOne(id);
    const userId = kycRecord.userId;

    if (action === "approve") {
      // Update KYC record
      await pb.collection("kyc_verifications").update(id, {
        status: "approved",
        reviewedAt: new Date().toISOString(),
        reviewedBy: adminUid,
        rejectionReason: null,
      });

      // Update user's kycStatus
      await pb.collection("users").update(userId, { kycStatus: "approved" });

      // Create notification for user
      const notif = await pb.collection("notifications").create({
        userId,
        title: "Identity Verified",
        message: "Your identity has been verified. You now have full access to all banking features.",
        type: "kyc",
        isRead: false,
      });

      return NextResponse.json(
        { success: true, message: "KYC submission approved.", notificationId: notif.id },
        { status: 200, headers: corsHeaders }
      );
    }

    if (action === "reject") {
      // Update KYC record
      await pb.collection("kyc_verifications").update(id, {
        status: "rejected",
        reviewedAt: new Date().toISOString(),
        reviewedBy: adminUid,
        rejectionReason: reason,
      });

      // Update user's kycStatus
      await pb.collection("users").update(userId, { kycStatus: "rejected" });

      // Create notification for user
      const notif = await pb.collection("notifications").create({
        userId,
        title: "Identity Verification Failed",
        message: `Your identity verification was not approved. Reason: ${reason}. Please resubmit with the correct documents.`,
        type: "kyc",
        isRead: false,
      });

      return NextResponse.json(
        { success: true, message: "KYC submission rejected.", notificationId: notif.id },
        { status: 200, headers: corsHeaders }
      );
    }

    return NextResponse.json(
      { error: "Invalid action. Use 'approve' or 'reject'." },
      { status: 400, headers: corsHeaders }
    );
  } catch (error: any) {
    if (error?.status === 404) {
      return NextResponse.json({ error: "KYC submission not found." }, { status: 404, headers: corsHeaders });
    }
    console.error("POST /api/kyc error:", error);
    return NextResponse.json({ error: "KYC action failed." }, { status: 500, headers: corsHeaders });
  }
}
