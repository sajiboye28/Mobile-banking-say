"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/AuthContext";
import Sidebar from "@/components/Sidebar";

const getToken = () => typeof window !== 'undefined' ? localStorage.getItem('pb_admin_token') ?? '' : '';
import { Toaster } from "react-hot-toast";
import toast from "react-hot-toast";
import {
  CheckCircle2, XCircle, ChevronDown, ChevronUp,
  FileText, User, Calendar, MapPin, Hash, X,
  Loader2, AlertTriangle, Shield, Eye,
} from "lucide-react";

interface KycSubmission {
  id: string;
  userId: string;
  userName: string;
  userEmail: string;
  documentType: string;
  status: string;
  submittedAt: string | null;
  reviewedAt: string | null;
  rejectionReason: string | null;
  firstName: string | null;
  lastName: string | null;
  dateOfBirth: string | null;
  address: string | null;
  city: string | null;
  country: string | null;
  postalCode: string | null;
  documentNumber: string | null;
  documentExpiry: string | null;
  documentFrontUrl: string | null;
  documentBackUrl: string | null;
  selfieUrl: string | null;
}

interface Counts {
  pending: number;
  approved: number;
  rejected: number;
  all: number;
}

const TAB_OPTIONS = [
  { value: "pending", label: "Pending" },
  { value: "approved", label: "Approved" },
  { value: "rejected", label: "Rejected" },
  { value: "all", label: "All" },
];

const STATUS_STYLES: Record<string, string> = {
  pending: "bg-amber-50 text-amber-700 ring-1 ring-amber-200",
  approved: "bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200",
  rejected: "bg-rose-50 text-rose-700 ring-1 ring-rose-200",
};

