/**
 * Email service — STCU Digital Banking
 *
 * Provider : Resend (resend.com)
 *   Free tier : 3,000 emails / month · 100 / day · no credit card required
 *   Env vars  : RESEND_API_KEY, RESEND_FROM_EMAIL
 *
 * Templates : React Email  (@react-email/components)
 *   Render   : @react-email/render  (server-side → HTML string)
 *
 * Usage:
 *   import { sendOtpEmail } from "@/lib/email";
 *   await sendOtpEmail({ to: "user@example.com", fullName: "Alice", otpCode: "738291" });
 */

import { Resend } from "resend";
import { render } from "@react-email/render";
import { createElement } from "react";
import { TransactionOtpEmail } from "@/emails/TransactionOtpEmail";

// ─── Types ────────────────────────────────────────────────────────────────────

export interface SendEmailResult {
  success: boolean;
  provider?: string;
  messageId?: string;
  error?: string;
}

// ─── Core sender ─────────────────────────────────────────────────────────────

async function sendEmail(opts: {
  to: string;
  subject: string;
  reactElement: React.ReactElement;
}): Promise<SendEmailResult> {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    const msg = "RESEND_API_KEY is not set.";
    console.warn("[email]", msg);
    return { success: false, error: msg };
  }

  const fromEnv = process.env.RESEND_FROM_EMAIL;
  const from = fromEnv
    ? `STCU Digital Banking <${fromEnv}>`
    : "STCU Digital Banking <onboarding@resend.dev>";

  const html = await render(opts.reactElement);

  try {
    const resend = new Resend(apiKey);
    const result = await resend.emails.send({
      from,
      to: opts.to,
      subject: opts.subject,
      html,
    });

    if (result.error) {
      console.error("[email] Resend error:", result.error);
      return { success: false, provider: "resend", error: result.error.message };
    }

    return { success: true, provider: "resend", messageId: result.data?.id };
  } catch (err: any) {
    console.error("[email] Resend threw:", err.message);
    return { success: false, provider: "resend", error: err.message };
  }
}

// ─── Public API ───────────────────────────────────────────────────────────────

/**
 * Send a transaction authentication OTP to the user.
 *
 * @param to               Recipient email address
 * @param fullName         Recipient's display name
 * @param otpCode          The OTP / TCC code to display
 * @param expiresInMinutes How long the code is valid (default 10)
 */
export async function sendOtpEmail(opts: {
  to: string;
  fullName: string;
  otpCode: string;
  expiresInMinutes?: number;
}): Promise<SendEmailResult> {
  return sendEmail({
    to: opts.to,
    subject: `${opts.otpCode} is your STCU transaction code`,
    reactElement: createElement(TransactionOtpEmail, {
      fullName: opts.fullName,
      otpCode: opts.otpCode,
      expiresInMinutes: opts.expiresInMinutes ?? 10,
    }),
  });
}
