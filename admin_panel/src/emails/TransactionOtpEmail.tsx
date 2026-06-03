import {
  Body,
  Container,
  Head,
  Heading,
  Hr,
  Html,
  Preview,
  Section,
  Text,
  Row,
  Column,
  Font,
} from "@react-email/components";
import * as React from "react";

interface TransactionOtpEmailProps {
  fullName: string;
  otpCode: string;
  expiresInMinutes?: number;
}

export function TransactionOtpEmail({
  fullName,
  otpCode,
  expiresInMinutes = 10,
}: TransactionOtpEmailProps) {
  return (
    <Html lang="en" dir="ltr">
      <Head>
        <Font
          fontFamily="Inter"
          fallbackFontFamily="Arial"
          webFont={{
            url: "https://fonts.gstatic.com/s/inter/v13/UcCO3FwrK3iLTeHuS_fvQtMwCp50KnMw2boKoduKmMEVuLyfAZ9hiJ-Ek-_EeA.woff2",
            format: "woff2",
          }}
          fontWeight={400}
          fontStyle="normal"
        />
      </Head>

      <Preview>
        {`Your STCU transaction code: ${otpCode} — valid for ${expiresInMinutes} minutes`}
      </Preview>

      <Body style={body}>
        <Container style={card}>
          {/* ── Header ── */}
          <Section style={header}>
            <Text style={brandLabel}>STCU Digital Banking</Text>
            <Heading as="h1" style={headerTitle}>
              Transaction Code
            </Heading>
            <Text style={headerSubtitle}>
              One-time authorisation code
            </Text>
          </Section>

          {/* ── Body ── */}
          <Section style={bodySection}>
            <Text style={greeting}>
              Hello <strong style={highlight}>{fullName}</strong>,
            </Text>

            <Text style={paragraph}>
              A transaction was initiated on your STCU account. Use the
              one-time code below to authorise it. The code expires in{" "}
              <strong style={highlight}>{expiresInMinutes} minutes</strong>.
            </Text>

            {/* OTP box */}
            <Section style={codeBox}>
              <Text style={codeLabel}>Your One-Time Code</Text>
              <Text style={codeText}>{otpCode}</Text>
              <Text style={timerText}>
                ⏱ Valid for {expiresInMinutes} minutes
              </Text>
            </Section>

            {/* Warning */}
            <Section style={warningBox}>
              <Text style={warningText}>
                <strong>⚠️ Never share this code.</strong> STCU staff will
                never ask for it. If you did not initiate a transaction, contact
                support immediately and change your PIN.
              </Text>
            </Section>
          </Section>

          <Hr style={divider} />

          {/* ── Footer ── */}
          <Section style={footerSection}>
            <Text style={footerText}>
              © {new Date().getFullYear()} STCU Digital Banking &nbsp;·&nbsp;
              Automated message — do not reply.
            </Text>
          </Section>
        </Container>
      </Body>
    </Html>
  );
}

export default TransactionOtpEmail;

// ─── Styles ───────────────────────────────────────────────────────────────────

const body: React.CSSProperties = {
  backgroundColor: "#0a0a0f",
  fontFamily:
    "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
  margin: 0,
  padding: "40px 20px",
};

const card: React.CSSProperties = {
  maxWidth: "520px",
  margin: "0 auto",
  backgroundColor: "#12121a",
  borderRadius: "20px",
  border: "1px solid #1e1e2e",
  overflow: "hidden",
};

const header: React.CSSProperties = {
  background: "linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%)",
  padding: "36px 32px",
  textAlign: "center",
};

const brandLabel: React.CSSProperties = {
  color: "#fff",
  fontSize: "10px",
  fontWeight: 800,
  letterSpacing: "4px",
  textTransform: "uppercase",
  opacity: 0.7,
  margin: "0 0 8px",
};

const headerTitle: React.CSSProperties = {
  color: "#fff",
  fontSize: "22px",
  fontWeight: 800,
  margin: "0 0 6px",
  letterSpacing: "-0.5px",
};

const headerSubtitle: React.CSSProperties = {
  color: "rgba(255,255,255,0.65)",
  fontSize: "13px",
  margin: 0,
};

const bodySection: React.CSSProperties = {
  padding: "36px 32px",
};

const greeting: React.CSSProperties = {
  color: "#e2e8f0",
  fontSize: "15px",
  margin: "0 0 20px",
  lineHeight: "1.6",
};

const highlight: React.CSSProperties = {
  color: "#e2e8f0",
};

const paragraph: React.CSSProperties = {
  color: "#94a3b8",
  fontSize: "14px",
  lineHeight: "1.7",
  margin: "0 0 28px",
};

const codeBox: React.CSSProperties = {
  background: "linear-gradient(135deg, #1a1a2e, #16213e)",
  border: "2px solid #4f46e5",
  borderRadius: "16px",
  padding: "28px 24px",
  textAlign: "center",
  margin: "0 0 24px",
};

const codeLabel: React.CSSProperties = {
  color: "#6b7280",
  fontSize: "10px",
  fontWeight: 700,
  letterSpacing: "3px",
  textTransform: "uppercase",
  margin: "0 0 14px",
};

const codeText: React.CSSProperties = {
  color: "#a5b4fc",
  fontSize: "44px",
  fontWeight: 900,
  letterSpacing: "12px",
  fontVariantNumeric: "tabular-nums",
  margin: "0 0 10px",
  lineHeight: 1,
};

const timerText: React.CSSProperties = {
  color: "#6b7280",
  fontSize: "12px",
  margin: 0,
};

const warningBox: React.CSSProperties = {
  backgroundColor: "rgba(239,68,68,0.08)",
  border: "1px solid rgba(239,68,68,0.25)",
  borderRadius: "12px",
  padding: "16px 18px",
};

const warningText: React.CSSProperties = {
  color: "#fca5a5",
  fontSize: "13px",
  lineHeight: "1.6",
  margin: 0,
};

const divider: React.CSSProperties = {
  borderColor: "#1e1e2e",
  margin: "0 32px",
};

const footerSection: React.CSSProperties = {
  padding: "20px 32px",
};

const footerText: React.CSSProperties = {
  color: "#374151",
  fontSize: "11px",
  textAlign: "center",
  lineHeight: "1.6",
  margin: 0,
};
