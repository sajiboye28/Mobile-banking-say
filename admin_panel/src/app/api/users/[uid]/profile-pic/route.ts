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

const MAX_BASE64_SIZE = 500 * 1024; // 500 KB
const ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"];

export async function POST(req: NextRequest, { params }: { params: { uid: string } }) {
  const adminUid = await verifyAdmin(req);
  if (!adminUid) return NextResponse.json({ error: "Unauthorized" }, { status: 401, headers: cors });

  const { uid } = params;
  if (!uid) return NextResponse.json({ error: "uid required" }, { status: 400, headers: cors });

  try {
    const pb = await getAdminPb();

    // Verify user exists
    await pb.collection("users").getOne(uid);

    const contentType = req.headers.get("content-type") || "";

    // ── Path 1: multipart/form-data with a "file" field ─────────────────────
    if (contentType.includes("multipart/form-data")) {
      let formData: FormData;
      try {
        formData = await req.formData();
      } catch {
        return NextResponse.json({ error: "Failed to parse multipart form data" }, { status: 400, headers: cors });
      }

      const file = formData.get("file") as File | null;
      if (!file) return NextResponse.json({ error: "No file field in form data" }, { status: 400, headers: cors });

      if (!ALLOWED_MIME_TYPES.includes(file.type)) {
        return NextResponse.json(
          { error: `File type not allowed. Allowed: ${ALLOWED_MIME_TYPES.join(", ")}` },
          { status: 400, headers: cors }
        );
      }

      // Store as base64 in PocketBase (PocketBase file uploads require multipart
      // on the PocketBase side; for simplicity we store the data URI in the record)
      const arrayBuffer = await file.arrayBuffer();
      const buffer = Buffer.from(arrayBuffer);

      if (buffer.byteLength > MAX_BASE64_SIZE) {
        return NextResponse.json(
          { error: "File too large. Max size: 500 KB" },
          { status: 413, headers: cors }
        );
      }

      const base64 = `data:${file.type};base64,${buffer.toString("base64")}`;

      await pb.collection("users").update(uid, {
        profilePicBase64: base64,
        profilePicUrl: null,
      });

      return NextResponse.json({ success: true, url: base64, fallback: "base64" }, { headers: cors });
    }

    // ── Path 2: JSON body with base64 string ────────────────────────────────
    if (contentType.includes("application/json")) {
      let body: { base64: string; mimeType?: string };
      try {
        body = await req.json();
      } catch {
        return NextResponse.json({ error: "Invalid JSON body" }, { status: 400, headers: cors });
      }

      const { base64, mimeType = "image/jpeg" } = body;

      if (!base64) return NextResponse.json({ error: "base64 field required" }, { status: 400, headers: cors });

      // Strip data URI prefix if present, then re-attach
      const rawBase64 = base64.replace(/^data:[^;]+;base64,/, "");
      const buffer = Buffer.from(rawBase64, "base64");

      if (buffer.byteLength > MAX_BASE64_SIZE) {
        return NextResponse.json(
          { error: "Image too large. Max size: 500 KB" },
          { status: 413, headers: cors }
        );
      }

      const dataUri = base64.startsWith("data:") ? base64 : `data:${mimeType};base64,${rawBase64}`;

      await pb.collection("users").update(uid, {
        profilePicBase64: dataUri,
        profilePicUrl: null,
      });

      return NextResponse.json({ success: true, url: dataUri, fallback: "base64" }, { headers: cors });
    }

    return NextResponse.json(
      { error: "Unsupported Content-Type. Use multipart/form-data or application/json" },
      { status: 415, headers: cors }
    );
  } catch (e: any) {
    if (e?.status === 404) {
      return NextResponse.json({ error: "User not found" }, { status: 404, headers: cors });
    }
    return NextResponse.json({ error: e.message || "Server error" }, { status: 500, headers: cors });
  }
}
