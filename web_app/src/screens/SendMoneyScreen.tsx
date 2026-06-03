import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Search, CheckCircle, XCircle, ArrowRight,
  User as UserIcon, DollarSign, KeyRound, SendHorizonal,
  AlertTriangle, Globe,
} from 'lucide-react';
import { pb, API_URL } from '../services/pb';
import { useAuth } from '../context/AuthContext';
import PageHeader from '../components/PageHeader';

// ── Step types ───────────────────────────────────────────────────────────────
// 1 = recipient lookup  2 = amount  3 = OTP entry  4 = result
type Step = 1 | 2 | 3 | 4;

interface RecipientInfo {
  id: string | null;
  fullName: string;
  accountNumber: string;
  email: string;
  isExternal?: boolean;
}

// ── Step indicator ───────────────────────────────────────────────────────────
function StepBar({ current }: { current: number }) {
  const total = 3; // steps 1–3 visible; 4 = result
  return (
    <div className="flex gap-1.5 px-4 mb-6">
      {Array.from({ length: total }).map((_, i) => (
        <div
          key={i}
          className={`h-1 flex-1 rounded-full transition-colors ${
            i + 1 <= current ? 'bg-[#0052ff]' : 'bg-[#3a3939]'
          }`}
        />
      ))}
    </div>
  );
}

