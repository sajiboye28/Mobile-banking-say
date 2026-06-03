import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Banknote, Plus, X, Loader2, ChevronDown, ChevronUp,
  AlertCircle, Clock, CheckCircle2, TrendingUp, XCircle,
} from 'lucide-react';
import { format } from 'date-fns';
import { pb } from '../services/pb';
import { useAuth } from '../context/AuthContext';
import type { Loan } from '../models/types';
import PageHeader from '../components/PageHeader';

const LOAN_PURPOSES = [
  'Personal', 'Home Improvement', 'Education', 'Vehicle',
  'Medical', 'Business', 'Debt Consolidation', 'Travel', 'Other',
];
const LOAN_TERMS = [6, 12, 18, 24, 36, 48, 60];
const INTEREST_RATE = 0.12;

function calcMonthly(amount: number, term: number): number {
  const r = INTEREST_RATE / 12;
  return (amount * r * Math.pow(1 + r, term)) / (Math.pow(1 + r, term) - 1);
}

const STATUS_CONFIG = {
  pending: { icon: Clock, color: 'text-yellow-400', bg: 'bg-yellow-400/10', label: 'Pending' },
  approved: { icon: CheckCircle2, color: 'text-green-400', bg: 'bg-green-400/10', label: 'Approved' },
  active: { icon: TrendingUp, color: 'text-blue-400', bg: 'bg-blue-400/10', label: 'Active' },
  rejected: { icon: XCircle, color: 'text-red-400', bg: 'bg-red-400/10', label: 'Rejected' },
  closed: { icon: CheckCircle2, color: 'text-[#8d90a2]', bg: 'bg-[#8d90a2]/10', label: 'Closed' },
} as const;

function formatCurrency(n: number) {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(n);
}

