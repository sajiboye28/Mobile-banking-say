"use client";

import { useEffect, useState, useMemo } from "react";
import Link from "next/link";

const getToken = () => typeof window !== 'undefined' ? localStorage.getItem('pb_admin_token') ?? '' : '';
const apiCall = async (url: string, options: RequestInit = {}) => {
  const res = await fetch(url, {
    ...options,
    headers: { 'Authorization': `Bearer ${getToken()}`, 'Content-Type': 'application/json', ...(options.headers ?? {}) }
  });
  if (!res.ok) throw new Error((await res.json().catch(() => ({}))).error || res.statusText);
  return res.json();
};
import {
  Users, Clock, ShieldOff, DollarSign,
  ArrowUpRight, ArrowDownRight, Inbox,
  TrendingUp, TrendingDown, Activity, BarChart2,
  Megaphone, X, Bell, ShieldCheck, UserCheck, Zap,
  CheckCircle2, Wifi,
} from "lucide-react";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, Legend,
} from "recharts";

interface UserData {
  uid: string;
  fullName: string;
  email: string;
  balance: number;
  accountStatus: string;
  kycStatus: string;
  createdAt: any;
  photoURL?: string;
}

interface TransactionData {
  transactionId: string;
  userId: string;
  amount: number;
  type: string;
  description: string;
  status: string;
  timestamp: any;
}

