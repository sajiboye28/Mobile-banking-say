"use client";

import { useState } from "react";
import toast from "react-hot-toast";

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
  Search,
  CheckCircle2,
  AlertCircle,
  ArrowDownRight,
  ArrowUpRight,
  DollarSign,
  FileText,
  Clock,
  Loader2,
  Send,
} from "lucide-react";

export default function CreateTransactionPage() {
  const [userId, setUserId] = useState("");
  const [amount, setAmount] = useState("");
  const [type, setType] = useState<"Credit" | "Debit">("Credit");
  const [description, setDescription] = useState("");
  const [status, setStatus] = useState<"Success" | "Pending" | "Failed">("Success");
  const [customTimestamp, setCustomTimestamp] = useState("");
  const [adjustBalance, setAdjustBalance] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [userName, setUserName] = useState<string | null>(null);
  const [lookupError, setLookupError] = useState<string | null>(null);

  const lookupUser = async () => {
    if (!userId.trim()) return;
    setLookupError(null);
    setUserName(null);

    try {
      const data = await apiCall(`/api/users/${userId.trim()}`);
      if (data.user) {
        setUserName(data.user.fullName || "Unknown");
      } else {
        setLookupError("No user found with this UID.");
      }
    } catch (error) {
      setLookupError("No user found with this UID.");
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const amountValue = parseFloat(amount);
    if (isNaN(amountValue) || amountValue <= 0) {
      toast.error("Amount must be a positive number.");
      return;
    }

    if (!userId.trim()) {
      toast.error("User ID is required.");
      return;
    }

    setIsSubmitting(true);

    try {
      await apiCall(`/api/users/${userId.trim()}/transaction`, {
        method: 'POST',
        body: JSON.stringify({
          amount: amountValue,
          type,
          description: description.trim() || `Manual ${type} by Admin`,
          status,
          ...(customTimestamp ? { timestamp: new Date(customTimestamp).toISOString() } : {}),
          adjustBalance,
        }),
      });

      toast.success("Transaction created successfully.");
      setAmount("");
      setDescription("");
      setCustomTimestamp("");
    } catch (error: any) {
      toast.error("Failed to create transaction: " + (error.message || "Unknown error"));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Create Manual Transaction</h1>
        <p className="text-sm text-gray-500 mt-0.5">Manually create a transaction record for any user</p>
      </div>

      <div className="max-w-2xl">
        <div className="card">
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* User ID Lookup */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                <span className="flex items-center gap-1.5">
                  <Search className="w-4 h-4 text-gray-400" />
                  User ID
                </span>
              </label>
              <div className="flex gap-2">
                <input
                  type="text"
                  value={userId}
                  onChange={(e) => {
                    setUserId(e.target.value);
                    setUserName(null);
                    setLookupError(null);
                  }}
                  className="input-field flex-1"
                  placeholder="Enter User ID"
                  required
                />
                <button type="button" onClick={lookupUser} className="btn-secondary whitespace-nowrap inline-flex items-center gap-1.5">
                  <Search className="w-4 h-4" />
                  Lookup
                </button>
              </div>
              {userName && (
                <p className="mt-2 text-sm text-emerald-600 flex items-center gap-1.5 bg-emerald-50 px-3 py-2 rounded-lg">
                  <CheckCircle2 className="w-4 h-4" />
                  Found: <span className="font-semibold">{userName}</span>
                </p>
              )}
              {lookupError && (
                <p className="mt-2 text-sm text-rose-600 flex items-center gap-1.5 bg-rose-50 px-3 py-2 rounded-lg">
                  <AlertCircle className="w-4 h-4" />
                  {lookupError}
                </p>
              )}
            </div>

            {/* Divider */}
            <div className="border-t border-gray-100" />

            {/* Transaction Type */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">Transaction Type</label>
              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => setType("Credit")}
                  className={`flex-1 py-4 rounded-xl font-semibold text-sm border-2 transition-all duration-200 ${
                    type === "Credit"
                      ? "border-emerald-500 bg-emerald-50 text-emerald-700 shadow-glow-emerald"
                      : "border-gray-200 bg-white text-gray-500 hover:border-gray-300 hover:bg-gray-50"
                  }`}
                >
                  <ArrowDownRight className={`w-6 h-6 mx-auto mb-1.5 ${type === "Credit" ? "text-emerald-500" : "text-gray-400"}`} />
                  Credit (Add Funds)
                </button>
                <button
                  type="button"
                  onClick={() => setType("Debit")}
                  className={`flex-1 py-4 rounded-xl font-semibold text-sm border-2 transition-all duration-200 ${
                    type === "Debit"
                      ? "border-rose-500 bg-rose-50 text-rose-700 shadow-glow-rose"
                      : "border-gray-200 bg-white text-gray-500 hover:border-gray-300 hover:bg-gray-50"
                  }`}
                >
                  <ArrowUpRight className={`w-6 h-6 mx-auto mb-1.5 ${type === "Debit" ? "text-rose-500" : "text-gray-400"}`} />
                  Debit (Remove Funds)
                </button>
              </div>
            </div>

            {/* Amount */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                <span className="flex items-center gap-1.5">
                  <DollarSign className="w-4 h-4 text-gray-400" />
                  Amount ($)
                </span>
              </label>
              <input
                type="number"
                step="0.01"
                min="0.01"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="input-field text-lg font-semibold"
                placeholder="0.00"
                required
              />
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                <span className="flex items-center gap-1.5">
                  <FileText className="w-4 h-4 text-gray-400" />
                  Description
                </span>
              </label>
              <input
                type="text"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="input-field"
                placeholder="e.g., Initial deposit, Refund, Fee adjustment"
              />
            </div>

            {/* Status */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">Status</label>
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value as "Success" | "Pending" | "Failed")}
                className="input-field"
              >
                <option value="Success">Success</option>
                <option value="Pending">Pending</option>
                <option value="Failed">Failed</option>
              </select>
            </div>

            {/* Divider */}
            <div className="border-t border-gray-100" />

            {/* Time Travel Section */}
            <div className="p-4 bg-gradient-to-br from-indigo-50/80 to-blue-50/80 rounded-xl border border-indigo-100">
              <label className="block text-sm font-semibold text-indigo-700 mb-2">
                <span className="flex items-center gap-1.5">
                  <Clock className="w-4 h-4" />
                  Timestamp
                  <span className="px-1.5 py-0.5 bg-indigo-100 text-indigo-700 rounded text-[10px] font-bold ml-1">TIME TRAVEL</span>
                </span>
              </label>
              <input
                type="datetime-local"
                value={customTimestamp}
                onChange={(e) => setCustomTimestamp(e.target.value)}
                className="input-field bg-white/80"
              />
              <p className="text-xs text-indigo-500 mt-2">Leave empty to use current server time. Set a custom date to backdate or future-date.</p>
            </div>

            {/* Adjust Balance Toggle */}
            <div className="flex items-center justify-between p-4 bg-slate-50 rounded-xl border border-gray-100">
              <div>
                <p className="text-sm font-semibold text-gray-700">Auto-adjust user balance</p>
                <p className="text-xs text-gray-500 mt-0.5">
                  Automatically update the user&apos;s balance when status is &quot;Success&quot;
                </p>
              </div>
              <button
                type="button"
                onClick={() => setAdjustBalance(!adjustBalance)}
                className={`toggle-switch ${adjustBalance ? "bg-emerald-500" : "bg-gray-300"}`}
              >
                <span
                  className={`toggle-switch-dot ${
                    adjustBalance ? "translate-x-6" : "translate-x-1"
                  }`}
                />
              </button>
            </div>

            {/* Submit */}
            <button type="submit" disabled={isSubmitting} className="btn-primary w-full py-3.5 text-base inline-flex items-center justify-center gap-2">
              {isSubmitting ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Creating Transaction...
                </>
              ) : (
                <>
                  <Send className="w-5 h-5" />
                  Create Transaction
                </>
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
