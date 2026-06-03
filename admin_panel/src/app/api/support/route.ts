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

// GET /api/support — returns all support tickets with user info joined
export async function GET(req: NextRequest) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401, headers: corsHeaders });
  }

  try {
    const pb = await getAdminPb();

    const ticketRecords = await pb.collection("support_tickets").getFullList({
      sort: "-created",
    });

    const tickets = await Promise.all(
      ticketRecords.map(async (doc) => {
        let userInfo: { fullName?: string; email?: string; accountNumber?: string } = {};

        if (doc.userId) {
          try {
            const userRecord = await pb.collection("users").getOne(doc.userId);
            userInfo = {
              fullName: userRecord.fullName || userRecord.userName || "",
              email: userRecord.email || "",
              accountNumber: userRecord.accountNumber || userRecord.tccCode || "",
            };
          } catch {
            // user not found, ignore
          }
        }

        return {
          id: doc.id,
          userId: doc.userId || "",
          userName:
            userInfo.fullName ||
            doc.userName ||
            doc.userEmail?.split("@")[0] ||
            "Unknown",
          userEmail: userInfo.email || doc.userEmail || "",
          userAccountNumber: userInfo.accountNumber || "",
          subject: doc.subject || "(No subject)",
          category: doc.category || "General",
          description: doc.description || doc.message || "",
          status: doc.status || "open",
          priority: doc.priority || "medium",
          attachments: doc.attachments || [],
          replies: Array.isArray(doc.replies) ? doc.replies : [],
          createdAt: doc.created || null,
          updatedAt: doc.updated || null,
        };
      })
    );

    // Counts
    const counts = {
      total: tickets.length,
      open: tickets.filter((t) => t.status === "open").length,
      in_progress: tickets.filter((t) => t.status === "in_progress").length,
      resolved: tickets.filter((t) => t.status === "resolved").length,
      closed: tickets.filter((t) => t.status === "closed").length,
    };

    return NextResponse.json({ tickets, counts }, { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error("GET /api/support error:", error);
    return NextResponse.json(
      { error: "Failed to fetch support tickets." },
      { status: 500, headers: corsHeaders }
    );
  }
}

// POST /api/support
// action "update_status": { ticketId, status }
// action "reply": { ticketId, replyText, adminEmail }
// action "close": { ticketId }
export async function POST(req: NextRequest) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401, headers: corsHeaders });
  }

  let body: {
    action: "update_status" | "reply" | "close";
    ticketId: string;
    status?: string;
    replyText?: string;
    adminEmail?: string;
  };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400, headers: corsHeaders });
  }

  const { action, ticketId } = body;
  if (!action || !ticketId) {
    return NextResponse.json(
      { error: "action and ticketId are required." },
      { status: 400, headers: corsHeaders }
    );
  }

  try {
    const pb = await getAdminPb();

    const ticketRecord = await pb.collection("support_tickets").getOne(ticketId);

    if (action === "update_status") {
      const { status } = body;
      if (!status) {
        return NextResponse.json(
          { error: "status is required for update_status." },
          { status: 400, headers: corsHeaders }
        );
      }
      await pb.collection("support_tickets").update(ticketId, { status });
      return NextResponse.json(
        { success: true, message: `Status updated to ${status}.` },
        { status: 200, headers: corsHeaders }
      );
    }

    if (action === "reply") {
      const { replyText, adminEmail } = body;
      if (!replyText?.trim()) {
        return NextResponse.json(
          { error: "replyText is required." },
          { status: 400, headers: corsHeaders }
        );
      }

      const reply = {
        text: replyText.trim(),
        authorUid: adminUid,
        authorEmail: adminEmail || "admin",
        isAdmin: true,
        createdAt: new Date().toISOString(),
      };

      // PocketBase doesn't have arrayUnion; we fetch then update the array
      const existingReplies: any[] = Array.isArray(ticketRecord.replies)
        ? ticketRecord.replies
        : [];

      const updates: Record<string, any> = { replies: [...existingReplies, reply] };
      // Move to in_progress if currently open
      if (ticketRecord.status === "open") {
        updates.status = "in_progress";
      }

      await pb.collection("support_tickets").update(ticketId, updates);

      return NextResponse.json(
        { success: true, message: "Reply sent." },
        { status: 200, headers: corsHeaders }
      );
    }

    if (action === "close") {
      await pb.collection("support_tickets").update(ticketId, { status: "closed" });
      return NextResponse.json(
        { success: true, message: "Ticket closed." },
        { status: 200, headers: corsHeaders }
      );
    }

    return NextResponse.json({ error: "Invalid action." }, { status: 400, headers: corsHeaders });
  } catch (error: any) {
    if (error?.status === 404) {
      return NextResponse.json({ error: "Ticket not found." }, { status: 404, headers: corsHeaders });
    }
    console.error("POST /api/support error:", error);
    return NextResponse.json({ error: "Operation failed." }, { status: 500, headers: corsHeaders });
  }
}
