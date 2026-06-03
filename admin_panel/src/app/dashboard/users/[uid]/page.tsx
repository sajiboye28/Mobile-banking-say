"use client";

import { useEffect, useState, useRef, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import toast from "react-hot-toast";
import Link from "next/link";
import {
  ArrowLeft, User, Save, RefreshCw, CheckCircle2, Clock,
  XCircle, Calendar, Hash, ArrowDownRight, ArrowUpRight,
  Loader2, Trash2, Mail, Bell, DollarSign, Phone, MapPin,
  CreditCard, Shield, Send, AlertTriangle, Pencil, PlusCircle,
  Building, Globe, FileText, Camera, X, Key, Ban, Lock,
  Copy, Check, ChevronDown, ToggleLeft, ToggleRight, LogOut,
  ShieldCheck, ShieldAlert, Fingerprint, MoreHorizontal, Eye,
} from "lucide-react";

// ─── Interfaces ──────────────────────────────────────────────────────────────

interface UserData {
  uid: string;
  fullName: string;
  email: string;
  phone?: string;
  address?: string;
  city?: string;
  country?: string;
  postalCode?: string;
  balance: number;
  profilePicUrl?: string;
  accountStatus: string;
  accountNumber?: string;
  accountType?: string;
  canTransact: boolean;
  tccCode?: string;
  kycStatus?: string;
  two_fa_enabled?: boolean;
  login_alerts_enabled?: boolean;
  createdAt: any;
  updatedAt: any;
  lastLoginAt?: any;
  fcmToken?: string;
}

interface TransactionData {
  transactionId: string;
  userId: string;
  amount: number;
  type: string;
  timestamp: any;
  description: string;
  status: string;
  relatedUserName?: string;
}

interface NotificationData {
  id: string;
  title: string;
  body: string;
  type: string;
  isRead: boolean;
  createdAt: any;
}

interface OtpInfo {
  id: string;
  code: string;
  expiresAt: string;
  used: boolean;
  created: string;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

const getToken = () => typeof window !== 'undefined' ? localStorage.getItem('pb_admin_token') ?? '' : '';

const apiCall = async (path: string, options: RequestInit = {}) => {
  return fetch(path, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${getToken()}`,
      ...((options.headers as Record<string, string>) || {}),
    },
  });
};

const uploadFile = async (path: string, formData: FormData) => {
  return fetch(path, {
    method: "POST",
    headers: { Authorization: `Bearer ${getToken()}` },
    body: formData,
  });
};

const fmt = (n: number) =>
  new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(n);

const fmtDate = (val: any): string => {
  if (!val) return "—";
  if (val._seconds) return new Date(val._seconds * 1000).toLocaleString();
  if (typeof val === "string") return new Date(val).toLocaleString();
  if (val instanceof Date) return val.toLocaleString();
  return "—";
};

const initials = (name: string) =>
  name
    .split(" ")
    .map((w) => w[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);

const statusColor: Record<string, string> = {
  active: "bg-emerald-100 text-emerald-700 border-emerald-200",
  pending: "bg-amber-100 text-amber-700 border-amber-200",
  suspended: "bg-red-100 text-red-700 border-red-200",
  closed: "bg-gray-100 text-gray-600 border-gray-200",
  frozen: "bg-blue-100 text-blue-700 border-blue-200",
};

const statusBorder: Record<string, string> = {
  active: "border-t-emerald-500",
  pending: "border-t-amber-400",
  suspended: "border-t-red-500",
  closed: "border-t-gray-400",
  frozen: "border-t-blue-500",
};

const kycColor: Record<string, string> = {
  approved: "bg-emerald-100 text-emerald-700",
  verified: "bg-emerald-100 text-emerald-700", // legacy alias kept for safety
  pending: "bg-amber-100 text-amber-700",
  rejected: "bg-red-100 text-red-700",
  not_submitted: "bg-gray-100 text-gray-500",
  unverified: "bg-gray-100 text-gray-500",
};

// ─── Sub-components ───────────────────────────────────────────────────────────

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);
  const copy = () => {
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };
  return (
    <button onClick={copy} className="ml-1.5 text-gray-400 hover:text-indigo-600 transition-colors">
      {copied ? <Check size={13} className="text-emerald-500" /> : <Copy size={13} />}
    </button>
  );
}

function Toggle({
  checked,
  onChange,
  disabled,
}: {
  checked: boolean;
  onChange: () => void;
  disabled?: boolean;
}) {
  return (
    <button
      onClick={onChange}
      disabled={disabled}
      className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none ${
        checked ? "bg-indigo-600" : "bg-gray-200"
      } ${disabled ? "opacity-50 cursor-not-allowed" : "cursor-pointer"}`}
    >
      <span
        className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform ${
          checked ? "translate-x-6" : "translate-x-1"
        }`}
      />
    </button>
  );
}

function Skeleton({ className }: { className?: string }) {
  return <div className={`animate-pulse bg-gray-200 rounded-lg ${className ?? ""}`} />;
}

function LoadingSkeleton() {
  return (
    <div className="min-h-screen bg-gray-50 p-6 space-y-5">
      {/* Hero */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6 border-t-4 border-t-gray-200">
        <div className="flex items-start gap-5">
          <Skeleton className="w-24 h-24 rounded-full" />
          <div className="flex-1 space-y-3">
            <Skeleton className="h-7 w-56" />
            <Skeleton className="h-4 w-44" />
            <Skeleton className="h-4 w-36" />
            <div className="flex gap-2 mt-4">
              {[...Array(6)].map((_, i) => <Skeleton key={i} className="h-9 w-28" />)}
            </div>
          </div>
        </div>
      </div>
      {/* Status bar */}
      <Skeleton className="h-16 w-full rounded-2xl" />
      {/* Grid */}
      <div className="grid grid-cols-3 gap-5">
        <div className="col-span-2 space-y-5">
          <Skeleton className="h-64 rounded-2xl" />
          <Skeleton className="h-52 rounded-2xl" />
          <Skeleton className="h-80 rounded-2xl" />
        </div>
        <div className="space-y-5">
          <Skeleton className="h-40 rounded-2xl" />
          <Skeleton className="h-36 rounded-2xl" />
          <Skeleton className="h-48 rounded-2xl" />
          <Skeleton className="h-44 rounded-2xl" />
        </div>
      </div>
    </div>
  );
}

// ─── Modal wrapper ────────────────────────────────────────────────────────────

function Modal({
  open,
  onClose,
  title,
  children,
  width = "max-w-lg",
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  width?: string;
}) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div
        className={`relative bg-white rounded-2xl shadow-2xl w-full ${width} max-h-[90vh] overflow-y-auto`}
      >
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-700 transition-colors">
            <X size={20} />
          </button>
        </div>
        <div className="px-6 py-5">{children}</div>
      </div>
    </div>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function UserDetailPage() {
  const params = useParams();
  const router = useRouter();
  const uid = params.uid as string;

  const [user, setUser] = useState<UserData | null>(null);
  const [transactions, setTransactions] = useState<TransactionData[]>([]);
  const [notifications, setNotifications] = useState<NotificationData[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [revoking, setRevoking] = useState(false);

  // Edit personal info
  const [isEditingInfo, setIsEditingInfo] = useState(false);
  const [editForm, setEditForm] = useState({
    fullName: "",
    phone: "",
    address: "",
    city: "",
    country: "",
    postalCode: "",
    accountType: "",
  });

  // Balance
  const [balanceTab, setBalanceTab] = useState<"add" | "subtract" | "set">("add");
  const [balanceAmount, setBalanceAmount] = useState("");
  const [balanceNote, setBalanceNote] = useState("");
  const [balanceSaving, setBalanceSaving] = useState(false);

  // Profile pic
  const picInputRef = useRef<HTMLInputElement>(null);
  const [picUploading, setPicUploading] = useState(false);

  // TCC
  const [tccCode, setTccCode] = useState("");
  const [tccSaving, setTccSaving] = useState(false);
  const [latestOtp, setLatestOtp] = useState<OtpInfo | null>(null);

  // KYC
  const [kycValue, setKycValue] = useState("not_submitted");
  const [kycSaving, setKycSaving] = useState(false);

  // Modals
  const [emailModal, setEmailModal] = useState(false);
  const [notifModal, setNotifModal] = useState(false);
  const [deleteModal, setDeleteModal] = useState(false);
  const [txAddModal, setTxAddModal] = useState(false);
  const [txEditModal, setTxEditModal] = useState<TransactionData | null>(null);
  const [resetModal, setResetModal] = useState<{ link?: string } | null>(null);

  // Modal form states
  const [emailForm, setEmailForm] = useState({ subject: "", body: "" });
  const [notifForm, setNotifForm] = useState({ title: "", body: "", type: "announcement" });
  const [deleteConfirmName, setDeleteConfirmName] = useState("");
  const [txForm, setTxForm] = useState({ type: "credit", amount: "", description: "", status: "completed" });
  const [modalSaving, setModalSaving] = useState(false);

  // ── Data loading ──────────────────────────────────────────────────────────

  const loadData = useCallback(
    async (opts: { user?: boolean; transactions?: boolean } = { user: true, transactions: true }) => {
      try {
        const res = await apiCall(`/api/users/${uid}`);
        if (!res.ok) throw new Error("Failed to load user");
        const data = await res.json();
        if (opts.user !== false) {
          setUser(data.user);
          setTccCode(data.user.tccCode ?? "");
          setLatestOtp(data.latestOtp ?? null);
          setKycValue(data.user.kycStatus ?? "not_submitted");
          setEditForm({
            fullName: data.user.fullName ?? "",
            phone: data.user.phone ?? "",
            address: data.user.address ?? "",
            city: data.user.city ?? "",
            country: data.user.country ?? "",
            postalCode: data.user.postalCode ?? "",
            accountType: data.user.accountType ?? "",
          });
        }
        if (opts.transactions !== false) {
          setTransactions(data.transactions ?? []);
          setNotifications(data.notifications ?? []);
        }
      } catch (e: any) {
        toast.error(e.message ?? "Load error");
      }
    },
    [uid]
  );

  useEffect(() => {
    setLoading(true);
    loadData().finally(() => setLoading(false));
  }, [loadData]);

  const refreshUser = () => loadData({ user: true, transactions: false });
  const refreshTransactions = () => loadData({ user: false, transactions: true });

  // ── Status change ─────────────────────────────────────────────────────────

  const changeStatus = async (status: string) => {
    if (!user) return;
    setSaving(true);
    try {
      const res = await apiCall(`/api/users/${uid}/status`, {
        method: "POST",
        // frozen disables transactions the same way suspended does
        body: JSON.stringify({ status }),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      toast.success(`Status set to ${status}`);
      await refreshUser();
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setSaving(false);
    }
  };

  const toggleCanTransact = async () => {
    if (!user) return;
    setSaving(true);
    try {
      const res = await apiCall(`/api/users/${uid}`, {
        method: "PATCH",
        body: JSON.stringify({ canTransact: !user.canTransact }),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      toast.success(`Transactions ${!user.canTransact ? "enabled" : "disabled"}`);
      await refreshUser();
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setSaving(false);
    }
  };

  // ── Save personal info ────────────────────────────────────────────────────

  const savePersonalInfo = async () => {
    setSaving(true);
    try {
      const res = await apiCall(`/api/users/${uid}`, {
        method: "PATCH",
        body: JSON.stringify(editForm),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      toast.success("Profile updated");
      setIsEditingInfo(false);
      await refreshUser();
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setSaving(false);
    }
  };

  // ── Balance ───────────────────────────────────────────────────────────────

  const submitBalance = async () => {
    const amt = parseFloat(balanceAmount);
    if (isNaN(amt) || amt <= 0) return toast.error("Enter a valid amount");
    setBalanceSaving(true);
    try {
      const res = await apiCall(`/api/users/${uid}/balance`, {
        method: "POST",
        body: JSON.stringify({ action: balanceTab, amount: amt, note: balanceNote }),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      toast.success("Balance updated");
      setBalanceAmount("");
      setBalanceNote("");
      await refreshUser();
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setBalanceSaving(false);
    }
  };

  // ── Profile pic ───────────────────────────────────────────────────────────

  const handlePicChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setPicUploading(true);
    try {
      const fd = new FormData();
      fd.append("file", file);
      const res = await uploadFile(`/api/users/${uid}/profile-pic`, fd);
      if (!res.ok) throw new Error((await res.json()).error ?? "Upload failed");
      toast.success("Profile picture updated");
      await refreshUser();
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setPicUploading(false);
      e.target.value = "";
    }
  };

  // ── KYC ───────────────────────────────────────────────────────────────────

  const saveKyc = async () => {
    setKycSaving(true);
    try {
      const res = await apiCall(`/api/users/${uid}`, {
        method: "PATCH",
        body: JSON.stringify({ kycStatus: kycValue }),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      toast.success("KYC status updated");
      await refreshUser();
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setKycSaving(false);
    }
  };

  // ── TCC ───────────────────────────────────────────────────────────────────

  const saveTcc = async () => {
    setTccSaving(true);
    try {
      const res = await apiCall(`/api/send-tcc`, {
        method: "POST",
        body: JSON.stringify({ uid, tccCode }),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      toast.success("TCC saved & emailed");
      await refreshUser();
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setTccSaving(false);
    }
  };

  const generateTcc = () => {
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    let code = "";
    for (let i = 0; i < 6; i++) code += chars[Math.floor(Math.random() * chars.length)];
    setTccCode(code);
  };

  // ── Security toggles ──────────────────────────────────────────────────────

  const toggleSecurity = async (field: "two_fa_enabled" | "login_alerts_enabled", current: boolean) => {
    try {
      const res = await apiCall(`/api/users/${uid}`, {
        method: "PATCH",
        body: JSON.stringify({ [field]: !current }),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      toast.success("Setting updated");
      await refreshUser();
    } catch (e: any) {
      toast.error(e.message);
    }
  };

  // ── Password reset ────────────────────────────────────────────────────────

  const sendPasswordReset = async () => {
    try {
      const res = await apiCall(`/api/users/${uid}/reset-password`, { method: "POST" });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "Failed");
      setResetModal({ link: data.link });
    } catch (e: any) {
      toast.error(e.message);
    }
  };

  // ── Delete ────────────────────────────────────────────────────────────────

  const deleteUser = async () => {
    if (deleteConfirmName.trim().toLowerCase() !== user?.fullName?.trim().toLowerCase()) {
      return toast.error("Name does not match");
    }
    setModalSaving(true);
    try {
      const res = await apiCall(`/api/users/${uid}`, { method: "DELETE" });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      toast.success("Account deleted");
      router.push("/dashboard/users");
    } catch (e: any) {
      toast.error(e.message);
      setModalSaving(false);
    }
  };

  // ── Transactions ──────────────────────────────────────────────────────────

  const addTransaction = async () => {
    if (!txForm.amount || isNaN(parseFloat(txForm.amount))) return toast.error("Invalid amount");
    setModalSaving(true);
    try {
      const res = await apiCall(`/api/users/${uid}/transaction`, {
        method: "POST",
        body: JSON.stringify({
          type: txForm.type,
          amount: parseFloat(txForm.amount),
          description: txForm.description,
          status: txForm.status,
        }),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      toast.success("Transaction added");
      setTxAddModal(false);
      setTxForm({ type: "credit", amount: "", description: "", status: "completed" });
      await refreshTransactions();
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setModalSaving(false);
    }
  };

  const updateTransaction = async () => {
    if (!txEditModal) return;
    setModalSaving(true);
    try {
      const res = await apiCall(`/api/users/${uid}/transaction`, {
        method: "PATCH",
        body: JSON.stringify({
          transactionId: txEditModal.transactionId,
          type: txForm.type,
          amount: parseFloat(txForm.amount),
          description: txForm.description,
          status: txForm.status,
        }),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      toast.success("Transaction updated");
      setTxEditModal(null);
      await refreshTransactions();
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setModalSaving(false);
    }
  };

  const deleteTransaction = async (transactionId: string) => {
    if (!confirm("Delete this transaction?")) return;
    try {
      const res = await apiCall(`/api/users/${uid}/transaction`, {
        method: "DELETE",
        body: JSON.stringify({ transactionId }),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      toast.success("Transaction deleted");
      await refreshTransactions();
    } catch (e: any) {
      toast.error(e.message);
    }
  };

  const openEditTx = (tx: TransactionData) => {
    setTxForm({
      type: tx.type,
      amount: String(tx.amount),
      description: tx.description,
      status: tx.status,
    });
    setTxEditModal(tx);
  };

  // ── Send notification ──────────────────────────────────────────────────────

  const sendNotification = async () => {
    if (!notifForm.title || !notifForm.body) return toast.error("Title and body required");
    setModalSaving(true);
    try {
      const res = await apiCall(`/api/notify`, {
        method: "POST",
        body: JSON.stringify({ uid, ...notifForm }),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      toast.success("Notification sent");
      setNotifModal(false);
      setNotifForm({ title: "", body: "", type: "announcement" });
      await refreshTransactions();
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setModalSaving(false);
    }
  };

  // ── Send email ────────────────────────────────────────────────────────────

  const sendEmail = async () => {
    if (!emailForm.subject || !emailForm.body) return toast.error("Subject and body required");
    setModalSaving(true);
    try {
      const res = await apiCall(`/api/notify`, {
        method: "POST",
        body: JSON.stringify({ uid, title: emailForm.subject, body: emailForm.body, type: "email" }),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      toast.success("Email notification sent");
      setEmailModal(false);
      setEmailForm({ subject: "", body: "" });
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setModalSaving(false);
    }
  };

  // ─────────────────────────────────────────────────────────────────────────

  if (loading) return <LoadingSkeleton />;
  if (!user) return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <AlertTriangle size={40} className="mx-auto text-red-400 mb-3" />
        <p className="text-gray-600 font-medium">User not found</p>
        <Link href="/dashboard/users" className="mt-3 inline-block text-indigo-600 text-sm">
          Back to users
        </Link>
      </div>
    </div>
  );

  const statusKey = user.accountStatus?.toLowerCase() ?? "active";

  // ─── Render ───────────────────────────────────────────────────────────────

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Hidden file input */}
      <input
        ref={picInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={handlePicChange}
      />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6 space-y-5">

        {/* Back nav */}
        <Link
          href="/dashboard/users"
          className="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-indigo-600 transition-colors"
        >
          <ArrowLeft size={15} />
          Back to Users
        </Link>

        {/* ═══ HERO CARD ════════════════════════════════════════════════════ */}
        <div
          className={`bg-white rounded-2xl border border-gray-100 shadow-sm border-t-4 ${
            statusBorder[statusKey] ?? "border-t-gray-300"
          } p-6`}
        >
          <div className="flex flex-col sm:flex-row items-start gap-5">
            {/* Avatar */}
            <div className="relative flex-shrink-0 group">
              <button
                onClick={() => picInputRef.current?.click()}
                disabled={picUploading}
                className="block w-24 h-24 rounded-full overflow-hidden ring-4 ring-white shadow-lg focus:outline-none"
              >
                {picUploading ? (
                  <div className="w-full h-full flex items-center justify-center bg-gray-100">
                    <Loader2 size={28} className="animate-spin text-indigo-500" />
                  </div>
                ) : user.profilePicUrl ? (
                  <img
                    src={user.profilePicUrl}
                    alt={user.fullName}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-indigo-400 to-purple-500 text-white text-2xl font-bold select-none">
                    {initials(user.fullName ?? "?")}
                  </div>
                )}
                <div className="absolute inset-0 bg-black/40 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                  <Camera size={22} className="text-white" />
                </div>
              </button>
            </div>

            {/* Info */}
            <div className="flex-1 min-w-0">
              <div className="flex flex-wrap items-center gap-2 mb-1">
                <h1 className="text-2xl font-bold text-gray-900 leading-tight truncate">
                  {user.fullName}
                </h1>
                <span
                  className={`text-xs font-semibold px-2.5 py-1 rounded-full border ${
                    statusColor[statusKey] ?? "bg-gray-100 text-gray-600 border-gray-200"
                  }`}
                >
                  {user.accountStatus?.toUpperCase() ?? "ACTIVE"}
                </span>
                {user.accountType && (
                  <span className="text-xs font-medium px-2.5 py-1 rounded-full bg-indigo-50 text-indigo-700 border border-indigo-100">
                    {user.accountType}
                  </span>
                )}
              </div>
              <p className="text-sm text-gray-500 mb-0.5">{user.email}</p>
              {user.accountNumber && (
                <p className="text-sm text-gray-400 font-mono flex items-center gap-1">
                  <CreditCard size={13} />
                  {user.accountNumber}
                  <CopyButton text={user.accountNumber} />
                </p>
              )}

              {/* Quick actions */}
              <div className="flex flex-wrap gap-2 mt-4">
                <button
                  onClick={() => setEmailModal(true)}
                  className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-medium bg-gray-100 hover:bg-gray-200 text-gray-700 transition-colors"
                >
                  <Mail size={14} /> Email
                </button>
                <button
                  onClick={() => setNotifModal(true)}
                  className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-medium bg-gray-100 hover:bg-gray-200 text-gray-700 transition-colors"
                >
                  <Bell size={14} /> Notify
                </button>
                <button
                  onClick={() => setBalanceTab("add")}
                  className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-medium bg-indigo-50 hover:bg-indigo-100 text-indigo-700 transition-colors"
                >
                  <DollarSign size={14} /> Balance
                </button>
                <button
                  onClick={() => { generateTcc(); }}
                  className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-medium bg-gray-100 hover:bg-gray-200 text-gray-700 transition-colors"
                >
                  <Key size={14} /> TCC
                </button>
                <button
                  onClick={sendPasswordReset}
                  className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-medium bg-amber-50 hover:bg-amber-100 text-amber-700 transition-colors"
                >
                  <RefreshCw size={14} /> Reset Password
                </button>
                <button
                  onClick={() => setDeleteModal(true)}
                  className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-medium bg-red-50 hover:bg-red-100 text-red-600 transition-colors"
                >
                  <Trash2 size={14} /> Delete
                </button>
              </div>
            </div>

            {/* Balance summary */}
            <div className="text-right flex-shrink-0">
              <p className="text-xs text-gray-400 uppercase tracking-wide mb-1">Balance</p>
              <p className="text-3xl font-bold text-gray-900">{fmt(user.balance ?? 0)}</p>
            </div>
          </div>
        </div>

        {/* ═══ STATUS CONTROL BAR ═══════════════════════════════════════════ */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm px-5 py-4">
          <div className="flex flex-col sm:flex-row items-center gap-4">
            {/* Status buttons */}
            <div className="flex items-center gap-2 flex-wrap">
              {(["active", "pending", "suspended", "frozen", "closed"] as const).map((s) => (
                <button
                  key={s}
                  onClick={() => changeStatus(s)}
                  disabled={saving || statusKey === s}
                  className={`inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-semibold border transition-all ${
                    statusKey === s
                      ? statusColor[s]
                      : s === "frozen"
                      ? "bg-gray-50 text-blue-500 border-blue-200 hover:bg-blue-50"
                      : "bg-gray-50 text-gray-500 border-gray-200 hover:bg-gray-100"
                  } disabled:opacity-60`}
                >
                  {s === "active" && <CheckCircle2 size={13} />}
                  {s === "pending" && <Clock size={13} />}
                  {s === "suspended" && <Ban size={13} />}
                  {s === "frozen" && <Lock size={13} className={statusKey === s ? "text-blue-700" : "text-blue-500"} />}
                  {s === "closed" && <XCircle size={13} />}
                  {s.charAt(0).toUpperCase() + s.slice(1)}
                </button>
              ))}
            </div>

            {/* Center: current status */}
            <div className="flex-1 text-center hidden sm:block">
              <span className="text-xs text-gray-400 uppercase tracking-widest">Current Status</span>
              <p className="text-sm font-bold text-gray-800">{user.accountStatus?.toUpperCase()}</p>
            </div>

            {/* Transactions toggle */}
            <div className="flex items-center gap-3 ml-auto">
              <span className="text-sm text-gray-600 font-medium">Transactions</span>
              <Toggle
                checked={!!user.canTransact}
                onChange={toggleCanTransact}
                disabled={saving}
              />
              <span
                className={`text-xs font-semibold ${
                  user.canTransact ? "text-emerald-600" : "text-gray-400"
                }`}
              >
                {user.canTransact ? "Enabled" : "Disabled"}
              </span>
            </div>
          </div>
        </div>

        {/* ═══ MAIN GRID ════════════════════════════════════════════════════ */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">

          {/* ── LEFT COLUMN (2/3) ─────────────────────────────────────────── */}
          <div className="lg:col-span-2 space-y-5">

            {/* Card: Personal Information */}
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
              <div className="flex items-center justify-between mb-5">
                <h2 className="text-base font-semibold text-gray-900 flex items-center gap-2">
                  <User size={16} className="text-indigo-500" />
                  Personal Information
                </h2>
                {!isEditingInfo ? (
                  <button
                    onClick={() => setIsEditingInfo(true)}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium text-indigo-600 border border-indigo-200 hover:bg-indigo-50 transition-colors"
                  >
                    <Pencil size={12} /> Edit
                  </button>
                ) : (
                  <div className="flex gap-2">
                    <button
                      onClick={() => setIsEditingInfo(false)}
                      className="px-3 py-1.5 rounded-xl text-xs font-medium text-gray-500 border border-gray-200 hover:bg-gray-50 transition-colors"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={savePersonalInfo}
                      disabled={saving}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium bg-indigo-600 text-white hover:bg-indigo-700 transition-colors disabled:opacity-60"
                    >
                      {saving ? <Loader2 size={12} className="animate-spin" /> : <Save size={12} />}
                      Save
                    </button>
                  </div>
                )}
              </div>

              {!isEditingInfo ? (
                <div className="grid grid-cols-2 gap-x-6 gap-y-4">
                  {[
                    ["Full Name", user.fullName, <User size={13} />],
                    ["Email", user.email, <Mail size={13} />],
                    ["Phone", user.phone || "—", <Phone size={13} />],
                    ["Account Type", user.accountType || "—", <CreditCard size={13} />],
                    ["Account Number", user.accountNumber || "—", <Hash size={13} />],
                    ["KYC Status", user.kycStatus || "—", <ShieldCheck size={13} />],
                    ["Address", user.address || "—", <MapPin size={13} />],
                    ["City", user.city || "—", <Building size={13} />],
                    ["Country", user.country || "—", <Globe size={13} />],
                    ["Postal Code", user.postalCode || "—", <FileText size={13} />],
                  ].map(([label, value, icon]) => (
                    <div key={label as string}>
                      <p className="text-xs text-gray-400 uppercase tracking-wide mb-0.5 flex items-center gap-1">
                        {icon as React.ReactNode} {label as string}
                      </p>
                      <p className="text-sm font-medium text-gray-800 truncate">{value as string}</p>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="grid grid-cols-2 gap-4">
                  {[
                    ["fullName", "Full Name", "text"],
                    ["phone", "Phone", "tel"],
                    ["address", "Address", "text"],
                    ["city", "City", "text"],
                    ["country", "Country", "text"],
                    ["postalCode", "Postal Code", "text"],
                    ["accountType", "Account Type", "text"],
                  ].map(([field, label, type]) => (
                    <div key={field}>
                      <label className="block text-xs font-medium text-gray-500 mb-1">{label}</label>
                      {field === "accountType" ? (
                        <select
                          value={(editForm as any)[field]}
                          onChange={(e) => setEditForm({ ...editForm, [field]: e.target.value })}
                          className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                        >
                          <option value="">Select account type</option>
                          <option value="savings">Savings Account</option>
                          <option value="checking">Checking Account</option>
                          <option value="premium">Premium Account</option>
                          <option value="business">Business Account</option>
                          <option value="student">Student Account</option>
                          <option value="joint">Joint Account</option>
                        </select>
                      ) : (
                        <input
                          type={type}
                          value={(editForm as any)[field]}
                          onChange={(e) => setEditForm({ ...editForm, [field]: e.target.value })}
                          className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                        />
                      )}
                    </div>
                  ))}
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">Email (read-only)</label>
                    <input
                      type="email"
                      value={user.email}
                      readOnly
                      className="w-full px-3 py-2 rounded-xl border border-gray-100 text-sm bg-gray-50 text-gray-400 cursor-not-allowed"
                    />
                  </div>
                </div>
              )}

              {/* Dates */}
              <div className="mt-5 pt-4 border-t border-gray-50 grid grid-cols-3 gap-4">
                {[
                  ["Created", fmtDate(user.createdAt)],
                  ["Updated", fmtDate(user.updatedAt)],
                  ["Last Login", fmtDate(user.lastLoginAt)],
                ].map(([l, v]) => (
                  <div key={l}>
                    <p className="text-xs text-gray-400 uppercase tracking-wide mb-0.5 flex items-center gap-1">
                      <Calendar size={11} /> {l}
                    </p>
                    <p className="text-xs text-gray-600">{v}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Card: Balance & Finance */}
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-base font-semibold text-gray-900 flex items-center gap-2">
                  <DollarSign size={16} className="text-emerald-500" />
                  Balance & Finance
                </h2>
                <span className="text-2xl font-bold text-gray-900">{fmt(user.balance ?? 0)}</span>
              </div>

              {/* Tabs */}
              <div className="flex gap-2 mb-4">
                {(["add", "subtract", "set"] as const).map((t) => (
                  <button
                    key={t}
                    onClick={() => setBalanceTab(t)}
                    className={`flex-1 py-2 rounded-xl text-xs font-semibold transition-colors ${
                      balanceTab === t
                        ? t === "add"
                          ? "bg-emerald-500 text-white"
                          : t === "subtract"
                          ? "bg-red-500 text-white"
                          : "bg-indigo-500 text-white"
                        : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                    }`}
                  >
                    {t === "add" ? "+ Credit" : t === "subtract" ? "– Debit" : "= Set Balance"}
                  </button>
                ))}
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1">Amount (USD)</label>
                  <input
                    type="number"
                    min="0"
                    step="0.01"
                    value={balanceAmount}
                    onChange={(e) => setBalanceAmount(e.target.value)}
                    placeholder="0.00"
                    className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1">Note (optional)</label>
                  <input
                    type="text"
                    value={balanceNote}
                    onChange={(e) => setBalanceNote(e.target.value)}
                    placeholder="Reason..."
                    className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  />
                </div>
              </div>
              <button
                onClick={submitBalance}
                disabled={balanceSaving}
                className="mt-3 w-full py-2.5 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition-colors disabled:opacity-60 flex items-center justify-center gap-2"
              >
                {balanceSaving && <Loader2 size={14} className="animate-spin" />}
                Apply{" "}
                {balanceTab === "add" ? "Credit" : balanceTab === "subtract" ? "Debit" : "Balance Update"}
              </button>
            </div>

            {/* Card: Transaction History */}
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-base font-semibold text-gray-900 flex items-center gap-2">
                  <ArrowUpRight size={16} className="text-blue-500" />
                  Transaction History
                </h2>
                <button
                  onClick={() => {
                    setTxForm({ type: "credit", amount: "", description: "", status: "completed" });
                    setTxAddModal(true);
                  }}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium bg-indigo-600 text-white hover:bg-indigo-700 transition-colors"
                >
                  <PlusCircle size={13} /> Add Transaction
                </button>
              </div>

              {transactions.length === 0 ? (
                <div className="text-center py-10 text-gray-400">
                  <ArrowUpRight size={32} className="mx-auto mb-2 opacity-30" />
                  <p className="text-sm">No transactions yet</p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="text-left text-xs text-gray-400 uppercase tracking-wide border-b border-gray-100">
                        <th className="pb-2 font-medium">Type</th>
                        <th className="pb-2 font-medium">Amount</th>
                        <th className="pb-2 font-medium">Description</th>
                        <th className="pb-2 font-medium">Status</th>
                        <th className="pb-2 font-medium">Date</th>
                        <th className="pb-2 font-medium text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-50">
                      {transactions.slice(0, 20).map((tx) => (
                        <tr key={tx.transactionId} className="hover:bg-gray-50/50 transition-colors">
                          <td className="py-2.5 pr-3">
                            <span
                              className={`inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full ${
                                tx.type === "credit"
                                  ? "bg-emerald-50 text-emerald-700"
                                  : tx.type === "debit"
                                  ? "bg-red-50 text-red-600"
                                  : "bg-gray-100 text-gray-600"
                              }`}
                            >
                              {tx.type === "credit" ? (
                                <ArrowDownRight size={10} />
                              ) : (
                                <ArrowUpRight size={10} />
                              )}
                              {tx.type}
                            </span>
                          </td>
                          <td className="py-2.5 pr-3 font-semibold text-gray-800">
                            {tx.type === "debit" ? "-" : "+"}
                            {fmt(tx.amount)}
                          </td>
                          <td className="py-2.5 pr-3 text-gray-600 max-w-[160px] truncate">
                            {tx.description || "—"}
                          </td>
                          <td className="py-2.5 pr-3">
                            <span
                              className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                                tx.status === "completed"
                                  ? "bg-emerald-50 text-emerald-700"
                                  : tx.status === "pending"
                                  ? "bg-amber-50 text-amber-700"
                                  : "bg-red-50 text-red-600"
                              }`}
                            >
                              {tx.status}
                            </span>
                          </td>
                          <td className="py-2.5 pr-3 text-gray-400 text-xs whitespace-nowrap">
                            {fmtDate(tx.timestamp)}
                          </td>
                          <td className="py-2.5 text-right">
                            <div className="flex items-center justify-end gap-2">
                              <button
                                onClick={() => openEditTx(tx)}
                                className="text-gray-400 hover:text-indigo-600 transition-colors"
                              >
                                <Pencil size={13} />
                              </button>
                              <button
                                onClick={() => deleteTransaction(tx.transactionId)}
                                className="text-gray-400 hover:text-red-500 transition-colors"
                              >
                                <Trash2 size={13} />
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

            {/* Card: Notifications Sent */}
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-base font-semibold text-gray-900 flex items-center gap-2">
                  <Bell size={16} className="text-purple-500" />
                  Notifications Sent
                </h2>
                <button
                  onClick={() => setNotifModal(true)}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium bg-purple-600 text-white hover:bg-purple-700 transition-colors"
                >
                  <Send size={13} /> Send Notification
                </button>
              </div>

              {notifications.length === 0 ? (
                <div className="text-center py-8 text-gray-400">
                  <Bell size={28} className="mx-auto mb-2 opacity-30" />
                  <p className="text-sm">No notifications yet</p>
                </div>
              ) : (
                <div className="space-y-2.5 max-h-72 overflow-y-auto pr-1">
                  {notifications.map((n) => (
                    <div
                      key={n.id}
                      className={`flex items-start gap-3 p-3 rounded-xl border ${
                        n.isRead ? "border-gray-100 bg-gray-50" : "border-indigo-100 bg-indigo-50"
                      }`}
                    >
                      <div
                        className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center ${
                          n.isRead ? "bg-gray-200" : "bg-indigo-100"
                        }`}
                      >
                        <Bell size={14} className={n.isRead ? "text-gray-400" : "text-indigo-600"} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-semibold text-gray-800 truncate">{n.title}</p>
                        <p className="text-xs text-gray-500 truncate">{n.body}</p>
                        <p className="text-xs text-gray-400 mt-0.5">{fmtDate(n.createdAt)}</p>
                      </div>
                      <span
                        className={`flex-shrink-0 text-xs font-medium px-2 py-0.5 rounded-full ${
                          n.isRead ? "bg-gray-200 text-gray-500" : "bg-indigo-200 text-indigo-700"
                        }`}
                      >
                        {n.isRead ? "Read" : "Unread"}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* ── RIGHT COLUMN (1/3) ────────────────────────────────────────── */}
          <div className="space-y-5">

            {/* KYC & Verification */}
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
              <h2 className="text-sm font-semibold text-gray-900 flex items-center gap-2 mb-4">
                <ShieldCheck size={15} className="text-emerald-500" />
                KYC & Verification
              </h2>
              <span
                className={`inline-block text-xs font-semibold px-3 py-1 rounded-full mb-4 ${
                  kycColor[user.kycStatus ?? "not_submitted"] ?? "bg-gray-100 text-gray-500"
                }`}
              >
                {user.kycStatus?.replace("_", " ")?.toUpperCase() ?? "NOT SUBMITTED"}
              </span>
              <div className="relative mb-3">
                <select
                  value={kycValue}
                  onChange={(e) => setKycValue(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm appearance-none focus:outline-none focus:ring-2 focus:ring-indigo-300 bg-white pr-8"
                >
                  <option value="not_submitted">Not Submitted</option>
                  <option value="pending">Pending</option>
                  <option value="approved">Verified</option>
                  <option value="rejected">Rejected</option>
                </select>
                <ChevronDown size={14} className="absolute right-3 top-3 text-gray-400 pointer-events-none" />
              </div>
              <button
                onClick={saveKyc}
                disabled={kycSaving}
                className="w-full py-2 rounded-xl bg-emerald-600 text-white text-xs font-semibold hover:bg-emerald-700 transition-colors disabled:opacity-60 flex items-center justify-center gap-1.5"
              >
                {kycSaving && <Loader2 size={12} className="animate-spin" />}
                Update KYC
              </button>
            </div>

            {/* TCC Code */}
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
              <h2 className="text-sm font-semibold text-gray-900 flex items-center gap-2 mb-4">
                <Key size={15} className="text-amber-500" />
                TCC Code
              </h2>

              {/* ── Live active-code display ── */}
              {(() => {
                const otp = latestOtp;
                const displayCode = otp?.code || user.tccCode || "";
                const hasCode = !!displayCode;
                const expired = otp?.expiresAt ? new Date(otp.expiresAt) < new Date() : !otp;
                const active = hasCode && !expired;
                const diff = otp?.expiresAt ? new Date(otp.expiresAt).getTime() - Date.now() : 0;
                const expiryLabel = !hasCode
                  ? "No code set"
                  : !otp
                  ? "Set by admin (no OTP record)"
                  : expired
                  ? "Expired"
                  : diff < 60_000
                  ? "Expires in <1 min"
                  : diff < 3_600_000
                  ? `Expires in ${Math.ceil(diff / 60_000)} min`
                  : `Expires in ${Math.ceil(diff / 3_600_000)}h`;

                return (
                  <div className={`rounded-xl border p-3 mb-4 ${active ? "bg-emerald-50 border-emerald-200" : "bg-gray-50 border-gray-200"}`}>
                    <p className={`text-[10px] font-bold uppercase tracking-wider mb-2 ${active ? "text-emerald-600" : "text-gray-400"}`}>
                      {active ? "✓ Active Code" : "Last Code"}
                    </p>
                    <div className="flex items-center justify-between gap-2">
                      <span className={`font-mono text-2xl font-black tracking-[0.2em] ${active ? "text-gray-900" : "text-gray-400"}`}>
                        {displayCode || "——"}
                      </span>
                      <button
                        onClick={() => {
                          if (displayCode) {
                            navigator.clipboard.writeText(displayCode);
                            toast.success("Code copied to clipboard");
                          }
                        }}
                        title="Copy to clipboard"
                        disabled={!displayCode}
                        className="flex-shrink-0 p-2 rounded-lg bg-white border border-gray-200 hover:border-amber-400 hover:text-amber-600 transition-colors disabled:opacity-40"
                      >
                        <Copy size={14} />
                      </button>
                    </div>
                    <p className={`text-[11px] mt-1.5 flex items-center gap-1 ${active ? "text-emerald-600" : "text-gray-400"}`}>
                      <Clock size={10} />
                      {expiryLabel}
                    </p>
                  </div>
                );
              })()}

              {/* ── Set / generate a new code ── */}
              <p className="text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-2">Issue New Code</p>
              <input
                type="text"
                value={tccCode}
                onChange={(e) => setTccCode(e.target.value.toUpperCase().replace(/[^A-Z2-9]/g, '').slice(0, 6))}
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm font-mono font-semibold text-gray-800 tracking-widest uppercase focus:outline-none focus:ring-2 focus:ring-amber-300 mb-3"
                placeholder="6-char code…"
                maxLength={6}
              />
              <div className="grid grid-cols-2 gap-2">
                <button
                  onClick={generateTcc}
                  className="py-2 rounded-xl bg-gray-100 text-gray-700 text-xs font-semibold hover:bg-gray-200 transition-colors"
                >
                  Generate Random
                </button>
                <button
                  onClick={saveTcc}
                  disabled={tccSaving || tccCode.length !== 6}
                  className="py-2 rounded-xl bg-amber-500 text-white text-xs font-semibold hover:bg-amber-600 transition-colors disabled:opacity-60 flex items-center justify-center gap-1"
                >
                  {tccSaving && <Loader2 size={11} className="animate-spin" />}
                  Save & Email
                </button>
              </div>
            </div>

            {/* Security Settings */}
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
              <h2 className="text-sm font-semibold text-gray-900 flex items-center gap-2 mb-4">
                <Shield size={15} className="text-indigo-500" />
                Security Settings
              </h2>

              <div className="space-y-3 mb-4">
                {[
                  ["two_fa_enabled", "Two-Factor Auth", !!user.two_fa_enabled] as const,
                  ["login_alerts_enabled", "Login Alerts", !!user.login_alerts_enabled] as const,
                ].map(([field, label, val]) => (
                  <div key={field} className="flex items-center justify-between">
                    <span className="text-sm text-gray-700">{label}</span>
                    <Toggle
                      checked={val}
                      onChange={() => toggleSecurity(field, val)}
                    />
                  </div>
                ))}
              </div>

              <div className="space-y-2">
                <button
                  onClick={sendPasswordReset}
                  className="w-full py-2 rounded-xl border border-amber-200 text-amber-700 bg-amber-50 text-xs font-semibold hover:bg-amber-100 transition-colors flex items-center justify-center gap-1.5"
                >
                  <RefreshCw size={13} /> Send Password Reset Email
                </button>
                <button
                  onClick={async () => {
                    setRevoking(true);
                    try {
                      const res = await apiCall(`/api/users/${uid}/revoke-sessions`, { method: "POST" });
                      const data = await res.json();
                      if (!res.ok) throw new Error(data.error ?? "Failed to revoke sessions");
                      toast.success("All sessions revoked — user must re-login");
                    } catch (e: any) {
                      toast.error(e.message);
                    } finally {
                      setRevoking(false);
                    }
                  }}
                  disabled={revoking}
                  className="w-full py-2 rounded-xl border border-gray-200 text-gray-600 bg-gray-50 text-xs font-semibold hover:bg-gray-100 transition-colors flex items-center justify-center gap-1.5 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <LogOut size={13} /> {revoking ? "Revoking…" : "Force Sign Out All Devices"}
                </button>
              </div>
            </div>

            {/* Account Identifiers */}
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
              <h2 className="text-sm font-semibold text-gray-900 flex items-center gap-2 mb-4">
                <Fingerprint size={15} className="text-blue-500" />
                Account Identifiers
              </h2>
              <div className="space-y-3 text-xs">
                {[
                  ["UID", user.uid],
                  ["Account Number", user.accountNumber ?? "—"],
                  ["FCM Token", user.fcmToken ? user.fcmToken.slice(0, 28) + "…" : "—"],
                ].map(([label, value]) => (
                  <div key={label as string}>
                    <p className="text-gray-400 uppercase tracking-wide text-[10px] mb-0.5">{label as string}</p>
                    <div className="flex items-center gap-1 font-mono text-gray-700 bg-gray-50 px-2.5 py-1.5 rounded-lg">
                      <span className="truncate flex-1">{value as string}</span>
                      {value !== "—" && <CopyButton text={value as string} />}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Danger Zone */}
            <div className="bg-white rounded-2xl border-2 border-red-200 shadow-sm p-5">
              <h2 className="text-sm font-semibold text-red-700 flex items-center gap-2 mb-3">
                <AlertTriangle size={15} /> Danger Zone
              </h2>
              <p className="text-xs text-gray-500 mb-3">
                Permanently deletes this account and all associated data. This action cannot be undone.
              </p>
              <button
                onClick={() => setDeleteModal(true)}
                className="w-full py-2.5 rounded-xl bg-red-600 text-white text-xs font-bold hover:bg-red-700 transition-colors flex items-center justify-center gap-2"
              >
                <Trash2 size={13} /> Delete Account Permanently
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* ═══ MODALS ══════════════════════════════════════════════════════════ */}

      {/* Email Modal */}
      <Modal open={emailModal} onClose={() => setEmailModal(false)} title="Send Email Notification">
        <div className="space-y-4">
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Subject</label>
            <input
              type="text"
              value={emailForm.subject}
              onChange={(e) => setEmailForm({ ...emailForm, subject: e.target.value })}
              className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
              placeholder="Email subject..."
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Body</label>
            <textarea
              rows={4}
              value={emailForm.body}
              onChange={(e) => setEmailForm({ ...emailForm, body: e.target.value })}
              className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 resize-none"
              placeholder="Email content..."
            />
          </div>
          <div className="flex gap-2 pt-1">
            <button
              onClick={() => setEmailModal(false)}
              className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={sendEmail}
              disabled={modalSaving}
              className="flex-1 py-2.5 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition-colors disabled:opacity-60 flex items-center justify-center gap-2"
            >
              {modalSaving && <Loader2 size={14} className="animate-spin" />}
              <Send size={14} /> Send
            </button>
          </div>
        </div>
      </Modal>

      {/* Notification Modal */}
      <Modal open={notifModal} onClose={() => setNotifModal(false)} title="Send Notification">
        <div className="space-y-4">
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Title</label>
            <input
              type="text"
              value={notifForm.title}
              onChange={(e) => setNotifForm({ ...notifForm, title: e.target.value })}
              className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
              placeholder="Notification title..."
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Body</label>
            <textarea
              rows={3}
              value={notifForm.body}
              onChange={(e) => setNotifForm({ ...notifForm, body: e.target.value })}
              className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 resize-none"
              placeholder="Notification body..."
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Type</label>
            <select
              value={notifForm.type}
              onChange={(e) => setNotifForm({ ...notifForm, type: e.target.value })}
              className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 bg-white"
            >
              <option value="announcement">Announcement</option>
              <option value="alert">Alert</option>
              <option value="transaction">Transaction</option>
              <option value="security">Security</option>
              <option value="promotion">Promotion</option>
            </select>
          </div>
          <div className="flex gap-2 pt-1">
            <button
              onClick={() => setNotifModal(false)}
              className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={sendNotification}
              disabled={modalSaving}
              className="flex-1 py-2.5 rounded-xl bg-purple-600 text-white text-sm font-semibold hover:bg-purple-700 transition-colors disabled:opacity-60 flex items-center justify-center gap-2"
            >
              {modalSaving && <Loader2 size={14} className="animate-spin" />}
              <Bell size={14} /> Send
            </button>
          </div>
        </div>
      </Modal>

      {/* Delete confirmation Modal */}
      <Modal open={deleteModal} onClose={() => setDeleteModal(false)} title="Delete Account">
        <div className="space-y-4">
          <div className="flex items-start gap-3 p-4 bg-red-50 rounded-xl border border-red-200">
            <AlertTriangle size={18} className="text-red-600 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-semibold text-red-700">This action is permanent</p>
              <p className="text-xs text-red-600 mt-0.5">
                All data including transactions, documents, and notifications will be deleted forever.
              </p>
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">
              Type <span className="font-bold text-gray-800">{user.fullName}</span> to confirm
            </label>
            <input
              type="text"
              value={deleteConfirmName}
              onChange={(e) => setDeleteConfirmName(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border border-red-200 text-sm focus:outline-none focus:ring-2 focus:ring-red-300"
              placeholder="Type user's full name..."
            />
          </div>
          <div className="flex gap-2 pt-1">
            <button
              onClick={() => setDeleteModal(false)}
              className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={deleteUser}
              disabled={
                modalSaving ||
                deleteConfirmName.trim().toLowerCase() !== user.fullName?.trim().toLowerCase()
              }
              className="flex-1 py-2.5 rounded-xl bg-red-600 text-white text-sm font-bold hover:bg-red-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {modalSaving && <Loader2 size={14} className="animate-spin" />}
              <Trash2 size={14} /> Delete Forever
            </button>
          </div>
        </div>
      </Modal>

      {/* Transaction Add Modal */}
      <Modal open={txAddModal} onClose={() => setTxAddModal(false)} title="Add Transaction">
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Type</label>
              <select
                value={txForm.type}
                onChange={(e) => setTxForm({ ...txForm, type: e.target.value })}
                className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 bg-white"
              >
                <option value="credit">Credit</option>
                <option value="debit">Debit</option>
                <option value="transfer">Transfer</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Amount</label>
              <input
                type="number"
                min="0"
                step="0.01"
                value={txForm.amount}
                onChange={(e) => setTxForm({ ...txForm, amount: e.target.value })}
                className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                placeholder="0.00"
              />
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Description</label>
            <input
              type="text"
              value={txForm.description}
              onChange={(e) => setTxForm({ ...txForm, description: e.target.value })}
              className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
              placeholder="Transaction description..."
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Status</label>
            <select
              value={txForm.status}
              onChange={(e) => setTxForm({ ...txForm, status: e.target.value })}
              className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 bg-white"
            >
              <option value="completed">Completed</option>
              <option value="pending">Pending</option>
              <option value="failed">Failed</option>
            </select>
          </div>
          <div className="flex gap-2 pt-1">
            <button
              onClick={() => setTxAddModal(false)}
              className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={addTransaction}
              disabled={modalSaving}
              className="flex-1 py-2.5 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition-colors disabled:opacity-60 flex items-center justify-center gap-2"
            >
              {modalSaving && <Loader2 size={14} className="animate-spin" />}
              <PlusCircle size={14} /> Add
            </button>
          </div>
        </div>
      </Modal>

      {/* Transaction Edit Modal */}
      <Modal
        open={!!txEditModal}
        onClose={() => setTxEditModal(null)}
        title="Edit Transaction"
      >
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Type</label>
              <select
                value={txForm.type}
                onChange={(e) => setTxForm({ ...txForm, type: e.target.value })}
                className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 bg-white"
              >
                <option value="credit">Credit</option>
                <option value="debit">Debit</option>
                <option value="transfer">Transfer</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Amount</label>
              <input
                type="number"
                min="0"
                step="0.01"
                value={txForm.amount}
                onChange={(e) => setTxForm({ ...txForm, amount: e.target.value })}
                className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
              />
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Description</label>
            <input
              type="text"
              value={txForm.description}
              onChange={(e) => setTxForm({ ...txForm, description: e.target.value })}
              className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Status</label>
            <select
              value={txForm.status}
              onChange={(e) => setTxForm({ ...txForm, status: e.target.value })}
              className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 bg-white"
            >
              <option value="completed">Completed</option>
              <option value="pending">Pending</option>
              <option value="failed">Failed</option>
            </select>
          </div>
          <div className="flex gap-2 pt-1">
            <button
              onClick={() => {
                if (txEditModal) deleteTransaction(txEditModal.transactionId);
                setTxEditModal(null);
              }}
              className="py-2.5 px-4 rounded-xl border border-red-200 text-red-600 text-sm font-medium hover:bg-red-50 transition-colors flex items-center gap-1.5"
            >
              <Trash2 size={13} /> Delete
            </button>
            <button
              onClick={() => setTxEditModal(null)}
              className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={updateTransaction}
              disabled={modalSaving}
              className="flex-1 py-2.5 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition-colors disabled:opacity-60 flex items-center justify-center gap-2"
            >
              {modalSaving && <Loader2 size={14} className="animate-spin" />}
              <Save size={14} /> Save
            </button>
          </div>
        </div>
      </Modal>

      {/* Password Reset Result Modal */}
      <Modal
        open={!!resetModal}
        onClose={() => setResetModal(null)}
        title="Password Reset Sent"
      >
        <div className="space-y-4">
          <div className="flex items-center gap-3 p-4 bg-emerald-50 rounded-xl border border-emerald-200">
            <CheckCircle2 size={20} className="text-emerald-600 flex-shrink-0" />
            <div>
              <p className="text-sm font-semibold text-emerald-700">Reset email sent successfully</p>
              <p className="text-xs text-emerald-600 mt-0.5">
                The password reset link has been sent to {user.email}
              </p>
            </div>
          </div>
          {resetModal?.link && (
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Reset Link</label>
              <div className="flex items-center gap-2 p-3 bg-gray-50 rounded-xl border border-gray-200 font-mono text-xs text-gray-700 break-all">
                <span className="flex-1">{resetModal.link}</span>
                <CopyButton text={resetModal.link} />
              </div>
            </div>
          )}
          <button
            onClick={() => setResetModal(null)}
            className="w-full py-2.5 rounded-xl bg-gray-100 text-gray-700 text-sm font-medium hover:bg-gray-200 transition-colors"
          >
            Close
          </button>
        </div>
      </Modal>
    </div>
  );
}