export default function DashboardOverview() {
  const [users, setUsers] = useState<UserData[]>([]);
  const [pendingCount, setPendingCount] = useState(0);
  const [recentTransactions, setRecentTransactions] = useState<TransactionData[]>([]);
  const [allTransactions, setAllTransactions] = useState<TransactionData[]>([]);
  const [totalBalance, setTotalBalance] = useState(0);

  // Broadcast state
  const [showBroadcast, setShowBroadcast] = useState(false);
  const [broadcastTitle, setBroadcastTitle] = useState("");
  const [broadcastBody, setBroadcastBody] = useState("");
  const [broadcasting, setBroadcasting] = useState(false);

  useEffect(() => {
    const loadData = async () => {
      try {
        const [usersData, txData] = await Promise.all([
          apiCall('/api/users?page=1&limit=200&status=all').catch(() => ({ users: [] })),
          apiCall('/api/transaction?limit=200').catch(() => ({ items: [] })),
        ]);
        const usersArr: UserData[] = usersData.users ?? usersData.items ?? [];
        setUsers(usersArr);
        setTotalBalance(usersArr.reduce((sum: number, u: UserData) => sum + (u.balance || 0), 0));
        setPendingCount(usersArr.filter((u: UserData) => u.accountStatus === "pending").length);

        const txArr: TransactionData[] = txData.items ?? txData.transactions ?? [];
        txArr.sort((a, b) => {
          const at = a.timestamp ? new Date(a.timestamp).getTime() : 0;
          const bt = b.timestamp ? new Date(b.timestamp).getTime() : 0;
          return bt - at;
        });
        setAllTransactions(txArr);
        setRecentTransactions(txArr.slice(0, 10));
      } catch {
        // Silently ignore — stats will show zeros
      }
    };
    loadData();
  }, []);

  // ── Analytics (memoized) ───────────────────────────────────────────────────
  const { activeUsers, suspendedUsers, kycPendingCount, recentSignups } = useMemo(() => ({
    activeUsers: users.filter((u) => u.accountStatus === "active").length,
    suspendedUsers: users.filter((u) => u.accountStatus === "suspended").length,
    kycPendingCount: users.filter((u) => u.kycStatus === "pending").length,
    recentSignups: [...users]
      .sort((a, b) => {
        const aTime = a.createdAt ? new Date(a.createdAt).getTime() : 0;
        const bTime = b.createdAt ? new Date(b.createdAt).getTime() : 0;
        return bTime - aTime;
      })
      .slice(0, 5),
  }), [users]);

  const { totalCreditVol, totalDebitVol, totalVol, creditPct, debitPct, todayTx, creditTxCount, debitTxCount, successTxCount } = useMemo(() => {
    const successTx = allTransactions.filter((t) => t.status === "Success");
    const creditTx = successTx.filter((t) => t.type === "Credit");
    const debitTx = successTx.filter((t) => t.type === "Debit");
    const totalCreditVol = creditTx.reduce((s, t) => s + (t.amount || 0), 0);
    const totalDebitVol = debitTx.reduce((s, t) => s + (t.amount || 0), 0);
    const totalVol = totalCreditVol + totalDebitVol;
    const creditPct = totalVol > 0 ? (totalCreditVol / totalVol) * 100 : 50;
    const debitPct = totalVol > 0 ? (totalDebitVol / totalVol) * 100 : 50;
    const todayStart = new Date(); todayStart.setHours(0, 0, 0, 0);
    const todayTx = allTransactions.filter((t) => {
      if (!t.timestamp) return false;
      const ts = new Date(t.timestamp);
      return ts >= todayStart;
    });
    return { totalCreditVol, totalDebitVol, totalVol, creditPct, debitPct, todayTx, creditTxCount: creditTx.length, debitTxCount: debitTx.length, successTxCount: successTx.length };
  }, [allTransactions]);

  // ── 7-day chart data (memoized) ────────────────────────────────────────────
  const chartData = useMemo(() => {
    const days: { date: string; credits: number; debits: number }[] = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setHours(0, 0, 0, 0);
      d.setDate(d.getDate() - i);
      const next = new Date(d); next.setDate(next.getDate() + 1);
      const label = d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
      const dayTx = allTransactions.filter((t) => {
        if (!t.timestamp) return false;
        const ts = new Date(t.timestamp);
        return ts >= d && ts < next && t.status === "Success";
      });
      days.push({
        date: label,
        credits: Math.round(dayTx.filter((t) => t.type === "Credit").reduce((s, t) => s + t.amount, 0)),
        debits: Math.round(dayTx.filter((t) => t.type === "Debit").reduce((s, t) => s + t.amount, 0)),
      });
    }
    return days;
  }, [allTransactions]);

  // ── Broadcast ──────────────────────────────────────────────────────────────
  const sendBroadcast = async () => {
    if (!broadcastTitle.trim() || !broadcastBody.trim() || users.length === 0) return;
    setBroadcasting(true);
    try {
      await Promise.all(
        users.map((u) =>
          apiCall('/api/notify', {
            method: 'POST',
            body: JSON.stringify({ userId: u.uid, title: broadcastTitle.trim(), message: broadcastBody.trim(), type: 'announcement' }),
          })
        )
      );
      setShowBroadcast(false);
      setBroadcastTitle("");
      setBroadcastBody("");
    } catch (e) {
      console.error("Broadcast failed:", e);
    } finally {
      setBroadcasting(false);
    }
  };

  const fmt = (n: number) =>
    n >= 1_000_000 ? `$${(n / 1_000_000).toFixed(1)}M`
    : n >= 1_000 ? `$${(n / 1_000).toFixed(1)}K`
    : `$${n.toFixed(2)}`;

  const statCards = [
    { label: "Total Users", value: users.length, sub: `${activeUsers} active`, icon: Users, gradient: "from-blue-600 to-indigo-600", shadowColor: "shadow-blue-500/20" },
    { label: "Pending Approvals", value: pendingCount, sub: (<Link href="/dashboard/approval-queue" className="hover:underline">View queue</Link>), icon: Clock, gradient: "from-amber-500 to-orange-500", shadowColor: "shadow-amber-500/20" },
    { label: "Suspended Accounts", value: suspendedUsers, sub: "Requires attention", icon: ShieldOff, gradient: "from-rose-500 to-pink-600", shadowColor: "shadow-rose-500/20" },
    { label: "System Balance", value: `$${totalBalance.toLocaleString("en-US", { minimumFractionDigits: 2 })}`, sub: "Across all accounts", icon: DollarSign, gradient: "from-emerald-500 to-teal-600", shadowColor: "shadow-emerald-500/20" },
  ];

  const extraStatCards = [
    { label: "KYC Pending", value: kycPendingCount, sub: "Awaiting review", icon: ShieldCheck, gradient: "from-violet-500 to-purple-600", shadowColor: "shadow-violet-500/20" },
    { label: "Today's Transactions", value: todayTx.length, sub: `${todayTx.filter((t) => t.status === "Success").length} successful`, icon: Zap, gradient: "from-cyan-500 to-sky-600", shadowColor: "shadow-cyan-500/20" },
    { label: "Avg. Transaction", value: successTxCount > 0 ? fmt(totalVol / successTxCount) : "$0", sub: "Per successful tx", icon: TrendingUp, gradient: "from-teal-500 to-emerald-600", shadowColor: "shadow-teal-500/20" },
    { label: "Verified Users", value: users.filter((u) => u.kycStatus === "approved").length, sub: "KYC approved", icon: UserCheck, gradient: "from-green-500 to-teal-500", shadowColor: "shadow-green-500/20" },
  ];

  return (
    <div className="animate-fade-in">
      {/* Header with broadcast button */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Overview</h1>
          <p className="text-sm text-gray-500 mt-0.5">Real-time platform metrics</p>
        </div>
        <button
          onClick={() => setShowBroadcast(true)}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 text-white text-sm font-semibold hover:opacity-90 transition-opacity shadow-sm shadow-indigo-500/20"
        >
          <Megaphone className="w-4 h-4" />
          Broadcast
        </button>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
        {statCards.map((card, i) => {
          const Icon = card.icon;
          return (
            <div key={i} className={`relative overflow-hidden rounded-2xl bg-gradient-to-br ${card.gradient} p-6 text-white shadow-lg ${card.shadowColor} transition-all duration-300 hover:scale-[1.02] hover:shadow-xl`}>
              <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -translate-y-8 translate-x-8" />
              <div className="absolute bottom-0 left-0 w-20 h-20 bg-white/5 rounded-full translate-y-6 -translate-x-6" />
              <div className="relative">
                <div className="flex items-center justify-between mb-3">
                  <p className="text-sm font-medium text-white/80">{card.label}</p>
                  <div className="w-10 h-10 rounded-xl bg-white/20 backdrop-blur-sm flex items-center justify-center">
                    <Icon className="w-5 h-5 text-white" />
                  </div>
                </div>
                <p className="text-3xl font-bold mb-1">{card.value}</p>
                <p className="text-sm text-white/70">{card.sub}</p>
              </div>
            </div>
          );
        })}
      </div>

      {/* Extra stat cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {extraStatCards.map((card, i) => {
          const Icon = card.icon;
          return (
            <div key={i} className={`relative overflow-hidden rounded-2xl bg-gradient-to-br ${card.gradient} p-5 text-white shadow-lg ${card.shadowColor} transition-all duration-300 hover:scale-[1.02] hover:shadow-xl`}>
              <div className="absolute top-0 right-0 w-24 h-24 bg-white/10 rounded-full -translate-y-6 translate-x-6" />
              <div className="relative">
                <div className="flex items-center justify-between mb-2">
                  <p className="text-xs font-semibold text-white/80 uppercase tracking-wide">{card.label}</p>
                  <div className="w-8 h-8 rounded-lg bg-white/20 backdrop-blur-sm flex items-center justify-center">
                    <Icon className="w-4 h-4 text-white" />
                  </div>
                </div>
                <p className="text-2xl font-bold mb-0.5">{card.value}</p>
                <p className="text-xs text-white/70">{card.sub}</p>
              </div>
            </div>
          );
        })}
      </div>

      {/* 7-Day Transaction Chart */}
      <div className="card mb-8">
        <div className="flex items-center justify-between mb-5">
          <div>
            <h2 className="section-title">7-Day Transaction Volume</h2>
            <p className="text-xs text-gray-400 mt-0.5">Daily credit & debit totals (successful only)</p>
          </div>
          <BarChart2 className="w-5 h-5 text-indigo-400" />
        </div>
        <ResponsiveContainer width="100%" height={220}>
          <AreaChart data={chartData} margin={{ top: 5, right: 10, left: 0, bottom: 0 }}>
            <defs>
              <linearGradient id="colorCredits" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#10b981" stopOpacity={0.25} />
                <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
              </linearGradient>
              <linearGradient id="colorDebits" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#6366f1" stopOpacity={0.25} />
                <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis dataKey="date" tick={{ fontSize: 11, fill: "#9ca3af" }} tickLine={false} axisLine={false} />
            <YAxis tick={{ fontSize: 11, fill: "#9ca3af" }} tickLine={false} axisLine={false} tickFormatter={(v) => v >= 1000 ? `$${(v/1000).toFixed(0)}k` : `$${v}`} />
            <Tooltip
              contentStyle={{ borderRadius: 12, border: "none", boxShadow: "0 4px 20px rgba(0,0,0,0.1)", fontSize: 12 }}
              formatter={(value: unknown, name: unknown) => [`$${Number(value).toLocaleString()}`, name === "credits" ? "Credits" : "Debits"]}
            />
            <Legend formatter={(v) => v === "credits" ? "Credits" : "Debits"} iconType="circle" iconSize={8} wrapperStyle={{ fontSize: 12, paddingTop: 8 }} />
            <Area type="monotone" dataKey="credits" stroke="#10b981" strokeWidth={2} fill="url(#colorCredits)" dot={{ r: 3, fill: "#10b981" }} activeDot={{ r: 5 }} />
            <Area type="monotone" dataKey="debits" stroke="#6366f1" strokeWidth={2} fill="url(#colorDebits)" dot={{ r: 3, fill: "#6366f1" }} activeDot={{ r: 5 }} />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Analytics Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        {/* Transaction Volume Breakdown */}
        <div className="lg:col-span-2 card">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h2 className="section-title">Transaction Volume</h2>
              <p className="text-xs text-gray-400 mt-0.5">All-time credit vs debit breakdown</p>
            </div>
            <span className="text-xs font-semibold text-gray-500">{allTransactions.length} total</span>
          </div>
          <div className="grid grid-cols-2 gap-4 mb-6">
            <div className="rounded-xl bg-emerald-50 border border-emerald-100 p-4">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-7 h-7 rounded-lg bg-emerald-100 flex items-center justify-center">
                  <ArrowDownRight className="w-4 h-4 text-emerald-600" />
                </div>
                <span className="text-xs font-semibold text-emerald-600 uppercase tracking-wide">Credits In</span>
              </div>
              <p className="text-2xl font-bold text-emerald-700">{fmt(totalCreditVol)}</p>
              <p className="text-xs text-emerald-500 mt-0.5">{creditTxCount} transactions</p>
            </div>
            <div className="rounded-xl bg-rose-50 border border-rose-100 p-4">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-7 h-7 rounded-lg bg-rose-100 flex items-center justify-center">
                  <ArrowUpRight className="w-4 h-4 text-rose-600" />
                </div>
                <span className="text-xs font-semibold text-rose-600 uppercase tracking-wide">Debits Out</span>
              </div>
              <p className="text-2xl font-bold text-rose-700">{fmt(totalDebitVol)}</p>
              <p className="text-xs text-rose-500 mt-0.5">{debitTxCount} transactions</p>
            </div>
          </div>
          <div>
            <div className="flex justify-between text-xs text-gray-400 mb-1.5">
              <span>Credits {creditPct.toFixed(0)}%</span>
              <span>Debits {debitPct.toFixed(0)}%</span>
            </div>
            <div className="flex h-3 rounded-full overflow-hidden">
              <div className="bg-gradient-to-r from-emerald-400 to-emerald-500 transition-all duration-700" style={{ width: `${creditPct}%` }} />
              <div className="bg-gradient-to-r from-rose-400 to-rose-500 transition-all duration-700" style={{ width: `${debitPct}%` }} />
            </div>
            <div className="flex gap-4 mt-3">
              <div className="flex items-center gap-1.5"><div className="w-2.5 h-2.5 rounded-full bg-emerald-400" /><span className="text-xs text-gray-500">Credits</span></div>
              <div className="flex items-center gap-1.5"><div className="w-2.5 h-2.5 rounded-full bg-rose-400" /><span className="text-xs text-gray-500">Debits</span></div>
            </div>
          </div>
        </div>

        {/* Activity Summary */}
        <div className="card flex flex-col gap-4">
          <div>
            <h2 className="section-title">Activity Summary</h2>
            <p className="text-xs text-gray-400 mt-0.5">Platform health at a glance</p>
          </div>
          <div className="flex flex-col gap-3">
            <div className="flex items-center justify-between p-3 rounded-xl bg-indigo-50 border border-indigo-100">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-indigo-100 flex items-center justify-center"><Activity className="w-4 h-4 text-indigo-600" /></div>
                <div><p className="text-xs font-semibold text-indigo-700">Today</p><p className="text-xs text-indigo-500">Transactions</p></div>
              </div>
              <span className="text-xl font-bold text-indigo-700">{todayTx.length}</span>
            </div>
            <div className="flex items-center justify-between p-3 rounded-xl bg-gray-50 border border-gray-100">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center"><BarChart2 className="w-4 h-4 text-gray-500" /></div>
                <div><p className="text-xs font-semibold text-gray-600">All Time</p><p className="text-xs text-gray-400">Transactions</p></div>
              </div>
              <span className="text-xl font-bold text-gray-700">{allTransactions.length}</span>
            </div>
            <div className="flex items-center justify-between p-3 rounded-xl bg-amber-50 border border-amber-100">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-amber-100 flex items-center justify-center"><TrendingUp className="w-4 h-4 text-amber-600" /></div>
                <div><p className="text-xs font-semibold text-amber-700">Avg. Value</p><p className="text-xs text-amber-500">Per transaction</p></div>
              </div>
              <span className="text-lg font-bold text-amber-700">{successTxCount > 0 ? fmt(totalVol / successTxCount) : "$0"}</span>
            </div>
            <div className="flex items-center justify-between p-3 rounded-xl bg-rose-50 border border-rose-100">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-rose-100 flex items-center justify-center"><TrendingDown className="w-4 h-4 text-rose-600" /></div>
                <div><p className="text-xs font-semibold text-rose-700">Failed</p><p className="text-xs text-rose-500">Transactions</p></div>
              </div>
              <span className="text-xl font-bold text-rose-700">{allTransactions.filter((t) => t.status === "Failed").length}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Transactions */}
      <div className="card">
        <div className="flex items-center justify-between mb-5">
          <h2 className="section-title">Recent Transactions</h2>
          <Link href="/dashboard/transactions" className="text-sm text-indigo-600 hover:text-indigo-700 font-medium transition-colors">View all</Link>
        </div>
        {recentTransactions.length === 0 ? (
          <div className="text-center py-12">
            <Inbox className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p className="text-gray-500 text-sm font-medium">No transactions yet</p>
            <p className="text-gray-400 text-xs mt-1">Transactions will appear here as they happen</p>
          </div>
        ) : (
          <div className="overflow-x-auto -mx-6">
            <table className="w-full text-sm">
              <thead>
                <tr className="table-header">
                  <th>ID</th><th>User ID</th><th>Type</th>
                  <th className="text-right">Amount</th><th>Description</th><th>Status</th>
                </tr>
              </thead>
              <tbody>
                {recentTransactions.map((tx) => (
                  <tr key={tx.transactionId} className="table-row">
                    <td className="font-mono text-xs text-gray-500">{tx.transactionId?.substring(0, 8)}...</td>
                    <td className="font-mono text-xs text-gray-500">{tx.userId?.substring(0, 8)}...</td>
                    <td>
                      <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold ${tx.type === "Credit" ? "bg-emerald-50 text-emerald-700" : "bg-rose-50 text-rose-700"}`}>
                        {tx.type === "Credit" ? <ArrowDownRight className="w-3 h-3" /> : <ArrowUpRight className="w-3 h-3" />}
                        {tx.type}
                      </span>
                    </td>
                    <td className="text-right font-semibold text-gray-900">${tx.amount?.toLocaleString("en-US", { minimumFractionDigits: 2 })}</td>
                    <td className="text-gray-600 max-w-[200px] truncate">{tx.description}</td>
                    <td>
                      <span className={`${tx.status === "Success" ? "status-badge-active" : tx.status === "Pending" ? "status-badge-pending" : "status-badge-suspended"}`}>
                        <span className={`w-1.5 h-1.5 rounded-full ${tx.status === "Success" ? "bg-emerald-500" : tx.status === "Pending" ? "bg-amber-500" : "bg-rose-500"}`} />
                        {tx.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Recent Signups + System Health */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-8">
        {/* Recent Signups */}
        <div className="lg:col-span-2 card">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h2 className="section-title">Recent Signups</h2>
              <p className="text-xs text-gray-400 mt-0.5">Latest 5 user registrations</p>
            </div>
            <Link href="/dashboard/users" className="text-sm text-indigo-600 hover:text-indigo-700 font-medium transition-colors">View all</Link>
          </div>
          {recentSignups.length === 0 ? (
            <div className="text-center py-10">
              <Users className="w-10 h-10 text-gray-300 mx-auto mb-3" />
              <p className="text-gray-400 text-sm">No users yet</p>
            </div>
          ) : (
            <div className="flex flex-col gap-3">
              {recentSignups.map((u) => {
                const initials = u.fullName?.split(" ").map((n: string) => n[0]).join("").substring(0, 2).toUpperCase() || "?";
                const statusClass = u.accountStatus === "active" ? "status-badge-active" : u.accountStatus === "suspended" ? "status-badge-suspended" : "status-badge-pending";
                const dotClass = u.accountStatus === "active" ? "bg-emerald-500" : u.accountStatus === "suspended" ? "bg-rose-500" : "bg-amber-500";
                const joinDate = u.createdAt ? new Date(u.createdAt) : null;
                return (
                  <div key={u.uid} className="flex items-center gap-3 p-3 rounded-xl hover:bg-gray-50/60 transition-colors">
                    <div className="w-9 h-9 rounded-full bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center ring-2 ring-gray-100 flex-shrink-0">
                      <span className="text-xs font-bold text-white">{initials}</span>
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold text-gray-900 truncate">{u.fullName || "—"}</p>
                      <p className="text-xs text-gray-400 truncate">{u.email}</p>
                    </div>
                    <div className="flex items-center gap-3 flex-shrink-0">
                      <span className={`${statusClass} status-badge`}>
                        <span className={`w-1.5 h-1.5 rounded-full ${dotClass}`} />
                        {u.accountStatus}
                      </span>
                      <span className="text-xs text-gray-400 hidden sm:block">
                        {joinDate ? joinDate.toLocaleDateString("en-US", { month: "short", day: "numeric" }) : "—"}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* System Health */}
        <div className="card flex flex-col gap-4">
          <div>
            <h2 className="section-title">System Health</h2>
            <p className="text-xs text-gray-400 mt-0.5">Platform service status</p>
          </div>
          <div className="flex flex-col gap-3">
            <div className="flex items-center justify-between p-3.5 rounded-xl bg-emerald-50 border border-emerald-100">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-emerald-100 flex items-center justify-center">
                  <Wifi className="w-4 h-4 text-emerald-600" />
                </div>
                <div>
                  <p className="text-xs font-semibold text-emerald-700">API Status</p>
                  <p className="text-xs text-emerald-500">Next.js API Routes</p>
                </div>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                <span className="text-xs font-bold text-emerald-700">Online</span>
              </div>
            </div>

            <div className="flex items-center justify-between p-3.5 rounded-xl bg-blue-50 border border-blue-100">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-blue-100 flex items-center justify-center">
                  <CheckCircle2 className="w-4 h-4 text-blue-600" />
                </div>
                <div>
                  <p className="text-xs font-semibold text-blue-700">PocketBase</p>
                  <p className="text-xs text-blue-500">Database + Auth</p>
                </div>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-blue-500 animate-pulse" />
                <span className="text-xs font-bold text-blue-700">Connected</span>
              </div>
            </div>

            <div className="flex items-center justify-between p-3.5 rounded-xl bg-gray-50 border border-gray-100">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center">
                  <Activity className="w-4 h-4 text-gray-500" />
                </div>
                <div>
                  <p className="text-xs font-semibold text-gray-600">Last Transaction</p>
                  <p className="text-xs text-gray-400">
                    {recentTransactions[0]?.timestamp
                      ? (() => {
                          const diff = Date.now() - new Date(recentTransactions[0].timestamp).getTime();
                          const mins = Math.floor(diff / 60000);
                          const hrs = Math.floor(mins / 60);
                          const days = Math.floor(hrs / 24);
                          if (days > 0) return `${days}d ago`;
                          if (hrs > 0) return `${hrs}h ago`;
                          if (mins > 0) return `${mins}m ago`;
                          return "Just now";
                        })()
                      : "No transactions"}
                  </p>
                </div>
              </div>
              <span className={`text-xs font-bold ${recentTransactions.length > 0 ? "text-gray-600" : "text-gray-400"}`}>
                {recentTransactions.length > 0 ? "Active" : "—"}
              </span>
            </div>

            <div className="flex items-center justify-between p-3.5 rounded-xl bg-indigo-50 border border-indigo-100">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-indigo-100 flex items-center justify-center">
                  <Users className="w-4 h-4 text-indigo-600" />
                </div>
                <div>
                  <p className="text-xs font-semibold text-indigo-700">Total Users</p>
                  <p className="text-xs text-indigo-500">{activeUsers} active</p>
                </div>
              </div>
              <span className="text-xl font-bold text-indigo-700">{users.length}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Broadcast Modal */}
      {showBroadcast && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md mx-4 p-6">
            <div className="flex items-center justify-between mb-5">
              <div>
                <h3 className="text-lg font-bold text-gray-900">Broadcast Notification</h3>
                <p className="text-sm text-gray-500 mt-0.5">Send to all <span className="font-semibold text-indigo-600">{users.length} users</span></p>
              </div>
              <button onClick={() => setShowBroadcast(false)} className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center hover:bg-gray-200 transition-colors">
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">Title</label>
                <input type="text" value={broadcastTitle} onChange={(e) => setBroadcastTitle(e.target.value)} placeholder="e.g. System Maintenance Notice" className="input-field" />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">Message</label>
                <textarea value={broadcastBody} onChange={(e) => setBroadcastBody(e.target.value)} placeholder="Enter your message to all users..." rows={4} className="input-field resize-none" />
              </div>
              <div className="flex gap-3 pt-1">
                <button onClick={() => setShowBroadcast(false)} className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-50 transition-colors">Cancel</button>
                <button
                  onClick={sendBroadcast}
                  disabled={broadcasting || !broadcastTitle.trim() || !broadcastBody.trim()}
                  className="flex-1 py-2.5 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 text-white text-sm font-semibold hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                >
                  <Bell className="w-4 h-4" />
                  {broadcasting ? `Sending to ${users.length}…` : `Send to ${users.length} users`}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
