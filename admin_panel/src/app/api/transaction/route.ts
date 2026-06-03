import { NextRequest, NextResponse } from "next/server";
import { getAdminPb, verifyAdmin, getUserIdFromToken } from "@/lib/pocketbase";

// Allow Flutter app (and any origin) to call this endpoint
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

// ── GET /api/transaction?limit=N  (admin: list all transactions) ─────────────
export async function GET(req: NextRequest) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401, headers: corsHeaders });
  }

  const { searchParams } = new URL(req.url);
  const limit = Math.min(parseInt(searchParams.get("limit") ?? "200", 10), 500);

  try {
    const pb = await getAdminPb();
    const records = await pb.collection("transactions").getFullList({
      sort: "-created",
      perPage: limit,
    });

    const items = records.map((r) => ({
      transactionId: r.id,
      userId: r.userId || "",
      amount: r.amount || 0,
      type: r.type || "Debit",
      description: r.description || "",
      status: r.status || "Pending",
      relatedUserId: r.relatedUserId || "",
      relatedUserName: r.relatedUserName || "",
      timestamp: r.created || null,
    }));

    return NextResponse.json({ items }, { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error("GET /api/transaction error:", error);
    return NextResponse.json({ error: "Failed to fetch transactions." }, { status: 500, headers: corsHeaders });
  }
}

// ── PATCH /api/transaction  (admin: edit a transaction) ──────────────────────
export async function PATCH(req: NextRequest) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401, headers: corsHeaders });
  }

  let body: {
    transactionId: string;
    amount?: number;
    description?: string;
    status?: string;
    type?: string;
    timestamp?: string;
  };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400, headers: corsHeaders });
  }

  const { transactionId, ...fields } = body;
  if (!transactionId) {
    return NextResponse.json({ error: "transactionId is required." }, { status: 400, headers: corsHeaders });
  }

  try {
    const pb = await getAdminPb();
    const updateData: Record<string, any> = {};
    if (fields.amount !== undefined) updateData.amount = fields.amount;
    if (fields.description !== undefined) updateData.description = fields.description;
    if (fields.status !== undefined) updateData.status = fields.status;
    if (fields.type !== undefined) updateData.type = fields.type;
    if (fields.timestamp !== undefined) updateData.created = fields.timestamp;

    await pb.collection("transactions").update(transactionId, updateData);
    return NextResponse.json({ success: true }, { status: 200, headers: corsHeaders });
  } catch (error: any) {
    if (error?.status === 404) {
      return NextResponse.json({ error: "Transaction not found." }, { status: 404, headers: corsHeaders });
    }
    console.error("PATCH /api/transaction error:", error);
    return NextResponse.json({ error: "Failed to update transaction." }, { status: 500, headers: corsHeaders });
  }
}

// ── DELETE /api/transaction  (admin: delete a transaction) ───────────────────
export async function DELETE(req: NextRequest) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401, headers: corsHeaders });
  }

  let body: { transactionId: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400, headers: corsHeaders });
  }

  if (!body.transactionId) {
    return NextResponse.json({ error: "transactionId is required." }, { status: 400, headers: corsHeaders });
  }

  try {
    const pb = await getAdminPb();
    await pb.collection("transactions").delete(body.transactionId);
    return NextResponse.json({ success: true }, { status: 200, headers: corsHeaders });
  } catch (error: any) {
    if (error?.status === 404) {
      return NextResponse.json({ error: "Transaction not found." }, { status: 404, headers: corsHeaders });
    }
    console.error("DELETE /api/transaction error:", error);
    return NextResponse.json({ error: "Failed to delete transaction." }, { status: 500, headers: corsHeaders });
  }
}

