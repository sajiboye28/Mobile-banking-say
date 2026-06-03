import PocketBase from 'pocketbase';

// ── Dev vs Production URL strategy ──────────────────────────────────────────
//
// DEV  (import.meta.env.DEV === true):
//   • PocketBase calls go to  window.origin/pb-proxy/...
//     Vite proxies them server-side to localhost:8091 — same-origin, no CORS,
//     and the real backend URL never appears in the browser's network tab.
//
//   • API (Next.js) calls use a relative base '' so fetch('/api/...')
//     goes to the same Vite origin and is proxied to localhost:3040.
//
// PROD (import.meta.env.DEV === false):
//   • Use VITE_PB_URL  and VITE_API_URL from .env for your real servers.
//   • Make sure both are served over HTTPS so request bodies are encrypted.
//
const isDev = import.meta.env.DEV;

export const PB_URL: string = isDev
  ? `${window.location.origin}/pb-proxy`           // proxied — hides PocketBase
  : (import.meta.env.VITE_PB_URL || 'http://localhost:8091');

export const API_URL: string = isDev
  ? ''                                              // relative — Vite proxies /api/*
  : (import.meta.env.VITE_API_URL || 'http://localhost:3040');

export const pb = new PocketBase(PB_URL);
