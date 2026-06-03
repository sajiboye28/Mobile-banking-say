"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/AuthContext";
import Sidebar from "@/components/Sidebar";

const getToken = () => typeof window !== 'undefined' ? localStorage.getItem('pb_admin_token') ?? '' : '';
import { Toaster } from "react-hot-toast";
import toast from "react-hot-toast";
import {
  Search, Filter, Download, X, ChevronLeft, ChevronRight,
  User, Mail, CreditCard, DollarSign, Calendar, Shield,
  ShieldBan, RotateCcw, KeyRound, ArrowLeftRight, Loader2,
  CheckCircle2, Clock, AlertCircle, BadgeCheck, BadgeX,
} from "lucide-react";

interface UserRecord {
  uid: string;
  fullName: string;
  email: string;
  accountNumber: string;
  balance: number;
  accountStatus: string;
  kycStatus: string;
  createdAt: string | null;
  photoURL: string | null;
  phone: string | null;
  address: string | null;
  tccCode: string | null;
  canTransact: boolean;
}

interface Pagination {
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

const STATUS_COLORS: Record<string, string> = {
  active: "status-badge-active",
  pending: "status-badge-pending",
  suspended: "status-badge-suspended",
  closed: "status-badge-closed",
};

const STATUS_DOT: Record<string, string> = {
  active: "bg-emerald-500",
  pending: "bg-amber-500",
  suspended: "bg-rose-500",
  closed: "bg-gray-400",
};

const KYC_COLORS: Record<string, string> = {
  approved: "bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200",
  pending: "bg-amber-50 text-amber-700 ring-1 ring-amber-200",
  rejected: "bg-rose-50 text-rose-700 ring-1 ring-rose-200",
  not_submitted: "bg-gray-100 text-gray-600 ring-1 ring-gray-200",
};

function StatusBadge({ status }: { status: string }) {
  return (
    <span className={`${STATUS_COLORS[status] || "status-badge-closed"} status-badge`}>
      <span className={`w-1.5 h-1.5 rounded-full ${STATUS_DOT[status] || "bg-gray-400"}`} />
      {status}
    </span>
  );
}

function KycBadge({ status }: { status: string }) {
  const label =
    status === "not_submitted" ? "Not Submitted" :
    status.charAt(0).toUpperCase() + status.slice(1);
  const Icon = status === "approved" ? BadgeCheck : status === "rejected" ? BadgeX : AlertCircle;
  return (
    <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold ${KYC_COLORS[status] || KYC_COLORS.not_submitted}`}>
      <Icon className="w-3 h-3" />
      {label}
    </span>
  );
}

function Avatar({ user }: { user: UserRecord }) {
  if (user.photoURL) {
    return <img src={user.photoURL} alt={user.fullName} className="w-9 h-9 rounded-full object-cover ring-2 ring-gray-100" />;
  }
  const initials = user.fullName.split(" ").map((n) => n[0]).join("").substring(0, 2).toUpperCase() || "?";
  const colors = ["from-indigo-500 to-blue-500", "from-purple-500 to-pink-500", "from-emerald-500 to-teal-500", "from-amber-500 to-orange-500", "from-rose-500 to-red-500"];
  const color = colors[user.fullName.charCodeAt(0) % colors.length];
  return (
    <div className={`w-9 h-9 rounded-full bg-gradient-to-br ${color} flex items-center justify-center ring-2 ring-gray-100`}>
      <span className="text-xs font-bold text-white">{initials}</span>
    </div>
  );
}

export default function UsersPage() {
  const { user, isAdmin, loading: authLoading } = useAuth();
  const router = useRouter();

  const [users, setUsers] = useState<UserRecord[]>([]);
  const [pagination, setPagination] = useState<Pagination>({ total: 0, page: 1, pageSize: 10, totalPages: 1 });
  const [fetching, setFetching] = useState(false);
  const [search, setSearch] = useState("");
  const [searchInput, setSearchInput] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [selectedUser, setSelectedUser] = useState<UserRecord | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    if (!authLoading && (!user || !isAdmin)) {
      router.push("/login");
    }
  }, [user, isAdmin, authLoading, router]);

  const fetchUsers = useCallback(async (page = 1, status = statusFilter, q = search) => {
    if (!user) return;
    setFetching(true);
    try {
      const token = getToken();
      const params = new URLSearchParams({
        page: String(page),
        limit: "10",
        status,
        search: q,
      });
      const res = await fetch(`/api/users?${params}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) throw new Error("Failed to fetch users");
      const data = await res.json();
      setUsers(data.users);
      setPagination(data.pagination);
    } catch (e) {
      toast.error("Failed to load users");
    } finally {
      setFetching(false);
    }
  }, [user, statusFilter, search]);

  useEffect(() => {
    if (user && isAdmin) {
      fetchUsers(1, statusFilter, search);
    }
  }, [user, isAdmin, statusFilter, search]);

  const handleSearch = () => {
    setSearch(searchInput);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") handleSearch();
  };

  const handlePageChange = (newPage: number) => {
    fetchUsers(newPage, statusFilter, search);
  };

  const performAction = async (uid: string, action: "suspend" | "activate" | "reset_password") => {
    setActionLoading(true);
    try {
      const token = getToken();
      const res = await fetch("/api/users", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ uid, action }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Action failed");

      if (action === "reset_password") {
        toast.success(`Password reset email sent to user.`);
      } else if (action === "suspend") {
        toast.success("Account suspended successfully.");
        setSelectedUser((prev) => prev ? { ...prev, accountStatus: "suspended" } : null);
      } else if (action === "activate") {
        toast.success("Account activated successfully.");
        setSelectedUser((prev) => prev ? { ...prev, accountStatus: "active" } : null);
      }
      fetchUsers(pagination.page, statusFilter, search);
    } catch (e: any) {
      toast.error(e.message || "Action failed");
    } finally {
      setActionLoading(false);
    }
  };

  const exportCsv = () => {
    if (users.length === 0) {
      toast.error("No users to export");
      return;
    }
    const headers = ["UID", "Full Name", "Email", "Account Number", "Balance", "Status", "KYC Status", "Join Date"];
    const rows = users.map((u) => [
      u.uid,
      u.fullName,
      u.email,
      u.accountNumber,
      u.balance.toFixed(2),
      u.accountStatus,
      u.kycStatus,
      u.createdAt ? new Date(u.createdAt).toLocaleDateString() : "N/A",
    ]);
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `users-export-${new Date().toISOString().split("T")[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    toast.success("CSV exported successfully");
  };

  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-100">
        <Loader2 className="w-10 h-10 text-indigo-600 animate-spin" />
      </div>
    );
  }

  if (!user || !isAdmin) return null;

  return (
    <div className="flex min-h-screen bg-slate-100">
      <Toaster
        position="top-right"
        toastOptions={{
          style: { borderRadius: "12px", background: "#1e293b", color: "#f1f5f9", fontSize: "14px", padding: "12px 16px" },
        }}
      />
      <Sidebar />
      <div className="flex-1 flex flex-col min-h-screen overflow-hidden">
        <header className="h-16 bg-white/80 backdrop-blur-sm border-b border-gray-200/60 flex items-center justify-between px-8 flex-shrink-0">
          <h1 className="text-lg font-bold text-gray-900">User Management</h1>
          <div className="flex items-center gap-3">
            <span className="text-sm text-gray-500">{user.email}</span>
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center">
              <span className="text-xs font-bold text-white">{user.email?.charAt(0).toUpperCase() || "A"}</span>
            </div>
          </div>
        </header>

        <main className="flex-1 p-8 overflow-auto">
          <div className="animate-fade-in">
            {/* Page header */}
            <div className="flex items-center justify-between mb-6">
              <div>
                <h1 className="text-2xl font-bold text-gray-900">User Management</h1>
                <p className="text-sm text-gray-500 mt-0.5">
                  {pagination.total} total users registered
                </p>
              </div>
              <button
                onClick={exportCsv}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-white border border-gray-200 text-sm font-semibold text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-all shadow-sm"
              >
                <Download className="w-4 h-4" />
                Export CSV
              </button>
            </div>

            {/* Filters */}
            <div className="card mb-6">
              <div className="flex flex-col sm:flex-row gap-4">
                <div className="relative flex-1 flex gap-2">
                  <div className="relative flex-1">
                    <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input
                      type="text"
                      placeholder="Search by name, email, or account number…"
                      value={searchInput}
                      onChange={(e) => setSearchInput(e.target.value)}
                      onKeyDown={handleKeyDown}
                      className="input-field pl-10"
                    />
                  </div>
                  <button
                    onClick={handleSearch}
                    className="px-4 py-2.5 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition-colors"
                  >
                    Search
                  </button>
                </div>
                <div className="flex items-center gap-2">
                  <Filter className="w-4 h-4 text-gray-400 flex-shrink-0" />
                  <select
                    value={statusFilter}
                    onChange={(e) => { setStatusFilter(e.target.value); setPagination((p) => ({ ...p, page: 1 })); }}
                    className="input-field sm:w-44"
                  >
                    <option value="all">All Statuses</option>
                    <option value="active">Active</option>
                    <option value="pending">Pending</option>
                    <option value="suspended">Suspended</option>
                    <option value="closed">Closed</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Table */}
            <div className="card overflow-hidden p-0">
              {fetching ? (
                <div className="flex items-center justify-center py-24">
                  <Loader2 className="w-8 h-8 text-indigo-500 animate-spin" />
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="table-header">
                        <th>User</th>
                        <th>Account #</th>
                        <th className="text-right">Balance</th>
                        <th className="text-center">Status</th>
                        <th className="text-center">KYC</th>
                        <th>Join Date</th>
                        <th className="text-center">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {users.map((u) => (
                        <tr
                          key={u.uid}
                          className="table-row cursor-pointer"
                          onClick={() => router.push(`/dashboard/users/${u.uid}`)}
                        >
                          <td>
                            <div className="flex items-center gap-3">
                              <Avatar user={u} />
                              <div>
                                <p className="font-semibold text-gray-900 hover:text-indigo-600 transition-colors">
                                  {u.fullName || "—"}
                                </p>
                                <p className="text-xs text-gray-500">{u.email}</p>
                              </div>
                            </div>
                          </td>
                          <td className="font-mono text-xs text-gray-600">{u.accountNumber || u.tccCode || "—"}</td>
                          <td className="text-right font-semibold text-gray-900">
                            ${u.balance.toLocaleString("en-US", { minimumFractionDigits: 2 })}
                          </td>
                          <td className="text-center">
                            <StatusBadge status={u.accountStatus} />
                          </td>
                          <td className="text-center">
                            <KycBadge status={u.kycStatus} />
                          </td>
                          <td className="text-gray-500 text-xs">
                            {u.createdAt ? new Date(u.createdAt).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" }) : "—"}
                          </td>
                          <td className="text-center" onClick={(e) => e.stopPropagation()}>
                            <button
                              onClick={() => router.push(`/dashboard/users/${u.uid}`)}
                              className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold rounded-lg transition-colors shadow-sm"
                            >
                              Manage →
                            </button>
                          </td>
                        </tr>
                      ))}
                      {users.length === 0 && (
                        <tr>
                          <td colSpan={6} className="py-16 text-center">
                            <Search className="w-10 h-10 text-gray-300 mx-auto mb-3" />
                            <p className="text-gray-500 font-medium">No users found</p>
                            <p className="text-gray-400 text-xs mt-1">Try adjusting your search or filter</p>
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              )}

              {/* Pagination */}
              {pagination.totalPages > 1 && (
                <div className="flex items-center justify-between px-6 py-4 border-t border-gray-100">
                  <p className="text-sm text-gray-500">
                    Showing {((pagination.page - 1) * pagination.pageSize) + 1}–{Math.min(pagination.page * pagination.pageSize, pagination.total)} of {pagination.total} users
                  </p>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => handlePageChange(pagination.page - 1)}
                      disabled={pagination.page <= 1 || fetching}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                    >
                      <ChevronLeft className="w-4 h-4" />
                      Previous
                    </button>
                    <span className="text-sm font-semibold text-gray-700 px-2">
                      {pagination.page} / {pagination.totalPages}
                    </span>
                    <button
                      onClick={() => handlePageChange(pagination.page + 1)}
                      disabled={pagination.page >= pagination.totalPages || fetching}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                    >
                      Next
                      <ChevronRight className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </main>
      </div>

      {/* User Detail Side Drawer */}
      {selectedUser && (
        <div className="fixed inset-0 z-50 flex">
          {/* Backdrop */}
          <div
            className="flex-1 bg-black/40 backdrop-blur-sm"
            onClick={() => setSelectedUser(null)}
          />
          {/* Drawer */}
          <div className="w-full max-w-md bg-white shadow-2xl flex flex-col h-full overflow-y-auto">
            {/* Drawer header */}
            <div className="flex items-center justify-between px-6 py-5 border-b border-gray-100">
              <h2 className="text-lg font-bold text-gray-900">User Details</h2>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => { setSelectedUser(null); router.push(`/dashboard/users/${selectedUser.uid}`); }}
                  className="flex items-center gap-1.5 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold rounded-lg transition-colors"
                >
                  Full Control Panel →
                </button>
                <button
                  onClick={() => setSelectedUser(null)}
                  className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center hover:bg-gray-200 transition-colors"
                >
                  <X className="w-4 h-4 text-gray-500" />
                </button>
              </div>
            </div>

            {/* Profile section */}
            <div className="px-6 py-6 border-b border-gray-100">
              <div className="flex items-center gap-4 mb-5">
                <div className="scale-150 origin-left ml-2">
                  <Avatar user={selectedUser} />
                </div>
                <div className="ml-4">
                  <h3 className="text-xl font-bold text-gray-900">{selectedUser.fullName || "—"}</h3>
                  <p className="text-sm text-gray-500">{selectedUser.email}</p>
                  <div className="flex items-center gap-2 mt-2">
                    <StatusBadge status={selectedUser.accountStatus} />
                    <KycBadge status={selectedUser.kycStatus} />
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 gap-3">
                <InfoRow icon={User} label="UID" value={selectedUser.uid} mono />
                <InfoRow icon={Mail} label="Email" value={selectedUser.email} />
                <InfoRow icon={CreditCard} label="Account #" value={selectedUser.accountNumber || selectedUser.tccCode || "—"} mono />
                <InfoRow
                  icon={DollarSign}
                  label="Balance"
                  value={`$${selectedUser.balance.toLocaleString("en-US", { minimumFractionDigits: 2 })}`}
                  valueClass="text-emerald-600 font-bold"
                />
                {selectedUser.phone && <InfoRow icon={Shield} label="Phone" value={selectedUser.phone} />}
                {selectedUser.address && <InfoRow icon={Shield} label="Address" value={selectedUser.address} />}
                <InfoRow
                  icon={Calendar}
                  label="Join Date"
                  value={selectedUser.createdAt ? new Date(selectedUser.createdAt).toLocaleDateString("en-US", { month: "long", day: "numeric", year: "numeric" }) : "—"}
                />
                <div className="flex items-center gap-3 py-2.5 px-3 rounded-xl bg-gray-50">
                  <div className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center flex-shrink-0">
                    <ArrowLeftRight className="w-4 h-4 text-gray-500" />
                  </div>
                  <div className="flex-1">
                    <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Can Transact</p>
                    <p className={`text-sm font-semibold ${selectedUser.canTransact ? "text-emerald-600" : "text-rose-600"}`}>
                      {selectedUser.canTransact ? "Yes" : "No"}
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Action buttons */}
            <div className="px-6 py-5 flex-1">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-4">Actions</p>
              <div className="flex flex-col gap-3">
                {selectedUser.accountStatus !== "suspended" ? (
                  <button
                    onClick={() => performAction(selectedUser.uid, "suspend")}
                    disabled={actionLoading}
                    className="flex items-center gap-3 w-full px-4 py-3 rounded-xl bg-rose-50 text-rose-700 border border-rose-200 hover:bg-rose-100 transition-colors font-semibold text-sm disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <ShieldBan className="w-4 h-4" />
                    Suspend Account
                    {actionLoading && <Loader2 className="w-4 h-4 ml-auto animate-spin" />}
                  </button>
                ) : (
                  <button
                    onClick={() => performAction(selectedUser.uid, "activate")}
                    disabled={actionLoading}
                    className="flex items-center gap-3 w-full px-4 py-3 rounded-xl bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100 transition-colors font-semibold text-sm disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <RotateCcw className="w-4 h-4" />
                    Activate Account
                    {actionLoading && <Loader2 className="w-4 h-4 ml-auto animate-spin" />}
                  </button>
                )}

                {selectedUser.accountStatus === "pending" && (
                  <button
                    onClick={() => performAction(selectedUser.uid, "activate")}
                    disabled={actionLoading}
                    className="flex items-center gap-3 w-full px-4 py-3 rounded-xl bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100 transition-colors font-semibold text-sm disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <CheckCircle2 className="w-4 h-4" />
                    Activate Account
                    {actionLoading && <Loader2 className="w-4 h-4 ml-auto animate-spin" />}
                  </button>
                )}

                <button
                  onClick={() => performAction(selectedUser.uid, "reset_password")}
                  disabled={actionLoading}
                  className="flex items-center gap-3 w-full px-4 py-3 rounded-xl bg-amber-50 text-amber-700 border border-amber-200 hover:bg-amber-100 transition-colors font-semibold text-sm disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <KeyRound className="w-4 h-4" />
                  Reset Password
                  {actionLoading && <Loader2 className="w-4 h-4 ml-auto animate-spin" />}
                </button>

                <button
                  onClick={() => {
                    router.push(`/dashboard/transactions?userId=${selectedUser.uid}`);
                  }}
                  className="flex items-center gap-3 w-full px-4 py-3 rounded-xl bg-indigo-50 text-indigo-700 border border-indigo-200 hover:bg-indigo-100 transition-colors font-semibold text-sm"
                >
                  <ArrowLeftRight className="w-4 h-4" />
                  View Transactions
                </button>
              </div>
            </div>

            {/* Drawer footer */}
            <div className="px-6 py-4 border-t border-gray-100 bg-gray-50/50">
              <p className="text-xs text-gray-400 text-center">
                Last updated: {selectedUser.createdAt ? new Date(selectedUser.createdAt).toLocaleDateString() : "N/A"}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function InfoRow({
  icon: Icon,
  label,
  value,
  mono = false,
  valueClass = "",
}: {
  icon: React.ElementType;
  label: string;
  value: string;
  mono?: boolean;
  valueClass?: string;
}) {
  return (
    <div className="flex items-center gap-3 py-2.5 px-3 rounded-xl bg-gray-50">
      <div className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center flex-shrink-0">
        <Icon className="w-4 h-4 text-gray-500" />
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">{label}</p>
        <p className={`text-sm font-medium text-gray-900 truncate ${mono ? "font-mono" : ""} ${valueClass}`}>{value}</p>
      </div>
    </div>
  );
}
