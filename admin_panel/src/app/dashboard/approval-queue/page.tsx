"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import toast from "react-hot-toast";
import { CheckCircle2, XCircle, ExternalLink, UserCheck, Clock, Inbox, RefreshCw } from "lucide-react";

const getToken = () => typeof window !== 'undefined' ? localStorage.getItem('pb_admin_token') ?? '' : '';
const apiCall = async (url: string, options: RequestInit = {}) => {
  const res = await fetch(url, {
    ...options,
    headers: { 'Authorization': `Bearer ${getToken()}`, 'Content-Type': 'application/json', ...(options.headers ?? {}) }
  });
  if (!res.ok) throw new Error((await res.json().catch(() => ({}))).error || res.statusText);
  return res.json();
};

interface UserData {
  uid: string;
  fullName: string;
  email: string;
  balance: number;
  accountStatus: string;
  createdAt: any;
}

export default function ApprovalQueuePage() {
  const [pendingUsers, setPendingUsers] = useState<UserData[]>([]);
  const [loading, setLoading] = useState(true);

  const loadPending = async () => {
    setLoading(true);
    try {
      const data = await apiCall('/api/users?status=pending&limit=200');
      setPendingUsers(data.users ?? data.items ?? []);
    } catch {
      toast.error("Failed to load pending users.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadPending(); }, []);

  const approveUser = async (uid: string) => {
    try {
      await apiCall(`/api/users/${uid}/status`, {
        method: 'POST',
        body: JSON.stringify({ status: 'active', canTransact: true }),
      });
      toast.success("User account approved and activated.");
      await loadPending();
    } catch {
      toast.error("Failed to approve user.");
    }
  };

  const rejectUser = async (uid: string) => {
    try {
      await apiCall(`/api/users/${uid}/status`, {
        method: 'POST',
        body: JSON.stringify({ status: 'closed', canTransact: false }),
      });
      toast.success("User account rejected and closed.");
      await loadPending();
    } catch {
      toast.error("Failed to reject user.");
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Approval Queue</h1>
          <p className="text-sm text-gray-500 mt-0.5">{pendingUsers.length} pending review</p>
        </div>
        <button
          onClick={loadPending}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-white border border-gray-200 text-sm font-semibold text-gray-700 hover:bg-gray-50 transition-colors shadow-sm"
        >
          <RefreshCw className="w-4 h-4" />
          Refresh
        </button>
      </div>

      {loading ? (
        <div className="card text-center py-16">
          <RefreshCw className="w-10 h-10 text-indigo-400 animate-spin mx-auto mb-3" />
          <p className="text-gray-500">Loading pending accounts...</p>
        </div>
      ) : pendingUsers.length === 0 ? (
        <div className="card text-center py-16">
          <div className="w-20 h-20 mx-auto mb-5 rounded-2xl bg-gradient-to-br from-emerald-50 to-green-100 flex items-center justify-center">
            <UserCheck className="w-10 h-10 text-emerald-500" />
          </div>
          <h2 className="text-xl font-bold text-gray-800">All Clear</h2>
          <p className="text-gray-500 mt-2 max-w-sm mx-auto">
            No pending accounts to review. New registration requests will appear here automatically.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {pendingUsers.map((user) => (
            <div key={user.uid} className="card-hover group">
              {/* Card top accent */}
              <div className="h-1 -mx-6 -mt-6 mb-5 rounded-t-2xl bg-gradient-to-r from-amber-400 to-orange-400" />

              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-amber-400 to-orange-500 flex items-center justify-center text-white font-bold">
                    {user.fullName?.charAt(0).toUpperCase() || "?"}
                  </div>
                  <div>
                    <h3 className="font-bold text-gray-900">{user.fullName}</h3>
                    <p className="text-sm text-gray-500">{user.email}</p>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-4 text-xs text-gray-400 mb-5 p-3 bg-slate-50 rounded-xl">
                <div className="flex items-center gap-1.5">
                  <Clock className="w-3.5 h-3.5" />
                  <span>
                    {user.createdAt ? new Date(user.createdAt).toLocaleDateString() : "N/A"}
                  </span>
                </div>
                <span className="status-badge-pending">
                  <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
                  Pending
                </span>
              </div>

              <p className="text-xs text-gray-400 mb-4 font-mono truncate">
                UID: {user.uid}
              </p>

              <div className="flex gap-2">
                <button
                  onClick={() => approveUser(user.uid)}
                  className="btn-success flex-1 text-sm py-2.5 inline-flex items-center justify-center gap-1.5"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  Approve
                </button>
                <button
                  onClick={() => rejectUser(user.uid)}
                  className="btn-danger flex-1 text-sm py-2.5 inline-flex items-center justify-center gap-1.5"
                >
                  <XCircle className="w-4 h-4" />
                  Reject
                </button>
                <Link
                  href={`/dashboard/users/${user.uid}`}
                  className="btn-secondary text-sm py-2.5 inline-flex items-center justify-center gap-1.5 px-3"
                >
                  <ExternalLink className="w-4 h-4" />
                </Link>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
