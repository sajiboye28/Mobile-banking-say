"use client";

import { useEffect, useState } from "react";
import toast from "react-hot-toast";
import {
  Search,
  ArrowDownRight,
  ArrowUpRight,
  Clock,
  Check,
  X,
  Inbox,
  Download,
  Pencil,
  Trash2,
  AlertTriangle,
  RefreshCw,
} from "lucide-react";

const getToken = () => typeof window !== 'undefined' ? localStorage.getItem('pb_admin_token') ?? '' : '';
const apiCall = async (url: string, options: RequestInit = {}) => {
  const res = await fetch(url, {
    ...options,
    headers: { 'Authorization': `Bearer ${getToken()}`, 'Content-Type': 'application/json', ...(options.headers ?? {}) }
  });
  if (!res.ok) throw new Error((await res.json().catch(() => ({}))).error || res.statusText);
  return res.json();
};

interface TransactionData {
  transactionId: string;
  userId: string;
  amount: number;
  type: string;
  timestamp: string | null;
  description: string;
  status: string;
  relatedUserName?: string;
}

export default function TransactionsPage() {
  const [transactions, setTransactions] = useState<TransactionData[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [typeFilter, setTypeFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [editingTimestamp, setEditingTimestamp] = useState<string | null>(null);
  const [newTimestamp, setNewTimestamp] = useState("");
  const [timeTravelChanged, setTimeTravelChanged] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editingTransaction, setEditingTransaction] = useState<TransactionData | null>(null);
  const [editForm, setEditForm] = useState({ amount: 0, description: '', status: '', type: '' });
  const [editModalTimestamp, setEditModalTimestamp] = useState("");
  const [editModalTimestampDirty, setEditModalTimestampDirty] = useState(false);
  const [isSavingEdit, setIsSavingEdit] = useState(false);

  const loadTransactions = async () => {
    setLoading(true);
    try {
      const data = await apiCall('/api/transaction?limit=200');
      const txArr: TransactionData[] = (data.items ?? data.transactions ?? []).map((t: any) => ({
        transactionId: t.id ?? t.transactionId,
        userId: t.userId ?? t.user,
        amount: t.amount ?? 0,
        type: t.type ?? 'Debit',
        timestamp: t.timestamp ?? t.created ?? null,
        description: t.description ?? '',
        status: t.status ?? 'Success',
        relatedUserName: t.relatedUserName ?? '',
      }));
      txArr.sort((a, b) => {
        const at = a.timestamp ? new Date(a.timestamp).getTime() : 0;
        const bt = b.timestamp ? new Date(b.timestamp).getTime() : 0;
        return bt - at;
      });
      setTransactions(txArr);
    } catch (err: any) {
      toast.error("Failed to load transactions.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadTransactions(); }, []);

  useEffect(() => {
    if (editingTransaction) {
      setEditForm({
        amount: editingTransaction.amount,
        description: editingTransaction.description,
        status: editingTransaction.status || 'Success',
        type: editingTransaction.type || 'Debit',
      });
      if (editingTransaction.timestamp) {
        const d = new Date(editingTransaction.timestamp);
        const iso = new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
        setEditModalTimestamp(iso);
      } else {
        setEditModalTimestamp("");
      }
      setEditModalTimestampDirty(false);
    }
  }, [editingTransaction]);

  const handleTimeTravelSave = async (transactionId: string) => {
    try {
      const date = new Date(newTimestamp);
      if (isNaN(date.getTime())) { toast.error("Invalid date/time format."); return; }
      await apiCall(`/api/transaction`, {
        method: 'PATCH',
        body: JSON.stringify({ transactionId, timestamp: date.toISOString() }),
      });
      toast.success("Transaction timestamp updated (Time Travel applied).");
      setEditingTimestamp(null);
      setNewTimestamp("");
      await loadTransactions();
    } catch {
      toast.error("Failed to update timestamp.");
    }
  };

  const startEditTimestamp = (transactionId: string, currentTimestamp: string | null) => {
    setEditingTimestamp(transactionId);
    setTimeTravelChanged(false);
    if (currentTimestamp) {
      const d = new Date(currentTimestamp);
      const iso = new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
      setNewTimestamp(iso);
    } else {
      setNewTimestamp("");
    }
  };

  const handleDeleteTransaction = async (transactionId: string) => {
    if (!confirm("Delete this transaction permanently?")) return;
    try {
      await apiCall(`/api/transaction`, {
        method: 'DELETE',
        body: JSON.stringify({ transactionId }),
      });
      toast.success("Transaction deleted");
      await loadTransactions();
    } catch {
      toast.error("Failed to delete transaction");
    }
  };

  const handleSaveEdit = async () => {
    if (!editingTransaction) return;
    setIsSavingEdit(true);
    try {
      const updates: Record<string, any> = {
        transactionId: editingTransaction.transactionId,
        amount: editForm.amount,
        description: editForm.description,
        status: editForm.status,
        type: editForm.type,
      };
      if (editModalTimestampDirty && editModalTimestamp) {
        const newDate = new Date(editModalTimestamp);
        if (!isNaN(newDate.getTime())) {
          updates.timestamp = newDate.toISOString();
        }
      }
      await apiCall(`/api/transaction`, { method: 'PATCH', body: JSON.stringify(updates) });
      toast.success("Transaction updated" + (editModalTimestampDirty && editModalTimestamp ? " (timestamp changed)" : ""));
      setShowEditModal(false);
      setEditingTransaction(null);
      await loadTransactions();
    } catch {
      toast.error("Failed to update transaction");
    } finally {
      setIsSavingEdit(false);
    }
  };

  const filteredTransactions = transactions.filter((tx) => {
    const matchesSearch =
      tx.transactionId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      tx.userId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      tx.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      tx.relatedUserName?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesType = typeFilter === "all" || tx.type?.toLowerCase() === typeFilter.toLowerCase();
    const matchesStatus = statusFilter === "all" || tx.status?.toLowerCase() === statusFilter.toLowerCase();
    return matchesSearch && matchesType && matchesStatus;
  });

  const exportCsv = () => {
    const headers = ["Transaction ID", "User ID", "Type", "Amount", "Description", "Status", "Related User", "Timestamp"];
    const rows = filteredTransactions.map((tx) => [
      tx.transactionId ?? "",
      tx.userId ?? "",
      tx.type ?? "",
      tx.amount?.toFixed(2) ?? "0.00",
      `"${(tx.description ?? "").replace(/"/g, '""')}"`,
      tx.status ?? "",
      tx.relatedUserName ?? "",
      tx.timestamp ?? "",
    ]);
    const csv = [headers, ...rows].map((r) => r.join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `nexus-transactions-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const fmtDate = (ts: string | null) => {
    if (!ts) return "N/A";
    return new Date(ts).toLocaleString();
  };

  return (
    <div className="animate-fade-in">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">All Transactions</h1>
          <p className="text-sm text-gray-500 mt-0.5">{transactions.length} transactions loaded</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={loadTransactions}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-white border border-gray-200 text-sm font-semibold text-gray-700 hover:bg-gray-50 transition-colors shadow-sm"
          >
            <RefreshCw className="w-4 h-4" />
            Refresh
          </button>
          <button
            onClick={exportCsv}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition-colors shadow-sm shadow-indigo-500/20"
          >
            <Download className="w-4 h-4" />
            Export CSV
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="card mb-6">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search by ID, User ID, or description..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input-field pl-10"
            />
          </div>
          <select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)} className="input-field sm:w-36">
            <option value="all">All Types</option>
            <option value="Credit">Credit</option>
            <option value="Debit">Debit</option>
          </select>
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="input-field sm:w-36">
            <option value="all">All Statuses</option>
            <option value="Success">Success</option>
            <option value="Pending">Pending</option>
            <option value="Failed">Failed</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="card overflow-hidden p-0">
        {loading ? (
          <div className="flex items-center justify-center py-16">
            <RefreshCw className="w-8 h-8 text-indigo-400 animate-spin" />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="table-header">
                  <th>Transaction ID</th>
                  <th>User ID</th>
                  <th>Type</th>
                  <th className="text-right">Amount</th>
                  <th>Description</th>
                  <th>Status</th>
                  <th>
                    <span className="flex items-center gap-1.5">
                      Timestamp
                      <span className="px-1.5 py-0.5 bg-indigo-100 text-indigo-700 rounded text-[10px] font-bold">TIME TRAVEL</span>
                    </span>
                  </th>
                  <th className="text-center">Actions</th>
                  <th className="text-right">Edit / Delete</th>
                </tr>
              </thead>
              <tbody>
                {filteredTransactions.map((tx) => (
                  <tr key={tx.transactionId} className="table-row">
                    <td className="font-mono text-xs text-gray-400">
                      {tx.transactionId?.substring(0, 12)}...
                    </td>
                    <td className="font-mono text-xs text-gray-400">
                      {tx.userId?.substring(0, 12)}...
                    </td>
                    <td>
                      <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold ${tx.type === "Credit" ? "bg-emerald-50 text-emerald-700" : "bg-rose-50 text-rose-700"}`}>
                        {tx.type === "Credit" ? <ArrowDownRight className="w-3 h-3" /> : <ArrowUpRight className="w-3 h-3" />}
                        {tx.type}
                      </span>
                    </td>
                    <td className="text-right font-semibold text-gray-900">
                      ${tx.amount?.toLocaleString("en-US", { minimumFractionDigits: 2 })}
                    </td>
                    <td className="text-gray-600 max-w-xs truncate">{tx.description}</td>
                    <td>
                      <span className={`${tx.status === "Success" ? "status-badge-active" : tx.status === "Pending" ? "status-badge-pending" : "status-badge-suspended"}`}>
                        <span className={`w-1.5 h-1.5 rounded-full ${tx.status === "Success" ? "bg-emerald-500" : tx.status === "Pending" ? "bg-amber-500" : "bg-rose-500"}`} />
                        {tx.status}
                      </span>
                    </td>
                    <td>
                      {editingTimestamp === tx.transactionId ? (
                        <div className="flex flex-col gap-1.5 min-w-[260px]">
                          {timeTravelChanged && (
                            <div className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-amber-50 border border-amber-200 text-amber-700">
                              <AlertTriangle className="w-3.5 h-3.5 flex-shrink-0" />
                              <span className="text-[11px] font-medium leading-tight">
                                Changing the timestamp will affect transaction history ordering
                              </span>
                            </div>
                          )}
                          <div className="flex items-center gap-2">
                            <input
                              type="datetime-local"
                              value={newTimestamp}
                              onChange={(e) => { setNewTimestamp(e.target.value); setTimeTravelChanged(true); }}
                              className="input-field text-xs py-1.5 px-2.5 bg-indigo-50/50 ring-1 ring-indigo-200"
                            />
                            <button
                              onClick={() => handleTimeTravelSave(tx.transactionId)}
                              className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 hover:bg-emerald-100 flex items-center justify-center transition-colors ring-1 ring-emerald-200/50"
                            >
                              <Check className="w-4 h-4" />
                            </button>
                            <button
                              onClick={() => { setEditingTimestamp(null); setTimeTravelChanged(false); }}
                              className="w-8 h-8 rounded-lg bg-gray-100 text-gray-500 hover:bg-gray-200 flex items-center justify-center transition-colors"
                            >
                              <X className="w-4 h-4" />
                            </button>
                          </div>
                        </div>
                      ) : (
                        <span className="text-xs text-gray-500">{fmtDate(tx.timestamp)}</span>
                      )}
                    </td>
                    <td className="text-center">
                      {editingTimestamp !== tx.transactionId && (
                        <button
                          onClick={() => startEditTimestamp(tx.transactionId, tx.timestamp)}
                          className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-semibold bg-indigo-50 text-indigo-700 rounded-lg hover:bg-indigo-100 transition-colors ring-1 ring-indigo-200/50"
                          title="Time Travel: Edit Timestamp"
                        >
                          <Clock className="w-3 h-3" />
                          Edit Time
                        </button>
                      )}
                    </td>
                    <td className="p-3 text-right">
                      <div className="flex gap-2 justify-end">
                        <button
                          onClick={() => { setEditingTransaction(tx); setShowEditModal(true); }}
                          className="p-1.5 rounded-lg bg-indigo-500/10 hover:bg-indigo-500/20 text-indigo-400 transition-colors"
                        >
                          <Pencil className="w-3.5 h-3.5" />
                        </button>
                        <button
                          onClick={() => handleDeleteTransaction(tx.transactionId)}
                          className="p-1.5 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-400 transition-colors"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {filteredTransactions.length === 0 && (
                  <tr>
                    <td colSpan={9} className="py-12 text-center">
                      <Inbox className="w-10 h-10 text-gray-300 mx-auto mb-3" />
                      <p className="text-gray-500 font-medium">No transactions found</p>
                      <p className="text-gray-400 text-xs mt-1">Try adjusting your search or filter</p>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Edit Modal */}
      {showEditModal && editingTransaction && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-[#12121a] border border-[#1e1e2e] rounded-2xl p-6 w-full max-w-md">
            <h3 className="text-lg font-bold text-white mb-4">Edit Transaction</h3>
            <div className="mb-3">
              <label className="text-xs text-gray-400 mb-1 block">Amount</label>
              <input
                type="number"
                value={editForm.amount}
                onChange={(e) => setEditForm({...editForm, amount: parseFloat(e.target.value) || 0})}
                className="w-full bg-[#1e1e2e] border border-[#2e2e3e] rounded-xl px-3 py-2 text-white text-sm"
              />
            </div>
            <div className="mb-3">
              <label className="text-xs text-gray-400 mb-1 block">Description</label>
              <input
                type="text"
                value={editForm.description}
                onChange={(e) => setEditForm({...editForm, description: e.target.value})}
                className="w-full bg-[#1e1e2e] border border-[#2e2e3e] rounded-xl px-3 py-2 text-white text-sm"
              />
            </div>
            <div className="mb-3">
              <label className="text-xs text-gray-400 mb-1 block">Status</label>
              <select
                value={editForm.status}
                onChange={(e) => setEditForm({...editForm, status: e.target.value})}
                className="w-full bg-[#1e1e2e] border border-[#2e2e3e] rounded-xl px-3 py-2 text-white text-sm"
              >
                <option value="Success">Success</option>
                <option value="Pending">Pending</option>
                <option value="Failed">Failed</option>
              </select>
            </div>
            <div className="mb-4">
              <label className="text-xs text-gray-400 mb-1 block">Type</label>
              <select
                value={editForm.type}
                onChange={(e) => setEditForm({...editForm, type: e.target.value})}
                className="w-full bg-[#1e1e2e] border border-[#2e2e3e] rounded-xl px-3 py-2 text-white text-sm"
              >
                <option value="Credit">Credit</option>
                <option value="Debit">Debit</option>
                <option value="Transfer">Transfer</option>
                <option value="Deposit">Deposit</option>
                <option value="Withdrawal">Withdrawal</option>
              </select>
            </div>
            <div className="mb-3">
              <label className="text-xs text-gray-400 mb-1 block flex items-center gap-1.5">
                Timestamp
                <span className="px-1.5 py-0.5 bg-indigo-500/20 text-indigo-300 rounded text-[10px] font-bold">TIME TRAVEL</span>
              </label>
              <input
                type="datetime-local"
                value={editModalTimestamp}
                onChange={(e) => { setEditModalTimestamp(e.target.value); setEditModalTimestampDirty(true); }}
                className="w-full bg-[#1e1e2e] border border-[#2e2e3e] rounded-xl px-3 py-2 text-white text-sm"
              />
              {editModalTimestampDirty && (
                <div className="flex items-start gap-2 mt-2 px-3 py-2 rounded-lg bg-amber-500/10 border border-amber-500/30">
                  <AlertTriangle className="w-3.5 h-3.5 text-amber-400 flex-shrink-0 mt-0.5" />
                  <p className="text-[11px] text-amber-300 leading-snug">
                    Changing the timestamp will affect transaction history ordering
                  </p>
                </div>
              )}
            </div>
            <div className="flex gap-3">
              <button
                onClick={() => { setShowEditModal(false); setEditingTransaction(null); }}
                className="flex-1 py-2.5 rounded-xl border border-[#2e2e3e] text-gray-400 text-sm font-medium"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveEdit}
                disabled={isSavingEdit}
                className="flex-1 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold disabled:opacity-50"
              >
                {isSavingEdit ? "Saving..." : "Save Changes"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
