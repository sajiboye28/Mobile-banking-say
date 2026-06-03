"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/AuthContext";
import Sidebar from "@/components/Sidebar";

const getToken = () => typeof window !== 'undefined' ? localStorage.getItem('pb_admin_token') ?? '' : '';
import { Toaster } from "react-hot-toast";
import toast from "react-hot-toast";
import {
  MessageSquare,
  Search,
  Clock,
  CheckCircle,
  XCircle,
  RefreshCw,
  X,
  User,
  Mail,
  Tag,
  Paperclip,
  Send,
  ChevronDown,
  Loader2,
  AlertCircle,
  Calendar,
  Hash,
  CreditCard,
} from "lucide-react";

interface Reply {
  text: string;
  authorEmail: string;
  isAdmin: boolean;
  createdAt: string | null;
}

interface Ticket {
  id: string;
  userId: string;
  userName: string;
  userEmail: string;
  userAccountNumber: string;
  subject: string;
  category: string;
  description: string;
  status: string;
  priority: string;
  attachments: string[];
  replies: Reply[];
  createdAt: string | null;
  updatedAt: string | null;
}

interface Counts {
  total: number;
  open: number;
  in_progress: number;
  resolved: number;
  closed: number;
}

const STATUS_CONFIG: Record<
  string,
  { label: string; color: string; dotColor: string; icon: React.ElementType }
> = {
  open: {
    label: "Open",
    color: "bg-amber-50 text-amber-700 ring-1 ring-amber-200",
    dotColor: "bg-amber-500",
    icon: Clock,
  },
  in_progress: {
    label: "In Progress",
    color: "bg-blue-50 text-blue-700 ring-1 ring-blue-200",
    dotColor: "bg-blue-500",
    icon: RefreshCw,
  },
  resolved: {
    label: "Resolved",
    color: "bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200",
    dotColor: "bg-emerald-500",
    icon: CheckCircle,
  },
  closed: {
    label: "Closed",
    color: "bg-gray-100 text-gray-600 ring-1 ring-gray-200",
    dotColor: "bg-gray-400",
    icon: XCircle,
  },
};

const PRIORITY_CONFIG: Record<string, { label: string; color: string }> = {
  low: { label: "Low", color: "text-gray-500" },
  medium: { label: "Medium", color: "text-amber-600" },
  high: { label: "High", color: "text-rose-600" },
};

