// pocketbase.ts - server-side PocketBase client
//
// NOTE: The PocketBase JS SDK (v0.27.0) sends auth tokens without the
// "Bearer " prefix required by PocketBase server v0.37.5, causing 400 errors
// on collection access.  We therefore bypass the SDK entirely for server-side
// admin operations and use native fetch() with the correct Bearer header.

const PB_URL = process.env.POCKETBASE_URL || 'http://127.0.0.1:8091';
const PB_ADMIN_EMAIL = process.env.POCKETBASE_ADMIN_EMAIL || 'admin@nexusbank.com';
const PB_ADMIN_PASSWORD = process.env.POCKETBASE_ADMIN_PASSWORD || 'NexusAdmin2025!';

// ── Minimal PocketBase-like admin client (fetch-based) ──────────────────────
// Exposes the collection API subset used by the admin panel API routes.

type PbRecord = Record<string, any>;

interface PbCollection {
  getFullList(options?: { sort?: string; filter?: string; perPage?: number; fields?: string }): Promise<PbRecord[]>;
  getList(page?: number, perPage?: number, options?: { sort?: string; filter?: string }): Promise<{ items: PbRecord[]; totalItems: number }>;
  getOne(id: string): Promise<PbRecord>;
  create(data: PbRecord): Promise<PbRecord>;
  update(id: string, data: PbRecord): Promise<PbRecord>;
  delete(id: string): Promise<void>;
  requestPasswordReset(email: string): Promise<void>;
  authWithPassword(identity: string, password: string): Promise<{ token: string; record: PbRecord }>;
}

interface AdminPbClient {
  collection(name: string): PbCollection;
}

async function pbFetch(token: string, path: string, options: RequestInit = {}): Promise<PbRecord> {
  const res = await fetch(`${PB_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
      ...(options.headers ?? {}),
    },
  });
  if (res.status === 204) return {};
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    const err = new Error(body.message || body.error || res.statusText) as any;
    err.status = res.status;
    err.data = body;
    throw err;
  }
  return body;
}

function makeCollection(token: string, name: string): PbCollection {
  const base = `/api/collections/${encodeURIComponent(name)}`;

  return {
    async getFullList(opts = {}) {
      const params = new URLSearchParams();
      params.set('perPage', String(opts.perPage ?? 500));
      if (opts.sort) params.set('sort', opts.sort);
      if (opts.filter) params.set('filter', opts.filter);
      if (opts.fields) params.set('fields', opts.fields);
      const data = await pbFetch(token, `${base}/records?${params}`);
      return (data.items as PbRecord[]) ?? [];
    },

    async getList(page = 1, perPage = 30, opts = {}) {
      const params = new URLSearchParams({ page: String(page), perPage: String(perPage) });
      if (opts.sort) params.set('sort', opts.sort);
      if (opts.filter) params.set('filter', opts.filter);
      const data = await pbFetch(token, `${base}/records?${params}`);
      return { items: (data.items as PbRecord[]) ?? [], totalItems: (data.totalItems as number) ?? 0 };
    },

    async getOne(id: string) {
      return pbFetch(token, `${base}/records/${encodeURIComponent(id)}`);
    },

    async create(data: PbRecord) {
      return pbFetch(token, `${base}/records`, { method: 'POST', body: JSON.stringify(data) });
    },

    async update(id: string, data: PbRecord) {
      return pbFetch(token, `${base}/records/${encodeURIComponent(id)}`, {
        method: 'PATCH', body: JSON.stringify(data),
      });
    },

    async delete(id: string) {
      await pbFetch(token, `${base}/records/${encodeURIComponent(id)}`, { method: 'DELETE' });
    },

    async requestPasswordReset(email: string) {
      await pbFetch(token, `${base}/request-password-reset`, {
        method: 'POST', body: JSON.stringify({ email }),
      });
    },

    async authWithPassword(identity: string, password: string) {
      const data = await pbFetch(token, `${base}/auth-with-password`, {
        method: 'POST', body: JSON.stringify({ identity, password }),
      });
      return data as { token: string; record: PbRecord };
    },
  };
}

// Server-side admin client — gets a fresh superuser token then wraps all
// collection calls with that Bearer token.
export async function getAdminPb(): Promise<AdminPbClient> {
  const loginRes = await fetch(`${PB_URL}/api/collections/_superusers/auth-with-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identity: PB_ADMIN_EMAIL, password: PB_ADMIN_PASSWORD }),
  });
  if (!loginRes.ok) {
    const err = await loginRes.json().catch(() => ({}));
    throw new Error(`PocketBase admin login failed: ${err.message || loginRes.statusText}`);
  }
  const { token } = (await loginRes.json()) as { token: string };

  return {
    collection: (name: string) => makeCollection(token, name),
  };
}

// ── JWT helpers ─────────────────────────────────────────────────────────────
// PocketBase JWTs use Base64URL encoding (RFC 4648 §5), not standard Base64.
// Base64URL replaces `+` → `-`, `/` → `_`, and strips `=` padding.
// Node's Buffer.from(str, 'base64') tolerates missing padding, so we just
// need to swap the two URL-safe characters before decoding.

function decodeJwtPayload(token: string): Record<string, unknown> {
  const part = token.split('.')[1] ?? '';
  const std = part.replace(/-/g, '+').replace(/_/g, '/');
  return JSON.parse(Buffer.from(std, 'base64').toString('utf-8'));
}

/**
 * Extracts the PocketBase user ID from a Bearer token string (without "Bearer " prefix).
 *
 * Compatible with PocketBase v0.37.5+:
 *   - New format: { collectionId: "_pb_users_auth_", id, ... }
 *   - Old format: { collectionName: "users", id, ... }
 *
 * Returns null if the token is missing, malformed, or not a regular user token.
 */
export function getUserIdFromToken(token: string): string | null {
  if (!token) return null;
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const payload = decodeJwtPayload(token);
    if (!payload?.id) return null;
    const isUserToken =
      payload.collectionId === '_pb_users_auth_' ||
      payload.collectionName === 'users';
    if (!isUserToken) return null;
    return payload.id as string;
  } catch {
    return null;
  }
}

// ── verifyAdmin ──────────────────────────────────────────────────────────────
// Verifies an incoming request carries a valid PocketBase superuser token.
// Returns the admin record ID on success, null on failure.
//
// Handles two JWT formats:
//   PocketBase ≤ v0.22 : { collectionName: "admins", id, ... }
//   PocketBase ≥ v0.23 : { collectionId: "pbc_3142635823", type: "auth", id, ... }
//                         (collectionName was dropped; _superusers has a fixed system collectionId)
import PocketBase from 'pocketbase';

export async function verifyAdmin(req: Request): Promise<string | null> {
  const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '').trim();
  if (!token) return null;
  try {
    const pb = new PocketBase(PB_URL);
    pb.authStore.save(token, null);
    if (!pb.authStore.isValid) return null;

    const payload = decodeJwtPayload(token);
    const recordId = payload.id as string | undefined;
    if (!recordId) return null;

    // Accept old-style (collectionName) OR new-style (collectionId) admin tokens.
    // pbc_3142635823 is the hardcoded system ID for _superusers in every PocketBase instance.
    const isAdmin =
      payload.collectionName === 'admins' ||
      payload.collectionName === '_superusers' ||
      payload.collectionId === 'pbc_3142635823';

    if (!isAdmin) return null;
    return recordId;
  } catch {
    return null;
  }
}
