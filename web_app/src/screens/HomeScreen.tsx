import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Bell, Send, Download, Receipt, Eye, EyeOff,
  ChevronRight, ArrowUpRight, ArrowDownLeft, TrendingUp,
  ShieldAlert, Wallet, CreditCard, PiggyBank, Landmark,
  MoreHorizontal,
} from 'lucide-react';
import { pb } from '../services/pb';
import { useAuth } from '../context/AuthContext';
import type { TransactionModel, NotificationModel } from '../models/types';
import { format, parseISO, startOfMonth } from 'date-fns';

function getGreeting(): string {
  const h = new Date().getHours();
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
  }).format(amount);
}

function formatCompact(amount: number): string {
  if (amount >= 1_000_000) return `$${(amount / 1_000_000).toFixed(1)}M`;
  if (amount >= 1_000) return `$${(amount / 1_000).toFixed(1)}K`;
  return `$${amount.toFixed(0)}`;
}

function maskAccount(acct: string): string {
  if (!acct || acct.length < 4) return '••••  ••••  ••••';
  return `••••  ••••  ${acct.slice(-4)}`;
}

function txCategoryIcon(tx: TransactionModel) {
  const d = (tx.description ?? '').toLowerCase();
  if (tx.type === 'Credit') return { icon: ArrowDownLeft, color: 'text-green-400', bg: 'bg-green-400/10' };
  if (d.includes('bill') || d.includes('util')) return { icon: Receipt, color: 'text-orange-400', bg: 'bg-orange-400/10' };
  if (d.includes('saving') || d.includes('invest')) return { icon: PiggyBank, color: 'text-emerald-400', bg: 'bg-emerald-400/10' };
  if (d.includes('loan')) return { icon: Landmark, color: 'text-yellow-400', bg: 'bg-yellow-400/10' };
  return { icon: ArrowUpRight, color: 'text-red-400', bg: 'bg-red-400/10' };
}