function StatusBadge({ status }: { status: string }) {
  const cfg = STATUS_CONFIG[status] || STATUS_CONFIG.open;
  const Icon = cfg.icon;
  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold ${cfg.color}`}
    >
      <Icon className="w-3 h-3" />
      {cfg.label}
    </span>
  );
}

function formatDate(iso: string | null) {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

function formatDateTime(iso: string | null) {
  if (!iso) return "—";
  return new Date(iso).toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export default function SupportPage() {
  const { user, isAdmin, loading: authLoading } = useAuth();
  const router = useRouter();

  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [counts, setCounts] = useState<Counts>({
    total: 0,
    open: 0,
    in_progress: 0,
    resolved: 0,
    closed: 0,
  });
  const [fetching, setFetching] = useState(false);
  const [activeTab, setActiveTab] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedTicket, setSelectedTicket] = useState<Ticket | null>(null);

  // Side panel state
  const [replyText, setReplyText] = useState("");
  const [replying, setReplying] = useState(false);
  const [statusChanging, setStatusChanging] = useState(false);
  const [closing, setClosing] = useState(false);
  const [showStatusDropdown, setShowStatusDropdown] = useState(false);

  useEffect(() => {
    if (!authLoading && (!user || !isAdmin)) {
      router.push("/login");
    }
  }, [user, isAdmin, authLoading, router]);

  const fetchTickets = useCallback(async () => {
    if (!user) return;
    setFetching(true);
    try {
      const token = getToken();
      const res = await fetch("/api/support", {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) throw new Error("Failed to fetch tickets");
      const data = await res.json();
      setTickets(data.tickets);
      setCounts(data.counts);
    } catch {
      toast.error("Failed to load support tickets");
    } finally {
      setFetching(false);
    }
  }, [user]);

  useEffect(() => {
    if (user && isAdmin) {
      fetchTickets();
    }
  }, [user, isAdmin, fetchTickets]);

  const handleUpdateStatus = async (ticketId: string, status: string) => {
    setStatusChanging(true);
    setShowStatusDropdown(false);
    try {
      const token = getToken();
      const res = await fetch("/api/support", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ action: "update_status", ticketId, status }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Failed to update status");
      toast.success(`Status updated to ${STATUS_CONFIG[status]?.label || status}`);
      // Update local state
      setTickets((prev) =>
        prev.map((t) => (t.id === ticketId ? { ...t, status } : t))
      );
      setSelectedTicket((prev) => (prev?.id === ticketId ? { ...prev, status } : prev));
      setCounts((prev) => {
        const old = selectedTicket?.status || "";
        const updated = { ...prev };
        if (old && old in updated) (updated as Record<string, number>)[old]--;
        if (status in updated) (updated as Record<string, number>)[status]++;
        return updated;
      });
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Failed to update status");
    } finally {
      setStatusChanging(false);
    }
  };

  const handleSendReply = async () => {
    if (!selectedTicket || !replyText.trim()) return;
    setReplying(true);
    try {
      const token = getToken();
      const res = await fetch("/api/support", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          action: "reply",
          ticketId: selectedTicket.id,
          replyText: replyText.trim(),
          adminEmail: user?.email || "admin",
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Failed to send reply");
      toast.success("Reply sent successfully");
      setReplyText("");
      // Optimistically add reply and possibly update status
      const newReply: Reply = {
        text: replyText.trim(),
        authorEmail: user?.email || "admin",
        isAdmin: true,
        createdAt: new Date().toISOString(),
      };
      const newStatus =
        selectedTicket.status === "open" ? "in_progress" : selectedTicket.status;
      setSelectedTicket((prev) =>
        prev
          ? {
              ...prev,
              replies: [...prev.replies, newReply],
              status: newStatus,
            }
          : prev
      );
      setTickets((prev) =>
        prev.map((t) =>
          t.id === selectedTicket.id
            ? { ...t, replies: [...t.replies, newReply], status: newStatus }
            : t
        )
      );
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Failed to send reply");
    } finally {
      setReplying(false);
    }
  };

  const handleCloseTicket = async () => {
    if (!selectedTicket) return;
    setClosing(true);
    try {
      const token = getToken();
      const res = await fetch("/api/support", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ action: "close", ticketId: selectedTicket.id }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Failed to close ticket");
      toast.success("Ticket closed");
      setTickets((prev) =>
        prev.map((t) => (t.id === selectedTicket.id ? { ...t, status: "closed" } : t))
      );
      setSelectedTicket((prev) => (prev ? { ...prev, status: "closed" } : prev));
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Failed to close ticket");
    } finally {
      setClosing(false);
    }
  };

  // Filtered tickets
  const filteredTickets = tickets.filter((t) => {
    const matchesTab =
      activeTab === "all" ||
      (activeTab === "in_progress" ? t.status === "in_progress" : t.status === activeTab);
    const q = searchQuery.toLowerCase();
    const matchesSearch =
      !q ||
      t.subject.toLowerCase().includes(q) ||
      t.userEmail.toLowerCase().includes(q) ||
      t.userName.toLowerCase().includes(q);
    return matchesTab && matchesSearch;
  });

  const tabs = [
    { value: "all", label: "All", count: counts.total },
    { value: "open", label: "Open", count: counts.open },
    { value: "in_progress", label: "In Progress", count: counts.in_progress },
    { value: "resolved", label: "Resolved", count: counts.resolved },
  ];

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
          style: {
            borderRadius: "12px",
            background: "#1e293b",
            color: "#f1f5f9",
            fontSize: "14px",
            padding: "12px 16px",
          },
        }}
      />
      <Sidebar />
      <div className="flex-1 flex flex-col min-h-screen overflow-hidden">
        {/* Top header */}
        <header className="h-16 bg-white/80 backdrop-blur-sm border-b border-gray-200/60 flex items-center justify-between px-8 flex-shrink-0">
          <h1 className="text-lg font-bold text-gray-900">Support Tickets</h1>
          <div className="flex items-center gap-3">
            <span className="text-sm text-gray-500">{user?.email}</span>
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center">
              <span className="text-xs font-bold text-white">
                {user?.email?.charAt(0).toUpperCase() || "A"}
              </span>
            </div>
          </div>
        </header>

        <main className="flex-1 p-8 overflow-auto">
          <div className="animate-fade-in">
            {/* Page header */}
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div>
                  <h2 className="text-2xl font-bold text-gray-900">Support Tickets</h2>
                  <p className="text-sm text-gray-500 mt-0.5">
                    Manage customer support requests
                  </p>
                </div>
                <span className="px-3 py-1 rounded-full bg-indigo-100 text-indigo-700 text-sm font-bold">
                  {counts.total}
                </span>
              </div>
              <button
                onClick={fetchTickets}
                disabled={fetching}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-white border border-gray-200 text-sm font-semibold text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-all shadow-sm disabled:opacity-50"
              >
                <RefreshCw className={`w-4 h-4 ${fetching ? "animate-spin" : ""}`} />
                Refresh
              </button>
            </div>

            {/* Stats row */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
              {[
                {
                  label: "Open",
                  count: counts.open,
                  bg: "bg-amber-50",
                  border: "border-amber-200",
                  iconBg: "bg-amber-100",
                  iconColor: "text-amber-600",
                  textColor: "text-amber-900",
                  icon: Clock,
                },
                {
                  label: "In Progress",
                  count: counts.in_progress,
                  bg: "bg-blue-50",
                  border: "border-blue-200",
                  iconBg: "bg-blue-100",
                  iconColor: "text-blue-600",
                  textColor: "text-blue-900",
                  icon: RefreshCw,
                },
                {
                  label: "Resolved",
                  count: counts.resolved,
                  bg: "bg-emerald-50",
                  border: "border-emerald-200",
                  iconBg: "bg-emerald-100",
                  iconColor: "text-emerald-600",
                  textColor: "text-emerald-900",
                  icon: CheckCircle,
                },
                {
                  label: "Closed",
                  count: counts.closed,
                  bg: "bg-gray-50",
                  border: "border-gray-200",
                  iconBg: "bg-gray-100",
                  iconColor: "text-gray-500",
                  textColor: "text-gray-700",
                  icon: XCircle,
                },
              ].map(({ label, count, bg, border, iconBg, iconColor, textColor, icon: Icon }) => (
                <div
                  key={label}
                  className={`${bg} border ${border} rounded-2xl p-4 flex items-center gap-4`}
                >
                  <div
                    className={`w-10 h-10 rounded-xl ${iconBg} flex items-center justify-center`}
                  >
                    <Icon className={`w-5 h-5 ${iconColor}`} />
                  </div>
                  <div>
                    <p className={`text-2xl font-bold ${textColor}`}>{count}</p>
                    <p className="text-xs text-gray-500 font-medium">{label}</p>
                  </div>
                </div>
              ))}
            </div>

            {/* Filter tabs + search */}
            <div className="bg-white rounded-2xl border border-gray-200 p-4 mb-6 flex flex-col sm:flex-row gap-4 items-start sm:items-center">
              {/* Tabs */}
              <div className="flex gap-1 p-1 bg-gray-100 rounded-xl flex-shrink-0 flex-wrap">
                {tabs.map((tab) => (
                  <button
                    key={tab.value}
                    onClick={() => setActiveTab(tab.value)}
                    className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all duration-200 ${
                      activeTab === tab.value
                        ? "bg-indigo-600 text-white shadow-sm"
                        : "text-gray-600 hover:text-gray-900 hover:bg-white"
                    }`}
                  >
                    {tab.label}
                    <span
                      className={`ml-2 text-xs ${
                        activeTab === tab.value ? "text-indigo-200" : "text-gray-400"
                      }`}
                    >
                      {tab.count}
                    </span>
                  </button>
                ))}
              </div>

              {/* Search */}
              <div className="relative flex-1 min-w-0">
                <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search by subject or user email..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 transition-all"
                />
                {searchQuery && (
                  <button
                    onClick={() => setSearchQuery("")}
                    className="absolute right-3 top-1/2 -translate-y-1/2"
                  >
                    <X className="w-4 h-4 text-gray-400 hover:text-gray-600" />
                  </button>
                )}
              </div>
            </div>

            {/* Table */}
            <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden shadow-sm">
              {fetching ? (
                <div className="flex items-center justify-center py-24">
                  <div className="flex flex-col items-center gap-3">
                    <Loader2 className="w-8 h-8 text-indigo-500 animate-spin" />
                    <p className="text-sm text-gray-500">Loading tickets...</p>
                  </div>
                </div>
              ) : filteredTickets.length === 0 ? (
                <div className="flex flex-col items-center py-20">
                  <div className="w-16 h-16 rounded-2xl bg-gray-100 flex items-center justify-center mb-4">
                    <MessageSquare className="w-8 h-8 text-gray-400" />
                  </div>
                  <p className="text-lg font-semibold text-gray-700 mb-1">No tickets found</p>
                  <p className="text-sm text-gray-400">
                    {searchQuery
                      ? "Try adjusting your search query."
                      : activeTab === "all"
                      ? "No support tickets have been submitted yet."
                      : `No ${activeTab.replace("_", " ")} tickets.`}
                  </p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="bg-gray-50 border-b border-gray-200">
                        <th className="text-left px-5 py-3.5 text-xs font-bold text-gray-500 uppercase tracking-wider">
                          Ticket ID
                        </th>
                        <th className="text-left px-5 py-3.5 text-xs font-bold text-gray-500 uppercase tracking-wider">
                          User
                        </th>
                        <th className="text-left px-5 py-3.5 text-xs font-bold text-gray-500 uppercase tracking-wider">
                          Subject
                        </th>
                        <th className="text-left px-5 py-3.5 text-xs font-bold text-gray-500 uppercase tracking-wider">
                          Category
                        </th>
                        <th className="text-center px-5 py-3.5 text-xs font-bold text-gray-500 uppercase tracking-wider">
                          Status
                        </th>
                        <th className="text-left px-5 py-3.5 text-xs font-bold text-gray-500 uppercase tracking-wider">
                          Created
                        </th>
                        <th className="text-center px-5 py-3.5 text-xs font-bold text-gray-500 uppercase tracking-wider">
                          Actions
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                      {filteredTickets.map((ticket) => (
                        <tr
                          key={ticket.id}
                          className="hover:bg-indigo-50/30 transition-colors cursor-pointer"
                          onClick={() => setSelectedTicket(ticket)}
                        >
                          <td className="px-5 py-4">
                            <span className="font-mono text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded-lg">
                              #{ticket.id.substring(0, 8)}
                            </span>
                          </td>
                          <td className="px-5 py-4">
                            <div className="flex items-center gap-2.5">
                              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-indigo-500 to-blue-500 flex items-center justify-center flex-shrink-0">
                                <span className="text-xs font-bold text-white">
                                  {ticket.userName.charAt(0).toUpperCase()}
                                </span>
                              </div>
                              <div>
                                <p className="font-semibold text-gray-900 text-sm">
                                  {ticket.userName}
                                </p>
                                <p className="text-xs text-gray-500">{ticket.userEmail}</p>
                              </div>
                            </div>
                          </td>
                          <td className="px-5 py-4">
                            <div className="flex items-center gap-2">
                              <p className="font-medium text-gray-900 max-w-[200px] truncate">
                                {ticket.subject}
                              </p>
                              {ticket.priority === "high" && (
                                <span className="text-[10px] font-bold text-rose-700 bg-rose-50 border border-rose-200 px-1.5 py-0.5 rounded-full flex-shrink-0">
                                  HIGH
                                </span>
                              )}
                              {ticket.replies.length > 0 && (
                                <span className="text-[10px] font-semibold text-indigo-600 bg-indigo-50 px-1.5 py-0.5 rounded-full flex-shrink-0">
                                  {ticket.replies.length} repl{ticket.replies.length === 1 ? "y" : "ies"}
                                </span>
                              )}
                            </div>
                          </td>
                          <td className="px-5 py-4">
                            <span className="text-xs font-medium text-gray-600 bg-gray-100 px-2.5 py-1 rounded-full">
                              {ticket.category}
                            </span>
                          </td>
                          <td className="px-5 py-4 text-center">
                            <StatusBadge status={ticket.status} />
                          </td>
                          <td className="px-5 py-4 text-gray-500 text-xs">
                            {formatDate(ticket.createdAt)}
                          </td>
                          <td className="px-5 py-4 text-center">
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setSelectedTicket(ticket);
                              }}
                              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-indigo-50 text-indigo-700 text-xs font-semibold hover:bg-indigo-100 transition-colors"
                            >
                              View
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </main>
      </div>

      {/* Detail Side Panel */}
      {selectedTicket && (
        <div className="fixed inset-0 z-50 flex">
          {/* Backdrop */}
          <div
            className="flex-1 bg-black/40 backdrop-blur-sm"
            onClick={() => {
              setSelectedTicket(null);
              setReplyText("");
              setShowStatusDropdown(false);
            }}
          />
          {/* Drawer */}
          <div className="w-full max-w-lg bg-white shadow-2xl flex flex-col h-full overflow-y-auto">
            {/* Drawer header */}
            <div className="flex items-center justify-between px-6 py-5 border-b border-gray-100 flex-shrink-0">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-indigo-100 flex items-center justify-center">
                  <MessageSquare className="w-5 h-5 text-indigo-600" />
                </div>
                <div>
                  <h2 className="text-base font-bold text-gray-900">Ticket Details</h2>
                  <p className="text-xs text-gray-500 font-mono">
                    #{selectedTicket.id.substring(0, 8)}
                  </p>
                </div>
              </div>
              <button
                onClick={() => {
                  setSelectedTicket(null);
                  setReplyText("");
                  setShowStatusDropdown(false);
                }}
                className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center hover:bg-gray-200 transition-colors"
              >
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto">
              {/* User info */}
              <div className="px-6 py-5 border-b border-gray-100">
                <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-3">
                  Customer Info
                </p>
                <div className="space-y-2">
                  <div className="flex items-center gap-2.5 py-2.5 px-3 rounded-xl bg-gray-50">
                    <div className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center flex-shrink-0">
                      <User className="w-4 h-4 text-gray-500" />
                    </div>
                    <div>
                      <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Name</p>
                      <p className="text-sm font-medium text-gray-900">
                        {selectedTicket.userName}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2.5 py-2.5 px-3 rounded-xl bg-gray-50">
                    <div className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center flex-shrink-0">
                      <Mail className="w-4 h-4 text-gray-500" />
                    </div>
                    <div>
                      <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Email</p>
                      <p className="text-sm font-medium text-gray-900">
                        {selectedTicket.userEmail || "—"}
                      </p>
                    </div>
                  </div>
                  {selectedTicket.userAccountNumber && (
                    <div className="flex items-center gap-2.5 py-2.5 px-3 rounded-xl bg-gray-50">
                      <div className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center flex-shrink-0">
                        <CreditCard className="w-4 h-4 text-gray-500" />
                      </div>
                      <div>
                        <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">
                          Account #
                        </p>
                        <p className="text-sm font-mono text-gray-900">
                          {selectedTicket.userAccountNumber}
                        </p>
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {/* Ticket details */}
              <div className="px-6 py-5 border-b border-gray-100">
                <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-3">
                  Ticket Info
                </p>
                <div className="space-y-3">
                  <div>
                    <p className="text-xs font-semibold text-gray-500 mb-1">Subject</p>
                    <p className="text-sm font-semibold text-gray-900">
                      {selectedTicket.subject}
                    </p>
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="py-2.5 px-3 rounded-xl bg-gray-50">
                      <div className="flex items-center gap-1.5 mb-1">
                        <Tag className="w-3 h-3 text-gray-400" />
                        <p className="text-xs font-semibold text-gray-500">Category</p>
                      </div>
                      <p className="text-sm font-medium text-gray-900">
                        {selectedTicket.category}
                      </p>
                    </div>
                    <div className="py-2.5 px-3 rounded-xl bg-gray-50">
                      <div className="flex items-center gap-1.5 mb-1">
                        <AlertCircle className="w-3 h-3 text-gray-400" />
                        <p className="text-xs font-semibold text-gray-500">Priority</p>
                      </div>
                      <p
                        className={`text-sm font-semibold ${
                          PRIORITY_CONFIG[selectedTicket.priority]?.color || "text-gray-600"
                        }`}
                      >
                        {PRIORITY_CONFIG[selectedTicket.priority]?.label || "Medium"}
                      </p>
                    </div>
                  </div>
                  <div className="py-2.5 px-3 rounded-xl bg-gray-50">
                    <div className="flex items-center gap-1.5 mb-1">
                      <Calendar className="w-3 h-3 text-gray-400" />
                      <p className="text-xs font-semibold text-gray-500">Submitted</p>
                    </div>
                    <p className="text-sm font-medium text-gray-900">
                      {formatDateTime(selectedTicket.createdAt)}
                    </p>
                  </div>
                </div>
              </div>

              {/* Description */}
              <div className="px-6 py-5 border-b border-gray-100">
                <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-3">
                  Description
                </p>
                <div className="bg-gray-50 rounded-xl p-4">
                  <p className="text-sm text-gray-700 leading-relaxed whitespace-pre-wrap">
                    {selectedTicket.description || "(No description provided)"}
                  </p>
                </div>
              </div>

              {/* Attachments */}
              {selectedTicket.attachments.length > 0 && (
                <div className="px-6 py-5 border-b border-gray-100">
                  <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-3">
                    Attachments ({selectedTicket.attachments.length})
                  </p>
                  <div className="space-y-2">
                    {selectedTicket.attachments.map((url, i) => (
                      <a
                        key={i}
                        href={url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center gap-2.5 px-3 py-2.5 rounded-xl bg-blue-50 border border-blue-100 hover:border-blue-300 transition-colors"
                      >
                        <Paperclip className="w-4 h-4 text-blue-500 flex-shrink-0" />
                        <span className="text-xs text-blue-700 font-medium truncate">
                          Attachment {i + 1}
                        </span>
                      </a>
                    ))}
                  </div>
                </div>
              )}

              {/* Replies thread */}
              {selectedTicket.replies.length > 0 && (
                <div className="px-6 py-5 border-b border-gray-100">
                  <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-3">
                    Replies ({selectedTicket.replies.length})
                  </p>
                  <div className="space-y-3">
                    {selectedTicket.replies.map((reply, i) => (
                      <div
                        key={i}
                        className={`rounded-xl p-4 ${
                          reply.isAdmin
                            ? "bg-indigo-50 border border-indigo-100"
                            : "bg-gray-50 border border-gray-200"
                        }`}
                      >
                        <div className="flex items-center justify-between mb-2">
                          <div className="flex items-center gap-2">
                            <div
                              className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold ${
                                reply.isAdmin
                                  ? "bg-indigo-200 text-indigo-700"
                                  : "bg-gray-200 text-gray-600"
                              }`}
                            >
                              {reply.isAdmin ? "A" : "U"}
                            </div>
                            <span
                              className={`text-xs font-semibold ${
                                reply.isAdmin ? "text-indigo-700" : "text-gray-700"
                              }`}
                            >
                              {reply.isAdmin ? "Admin" : "User"}
                            </span>
                            {reply.isAdmin && (
                              <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-indigo-200 text-indigo-700 font-bold">
                                STAFF
                              </span>
                            )}
                          </div>
                          <span className="text-[10px] text-gray-400">
                            {formatDateTime(reply.createdAt)}
                          </span>
                        </div>
                        <p className="text-sm text-gray-700 leading-relaxed whitespace-pre-wrap">
                          {reply.text}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Status change + actions */}
              <div className="px-6 py-5 border-b border-gray-100">
                <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-3">
                  Status
                </p>
                <div className="flex items-center gap-3">
                  <StatusBadge status={selectedTicket.status} />
                  <div className="relative">
                    <button
                      onClick={() => setShowStatusDropdown(!showStatusDropdown)}
                      disabled={statusChanging || selectedTicket.status === "closed"}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white border border-gray-200 text-xs font-semibold text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {statusChanging ? (
                        <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      ) : (
                        <ChevronDown className="w-3.5 h-3.5" />
                      )}
                      Change Status
                    </button>
                    {showStatusDropdown && (
                      <div className="absolute left-0 top-full mt-1 w-44 bg-white rounded-xl shadow-lg border border-gray-200 z-10 overflow-hidden">
                        {Object.entries(STATUS_CONFIG).map(([key, cfg]) => {
                          const Icon = cfg.icon;
                          return (
                            <button
                              key={key}
                              onClick={() => handleUpdateStatus(selectedTicket.id, key)}
                              className={`w-full flex items-center gap-2.5 px-4 py-2.5 text-sm font-medium transition-colors hover:bg-gray-50 ${
                                selectedTicket.status === key
                                  ? "text-indigo-600 bg-indigo-50"
                                  : "text-gray-700"
                              }`}
                            >
                              <Icon className="w-4 h-4" />
                              {cfg.label}
                            </button>
                          );
                        })}
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Reply textarea */}
              {selectedTicket.status !== "closed" && (
                <div className="px-6 py-5 border-b border-gray-100">
                  <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-3">
                    Send Reply
                  </p>
                  <textarea
                    value={replyText}
                    onChange={(e) => setReplyText(e.target.value)}
                    placeholder="Type your reply to the customer..."
                    rows={4}
                    className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 resize-none transition-all"
                  />
                  <button
                    onClick={handleSendReply}
                    disabled={replying || !replyText.trim()}
                    className="mt-3 w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {replying ? (
                      <Loader2 className="w-4 h-4 animate-spin" />
                    ) : (
                      <Send className="w-4 h-4" />
                    )}
                    {replying ? "Sending..." : "Send Reply"}
                  </button>
                </div>
              )}

              {/* Close ticket */}
              {selectedTicket.status !== "closed" && (
                <div className="px-6 py-5">
                  <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-3">
                    Close Ticket
                  </p>
                  <button
                    onClick={handleCloseTicket}
                    disabled={closing}
                    className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-gray-100 text-gray-700 border border-gray-200 text-sm font-semibold hover:bg-rose-50 hover:text-rose-700 hover:border-rose-200 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {closing ? (
                      <Loader2 className="w-4 h-4 animate-spin" />
                    ) : (
                      <XCircle className="w-4 h-4" />
                    )}
                    {closing ? "Closing..." : "Close Ticket"}
                  </button>
                </div>
              )}

              {selectedTicket.status === "closed" && (
                <div className="px-6 py-5">
                  <div className="flex items-center gap-3 px-4 py-3.5 rounded-xl bg-gray-50 border border-gray-200">
                    <XCircle className="w-5 h-5 text-gray-400 flex-shrink-0" />
                    <p className="text-sm text-gray-500 font-medium">
                      This ticket is closed. No further replies can be sent.
                    </p>
                  </div>
                </div>
              )}
            </div>

            {/* Drawer footer */}
            <div className="px-6 py-4 border-t border-gray-100 bg-gray-50/50 flex-shrink-0">
              <div className="flex items-center gap-2">
                <Hash className="w-3 h-3 text-gray-400" />
                <p className="text-xs text-gray-400 font-mono">{selectedTicket.id}</p>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
