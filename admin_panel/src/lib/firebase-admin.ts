import * as admin from "firebase-admin";
import { NextRequest } from "next/server";

function getApp(): admin.app.App {
  if (admin.apps.length > 0) return admin.apps[0]!;
  return admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_ADMIN_PROJECT_ID,
      clientEmail: process.env.FIREBASE_ADMIN_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, "\n"),
    }),
  });
}

export const adminAuth = () => getApp().auth();
export const adminDb = () => getApp().firestore();
export const adminFieldValue = admin.firestore.FieldValue;

/**
 * Fast admin verification — verifies the Bearer token and checks that a
 * document exists in the `admins` collection. No role field required.
 * Returns the uid on success, null on failure.
 */
export async function verifyAdmin(req: NextRequest): Promise<string | null> {
  try {
    const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "").trim();
    if (!token) return null;
    const decoded = await adminAuth().verifyIdToken(token);
    // Just check existence — no role field required
    const adminDoc = await adminDb().collection("admins").doc(decoded.uid).get();
    if (!adminDoc.exists) return null;
    return decoded.uid;
  } catch {
    return null;
  }
}