// ── Main component ───────────────────────────────────────────────────────────
export default function SendMoneyScreen() {
  const { user, refreshUser } = useAuth();
  const navigate = useNavigate();

  const [step, setStep] = useState<Step>(1);
  const [accountInput, setAccountInput] = useState('');
  const [recipient, setRecipient] = useState<RecipientInfo | null>(null);
  const [lookupError, setLookupError] = useState('');
  const [lookupLoading, setLookupLoading] = useState(false);
  const [externalPending, setExternalPending] = useState(false);

  const [amount, setAmount] = useState('');
  const [description, setDescription] = useState('');

  const [tcc, setTcc] = useState('');
  const [tccError, setTccError] = useState('');
  const [otpSent, setOtpSent] = useState(false);
  const [otpLoading, setOtpLoading] = useState(false);
  const [otpEmail, setOtpEmail] = useState('');

  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<{ success: boolean; message: string } | null>(null);

  // ── Step 1: lookup recipient ─────────────────────────────────────────────
  const handleLookup = useCallback(async () => {
    if (!accountInput.trim()) return;
    setLookupLoading(true);
    setLookupError('');
    setExternalPending(false);
    try {
      const token = pb.authStore.token;
      const res = await fetch(
        `${API_URL}/api/users/lookup?q=${encodeURIComponent(accountInput.trim())}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      const data = await res.json();
      if (res.status === 404) {
        setExternalPending(true);
        return;
      }
      if (!res.ok) {
        setLookupError(data?.error || 'Lookup failed.');
        return;
      }
      if (data.id === user?.id) {
        setLookupError('You cannot send money to yourself.');
        return;
      }
      setRecipient({
        id: data.id,
        fullName: data.fullName,
        accountNumber: data.accountNumber || accountInput.trim(),
        email: '',
      });
      setStep(2);
    } catch {
      setLookupError('Lookup failed. Please try again.');
    } finally {
      setLookupLoading(false);
    }
  }, [accountInput, user]);

  // ── Step 1b: confirm external transfer ────────────────────────────────────
  const confirmExternal = useCallback(() => {
    setExternalPending(false);
    setRecipient({
      id: null,
      fullName: 'External Account',
      accountNumber: accountInput.trim(),
      email: '',
      isExternal: true,
    });
    setStep(2);
  }, [accountInput]);

  // ── Step 2 → 3: validate amount then immediately request OTP ────────────
  const handleAmountNext = async () => {
    const n = parseFloat(amount);
    if (isNaN(n) || n <= 0) return;
    if (user && n > user.balance) return;
    setStep(3);
    await requestOtp();
  };

  // ── Request OTP from backend (no PIN required) ───────────────────────────
  const requestOtp = async () => {
    setOtpLoading(true);
    setTccError('');
    try {
      const token = pb.authStore.token;
      const res = await fetch(`${API_URL}/api/transaction/request-otp`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({}),
      });
      const data = await res.json();
      if (!res.ok) {
        setTccError(data?.error || 'Failed to send code. Try again.');
        return;
      }
      setOtpSent(true);
      setOtpEmail(data.email ?? '');
    } catch {
      setTccError('Network error. Please try again.');
    } finally {
      setOtpLoading(false);
    }
  };

  // ── Step 3: send money ───────────────────────────────────────────────────
  const handleSend = async () => {
    if (!recipient || !tcc.trim()) return;
    setSending(true);
    setTccError('');
    try {
      const token = pb.authStore.token;
      const res = await fetch(`${API_URL}/api/transaction`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          ...(recipient.accountNumber.includes('@')
            ? { recipientEmail: recipient.accountNumber }
            : { recipientAccountNumber: recipient.accountNumber }),
          amount: parseFloat(amount),
          tccCode: tcc.trim().toUpperCase(),
          description: description.trim() || undefined,
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        setTccError(data?.error || 'Transaction failed.');
        return;
      }
      await refreshUser();
      const displayName = recipient.isExternal
        ? `external account ${recipient.accountNumber}`
        : (data.recipientName || recipient.fullName);
      setResult({ success: true, message: `$${parseFloat(amount).toFixed(2)} sent to ${displayName}!` });
      setStep(4);
    } catch {
      setResult({ success: false, message: 'Network error. Please try again.' });
      setStep(4);
    } finally {
      setSending(false);
    }
  };

  const reset = () => {
    setStep(1);
    setAccountInput('');
    setRecipient(null);
    setLookupError('');
    setExternalPending(false);
    setAmount('');
    setDescription('');
    setTcc('');
    setTccError('');
    setOtpSent(false);
    setOtpEmail('');
    setResult(null);
  };

  return (
    <div className="flex flex-col min-h-screen bg-[#131313]">
      <PageHeader
        title="Send Money"
        onBack={step === 1 || step === 4 ? () => navigate(-1) : () => setStep((s) => (s - 1) as Step)}
      />

      {step < 4 && <StepBar current={step} />}

      <div className="flex-1 overflow-y-auto px-4 pb-24">

        {/* ── Step 1: Recipient ── */}
        {step === 1 && (
          <div className="flex flex-col gap-6">
            <div>
              <p className="text-white font-semibold text-lg mb-1">Who are you sending to?</p>
              <p className="text-[#8d90a2] text-sm">Enter the recipient's account number or email.</p>
            </div>

            <div className="flex flex-col gap-3">
              <label className="text-sm font-semibold text-[#8d90a2] uppercase tracking-wider">Account Number or Email</label>
              <input
                type="text"
                inputMode="text"
                placeholder="e.g. 10238472 or user@email.com"
                value={accountInput}
                onChange={(e) => { setAccountInput(e.target.value); setLookupError(''); setExternalPending(false); }}
                onKeyDown={(e) => e.key === 'Enter' && handleLookup()}
                className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white placeholder-[#8d90a2] outline-none"
              />
              {lookupError && <p className="text-red-400 text-sm">{lookupError}</p>}
            </div>

            {/* External transfer confirmation */}
            {externalPending && (
              <div className="bg-yellow-400/10 border border-yellow-400/30 rounded-2xl p-4 flex flex-col gap-3">
                <div className="flex items-start gap-2">
                  <AlertTriangle size={16} className="text-yellow-400 shrink-0 mt-0.5" />
                  <div>
                    <p className="text-yellow-400 text-sm font-semibold">Account not found in system</p>
                    <p className="text-[#8d90a2] text-xs mt-0.5">
                      No registered user found for <span className="text-white font-mono">{accountInput}</span>.
                      You can still send money as an external transfer — funds will be debited from your account.
                    </p>
                  </div>
                </div>
                <button
                  onClick={confirmExternal}
                  className="bg-yellow-400/20 border border-yellow-400/40 text-yellow-400 rounded-xl py-3 font-semibold text-sm flex items-center justify-center gap-2"
                >
                  <ArrowRight size={14} />
                  Continue as External Transfer
                </button>
              </div>
            )}

            <button
              onClick={handleLookup}
              disabled={lookupLoading || !accountInput.trim()}
              className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2 disabled:opacity-50"
            >
              {lookupLoading ? (
                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <>
                  <Search size={16} />
                  Find Account
                </>
              )}
            </button>
          </div>
        )}

        {/* ── Step 2: Amount ── */}
        {step === 2 && recipient && (
          <div className="flex flex-col gap-6">
            {/* Recipient card */}
            <div className={`rounded-2xl p-4 flex items-center gap-3 ${recipient.isExternal ? 'bg-yellow-400/10 border border-yellow-400/30' : 'bg-[#201f1f]'}`}>
              <div className={`w-12 h-12 rounded-full flex items-center justify-center shrink-0 ${recipient.isExternal ? 'bg-yellow-400/20' : 'bg-[#0052ff]/20'}`}>
                {recipient.isExternal
                  ? <Globe size={22} className="text-yellow-400" />
                  : <UserIcon size={22} className="text-[#0052ff]" />
                }
              </div>
              <div>
                <p className="text-white font-semibold">{recipient.isExternal ? 'External Transfer' : recipient.fullName}</p>
                <p className="text-[#8d90a2] text-sm">
                  {recipient.isExternal ? `To: ${recipient.accountNumber}` : `Acc: ${recipient.accountNumber}`}
                </p>
              </div>
              {recipient.isExternal
                ? <AlertTriangle size={18} className="text-yellow-400 ml-auto shrink-0" />
                : <CheckCircle size={18} className="text-green-400 ml-auto shrink-0" />
              }
            </div>

            {recipient.isExternal && (
              <div className="bg-yellow-400/10 border border-yellow-400/20 rounded-xl p-3">
                <p className="text-yellow-400 text-xs leading-relaxed">
                  <span className="font-semibold">External transfer:</span> Funds will be debited immediately and cannot be reversed.
                </p>
              </div>
            )}

            {/* Available balance */}
            <div className="bg-[#201f1f] rounded-2xl p-4 flex justify-between items-center">
              <span className="text-[#8d90a2] text-sm">Available balance</span>
              <span className="text-white font-bold">${(user?.balance ?? 0).toFixed(2)}</span>
            </div>

            {/* Amount input */}
            <div className="flex flex-col gap-3">
              <label className="text-sm font-semibold text-[#8d90a2] uppercase tracking-wider">Amount (USD)</label>
              <div className="relative">
                <DollarSign size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-[#8d90a2]" />
                <input
                  type="number"
                  inputMode="decimal"
                  placeholder="0.00"
                  value={amount}
                  min="0.01"
                  max={user?.balance}
                  onChange={(e) => setAmount(e.target.value)}
                  className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl pl-10 pr-4 py-3 text-white placeholder-[#8d90a2] outline-none w-full text-xl font-bold"
                />
              </div>
              {amount && user && parseFloat(amount) > user.balance && (
                <p className="text-red-400 text-sm">Insufficient balance.</p>
              )}
            </div>

            {/* Description */}
            <div className="flex flex-col gap-3">
              <label className="text-sm font-semibold text-[#8d90a2] uppercase tracking-wider">Description (optional)</label>
              <input
                type="text"
                placeholder="e.g. Rent payment"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white placeholder-[#8d90a2] outline-none"
              />
            </div>

            <button
              onClick={handleAmountNext}
              disabled={!amount || parseFloat(amount) <= 0 || (!!user && parseFloat(amount) > user.balance)}
              className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2 disabled:opacity-50 mt-2"
            >
              Continue — Send Code to My Email
              <ArrowRight size={16} />
            </button>
          </div>
        )}

        {/* ── Step 3: OTP ── */}
        {step === 3 && (
          <div className="flex flex-col gap-6 pt-2">
            <div className="text-center">
              <div className="w-14 h-14 rounded-full bg-[#0052ff]/20 flex items-center justify-center mx-auto mb-4">
                <KeyRound size={26} className="text-[#0052ff]" />
              </div>
              <p className="text-white font-semibold text-lg">Enter Transaction Code</p>
              {otpLoading ? (
                <p className="text-[#8d90a2] text-sm mt-1">Sending your code…</p>
              ) : otpSent ? (
                <p className="text-[#8d90a2] text-sm mt-1">
                  A 6-character code was sent to{' '}
                  <span className="text-white">{otpEmail}</span>. Valid for 10 minutes.
                </p>
              ) : (
                <p className="text-red-400 text-sm mt-1">Failed to send code. Tap Resend.</p>
              )}
            </div>

            {/* Transfer summary */}
            <div className="bg-[#201f1f] rounded-2xl p-4 space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-[#8d90a2]">To</span>
                <span className="text-white font-medium">
                  {recipient?.isExternal ? `External: ${recipient.accountNumber}` : recipient?.fullName}
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-[#8d90a2]">Amount</span>
                <span className="text-white font-bold">${parseFloat(amount).toFixed(2)}</span>
              </div>
              {description && (
                <div className="flex justify-between text-sm">
                  <span className="text-[#8d90a2]">Note</span>
                  <span className="text-white">{description}</span>
                </div>
              )}
            </div>

            <div className="flex flex-col gap-3">
              <label className="text-sm font-semibold text-[#8d90a2] uppercase tracking-wider">6-Character Code</label>
              <input
                type="text"
                inputMode="text"
                placeholder="e.g. X3A9KQ"
                value={tcc}
                onChange={(e) => { setTcc(e.target.value.toUpperCase().replace(/[^A-Z2-9]/g, '').slice(0, 6)); setTccError(''); }}
                maxLength={6}
                className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white placeholder-[#8d90a2] outline-none tracking-widest font-mono text-xl text-center"
              />
              {tccError && <p className="text-red-400 text-sm">{tccError}</p>}
            </div>

            <div className="flex gap-3">
              <button
                onClick={requestOtp}
                disabled={otpLoading}
                className="flex-1 bg-[#201f1f] text-white rounded-full py-4 font-semibold border border-[#8d90a2] text-sm"
              >
                {otpLoading ? 'Sending…' : 'Resend Code'}
              </button>
              <button
                onClick={handleSend}
                disabled={sending || tcc.length !== 6}
                className="flex-1 bg-[#0052ff] text-white rounded-full py-4 font-semibold flex items-center justify-center gap-2 disabled:opacity-50"
              >
                {sending ? (
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : (
                  <>
                    <SendHorizonal size={16} />
                    Send
                  </>
                )}
              </button>
            </div>
          </div>
        )}

        {/* ── Step 4: Result ── */}
        {step === 4 && result && (
          <div className="flex flex-col items-center justify-center min-h-[60vh] gap-6 text-center">
            <div
              className={`w-24 h-24 rounded-full flex items-center justify-center ${
                result.success ? 'bg-green-400/10' : 'bg-red-400/10'
              }`}
            >
              {result.success ? (
                <CheckCircle size={48} className="text-green-400" />
              ) : (
                <XCircle size={48} className="text-red-400" />
              )}
            </div>

            <div>
              <p className="text-white font-bold text-2xl mb-2">
                {result.success ? 'Transfer Successful!' : 'Transfer Failed'}
              </p>
              <p className="text-[#8d90a2] text-sm max-w-[280px] mx-auto">{result.message}</p>
            </div>

            <div className="flex flex-col gap-3 w-full mt-4">
              {result.success && (
                <button
                  onClick={() => navigate('/transactions')}
                  className="bg-[#201f1f] text-white rounded-full py-4 font-semibold border border-[#8d90a2]"
                >
                  View Transactions
                </button>
              )}
              <button
                onClick={result.success ? () => navigate('/') : reset}
                className="bg-[#0052ff] text-white rounded-full py-4 font-semibold"
              >
                {result.success ? 'Back to Home' : 'Try Again'}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
