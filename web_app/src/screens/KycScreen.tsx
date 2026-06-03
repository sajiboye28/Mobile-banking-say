import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Shield, CheckCircle2, Clock, XCircle, AlertTriangle,
  Loader2, ChevronRight,
} from 'lucide-react';
import { pb, API_URL } from '../services/pb';
import { useAuth } from '../context/AuthContext';
import PageHeader from '../components/PageHeader';

// ── Step indicator ────────────────────────────────────────────────────────────
function StepIndicator({ current, total }: { current: number; total: number }) {
  return (
    <div className="flex items-center justify-center gap-2 mb-6">
      {Array.from({ length: total }).map((_, i) => (
        <div key={i} className="flex items-center gap-2">
          <div
            className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold transition-colors ${
              i + 1 < current
                ? 'bg-green-400/20 text-green-400'
                : i + 1 === current
                ? 'bg-[#0052ff] text-white'
                : 'bg-[#3a3939] text-[#8d90a2]'
            }`}
          >
            {i + 1 < current ? '✓' : i + 1}
          </div>
          {i < total - 1 && (
            <div className={`w-8 h-0.5 rounded-full ${i + 1 < current ? 'bg-green-400' : 'bg-[#3a3939]'}`} />
          )}
        </div>
      ))}
    </div>
  );
}

const ID_TYPES = ['Passport', 'National ID', "Driver's License", 'Residence Permit'];

interface FormData {
  fullName: string;
  dateOfBirth: string;
  nationality: string;
  documentType: string;
  documentNumber: string;
  documentExpiry: string;
}

// ── Status display ────────────────────────────────────────────────────────────
function KycStatusView({
  status,
  rejectionReason,
  onResubmit,
}: {
  status: string;
  rejectionReason?: string;
  onResubmit: () => void;
}) {
  if (status === 'approved') {
    return (
      <div className="flex flex-col items-center gap-5 py-10 text-center">
        <div className="w-24 h-24 rounded-full bg-green-400/10 flex items-center justify-center">
          <CheckCircle2 size={48} className="text-green-400" />
        </div>
        <div>
          <p className="text-white font-bold text-2xl">Verified!</p>
          <p className="text-[#8d90a2] text-sm mt-1 max-w-[260px] mx-auto">
            Your identity is verified. You have full access to all features.
          </p>
        </div>
        <div className="bg-green-400/10 border border-green-400/20 rounded-2xl p-4 w-full">
          <div className="flex items-center gap-2">
            <CheckCircle2 size={16} className="text-green-400" />
            <span className="text-green-400 font-semibold text-sm">Identity Verified</span>
          </div>
        </div>
      </div>
    );
  }

  if (status === 'pending') {
    return (
      <div className="flex flex-col items-center gap-5 py-10 text-center">
        <div className="w-24 h-24 rounded-full bg-yellow-400/10 flex items-center justify-center">
          <Clock size={48} className="text-yellow-400" />
        </div>
        <div>
          <p className="text-white font-bold text-2xl">Under Review</p>
          <p className="text-[#8d90a2] text-sm mt-1 max-w-[260px] mx-auto">
            Your documents are being reviewed. This typically takes 1–2 business days.
          </p>
        </div>
        <div className="bg-yellow-400/10 border border-yellow-400/20 rounded-2xl p-4 w-full">
          <div className="flex items-center gap-2">
            <Clock size={14} className="text-yellow-400" />
            <span className="text-yellow-400 font-semibold text-sm">Pending Admin Review</span>
          </div>
          <p className="text-[#8d90a2] text-xs mt-1.5 text-left">
            You'll receive a notification once the review is complete.
          </p>
        </div>
      </div>
    );
  }

  if (status === 'rejected') {
    return (
      <div className="flex flex-col gap-5">
        <div className="flex flex-col items-center gap-4 py-6 text-center">
          <div className="w-20 h-20 rounded-full bg-red-400/10 flex items-center justify-center">
            <XCircle size={40} className="text-red-400" />
          </div>
          <div>
            <p className="text-white font-bold text-xl">Verification Rejected</p>
            <p className="text-[#8d90a2] text-sm mt-1">Please resubmit with valid documents.</p>
          </div>
        </div>

        {rejectionReason && (
          <div className="bg-red-400/10 border border-red-400/20 rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-1">
              <XCircle size={14} className="text-red-400" />
              <span className="text-red-400 font-semibold text-sm">Rejection Reason</span>
            </div>
            <p className="text-[#8d90a2] text-sm">{rejectionReason}</p>
          </div>
        )}

        <button
          onClick={onResubmit}
          className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2"
        >
          <Shield size={16} />
          Resubmit Verification
        </button>
      </div>
    );
  }

  // not_submitted / unverified — show overview
  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-col items-center gap-4 py-4 text-center">
        <div className="w-20 h-20 rounded-full bg-[#0052ff]/10 flex items-center justify-center">
          <Shield size={40} className="text-[#0052ff]" />
        </div>
        <div>
          <p className="text-white font-bold text-xl">Verify Your Identity</p>
          <p className="text-[#8d90a2] text-sm mt-1 max-w-[260px] mx-auto">
            Complete KYC to unlock full banking features and higher transaction limits.
          </p>
        </div>
      </div>

      <div className="bg-[#201f1f] rounded-2xl p-4 space-y-3">
        <p className="text-white text-sm font-semibold">What you'll need</p>
        {[
          'Full name and date of birth',
          'A valid government-issued ID',
          'Your nationality',
        ].map((item) => (
          <div key={item} className="flex items-center gap-2.5">
            <CheckCircle2 size={14} className="text-[#0052ff] shrink-0" />
            <p className="text-[#8d90a2] text-sm">{item}</p>
          </div>
        ))}
      </div>

      <div className="bg-[#201f1f] rounded-2xl overflow-hidden divide-y divide-[#3a3939]">
        {[
          { step: 1, title: 'Personal Information', desc: 'Full name, DOB, nationality' },
          { step: 2, title: 'Identity Document', desc: 'ID type, number, expiry' },
          { step: 3, title: 'Review & Submit', desc: 'Confirm and send for review' },
        ].map(({ step, title, desc }) => (
          <div key={step} className="flex items-center gap-3 px-4 py-3">
            <div className="w-8 h-8 rounded-full bg-[#0052ff]/10 flex items-center justify-center shrink-0 text-xs font-bold text-[#0052ff]">
              {step}
            </div>
            <div>
              <p className="text-white text-sm font-medium">{title}</p>
              <p className="text-[#8d90a2] text-xs">{desc}</p>
            </div>
            <ChevronRight size={14} className="text-[#8d90a2] ml-auto shrink-0" />
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Main ─────────────────────────────────────────────────────────────────────
export default function KycScreen() {
  const { user, refreshUser } = useAuth();
  const navigate = useNavigate();

  const kycStatus = user?.kycStatus ?? 'not_submitted';
  const canSubmit = ['not_submitted', 'rejected', 'unverified'].includes(kycStatus);

  const [formStep, setFormStep] = useState<0 | 1 | 2 | 3>(0); // 0 = overview, 1-3 = form steps
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState('');
  const [submitSuccess, setSubmitSuccess] = useState(false);

  const [form, setForm] = useState<FormData>({
    fullName: user?.fullName ?? '',
    dateOfBirth: '',
    nationality: '',
    documentType: ID_TYPES[0],
    documentNumber: '',
    documentExpiry: '',
  });

  const update = (field: keyof FormData, value: string) =>
    setForm((prev) => ({ ...prev, [field]: value }));

  const handleSubmit = useCallback(async () => {
    setSubmitting(true);
    setSubmitError('');
    try {
      const token = pb.authStore.token;
      const res = await fetch(`${API_URL}/api/kyc/submit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          fullName: form.fullName,
          dateOfBirth: form.dateOfBirth || undefined,
          nationality: form.nationality || undefined,
          documentType: form.documentType,
          documentNumber: form.documentNumber,
          documentExpiry: form.documentExpiry || undefined,
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        setSubmitError(data?.error || 'Submission failed.');
        return;
      }
      setSubmitSuccess(true);
      await refreshUser();
    } catch {
      setSubmitError('Network error. Please try again.');
    } finally {
      setSubmitting(false);
    }
  }, [form, refreshUser]);

  const inputClass = 'bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white placeholder-[#8d90a2] outline-none w-full';
  const labelClass = 'text-xs font-semibold text-[#8d90a2] uppercase tracking-wider';

  return (
    <div className="flex flex-col min-h-screen bg-[#131313]">
      <PageHeader title="KYC Verification" onBack={() => formStep === 0 ? navigate(-1) : setFormStep((s) => (s - 1) as 0 | 1 | 2 | 3)} />

      <div className="flex-1 overflow-y-auto px-4 pb-24">

        {/* Show status if already submitted */}
        {!canSubmit || (kycStatus !== 'not_submitted' && formStep === 0) ? (
          <KycStatusView
            status={kycStatus}
            onResubmit={() => setFormStep(1)}
          />
        ) : formStep === 0 ? (
          <>
            <KycStatusView status={kycStatus} onResubmit={() => setFormStep(1)} />
            {canSubmit && (
              <button
                onClick={() => setFormStep(1)}
                className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2 mt-5"
              >
                <Shield size={16} />
                Start Verification
              </button>
            )}
          </>
        ) : submitSuccess ? (
          <div className="flex flex-col items-center gap-5 py-10 text-center">
            <div className="w-24 h-24 rounded-full bg-yellow-400/10 flex items-center justify-center">
              <Clock size={48} className="text-yellow-400" />
            </div>
            <div>
              <p className="text-white font-bold text-2xl">Submitted!</p>
              <p className="text-[#8d90a2] text-sm mt-1 max-w-[260px] mx-auto">
                Your KYC application is under review. We'll notify you once processed.
              </p>
            </div>
            <button
              onClick={() => { setFormStep(0); navigate('/profile'); }}
              className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full mt-2"
            >
              Back to Profile
            </button>
          </div>
        ) : (
          <>
            <StepIndicator current={formStep} total={3} />

            {/* Step 1: Personal info */}
            {formStep === 1 && (
              <div className="space-y-4">
                <div>
                  <p className="text-white font-bold text-lg mb-1">Personal Information</p>
                  <p className="text-[#8d90a2] text-sm">Enter your legal personal details.</p>
                </div>

                <div className="flex flex-col gap-2">
                  <label className={labelClass}>Full Legal Name</label>
                  <input
                    type="text"
                    placeholder="e.g. John Michael Doe"
                    value={form.fullName}
                    onChange={(e) => update('fullName', e.target.value)}
                    className={inputClass}
                  />
                </div>

                <div className="flex flex-col gap-2">
                  <label className={labelClass}>Date of Birth</label>
                  <input
                    type="date"
                    value={form.dateOfBirth}
                    onChange={(e) => update('dateOfBirth', e.target.value)}
                    className={`${inputClass} [color-scheme:dark]`}
                  />
                </div>

                <div className="flex flex-col gap-2">
                  <label className={labelClass}>Nationality</label>
                  <input
                    type="text"
                    placeholder="e.g. American"
                    value={form.nationality}
                    onChange={(e) => update('nationality', e.target.value)}
                    className={inputClass}
                  />
                </div>

                <button
                  onClick={() => setFormStep(2)}
                  disabled={!form.fullName.trim()}
                  className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2 disabled:opacity-50 mt-2"
                >
                  Continue
                  <ChevronRight size={16} />
                </button>
              </div>
            )}

            {/* Step 2: ID details */}
            {formStep === 2 && (
              <div className="space-y-4">
                <div>
                  <p className="text-white font-bold text-lg mb-1">Identity Document</p>
                  <p className="text-[#8d90a2] text-sm">Enter your government-issued ID details.</p>
                </div>

                <div className="flex flex-col gap-2">
                  <label className={labelClass}>Document Type</label>
                  <select
                    value={form.documentType}
                    onChange={(e) => update('documentType', e.target.value)}
                    className={`${inputClass} [color-scheme:dark]`}
                  >
                    {ID_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
                  </select>
                </div>

                <div className="flex flex-col gap-2">
                  <label className={labelClass}>Document Number</label>
                  <input
                    type="text"
                    placeholder="e.g. AB1234567"
                    value={form.documentNumber}
                    onChange={(e) => update('documentNumber', e.target.value)}
                    className={`${inputClass} uppercase`}
                  />
                </div>

                <div className="flex flex-col gap-2">
                  <label className={labelClass}>Expiry Date (optional)</label>
                  <input
                    type="date"
                    value={form.documentExpiry}
                    onChange={(e) => update('documentExpiry', e.target.value)}
                    className={`${inputClass} [color-scheme:dark]`}
                  />
                </div>

                <button
                  onClick={() => setFormStep(3)}
                  disabled={!form.documentNumber.trim()}
                  className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2 disabled:opacity-50 mt-2"
                >
                  Continue
                  <ChevronRight size={16} />
                </button>
              </div>
            )}

            {/* Step 3: Review + submit */}
            {formStep === 3 && (
              <div className="space-y-4">
                <div>
                  <p className="text-white font-bold text-lg mb-1">Review & Submit</p>
                  <p className="text-[#8d90a2] text-sm">Please review your information before submitting.</p>
                </div>

                <div className="bg-[#201f1f] rounded-2xl p-4 space-y-3">
                  {[
                    { label: 'Full Name', value: form.fullName },
                    { label: 'Date of Birth', value: form.dateOfBirth || '—' },
                    { label: 'Nationality', value: form.nationality || '—' },
                    { label: 'Document Type', value: form.documentType },
                    { label: 'Document Number', value: form.documentNumber },
                    { label: 'Document Expiry', value: form.documentExpiry || '—' },
                  ].map(({ label, value }) => (
                    <div key={label} className="flex justify-between text-sm">
                      <span className="text-[#8d90a2]">{label}</span>
                      <span className="text-white font-medium">{value}</span>
                    </div>
                  ))}
                </div>

                <div className="flex items-start gap-2 bg-[#0052ff]/10 rounded-xl p-3">
                  <AlertTriangle size={14} className="text-[#0052ff] shrink-0 mt-0.5" />
                  <p className="text-[#8d90a2] text-xs">
                    By submitting, you confirm that all provided information is accurate and truthful.
                    False information may result in account termination.
                  </p>
                </div>

                {submitError && <p className="text-red-400 text-sm">{submitError}</p>}

                <button
                  onClick={handleSubmit}
                  disabled={submitting}
                  className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2 disabled:opacity-50"
                >
                  {submitting ? (
                    <Loader2 size={16} className="animate-spin" />
                  ) : (
                    <Shield size={16} />
                  )}
                  Submit for Verification
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
