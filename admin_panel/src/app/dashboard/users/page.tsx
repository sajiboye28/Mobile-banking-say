"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
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
import { Search, CheckCircle2, ShieldBan, RotateCcw, XCircle, ExternalLink, Bell, X, RefreshCw } from "lucide-react";

interface UserData {
  uid: string;
  fullName: string;
  email: string;
  balance: number;
  accountStatus: string;
  kycStatus?: string;
  canTransact: boolean;
  tccCode: string;
  createdAt: any;
}

export default function UsersPage() {
  const [users, setUsers] = useState<UserData[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [kycFilter, setKycFilter] = useState("all");
  const [notifTarget, setNotifTarget] = useState<UserData | null>(null);
  const [notifTitle, setNotifTitle] = useState("");
  const [notifBody, setNotifBody] = useState("");
  const [sendingNotif, setSendingNotif] = useState(false);

  const loadUsers = async () => {
    try {
      const data = await apiCall('/api/users?page=1&limit=100&status=all');
      setUsers(data.users ?? data.items ?? []);
    } catch (error) {
      toast.error("Failed to load users.");
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  const toggleCanTransact = async (uid: string, currentValue: boolean) => {
    try {
      await apiCall(`/api/users/${uid}/status`, { method: 'POST', body: JSON.stringify({ canTransact: !currentValue }) });
      toast.success(`Transaction ability ${!currentValue ? "enabled" : "disabled"}`);
      await loadUsers();
    } catch (error) {
      toast.error("Failed to update transaction ability.");
    }
  };

  const updateAccountStatus = async (uid: string, newStatus: string) => {
    try {
      await apiCall(`/api/users/${uid}/status`, { method: 'POST', body: JSON.stringify({ status: newStatus }) });
      toast.success(`Account status updated to "${newStatus}"`);
      await loadUsers();
    } catch (error) {
      toast.error("Failed to update account status.");
    }
  };

  const sendNotification = async () => {
    if (!notifTarget || !notifTitle.trim() || !notifBody.trim()) return;
    setSendingNotif(true);
    try {
      await apiCall('/api/notify', { method: 'POST', body: JSON.stringify({ userId: notifTarget.uid, title: notifTitle.trim(), message: notifBody.trim(), type: 'announcement' }) });
      toast.success(`Notification sent to ${notifTarget.fullName}`);
      setNotifTarget(null);
      setNotifTitle("");
      setNotifBody("");
    } catch (error) {
      toast.error("Failed to send notification.");
    } finally {
      setSendingNotif(false);
    }
  };

  // Normalize kycStatus to a canonical key for filtering/display
  const normalizeKyc = (kycStatus?: string): "approved" | "pending" | "rejected" | "unverified" => {
    if (!kycStatus) return "unverified";
    const s = kycStatus.toLowerCase();
    if (s === "approved" || s === "verified") return "approved";
    if (s === "pending") return "pending";
    if (s === "rejected") return "rejected";
    return "unverified";
  };

  const filteredUsers = users.filter((u) => {
    const matchesSearch =
      u.fullName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.uid?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === "all" || u.accountStatus === statusFilter;
    const matchesKyc = kycFilter === "all" || normalizeKyc(u.kycStatus) === kycFilter;
    return matchesSearch && matchesStatus && matchesKyc;
  });

  const getStatusBadge = (status: string) => {
    const map: Record<string, string> = {
      active: "status-badge-active",
      pending: "status-badge-pending",
      suspended: "status-badge-suspended",
      closed: "status-badge-closed",
    };
    const dotMap: Record<string, string> = {
      active: "bg-emerald-500",
      pending: "bg-amber-500",
      suspended: "bg-rose-500",
      closed: "bg-gray-400",
    };
    return (
      <span className={map[status] || "status-badge-closed"}>
        <span className={`w-1.5 h-1.5 rounded-full ${dotMap[status] || "bg-gray-400"}`} />
        {status}
      </span>
    );
  };

  const getKycBadge = (kycStatus?: string) => {
    const key = normalizeKyc(kycStatus);
    const config: Record<string, { label: string; className: string }> = {
      approved:   { label: "Verified",   className: "bg-emerald-100 text-emerald-700 ring-1 ring-emerald-200" },
      pending:    { label: "Pending",    className: "bg-amber-100 text-amber-700 ring-1 ring-amber-200" },
      rejected:   { label: "Rejected",   className: "bg-rose-100 text-rose-700 ring-1 ring-rose-200" },
      unverified: { label: "Unverified", className: "bg-gray-100 text-gray-500 ring-1 ring-gray-200" },
    };
    const { label, className } = config[key];
    return (
      <span className={`inline-flex items-center text-xs font-semibold px-2 py-0.5 rounded-full ${className}`}>
        {label}
      </span>
    );
  };

  return (
    <div className="animate-fade-in">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">User Oversight</h1>
          <p className="text-sm text-gray-500 mt-0.5">{users.length} total users registered</p>
        </div>
        <button
          onClick={loadUsers}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-white border border-gray-200 text-sm font-semibold text-gray-700 hover:bg-gray-50 transition-colors shadow-sm"
        >
          <RefreshCw className="w-4 h-4" />
          Refresh
        </button>
      </div>

      {/* Filters */}
      <div className="card mb-6">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search by name, email, or UID..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input-field pl-10"
            />
          </div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="input-field sm:w-48"
          >
            <option value="all">All Statuses</option>
            <option value="active">Active</option>
            <option value="pending">Pending</option>
            <option value="suspended">Suspended</option>
            <option value="closed">Closed</option>
          </select>
          <select
            value={kycFilter}
            onChange={(e) => setKycFilter(e.target.value)}
            className="input-field sm:w-44"
          >
            <option value="all">All KYC</option>
            <option value="approved">Verified</option>
            <option value="pending">Pending</option>
            <option value="rejected">Rejected</option>
            <option value="unverified">Unverified</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="card overflow-hidden p-0">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="table-header">
                <th>User</th>
                <th>UID</th>
                <th className="text-right">Balance</th>
                <th className="text-center">Status</th>
                <th className="text-center">KYC</th>
                <th className="text-center">Can Transact</th>
                <th>TCC Code</th>
                <th className="text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.map((user) => (
                <tr key={user.uid} className="table-row">
                  <td>
                    <Link href={`/dashboard/users/${user.uid}`} className="group">
                      <p className="font-semibold text-gray-900 group-hover:text-indigo-600 transition-colors">
                        {user.fullName}
                      </p>
                      <p className="text-xs text-gray-500">{user.email}</p>
                    </Link>
                  </td>
                  <td className="font-mono text-xs text-gray-400">{user.uid?.substring(0, 12)}...</td>
                  <td className="text-right font-semibold text-gray-900">
                    ${user.balance?.toLocaleString("en-US", { minimumFractionDigits: 2 })}
                  </td>
                  <td className="text-center">{getStatusBadge(user.accountStatus)}</td>
                  <td className="text-center">{getKycBadge(user.kycStatus)}</td>
                  <td className="text-center">
                    <button
                      onClick={() => toggleCanTransact(user.uid, user.canTransact)}
                      className={`toggle-switch ${user.canTransact ? "bg-emerald-500" : "bg-gray-300"}`}
                    >
                      <span
                        className={`toggle-switch-dot ${
                          user.canTransact ? "translate-x-6" : "translate-x-1"
                        }`}
                      />
                    </button>
                  </td>
                  <td className="font-mono text-sm text-gray-600 bg-slate-50/50 rounded">{user.tccCode}</td>
                  <td>
                    <div className="flex items-center justify-center gap-1.5">
                      {user.accountStatus === "pending" && (
                        <button
                          onClick={() => updateAccountStatus(user.uid, "active")}
                          className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-semibold bg-emerald-50 text-emerald-700 rounded-lg hover:bg-emerald-100 transition-colors ring-1 ring-emerald-200/50"
                        >
                          <CheckCircle2 className="w-3 h-3" />
                          Approve
                        </button>
                      )}
                      {user.accountStatus === "active" && (
                        <button
                          onClick={() => updateAccountStatus(user.uid, "suspended")}
                          className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-semibold bg-rose-50 text-rose-700 rounded-lg hover:bg-rose-100 transition-colors ring-1 ring-rose-200/50"
                        >
                          <ShieldBan className="w-3 h-3" />
                          Suspend
                        </button>
                      )}
                      {user.accountStatus === "suspended" && (
                        <>
                          <button
                            onClick={() => updateAccountStatus(user.uid, "active")}
                            className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-semibold bg-emerald-50 text-emerald-700 rounded-lg hover:bg-emerald-100 transition-colors ring-1 ring-emerald-200/50"
                          >
                            <RotateCcw className="w-3 h-3" />
                            Reactivate
                          </button>
                          <button
                            onClick={() => updateAccountStatus(user.uid, "closed")}
                            className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-semibold bg-gray-100 text-gray-600 rounded-lg hover:bg-gray-200 transition-colors ring-1 ring-gray-200/50"
                          >
                            <XCircle className="w-3 h-3" />
                            Close
                          </button>
                        </>
                      )}
                      <button
                        onClick={() => setNotifTarget(user)}
                        className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-semibold bg-amber-50 text-amber-700 rounded-lg hover:bg-amber-100 transition-colors ring-1 ring-amber-200/50"
                      >
                        <Bell className="w-3 h-3" />
                        Notify
                      </button>
                      <Link
                        href={`/dashboard/users/${user.uid}`}
                        className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-semibold bg-indigo-50 text-indigo-700 rounded-lg hover:bg-indigo-100 transition-colors ring-1 ring-indigo-200/50"
                      >
                        <ExternalLink className="w-3 h-3" />
                        Edit
                      </Link>
                    </div>
                  </td>
                </tr>
              ))}
              {filteredUsers.length === 0 && (
                <tr>
                  <td colSpan={8} className="py-12 text-center">
                    <Search className="w-10 h-10 text-gray-300 mx-auto mb-3" />
                    <p className="text-gray-500 font-medium">No users found</p>
                    <p className="text-gray-400 text-xs mt-1">Try adjusting your search or filter criteria</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Send Notification Modal */}
      {notifTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md mx-4 p-6 animate-slide-up">
            <div className="flex items-center justify-between mb-5">
              <div>
                <h3 className="text-lg font-bold text-gray-900">Send Notification</h3>
                <p className="text-sm text-gray-500 mt-0.5">To: <span className="font-semibold text-indigo-600">{notifTarget.fullName}</span></p>
              </div>
              <button
                onClick={() => { setNotifTarget(null); setNotifTitle(""); setNotifBody(""); }}
                className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center hover:bg-gray-200 transition-colors"
              >
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">Title</label>
                <input
                  type="text"
                  value={notifTitle}
                  onChange={(e) => setNotifTitle(e.target.value)}
                  placeholder="e.g. Account Update"
                  className="input-field"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">Message</label>
                <textarea
                  value={notifBody}
                  onChange={(e) => setNotifBody(e.target.value)}
                  placeholder="Enter your message to the user..."
                  rows={4}
                  className="input-field resize-none"
                />
              </div>

              <div className="flex gap-3 pt-1">
                <button
                  onClick={() => { setNotifTarget(null); setNotifTitle(""); setNotifBody(""); }}
                  className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={sendNotification}
                  disabled={sendingNotif || !notifTitle.trim() || !notifBody.trim()}
                  className="flex-1 py-2.5 rounded-xl bg-gradient-to-r from-amber-500 to-orange-500 text-white text-sm font-semibold hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                >
                  <Bell className="w-4 h-4" />
                  {sendingNotif ? "Sending…" : "Send"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