export default function HomeScreen() {
  const { user } = useAuth();
  const navigate = useNavigate();

  const [transactions, setTransactions] = useState<TransactionModel[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [balanceVisible, setBalanceVisible] = useState(true);
  const [loadingTx, setLoadingTx] = useState(true);
  const [monthlyIncome, setMonthlyIncome] = useState(0);
  const [monthlySpent, setMonthlySpent] = useState(0);

  const firstName = user?.fullName?.split(' ')[0] ?? 'there';

  useEffect(() => {
    if (!user?.id) return;
    const fetchData = async () => {
      try {
        const txList = await pb.collection('transactions').getList<TransactionModel>(1, 5, {
          filter: `userId = "${user.id}"`,
          sort: '-created',
        });
        setTransactions(txList.items);

        // Monthly stats from recent transactions
        const allTx = await pb.collection('transactions').getList<TransactionModel>(1, 200, {
          filter: `userId = "${user.id}"`,
          sort: '-created',
        });
        const monthStart = startOfMonth(new Date());
        let inc = 0, spent = 0;
        for (const t of allTx.items) {
          try {
            const d = parseISO(t.created);
            if (d < monthStart) continue;
            if (t.status === 'Failed') continue;
            if (t.type === 'Credit') inc += Number(t.amount);
            else spent += Number(t.amount);
          } catch { /* skip */ }
        }
        setMonthlyIncome(inc);
        setMonthlySpent(spent);
      } catch { /* no txns yet */ } finally {
        setLoadingTx(false);
      }

      try {
        const notifList = await pb.collection('notifications').getList<NotificationModel>(1, 1, {
          filter: `userId = "${user.id}" && isRead = false`,
        });
        setUnreadCount(notifList.totalItems);
      } catch { /* no notifs yet */ }
    };
    fetchData();
  }, [user?.id]);

  const kycPending = user?.kycStatus !== 'approved';

  const quickActions = [
    { icon: Send, label: 'Send', color: 'text-primary', bg: 'bg-primary/15', path: '/send' },
    { icon: Download, label: 'Receive', color: 'text-green-400', bg: 'bg-green-400/15', path: '/transactions' },
    { icon: CreditCard, label: 'Cards', color: 'text-purple-400', bg: 'bg-purple-400/15', path: '/cards' },
    { icon: PiggyBank, label: 'Savings', color: 'text-yellow-400', bg: 'bg-yellow-400/15', path: '/savings' },
    { icon: Receipt, label: 'Bills', color: 'text-orange-400', bg: 'bg-orange-400/15', path: '/bills' },
    { icon: Landmark, label: 'Loans', color: 'text-rose-400', bg: 'bg-rose-400/15', path: '/loans' },
    { icon: Wallet, label: 'History', color: 'text-sky-400', bg: 'bg-sky-400/15', path: '/transactions' },
    { icon: MoreHorizontal, label: 'More', color: 'text-outline', bg: 'bg-surface-bright/40', path: '/profile' },
  ];

  return (
    <div className="flex flex-col min-h-screen bg-surface pb-28">

      {/* ── Top Bar ─────────────────────────────────────────────────────── */}
      <div className="flex items-center justify-between px-5 pt-12 pb-4">
        <div>
          <p className="text-outline text-xs font-medium tracking-wide">{getGreeting()},</p>
          <h1 className="text-on-surface text-xl font-bold mt-0.5 tracking-tight">
            {firstName} <span className="wave" style={{ display: 'inline-block' }}>👋</span>
          </h1>
        </div>
        <button
          onClick={() => navigate('/notifications')}
          className="relative w-10 h-10 rounded-2xl bg-surface-container border border-surface-bright/60 flex items-center justify-center hover:bg-surface-bright transition-colors active:scale-95"
        >
          <Bell size={19} className="text-on-surface" strokeWidth={1.8} />
          {unreadCount > 0 && (
            <span className="absolute -top-1 -right-1 min-w-[18px] h-[18px] bg-primary text-white text-[9px] font-bold rounded-full flex items-center justify-center px-1 leading-none">
              {unreadCount > 99 ? '99+' : unreadCount}
            </span>
          )}
        </button>
      </div>

      <div className="px-4 flex flex-col gap-4">

        {/* ── KYC Banner ──────────────────────────────────────────────────── */}
        {kycPending && (
          <button
            onClick={() => navigate('/kyc')}
            className="flex items-center gap-3 bg-yellow-400/8 border border-yellow-400/20 rounded-2xl px-4 py-3 w-full text-left hover:bg-yellow-400/12 transition-colors active:scale-[0.99]"
          >
            <div className="w-9 h-9 rounded-full bg-yellow-400/15 flex items-center justify-center shrink-0">
              <ShieldAlert size={17} className="text-yellow-400" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-on-surface text-sm font-semibold">Complete Identity Verification</p>
              <p className="text-outline text-xs mt-0.5">Unlock all features — takes less than 2 minutes</p>
            </div>
            <ChevronRight size={15} className="text-outline shrink-0" />
          </button>
        )}

        {/* ── Balance Card ─────────────────────────────────────────────────── */}
        <div
          className="relative rounded-3xl overflow-hidden"
          style={{
            background: 'linear-gradient(135deg, #1c2d6b 0%, #0d1f5c 40%, #0a1440 100%)',
            boxShadow: '0 8px 40px rgba(79,120,255,0.30), 0 2px 8px rgba(0,0,0,0.5)',
          }}
        >
          {/* Decorative blobs */}
          <div className="absolute -top-10 -right-10 w-40 h-40 rounded-full pointer-events-none"
            style={{ background: 'radial-gradient(circle, rgba(79,120,255,0.18) 0%, transparent 70%)' }} />
          <div className="absolute -bottom-12 -left-8 w-36 h-36 rounded-full pointer-events-none"
            style={{ background: 'radial-gradient(circle, rgba(183,196,255,0.08) 0%, transparent 70%)' }} />
          <div className="absolute top-8 right-24 w-16 h-16 rounded-full pointer-events-none"
            style={{ background: 'radial-gradient(circle, rgba(255,255,255,0.05) 0%, transparent 70%)' }} />

          <div className="relative z-10 p-5">
            {/* Top row */}
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <span
                  className="text-[10px] font-bold tracking-[2px] uppercase px-2.5 py-1 rounded-full"
                  style={{ background: 'rgba(255,255,255,0.12)', color: 'rgba(255,255,255,0.75)' }}
                >
                  {user?.accountType ?? 'Checking'}
                </span>
              </div>
              <div className="flex items-center gap-2.5">
                {/* Status dot */}
                <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full"
                  style={{ background: 'rgba(255,255,255,0.10)' }}>
                  <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse" />
                  <span className="text-[10px] font-semibold text-green-400 capitalize">
                    {user?.accountStatus ?? 'Active'}
                  </span>
                </div>
                <button
                  onClick={() => setBalanceVisible(!balanceVisible)}
                  className="w-8 h-8 rounded-full flex items-center justify-center transition-colors active:scale-90"
                  style={{ background: 'rgba(255,255,255,0.10)' }}
                >
                  {balanceVisible
                    ? <EyeOff size={14} style={{ color: 'rgba(255,255,255,0.65)' }} />
                    : <Eye size={14} style={{ color: 'rgba(255,255,255,0.65)' }} />
                  }
                </button>
              </div>
            </div>

            {/* Balance */}
            <div className="mb-1">
              <p className="text-[10px] font-semibold tracking-[2.5px] uppercase mb-2"
                style={{ color: 'rgba(255,255,255,0.5)' }}>
                Available Balance
              </p>
              <div className="flex items-start gap-1.5">
                <span className="text-2xl font-bold mt-1.5" style={{ color: 'rgba(255,255,255,0.65)' }}>$</span>
                <span className="text-5xl font-black tracking-tight leading-none text-white"
                  style={{ letterSpacing: '-2px' }}>
                  {balanceVisible
                    ? Number(user?.balance ?? 0).toLocaleString('en-US', { minimumFractionDigits: 2 })
                    : '••••••'
                  }
                </span>
              </div>
            </div>

            {/* Account number */}
            <p className="text-xs font-mono mt-2 mb-4" style={{ color: 'rgba(255,255,255,0.4)', letterSpacing: '2px' }}>
              {maskAccount(user?.accountNumber ?? '')}
            </p>

            {/* Income / Expense chips */}
            <div className="flex items-center gap-2 mt-1">
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full"
                style={{ background: 'rgba(74,222,128,0.12)', border: '1px solid rgba(74,222,128,0.25)' }}>
                <ArrowDownLeft size={12} className="text-green-400" />
                <span className="text-[11px] font-bold text-green-400">
                  {balanceVisible ? formatCompact(monthlyIncome) : '••••'}
                </span>
                <span className="text-[10px]" style={{ color: 'rgba(255,255,255,0.35)' }}>in</span>
              </div>
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full"
                style={{ background: 'rgba(248,113,113,0.12)', border: '1px solid rgba(248,113,113,0.25)' }}>
                <ArrowUpRight size={12} className="text-red-400" />
                <span className="text-[11px] font-bold text-red-400">
                  {balanceVisible ? formatCompact(monthlySpent) : '••••'}
                </span>
                <span className="text-[10px]" style={{ color: 'rgba(255,255,255,0.35)' }}>out</span>
              </div>
              <span className="text-[10px] ml-auto" style={{ color: 'rgba(255,255,255,0.3)' }}>This month</span>
            </div>
          </div>
        </div>

        {/* ── Quick Actions ─────────────────────────────────────────────────── */}
        <div className="bg-surface-container rounded-3xl p-4">
          <div className="grid grid-cols-4 gap-3">
            {quickActions.map(({ icon: Icon, label, color, bg, path }) => (
              <button
                key={label}
                onClick={() => navigate(path)}
                className="flex flex-col items-center gap-2 active:scale-95 transition-transform"
              >
                <div
                  className={`w-[54px] h-[54px] rounded-2xl ${bg} flex items-center justify-center`}
                  style={{ boxShadow: '0 2px 8px rgba(0,0,0,0.2)' }}
                >
                  <Icon size={22} className={color} strokeWidth={1.9} />
                </div>
                <span className="text-on-surface text-[10px] font-semibold leading-tight text-center">
                  {label}
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* ── Recent Transactions ───────────────────────────────────────────── */}
        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between px-1">
            <h2 className="text-on-surface text-base font-bold tracking-tight">Recent Activity</h2>
            <button
              onClick={() => navigate('/transactions')}
              className="flex items-center gap-1 text-primary text-xs font-semibold hover:opacity-80 transition-opacity"
            >
              See all
              <ChevronRight size={13} />
            </button>
          </div>

          <div className="bg-surface-container rounded-3xl overflow-hidden">
            {loadingTx ? (
              <div className="p-4 space-y-3">
                {[1, 2, 3].map((i) => (
                  <div key={i} className="flex items-center gap-3 animate-pulse">
                    <div className="w-11 h-11 rounded-2xl bg-surface-bright shrink-0" />
                    <div className="flex-1 space-y-2">
                      <div className="h-3 bg-surface-bright rounded-full w-2/3" />
                      <div className="h-2.5 bg-surface-bright rounded-full w-1/3" />
                    </div>
                    <div className="h-3.5 bg-surface-bright rounded-full w-16" />
                  </div>
                ))}
              </div>
            ) : transactions.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-10 gap-3">
                <div className="w-14 h-14 rounded-2xl bg-surface-bright flex items-center justify-center">
                  <Receipt size={24} className="text-outline" strokeWidth={1.5} />
                </div>
                <div className="text-center">
                  <p className="text-on-surface text-sm font-semibold">No transactions yet</p>
                  <p className="text-outline text-xs mt-0.5">Your activity will appear here</p>
                </div>
              </div>
            ) : (
              <div>
                {transactions.map((tx, i) => {
                  const cat = txCategoryIcon(tx);
                  const Icon = cat.icon;
                  const isLast = i === transactions.length - 1;
                  return (
                    <div
                      key={tx.id}
                      className={`flex items-center gap-3.5 px-4 py-3.5 hover:bg-surface-bright/20 transition-colors cursor-pointer ${
                        !isLast ? 'border-b border-surface-bright/40' : ''
                      }`}
                    >
                      <div className={`w-11 h-11 rounded-2xl ${cat.bg} flex items-center justify-center shrink-0`}>
                        <Icon size={18} className={cat.color} strokeWidth={2} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-on-surface text-sm font-semibold truncate">
                          {tx.description || (tx.type === 'Credit' ? 'Money received' : 'Payment sent')}
                        </p>
                        <p className="text-outline text-[11px] mt-0.5">
                          {format(parseISO(tx.created), 'MMM d · h:mm a')}
                          {tx.status && tx.status !== 'Success' && (
                            <span className={`ml-1.5 font-semibold ${
                              tx.status === 'Failed' ? 'text-red-400' : 'text-yellow-400'
                            }`}>
                              · {tx.status}
                            </span>
                          )}
                        </p>
                      </div>
                      <div className="text-right shrink-0">
                        <span className={`text-sm font-bold ${
                          tx.type === 'Credit' ? 'text-green-400' : 'text-on-surface'
                        }`}>
                          {tx.type === 'Credit' ? '+' : '−'}{formatCurrency(Number(tx.amount))}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
