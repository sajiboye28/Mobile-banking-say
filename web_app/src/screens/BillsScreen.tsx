import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Zap, Droplets, Wifi, Tv, Phone, MoreHorizontal,
  ArrowLeft, CheckCircle, XCircle, Loader2, Receipt,
} from 'lucide-react';
import { format } from 'date-fns';
import { pb } from '../services/pb';
import { useAuth } from '../context/AuthContext';
import type { BillPayment } from '../models/types';
import PageHeader from '../components/PageHeader';

// ── Bill categories ──────────────────────────────────────────────────────────
const CATEGORIES = [
  { id: 'electricity', Icon: Zap, label: 'Electricity', color: '#fdcb6e', bg: '#fdcb6e1a' },
  { id: 'water', Icon: Droplets, label: 'Water', color: '#74b9ff', bg: '#74b9ff1a' },
  { id: 'internet', Icon: Wifi, label: 'Internet', color: '#a29bfe', bg: '#a29bfe1a' },
  { id: 'tv', Icon: Tv, label: 'TV / Cable', color: '#fd79a8', bg: '#fd79a81a' },
  { id: 'phone', Icon: Phone, label: 'Phone', color: '#55efc4', bg: '#55efc41a' },
  { id: 'others', Icon: MoreHorizontal, label: 'Others', color: '#8d90a2', bg: '#8d90a21a' },
];

const BILLERS: Record<string, string[]> = {
  electricity: ['PowerGrid Corp', 'City Electric', 'National Power'],
  water: ['Metro Water', 'City Utilities', 'AquaSupply'],
  internet: ['FiberNet', 'SpeedConnect', 'BroadLink'],
  tv: ['CableMax', 'StreamTV', 'SkyVision'],
  phone: ['MobilePlus', 'TelecomOne', 'CallNet'],
  others: ['Government Fees', 'Insurance', 'Mortgage', 'Custom'],
};

type FlowStep = 'select' | 'form' | 'confirm' | 'result';

function getCatConfig(id: string) {
  return CATEGORIES.find((c) => c.id === id) ?? CATEGORIES[CATEGORIES.length - 1];
}