function StatusBadge({ status }: { status: string }) {
  return (
    <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold ${STATUS_STYLES[status] || "bg-gray-100 text-gray-600 ring-1 ring-gray-200"}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${status === "approved" ? "bg-emerald-500" : status === "rejected" ? "bg-rose-500" : "bg-amber-500"}`} />
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  );
}

function DocImage({ url, label }: { url: string | null; label: string }) {
  if (!url) return null;
  return (
    <div className="flex flex-col gap-1">
      <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">{label}</p>
      <a href={url} target="_blank" rel="noopener noreferrer" className="block">
        <img
          src={url}
          alt={label}
          className="w-full max-h-40 object-cover rounded-xl border border-gray-200 hover:border-indigo-300 transition-colors cursor-zoom-in"
        />
      </a>
    </div>
  );
}

function KycCard({
  submission,
  onApprove,
  onReject,
  loading,
}: {
  submission: KycSubmission;
  onApprove: (id: string) => void;
  onReject: (submission: KycSubmission) => void;
  loading: string | null;
}) {
  const [expanded, setExpanded] = useState(false);
  const isLoading = loading === submission.id;

  return (
    <div className="card overflow-hidden p-0 transition-all duration-200">
      {/* Card header — always visible */}
      <div
        className="flex items-center gap-4 px-6 py-4 cursor-pointer hover:bg-gray-50/60 transition-colors"
        onClick={() => setExpanded(!expanded)}
      >
        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500 to-blue-500 flex items-center justify-center flex-shrink-0">
          <FileText className="w-5 h-5 text-white" />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-0.5">
            <p className="font-semibold text-gray-900 truncate">{submission.userName || "Unknown User"}</p>
            <StatusBadge status={submission.status} />
          </div>
          <p className="text-xs text-gray-500 truncate">{submission.userEmail}</p>
        </div>
        <div className="flex items-center gap-4 ml-2 flex-shrink-0">
          <div className="text-right hidden sm:block">
            <p className="text-xs font-semibold text-gray-600">{submission.documentType}</p>
            <p className="text-xs text-gray-400">
              {submission.submittedAt ? new Date(submission.submittedAt).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" }) : "—"}
            </p>
          </div>
          {expanded ? (
            <ChevronUp className="w-5 h-5 text-gray-400" />
          ) : (
            <ChevronDown className="w-5 h-5 text-gray-400" />
          )}
        </div>
      </div>

      {/* Expanded details */}
      {expanded && (
        <div className="border-t border-gray-100 px-6 py-5">
          {/* Submitted fields */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-5">
            {submission.firstName && (
              <FieldRow icon={User} label="First Name" value={submission.firstName} />
            )}
            {submission.lastName && (
              <FieldRow icon={User} label="Last Name" value={submission.lastName} />
            )}
            {submission.dateOfBirth && (
              <FieldRow icon={Calendar} label="Date of Birth" value={submission.dateOfBirth} />
            )}
            {submission.documentNumber && (
              <FieldRow icon={Hash} label="Document Number" value={submission.documentNumber} mono />
            )}
            {submission.documentExpiry && (
              <FieldRow icon={Calendar} label="Document Expiry" value={submission.documentExpiry} />
            )}
            {submission.address && (
              <FieldRow icon={MapPin} label="Address" value={submission.address} />
            )}
            {submission.city && (
              <FieldRow icon={MapPin} label="City" value={submission.city} />
            )}
            {submission.country && (
              <FieldRow icon={MapPin} label="Country" value={submission.country} />
            )}
            {submission.postalCode && (
              <FieldRow icon={MapPin} label="Postal Code" value={submission.postalCode} />
            )}
          </div>

          {/* Document images */}
          {(submission.documentFrontUrl || submission.documentBackUrl || submission.selfieUrl) && (
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-5">
              <DocImage url={submission.documentFrontUrl} label="Document Front" />
              <DocImage url={submission.documentBackUrl} label="Document Back" />
              <DocImage url={submission.selfieUrl} label="Selfie" />
            </div>
          )}

          {/* Rejection reason if rejected */}
          {submission.status === "rejected" && submission.rejectionReason && (
            <div className="flex gap-3 p-4 rounded-xl bg-rose-50 border border-rose-200 mb-5">
              <AlertTriangle className="w-5 h-5 text-rose-500 flex-shrink-0 mt-0.5" />
              <div>
                <p className="text-xs font-semibold text-rose-700 uppercase tracking-wide mb-1">Rejection Reason</p>
                <p className="text-sm text-rose-700">{submission.rejectionReason}</p>
              </div>
            </div>
          )}

          {/* Review info */}
          {submission.reviewedAt && (
            <p className="text-xs text-gray-400 mb-4">
              Reviewed on {new Date(submission.reviewedAt).toLocaleDateString("en-US", { month: "long", day: "numeric", year: "numeric" })}
            </p>
          )}

          {/* Action buttons — only for pending */}
          {submission.status === "pending" && (
            <div className="flex gap-3 pt-2">
              <button
                onClick={(e) => { e.stopPropagation(); onApprove(submission.id); }}
                disabled={isLoading}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-600 text-white text-sm font-semibold hover:bg-emerald-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <CheckCircle2 className="w-4 h-4" />}
                Approve
              </button>
              <button
                onClick={(e) => { e.stopPropagation(); onReject(submission); }}
                disabled={isLoading}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-rose-600 text-white text-sm font-semibold hover:bg-rose-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <XCircle className="w-4 h-4" />}
                Reject
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function FieldRow({
  icon: Icon,
  label,
  value,
  mono = false,
}: {
  icon: React.ElementType;
  label: string;
  value: string;
  mono?: boolean;
}) {
  return (
    <div className="flex items-start gap-2.5 p-3 rounded-xl bg-gray-50">
      <div className="w-7 h-7 rounded-lg bg-gray-100 flex items-center justify-center flex-shrink-0 mt-0.5">
        <Icon className="w-3.5 h-3.5 text-gray-500" />
      </div>
      <div>
        <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">{label}</p>
        <p className={`text-sm text-gray-900 ${mono ? "font-mono" : "font-medium"}`}>{value}</p>
      </div>
    </div>
  );
}

export default function KycPage() {
  const { user, isAdmin, loading: authLoading } = useAuth();
  const router = useRouter();

  const [submissions, setSubmissions] = useState<KycSubmission[]>([]);
  const [counts, setCounts] = useState<Counts>({ pending: 0, approved: 0, rejected: 0, all: 0 });
  const [activeTab, setActiveTab] = useState("pending");
  const [fetching, setFetching] = useState(false);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  // Reject modal state
  const [rejectTarget, setRejectTarget] = useState<KycSubmission | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [rejecting, setRejecting] = useState(false);

  useEffect(() => {
    if (!authLoading && (!user || !isAdmin)) {
      router.push("/login");
    }
  }, [user, isAdmin, authLoading, router]);

  const fetchSubmissions = useCallback(async (status: string) => {
    if (!user) return;
    setFetching(true);
    try {
      const token = getToken();
      const res = await fetch(`/api/kyc?status=${status}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) throw new Error("Failed to fetch KYC submissions");
      const data = await res.json();
      setSubmissions(data.submissions);
      setCounts(data.counts);
    } catch {
      toast.error("Failed to load KYC submissions");
    } finally {
      setFetching(false);
    }
  }, [user]);

  useEffect(() => {
    if (user && isAdmin) {
      fetchSubmissions(activeTab);
    }
  }, [user, isAdmin, activeTab, fetchSubmissions]);

  const handleApprove = async (id: string) => {
    setActionLoading(id);
    try {
      const token = getToken();
      const res = await fetch("/api/kyc", {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify({ id, action: "approve" }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Approval failed");
      toast.success("KYC submission approved. User notified.");
      fetchSubmissions(activeTab);
    } catch (e: any) {
      toast.error(e.message || "Approval failed");
    } finally {
      setActionLoading(null);
    }
  };

  const handleRejectConfirm = async () => {
    if (!rejectTarget || !rejectReason.trim()) return;
    setRejecting(true);
    try {
      const token = getToken();
      const res = await fetch("/api/kyc", {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify({ id: rejectTarget.id, action: "reject", reason: rejectReason.trim() }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Rejection failed");
      toast.success("KYC submission rejected. User notified.");
      setRejectTarget(null);
      setRejectReason("");
      fetchSubmissions(activeTab);
    } catch (e: any) {
      toast.error(e.message || "Rejection failed");
    } finally {
      setRejecting(false);
    }
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
          <h1 className="text-lg font-bold text-gray-900">KYC Verification</h1>
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
            <div className="mb-6">
              <h1 className="text-2xl font-bold text-gray-900">KYC Verification</h1>
              <p className="text-sm text-gray-500 mt-0.5">Review and process identity verification submissions</p>
            </div>

            {/* Tab filter */}
            <div className="flex gap-1 p-1 bg-white/80 rounded-2xl shadow-sm border border-gray-200/60 w-fit mb-6">
              {TAB_OPTIONS.map((tab) => {
                const count = counts[tab.value as keyof Counts];
                const isActive = activeTab === tab.value;
                return (
                  <button
                    key={tab.value}
                    onClick={() => setActiveTab(tab.value)}
                    className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all duration-200 ${
                      isActive
                        ? "bg-indigo-600 text-white shadow-sm"
                        : "text-gray-500 hover:text-gray-700 hover:bg-gray-50"
                    }`}
                  >
                    {tab.label}
                    {count > 0 && (
                      <span className={`text-xs px-1.5 py-0.5 rounded-full font-bold ${
                        isActive
                          ? "bg-white/20 text-white"
                          : tab.value === "pending"
                          ? "bg-amber-100 text-amber-700"
                          : tab.value === "approved"
                          ? "bg-emerald-100 text-emerald-700"
                          : tab.value === "rejected"
                          ? "bg-rose-100 text-rose-700"
                          : "bg-gray-100 text-gray-600"
                      }`}>
                        {count}
                      </span>
                    )}
                  </button>
                );
              })}
            </div>

            {/* Content */}
            {fetching ? (
              <div className="flex items-center justify-center py-24">
                <div className="flex flex-col items-center gap-3">
                  <Loader2 className="w-8 h-8 text-indigo-500 animate-spin" />
                  <p className="text-sm text-gray-500">Loading submissions…</p>
                </div>
              </div>
            ) : submissions.length === 0 ? (
              <div className="card flex flex-col items-center py-20">
                <div className="w-16 h-16 rounded-2xl bg-gray-100 flex items-center justify-center mb-4">
                  <Shield className="w-8 h-8 text-gray-400" />
                </div>
                <p className="text-lg font-semibold text-gray-700 mb-1">No submissions found</p>
                <p className="text-sm text-gray-400">
                  {activeTab === "pending" ? "All KYC submissions have been reviewed." : `No ${activeTab} submissions.`}
                </p>
              </div>
            ) : (
              <div className="flex flex-col gap-4">
                {submissions.map((submission) => (
                  <KycCard
                    key={submission.id}
                    submission={submission}
                    onApprove={handleApprove}
                    onReject={setRejectTarget}
                    loading={actionLoading}
                  />
                ))}
              </div>
            )}
          </div>
        </main>
      </div>

      {/* Reject Modal */}
      {rejectTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
            <div className="flex items-center justify-between mb-5">
              <div>
                <h3 className="text-lg font-bold text-gray-900">Reject KYC Submission</h3>
                <p className="text-sm text-gray-500 mt-0.5">
                  For: <span className="font-semibold text-rose-600">{rejectTarget.userName}</span>
                </p>
              </div>
              <button
                onClick={() => { setRejectTarget(null); setRejectReason(""); }}
                className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center hover:bg-gray-200 transition-colors"
              >
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>

            <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 mb-5">
              <div className="flex gap-3">
                <AlertTriangle className="w-5 h-5 text-rose-500 flex-shrink-0 mt-0.5" />
                <p className="text-sm text-rose-700">
                  The user will be notified of this rejection with the reason you provide below. They will need to resubmit their documents.
                </p>
              </div>
            </div>

            <div className="mb-5">
              <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">
                Rejection Reason <span className="text-rose-500">*</span>
              </label>
              <textarea
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                placeholder="e.g. Document image is blurry or unclear. Please resubmit a clear photo of your document."
                rows={4}
                className="input-field resize-none"
              />
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => { setRejectTarget(null); setRejectReason(""); }}
                className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleRejectConfirm}
                disabled={rejecting || !rejectReason.trim()}
                className="flex-1 py-2.5 rounded-xl bg-rose-600 text-white text-sm font-semibold hover:bg-rose-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {rejecting ? <Loader2 className="w-4 h-4 animate-spin" /> : <XCircle className="w-4 h-4" />}
                {rejecting ? "Rejecting…" : "Confirm Rejection"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