// ── Application form ─────────────────────────────────────────────────────────
function LoanApplicationForm({
  userId,
  onClose,
  onCreated,
}: {
  userId: string;
  onClose: () => void;
  onCreated: (loan: Loan) => void;
}) {
  const [amount, setAmount] = useState('');
  const [purpose, setPurpose] = useState(LOAN_PURPOSES[0]);
  const [term, setTerm] = useState(12);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const amountNum = parseFloat(amount) || 0;
  const monthly = amountNum > 0 ? calcMonthly(amountNum, term) : 0;

  const handleApply = async () => {
    const n = parseFloat(amount);
    if (isNaN(n) || n < 100) { setError('Minimum loan amount is $100.'); return; }
    if (n > 100000) { setError('Maximum loan amount is $100,000.'); return; }
    setSaving(true);
    setError('');
    try {
      const record = await pb.collection('loans').create({
        userId,
        amount: n,
        purpose,
        termMonths: term,
        interestRate: parseFloat((INTEREST_RATE * 100).toFixed(2)),
        monthlyPayment: parseFloat(monthly.toFixed(2)),
        status: 'pending',
      });
      onCreated(record as unknown as Loan);
      onClose();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to submit application.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end">
      <div className="absolute inset-0 bg-black/60" onClick={onClose} />
      <div className="relative bg-[#201f1f] rounded-t-3xl p-6 pb-10 space-y-5 max-h-[90vh] overflow-y-auto">
        <div className="w-10 h-1 bg-[#3a3939] rounded-full mx-auto mb-2" />
        <div className="flex items-center justify-between">
          <p className="text-white font-bold text-lg">Apply for a Loan</p>
          <button onClick={onClose}><X size={20} className="text-[#8d90a2]" /></button>
        </div>

        {/* Amount */}
        <div className="flex flex-col gap-2">
          <label className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider">Loan Amount (USD)</label>
          <input
            type="number"
            inputMode="decimal"
            placeholder="e.g. 5000"
            value={amount}
            min="100"
            max="100000"
            onChange={(e) => setAmount(e.target.value)}
            className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white placeholder-[#8d90a2] outline-none text-xl font-bold"
          />
        </div>

        {/* Purpose */}
        <div className="flex flex-col gap-2">
          <label className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider">Purpose</label>
          <select
            value={purpose}
            onChange={(e) => setPurpose(e.target.value)}
            className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white outline-none [color-scheme:dark]"
          >
            {LOAN_PURPOSES.map((p) => <option key={p} value={p}>{p}</option>)}
          </select>
        </div>

        {/* Term */}
        <div className="flex flex-col gap-2">
          <label className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider">Repayment Term</label>
          <div className="flex flex-wrap gap-2">
            {LOAN_TERMS.map((t) => (
              <button
                key={t}
                onClick={() => setTerm(t)}
                className={`px-4 py-2 rounded-xl text-sm font-semibold transition-colors ${
                  term === t ? 'bg-[#0052ff] text-white' : 'bg-[#2a2a2a] text-[#8d90a2] border border-[#3a3939]'
                }`}
              >
                {t} mo
              </button>
            ))}
          </div>
        </div>

        {/* Summary */}
        {amountNum > 0 && (
          <div className="bg-[#131313] rounded-xl p-4 space-y-2">
            <p className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider mb-3">Loan Summary</p>
            {[
              { label: 'Principal', value: formatCurrency(amountNum) },
              { label: 'Interest Rate', value: `${(INTEREST_RATE * 100).toFixed(0)}% p.a.` },
              { label: 'Term', value: `${term} months` },
              { label: 'Monthly Payment', value: formatCurrency(monthly) },
              { label: 'Total Repayment', value: formatCurrency(monthly * term) },
            ].map(({ label, value }) => (
              <div key={label} className="flex justify-between text-sm">
                <span className="text-[#8d90a2]">{label}</span>
                <span className="text-white font-medium">{value}</span>
              </div>
            ))}
          </div>
        )}

        <div className="flex items-start gap-2 bg-yellow-400/10 rounded-xl p-3">
          <AlertCircle size={14} className="text-yellow-400 shrink-0 mt-0.5" />
          <p className="text-yellow-400 text-xs">
            Loan applications are reviewed within 1–3 business days. Approval is not guaranteed.
          </p>
        </div>

        {error && <p className="text-red-400 text-sm">{error}</p>}

        <button
          onClick={handleApply}
          disabled={saving || !amount || parseFloat(amount) < 100}
          className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2 disabled:opacity-50"
        >
          {saving ? <Loader2 size={16} className="animate-spin" /> : <Banknote size={16} />}
          Submit Application
        </button>
      </div>
    </div>
  );
}

// ── Loan card ────────────────────────────────────────────────────────────────
function LoanCard({ loan }: { loan: Loan }) {
  const [expanded, setExpanded] = useState(false);
  const cfg = STATUS_CONFIG[loan.status as keyof typeof STATUS_CONFIG] ?? STATUS_CONFIG.pending;
  const StatusIcon = cfg.icon;

  return (
    <div className="bg-[#201f1f] rounded-2xl overflow-hidden">
      <button
        className="w-full p-4 flex items-center gap-3 text-left"
        onClick={() => setExpanded((e) => !e)}
      >
        <div className={`w-11 h-11 rounded-xl ${cfg.bg} flex items-center justify-center shrink-0`}>
          <StatusIcon size={20} className={cfg.color} />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-white font-semibold truncate">{loan.purpose}</p>
          <p className="text-[#8d90a2] text-sm">{formatCurrency(loan.amount)} · {loan.termMonths} months</p>
        </div>
        <div className="flex flex-col items-end gap-1.5 shrink-0">
          <span className={`text-xs font-semibold px-2 py-0.5 rounded-full capitalize ${cfg.bg} ${cfg.color}`}>
            {cfg.label}
          </span>
          {expanded ? (
            <ChevronUp size={14} className="text-[#8d90a2]" />
          ) : (
            <ChevronDown size={14} className="text-[#8d90a2]" />
          )}
        </div>
      </button>

      {expanded && (
        <div className="px-4 pb-4 border-t border-[#3a3939] pt-3 space-y-2">
          {[
            { label: 'Loan Amount', value: formatCurrency(loan.amount) },
            {
              label: 'Monthly Payment',
              value: loan.monthlyPayment > 0 ? formatCurrency(loan.monthlyPayment) : 'Pending review',
            },
            {
              label: 'Interest Rate',
              value: loan.interestRate > 0 ? `${loan.interestRate.toFixed(1)}% p.a.` : 'TBD',
            },
            { label: 'Term', value: `${loan.termMonths} months` },
            {
              label: 'Total Repayment',
              value: loan.monthlyPayment > 0
                ? formatCurrency(loan.monthlyPayment * loan.termMonths)
                : 'TBD',
            },
            {
              label: 'Applied',
              value: loan.created ? format(new Date(loan.created), 'MMM d, yyyy') : '—',
            },
          ].map(({ label, value }) => (
            <div key={label} className="flex justify-between text-sm">
              <span className="text-[#8d90a2]">{label}</span>
              <span className="text-white font-medium">{value}</span>
            </div>
          ))}

          {loan.status === 'active' && loan.monthlyPayment > 0 && (
            <div className="mt-3 pt-3 border-t border-[#3a3939]">
              <div className="flex justify-between text-xs text-[#8d90a2] mb-1.5">
                <span>Repayment progress</span>
                <span>Active</span>
              </div>
              <div className="h-1.5 bg-[#3a3939] rounded-full overflow-hidden">
                <div className="h-full bg-blue-400 rounded-full w-[10%]" />
              </div>
            </div>
          )}

          {loan.status === 'rejected' && loan.rejectionReason && (
            <div className="flex items-start gap-2 bg-red-400/10 rounded-xl p-3 mt-2">
              <AlertCircle size={14} className="text-red-400 shrink-0 mt-0.5" />
              <p className="text-red-400 text-xs">{loan.rejectionReason}</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// ── Main ─────────────────────────────────────────────────────────────────────
export default function LoansScreen() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [loans, setLoans] = useState<Loan[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);

  const load = useCallback(async () => {
    if (!user) return;
    setLoading(true);
    try {
      const records = await pb.collection('loans').getFullList({
        filter: `userId="${user.id}"`,
        sort: '-created',
      });
      setLoans(records as unknown as Loan[]);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [user]);

  useEffect(() => { load(); }, [load]);

  const handleCreated = (loan: Loan) => setLoans((prev) => [loan, ...prev]);

  const activeLoans = loans.filter((l) => l.status === 'active');
  const pendingLoans = loans.filter((l) => l.status === 'pending');
  const historyLoans = loans.filter((l) => !['active', 'pending'].includes(l.status));

  const totalActive = activeLoans.reduce((s, l) => s + l.amount, 0);

  return (
    <div className="flex flex-col min-h-screen bg-[#131313]">
      <PageHeader title="Loans" onBack={() => navigate(-1)} />

      <div className="flex-1 overflow-y-auto px-4 pb-32 space-y-5">

        {/* Active loan hero */}
        {activeLoans.length > 0 && (
          <div className="bg-gradient-to-br from-[#003bc2] to-[#0052ff] rounded-2xl p-5 space-y-3">
            <p className="text-white/70 text-sm">Total Active Loans</p>
            <p className="text-white text-3xl font-bold">{formatCurrency(totalActive)}</p>
            <div className="flex justify-between text-sm">
              {activeLoans.slice(0, 1).map((l) => (
                <>
                  <div key="monthly">
                    <p className="text-white/70">Monthly</p>
                    <p className="text-white font-semibold">{formatCurrency(l.monthlyPayment)}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-white/70">Rate</p>
                    <p className="text-white font-semibold">{l.interestRate}% p.a.</p>
                  </div>
                  <div className="text-right">
                    <p className="text-white/70">Term</p>
                    <p className="text-white font-semibold">{l.termMonths} mo</p>
                  </div>
                </>
              ))}
            </div>
          </div>
        )}

        {/* CTA banner */}
        {activeLoans.length === 0 && (
          <div className="bg-gradient-to-br from-[#1e2d5a] to-[#131313] rounded-2xl p-4 border border-[#0052ff]/20">
            <h3 className="text-white font-semibold text-base">Need financing?</h3>
            <p className="text-[#8d90a2] text-sm mt-1 mb-3">
              Apply for a personal loan with competitive rates starting at {(INTEREST_RATE * 100).toFixed(0)}% APR.
            </p>
          </div>
        )}

        {loading ? (
          <div className="space-y-3">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="bg-[#201f1f] rounded-2xl h-20 animate-pulse" />
            ))}
          </div>
        ) : loans.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 gap-4">
            <div className="w-20 h-20 rounded-full bg-[#201f1f] flex items-center justify-center">
              <Banknote size={36} className="text-[#8d90a2]" />
            </div>
            <p className="text-white font-semibold text-lg">No loans yet</p>
            <p className="text-[#8d90a2] text-sm text-center max-w-[240px]">
              Apply for a loan to get funds quickly and securely.
            </p>
          </div>
        ) : (
          <>
            {pendingLoans.length > 0 && (
              <div className="space-y-2">
                <p className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider">Pending</p>
                {pendingLoans.map((l) => <LoanCard key={l.id} loan={l} />)}
              </div>
            )}
            {activeLoans.length > 0 && (
              <div className="space-y-2">
                <p className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider">Active</p>
                {activeLoans.map((l) => <LoanCard key={l.id} loan={l} />)}
              </div>
            )}
            {historyLoans.length > 0 && (
              <div className="space-y-2">
                <p className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider">History</p>
                {historyLoans.map((l) => <LoanCard key={l.id} loan={l} />)}
              </div>
            )}
          </>
        )}
      </div>

      {/* FAB */}
      <div className="fixed bottom-8 left-1/2 -translate-x-1/2 w-full max-w-[430px] px-4">
        <button
          onClick={() => setShowForm(true)}
          className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2 shadow-lg"
        >
          <Plus size={18} />
          Apply for Loan
        </button>
      </div>

      {showForm && user && (
        <LoanApplicationForm
          userId={user.id}
          onClose={() => setShowForm(false)}
          onCreated={handleCreated}
        />
      )}
    </div>
  );
}