// ── Payment flow modal ────────────────────────────────────────────────────────
function BillPaymentFlow({
  userId,
  onClose,
  onSuccess,
}: {
  userId: string;
  onClose: () => void;
  onSuccess: (bill: BillPayment) => void;
}) {
  const [step, setStep] = useState<FlowStep>('select');
  const [category, setCategory] = useState<typeof CATEGORIES[0] | null>(null);
  const [biller, setBiller] = useState('');
  const [accountNumber, setAccountNumber] = useState('');
  const [amount, setAmount] = useState('');
  const [paying, setPaying] = useState(false);
  const [error, setError] = useState('');
  const [resultOk, setResultOk] = useState(false);

  const billerList = category ? BILLERS[category.id] ?? [] : [];

  const handlePay = async () => {
    const n = parseFloat(amount);
    if (isNaN(n) || n <= 0) { setError('Enter a valid amount.'); return; }
    setPaying(true);
    setError('');
    try {
      const record = await pb.collection('bill_payments').create({
        userId,
        category: category!.id,
        biller,
        accountNumber: accountNumber.trim(),
        amount: n,
        status: 'success',
      });
      setResultOk(true);
      onSuccess(record as unknown as BillPayment);
    } catch (e: unknown) {
      setResultOk(false);
      setError(e instanceof Error ? e.message : 'Payment failed.');
    } finally {
      setPaying(false);
      setStep('result');
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end">
      <div className="absolute inset-0 bg-black/60" onClick={onClose} />
      <div className="relative bg-[#201f1f] rounded-t-3xl p-6 pb-10 space-y-5 max-h-[90vh] overflow-y-auto">
        <div className="w-10 h-1 bg-[#3a3939] rounded-full mx-auto mb-2" />

        <div className="flex items-center gap-3">
          {step !== 'select' && step !== 'result' && (
            <button onClick={() => setStep(step === 'confirm' ? 'form' : 'select')}>
              <ArrowLeft size={20} className="text-[#8d90a2]" />
            </button>
          )}
          <p className="text-white font-bold text-lg flex-1">
            {step === 'select' && 'Pay a Bill'}
            {step === 'form' && `${category?.label} Payment`}
            {step === 'confirm' && 'Confirm Payment'}
            {step === 'result' && (resultOk ? 'Payment Successful' : 'Payment Failed')}
          </p>
        </div>

        {step === 'select' && (
          <div className="grid grid-cols-3 gap-3">
            {CATEGORIES.map((cat) => (
              <button
                key={cat.id}
                onClick={() => {
                  setCategory(cat);
                  setBiller(BILLERS[cat.id]?.[0] ?? '');
                  setStep('form');
                }}
                className="flex flex-col items-center gap-2 p-4 rounded-2xl bg-[#131313] active:bg-[#2a2a2a] transition-colors"
              >
                <div className="w-12 h-12 rounded-xl flex items-center justify-center" style={{ backgroundColor: cat.bg }}>
                  <cat.Icon size={22} style={{ color: cat.color }} />
                </div>
                <span className="text-white text-xs font-medium text-center">{cat.label}</span>
              </button>
            ))}
          </div>
        )}

        {step === 'form' && category && (
          <div className="space-y-4">
            <div
              className="flex items-center gap-2 px-3 py-2 rounded-xl w-fit"
              style={{ backgroundColor: category.bg }}
            >
              <category.Icon size={14} style={{ color: category.color }} />
              <span className="text-sm font-medium" style={{ color: category.color }}>{category.label}</span>
            </div>

            <div className="flex flex-col gap-2">
              <label className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider">Select Biller</label>
              <select
                value={biller}
                onChange={(e) => setBiller(e.target.value)}
                className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white outline-none [color-scheme:dark]"
              >
                {billerList.map((b) => <option key={b} value={b}>{b}</option>)}
              </select>
            </div>

            <div className="flex flex-col gap-2">
              <label className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider">Account / Reference</label>
              <input
                type="text"
                placeholder="Enter account number"
                value={accountNumber}
                onChange={(e) => setAccountNumber(e.target.value)}
                className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white placeholder-[#8d90a2] outline-none"
              />
            </div>

            <div className="flex flex-col gap-2">
              <label className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider">Amount (USD)</label>
              <input
                type="number"
                inputMode="decimal"
                placeholder="0.00"
                value={amount}
                min="0.01"
                onChange={(e) => setAmount(e.target.value)}
                className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white placeholder-[#8d90a2] outline-none text-xl font-bold"
              />
            </div>

            {error && <p className="text-red-400 text-sm">{error}</p>}

            <button
              onClick={() => {
                if (!biller || !accountNumber.trim() || !amount || parseFloat(amount) <= 0) {
                  setError('Please fill in all fields.');
                  return;
                }
                setError('');
                setStep('confirm');
              }}
              className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full"
            >
              Continue
            </button>
          </div>
        )}

        {step === 'confirm' && category && (
          <div className="space-y-4">
            <div className="bg-[#131313] rounded-xl p-4 space-y-3">
              {[
                { label: 'Category', value: category.label },
                { label: 'Biller', value: biller },
                { label: 'Account', value: accountNumber },
                { label: 'Amount', value: `$${parseFloat(amount).toFixed(2)}` },
              ].map(({ label, value }) => (
                <div key={label} className="flex justify-between text-sm">
                  <span className="text-[#8d90a2]">{label}</span>
                  <span className="text-white font-medium">{value}</span>
                </div>
              ))}
            </div>
            {error && <p className="text-red-400 text-sm">{error}</p>}
            <button
              onClick={handlePay}
              disabled={paying}
              className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2 disabled:opacity-50"
            >
              {paying ? <Loader2 size={16} className="animate-spin" /> : <Receipt size={16} />}
              Pay ${parseFloat(amount || '0').toFixed(2)}
            </button>
          </div>
        )}

        {step === 'result' && (
          <div className="flex flex-col items-center gap-5 py-6 text-center">
            <div className={`w-20 h-20 rounded-full flex items-center justify-center ${resultOk ? 'bg-green-400/10' : 'bg-red-400/10'}`}>
              {resultOk ? (
                <CheckCircle size={44} className="text-green-400" />
              ) : (
                <XCircle size={44} className="text-red-400" />
              )}
            </div>
            <div>
              <p className="text-white font-bold text-xl">
                {resultOk ? 'Payment Successful!' : 'Payment Failed'}
              </p>
              {resultOk && (
                <p className="text-[#8d90a2] text-sm mt-1">
                  ${parseFloat(amount).toFixed(2)} paid to {biller}
                </p>
              )}
              {!resultOk && error && <p className="text-red-400 text-sm mt-1">{error}</p>}
            </div>
            <button onClick={onClose} className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full mt-2">
              Done
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Main ─────────────────────────────────────────────────────────────────────
export default function BillsScreen() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [recentPayments, setRecentPayments] = useState<BillPayment[]>([]);
  const [loading, setLoading] = useState(true);
  const [showFlow, setShowFlow] = useState(false);

  const load = useCallback(async () => {
    if (!user) return;
    setLoading(true);
    try {
      const records = await pb.collection('bill_payments').getFullList({
        filter: `userId="${user.id}"`,
        sort: '-created',
      });
      setRecentPayments(records as unknown as BillPayment[]);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [user]);

  useEffect(() => { load(); }, [load]);

  const handleSuccess = (bill: BillPayment) => {
    setRecentPayments((prev) => [bill, ...prev]);
  };

  return (
    <div className="flex flex-col min-h-screen bg-[#131313]">
      <PageHeader title="Bill Payments" onBack={() => navigate(-1)} />

      <div className="flex-1 overflow-y-auto px-4 pb-24 space-y-6">
        {/* Category grid */}
        <div>
          <p className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider mb-3">Pay a Bill</p>
          <div className="grid grid-cols-3 gap-3">
            {CATEGORIES.map((cat) => (
              <button
                key={cat.id}
                onClick={() => setShowFlow(true)}
                className="flex flex-col items-center gap-2 p-4 rounded-2xl bg-[#201f1f] active:bg-[#2a2a2a] transition-colors"
              >
                <div className="w-12 h-12 rounded-xl flex items-center justify-center" style={{ backgroundColor: cat.bg }}>
                  <cat.Icon size={22} style={{ color: cat.color }} />
                </div>
                <span className="text-white text-xs font-medium text-center">{cat.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Recent payments */}
        <div>
          <p className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider mb-3">Recent Payments</p>
          {loading ? (
            <div className="space-y-2">
              {Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="bg-[#201f1f] rounded-2xl h-16 animate-pulse" />
              ))}
            </div>
          ) : recentPayments.length === 0 ? (
            <div className="flex flex-col items-center py-12 gap-3">
              <Receipt size={32} className="text-[#8d90a2]" />
              <p className="text-[#8d90a2] text-sm">No recent bill payments</p>
            </div>
          ) : (
            <div className="space-y-2">
              {recentPayments.map((bill) => {
                const cat = getCatConfig(bill.category);
                return (
                  <div key={bill.id} className="bg-[#201f1f] rounded-2xl p-4 flex items-center gap-3">
                    <div
                      className="w-10 h-10 rounded-full flex items-center justify-center shrink-0"
                      style={{ backgroundColor: cat.bg }}
                    >
                      <cat.Icon size={18} style={{ color: cat.color }} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-white text-sm font-medium truncate">{bill.biller}</p>
                      <p className="text-[#8d90a2] text-xs mt-0.5">
                        {bill.created ? format(new Date(bill.created), 'MMM d, h:mm a') : ''}
                      </p>
                    </div>
                    <div className="flex flex-col items-end gap-1 shrink-0">
                      <span className="text-red-400 font-bold text-sm">-${bill.amount.toFixed(2)}</span>
                      <span
                        className={`text-[10px] font-semibold px-1.5 py-0.5 rounded-full ${
                          bill.status === 'success'
                            ? 'text-green-400 bg-green-400/10'
                            : bill.status === 'failed'
                            ? 'text-red-400 bg-red-400/10'
                            : 'text-yellow-400 bg-yellow-400/10'
                        }`}
                      >
                        {bill.status}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {showFlow && user && (
        <BillPaymentFlow
          userId={user.id}
          onClose={() => setShowFlow(false)}
          onSuccess={handleSuccess}
        />
      )}
    </div>
  );
}