export async function POST(req: NextRequest) {
  // ── 1. Verify PocketBase user token ─────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return NextResponse.json(
      { error: "Unauthorized. No token provided." },
      { status: 401, headers: corsHeaders }
    );
  }

  const senderUid = getUserIdFromToken(authHeader.substring(7));
  if (!senderUid) {
    return NextResponse.json(
      { error: "Unauthorized. Invalid or expired token." },
      { status: 401, headers: corsHeaders }
    );
  }

  // ── 2. Parse + validate request body ────────────────────────────────────
  let body: {
    recipientEmail?: string;
    recipientAccountNumber?: string;
    amount: number;
    tccCode: string;
    description?: string;
  };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400, headers: corsHeaders });
  }

  const { recipientEmail, recipientAccountNumber, amount, tccCode, description } = body;

  if (!amount || !tccCode) {
    return NextResponse.json(
      { error: "amount and tccCode are required." },
      { status: 400, headers: corsHeaders }
    );
  }

  if (!recipientEmail && !recipientAccountNumber) {
    return NextResponse.json(
      { error: "recipientEmail or recipientAccountNumber is required." },
      { status: 400, headers: corsHeaders }
    );
  }

  if (typeof amount !== "number" || amount <= 0) {
    return NextResponse.json(
      { error: "Amount must be a positive number." },
      { status: 400, headers: corsHeaders }
    );
  }

  try {
    const pb = await getAdminPb();

    // ── 3. Resolve recipient — may be external (not in the system) ────────────
    let recipientRecords;
    if (recipientEmail) {
      recipientRecords = await pb.collection("users").getFullList({
        filter: `email="${recipientEmail.toLowerCase().trim()}"`,
      });
    } else {
      recipientRecords = await pb.collection("users").getFullList({
        filter: `accountNumber="${recipientAccountNumber!.trim()}"`,
      });
    }

    // Determine whether this is an internal or external transfer
    const isExternalTransfer = recipientRecords.length === 0;
    const externalIdentifier = recipientEmail ?? recipientAccountNumber ?? "";
    const recipientUid = isExternalTransfer ? null : recipientRecords[0].id;

    if (!isExternalTransfer && senderUid === recipientUid) {
      return NextResponse.json(
        { error: "You cannot send money to yourself." },
        { status: 400, headers: corsHeaders }
      );
    }

    // ── 4. Validate OTP / TCC code ─────────────────────────────────────────
    const otpRecords = await pb.collection("transaction_otps").getFullList({
      filter: `userId="${senderUid}" && code="${tccCode}" && used=false`,
    });

    if (otpRecords.length === 0) {
      return NextResponse.json(
        { error: "Invalid or expired Transaction Code. Please request a new one." },
        { status: 422, headers: corsHeaders }
      );
    }

    const otpRecord = otpRecords[0];
    const expiresAt = otpRecord.expiresAt ? new Date(otpRecord.expiresAt) : null;
    if (expiresAt && expiresAt < new Date()) {
      return NextResponse.json(
        { error: "Transaction Code has expired. Please request a new one." },
        { status: 422, headers: corsHeaders }
      );
    }

    // ── 5. Fetch sender record (and recipient if internal) ─────────────────
    const senderRecord = await pb.collection("users").getOne(senderUid);
    const recipientRecord = isExternalTransfer
      ? null
      : await pb.collection("users").getOne(recipientUid!);

    if (senderRecord.accountStatus !== "active") {
      return NextResponse.json(
        { error: "Your account is not active." },
        { status: 422, headers: corsHeaders }
      );
    }
    if (!senderRecord.canTransact) {
      return NextResponse.json(
        { error: "Your transaction ability has been disabled by an administrator." },
        { status: 422, headers: corsHeaders }
      );
    }
    if (!isExternalTransfer && recipientRecord!.accountStatus !== "active") {
      return NextResponse.json(
        { error: "Recipient account is not active." },
        { status: 422, headers: corsHeaders }
      );
    }
    if (senderRecord.balance < amount) {
      return NextResponse.json(
        { error: "Insufficient balance." },
        { status: 422, headers: corsHeaders }
      );
    }

    // ── 6. Execute transfer ────────────────────────────────────────────────
    const newSenderBalance = senderRecord.balance - amount;
    const recipientDisplayName = isExternalTransfer
      ? `External (${externalIdentifier})`
      : recipientRecord!.fullName;
    const txDescription =
      description?.trim() || `Transfer to ${recipientDisplayName}`;

    // Debit sender
    await pb.collection("users").update(senderUid, { balance: newSenderBalance });

    // Credit internal recipient only
    if (!isExternalTransfer) {
      const newRecipientBalance = recipientRecord!.balance + amount;
      await pb.collection("users").update(recipientUid!, { balance: newRecipientBalance });
    }

    // Create debit transaction for sender
    const debitTx = await pb.collection("transactions").create({
      userId: senderUid,
      amount,
      type: "Debit",
      description: txDescription,
      status: "Success",
      relatedUserId: recipientUid ?? "",
      relatedUserName: recipientDisplayName,
      recipient: isExternalTransfer
        ? JSON.stringify({ external: true, identifier: externalIdentifier })
        : null,
    });

    if (!isExternalTransfer) {
      // Create credit transaction for internal recipient
      await pb.collection("transactions").create({
        userId: recipientUid!,
        amount,
        type: "Credit",
        description: `Transfer from ${senderRecord.fullName}`,
        status: "Success",
        relatedUserId: senderUid,
        relatedUserName: senderRecord.fullName,
      });

      // Notify internal recipient
      await pb.collection("notifications").create({
        userId: recipientUid!,
        title: "Money Received",
        message: `You received $${amount.toFixed(2)} from ${senderRecord.fullName}.`,
        type: "credit",
        isRead: false,
        data: JSON.stringify({ transactionId: debitTx.id }),
      });
    }

    // Notify sender
    await pb.collection("notifications").create({
      userId: senderUid,
      title: "Transfer Sent",
      message: `$${amount.toFixed(2)} sent to ${recipientDisplayName} successfully.`,
      type: "debit",
      isRead: false,
      data: JSON.stringify({ transactionId: debitTx.id }),
    });

    // Mark OTP as used
    await pb.collection("transaction_otps").update(otpRecord.id, { used: true });

    return NextResponse.json(
      {
        success: true,
        message: "Transaction completed successfully.",
        newBalance: newSenderBalance,
        recipientName: recipientDisplayName,
        transactionId: debitTx.id,
        isExternalTransfer,
      },
      { status: 200, headers: corsHeaders }
    );
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Transaction failed.";
    return NextResponse.json({ error: message }, { status: 422, headers: corsHeaders });
  }
}
