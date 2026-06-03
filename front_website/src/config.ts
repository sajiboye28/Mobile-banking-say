/** URL of the live banking web application.
 *  Set VITE_WEB_APP_URL in .env to override (e.g. for production). */
export const WEB_APP_URL: string =
  import.meta.env.VITE_WEB_APP_URL ?? 'http://localhost:5173'
