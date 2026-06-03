"use client";

import { useState, useEffect } from "react";
import {
  MessageSquare,
  Clock,
  CheckCircle,
  XCircle,
  ChevronDown,
  ChevronUp,
  User,
  Mail,
  Tag,
  RefreshCw,
} from "lucide-react";
import toast from "react-hot-toast";

const getToken = () =>
  typeof window !== "undefined" ? localStorage.getItem("pb_admin_token") ?? "" : "";

const apiCall = async (url: string, options: RequestInit = {}) => {
  const res = await fetch(url, {
    ...options,
    headers: {
      Authorization: `Bearer ${getToken()}`,
      "Content-Type": "application/json",
      ...(options.headers ?? {}),
    },
  });
  if (!res.ok) throw new Error((await res.json().catch(() => ({}))).error || res.statusText);
  return res.json();
};

interface Ticket {
  id: string;
  userId: string;
  userName: string;
  userEmail: string;
  category: string;
  subject: string;
  description: string;
  status: "open" | "in_progress" | "resolved" | "closed";
  priority: "low" | "medium" | "high";
  createdAt: string | null;
  updatedAt: string | null;
}

const statusConfig = {
  open: {
    label: "Open",
    color: "text-amber-700 bg-amber-50 border-amber-200",
    icon: Clock,
  },
  in_progress: {
    label: "In Progress",
    color: "text-blue-700 bg-blue-50 border-blue-200",
    icon: RefreshCw,
  },
  resolved: {
    label: "Resolved",
    color: "text-emerald-700 bg-emerald-50 border-emerald-200",
    icon: CheckCircle,
  },
  closed: {
    label: "Closed",
    color: "text-gray-600 bg-gray-100 border-gray-200",
    icon: XCircle,
  },
};

const priorityConfig = {
  low: { label: "Low", color: "text-gray-500" },
  medium: { label: "Medium", color: "text-amber-600" },
  high: { label: "High", color: "text-red-600" },
};

export default function SupportTicketsPage() {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [filterStatus, setFilterStatus] = useState<string>("all");
  const [updatingId, setUpdatingId] = useState<string | null>(null);
  const [adminNotes, setAdminNotes] = useState<Record<string, string>>({});

  const loadTickets = async () => {
    setLoading(true);
    try {
      const data = await apiCall("/api/support");
      const list: Ticket[] = data.tickets ?? [];
      setTickets(list);
      const notes: Record<string, string> = {};
      list.forEach((t: any) => {
        if (t.adminNote) notes[t.id] = t.adminNote;
      });
      setAdminNotes(notes);
    } catch {
      toast.error("Failed to load support tickets.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadTickets();
  }, []);

  const updateStatus = async (ticketId: string, status: Ticket["status"]) => {
    setUpdatingId(ticketId);
    try {
      await apiCall("/api/support", {
        method: "POST",
        body: JSON.stringify({ action: "update_status", ticketId, status }),
      });
      toast.success(`Ticket marked as ${statusConfig[status].label}`);
      await loadTickets();
    } catch {
      toast.error("Failed to update ticket");
    } finally {
      setUpdatingId(null);
    }
  };

  const filteredTickets =
    filterStatus === "all" ? tickets : tickets.filter((t) => t.status === filterStatus);

  const counts = {
    all: tickets.length,
    open: tickets.filter((t) => t.status === "open").length,
    in_progress: tickets.filter((t) => t.status === "in_progress").length,
    resolved: tickets.filter((t) => t.status === "resolved").length,
    closed: tickets.filter((t) => t.status === "closed").length,
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="flex flex-col items-center gap-3">
          <RefreshCw className="w-8 h-8 text-indigo-500 animate-spin" />
          <p className="text-sm text-gray-500">Loading tickets...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Stats row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
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
          <div key={label} className={`${bg} border ${border} rounded-2xl p-4 flex items-center gap-4`}>
            <div className={`w-10 h-10 rounded-xl ${iconBg} flex items-center justify-center`}>
              <Icon className={`w-5 h-5 ${iconColor}`} />
            </div>
            <div>
              <p className={`text-2xl font-bold ${textColor}`}>{count}</p>
              <p className="text-xs text-gray-500 font-medium">{label}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Filter tabs */}
      <div className="bg-gray-100 border border-gray-200 rounded-2xl p-1 flex gap-1 w-fit flex-wrap">
        {["all", "open", "in_progress", "resolved", "closed"].map((s) => (
          <button
            key={s}
            onClick={() => setFilterStatus(s)}
            className={`px-4 py-2 rounded-xl text-sm font-medium transition-all duration-200 ${
              filterStatus === s
                ? "bg-indigo-600 text-white shadow-sm"
                : "text-gray-600 hover:text-gray-900 hover:bg-white"
            }`}
          >
            {s === "all"
              ? "All"
              : s.replace("_", " ").replace(/\b\w/g, (c) => c.toUpperCase())}
            <span
              className={`ml-2 text-xs ${
                filterStatus === s ? "text-indigo-200" : "text-gray-400"
              }`}
            >
              {counts[s as keyof typeof counts]}
            </span>
          </button>
        ))}
      </div>

      {/* Ticket list */}
      {filteredTickets.length === 0 ? (
        <div className="bg-white border border-gray-200 rounded-2xl p-16 flex flex-col items-center gap-4 text-center">
          <div className="w-16 h-16 rounded-2xl bg-gray-100 flex items-center justify-center">
            <MessageSquare className="w-8 h-8 text-gray-400" />
          </div>
          <div>
            <p className="text-gray-700 font-semibold text-lg">No tickets found</p>
            <p className="text-gray-500 text-sm mt-1">
              {filterStatus === "all"
                ? "No support tickets have been submitted yet."
                : `No ${filterStatus.replace("_", " ")} tickets.`}
            </p>
          </div>
        </div>
      ) : (
        <div className="space-y-3">
          {filteredTickets.map((ticket) => {
            const status = statusConfig[ticket.status] || statusConfig.open;
            const StatusIcon = status.icon;
            const isExpanded = expandedId === ticket.id;

            return (
              <div
                key={ticket.id}
                className="bg-white border border-gray-200 rounded-2xl overflow-hidden transition-all duration-200 hover:border-gray-300 hover:shadow-sm"
              >
                {/* Header row */}
                <button
                  className="w-full flex items-center gap-4 p-5 text-left"
                  onClick={() => setExpandedId(isExpanded ? null : ticket.id)}
                >
                  <div className="w-10 h-10 rounded-xl bg-indigo-50 flex items-center justify-center shrink-0">
                    <MessageSquare className="w-5 h-5 text-indigo-500" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <p className="text-sm font-semibold text-gray-900">{ticket.subject}</p>
                      {ticket.priority === "high" && (
                        <span className="text-[10px] font-bold text-red-700 bg-red-50 border border-red-200 px-2 py-0.5 rounded-full">
                          HIGH PRIORITY
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-3 mt-0.5 flex-wrap">
                      <span className="text-xs text-gray-500 flex items-center gap-1">
                        <User className="w-3 h-3" /> {ticket.userName}
                      </span>
                      <span className="text-xs text-gray-500 flex items-center gap-1">
                        <Tag className="w-3 h-3" /> {ticket.category}
                      </span>
                      {ticket.createdAt && (
                        <span className="text-xs text-gray-400">
                          {new Date(ticket.createdAt).toLocaleDateString("en-US", {
                            month: "short",
                            day: "numeric",
                            year: "numeric",
                          })}
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-3 shrink-0">
                    <span
                      className={`text-xs font-semibold px-3 py-1 rounded-full border ${status.color} flex items-center gap-1.5`}
                    >
                      <StatusIcon className="w-3 h-3" />
                      {status.label}
                    </span>
                    {isExpanded ? (
                      <ChevronUp className="w-4 h-4 text-gray-400" />
                    ) : (
                      <ChevronDown className="w-4 h-4 text-gray-400" />
                    )}
                  </div>
                </button>

                {/* Expanded detail */}
                {isExpanded && (
                  <div className="border-t border-gray-200 p-5 space-y-5 bg-gray-50">
                    {/* User info */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="bg-white border border-gray-200 rounded-xl p-4">
                        <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">
                          Customer
                        </p>
                        <p className="text-sm font-semibold text-gray-900">{ticket.userName}</p>
                        <p className="text-xs text-gray-500 flex items-center gap-1 mt-1">
                          <Mail className="w-3 h-3" /> {ticket.userEmail}
                        </p>
                      </div>
                      <div className="bg-white border border-gray-200 rounded-xl p-4">
                        <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">
                          Category
                        </p>
                        <p className="text-sm font-semibold text-gray-900">{ticket.category}</p>
                        <p
                          className={`text-xs font-semibold mt-1 ${
                            priorityConfig[ticket.priority]?.color ?? "text-gray-500"
                          }`}
                        >
                          {priorityConfig[ticket.priority]?.label ?? "Medium"} priority
                        </p>
                      </div>
                    </div>

                    {/* Message */}
                    <div className="bg-white border border-gray-200 rounded-xl p-4">
                      <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">
                        Message
                      </p>
                      <p className="text-sm text-gray-700 leading-relaxed whitespace-pre-wrap">
                        {ticket.description}
                      </p>
                    </div>

                    {/* Admin note */}
                    <div>
                      <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">
                        Admin Note
                      </p>
                      <textarea
                        className="w-full bg-white border border-gray-200 rounded-xl px-4 py-3 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 resize-none transition-all"
                        rows={3}
                        placeholder="Add internal note..."
                        value={adminNotes[ticket.id] ?? ""}
                        onChange={(e) =>
                          setAdminNotes((p) => ({ ...p, [ticket.id]: e.target.value }))
                        }
                      />
                    </div>

                    {/* Actions */}
                    <div className="flex flex-wrap gap-2">
                      {(["open", "in_progress", "resolved", "closed"] as Ticket["status"][]).map(
                        (s) => {
                          const cfg = statusConfig[s];
                          const Icon = cfg.icon;
                          return (
                            <button
                              key={s}
                              disabled={ticket.status === s || updatingId === ticket.id}
                              onClick={() => updateStatus(ticket.id, s)}
                              className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold border transition-all duration-200 disabled:opacity-40 ${
                                ticket.status === s
                                  ? cfg.color
                                  : "text-gray-600 border-gray-200 hover:border-gray-400 hover:text-gray-900 bg-white"
                              }`}
                            >
                              <Icon className="w-3.5 h-3.5" />
                              {cfg.label}
                            </button>
                          );
                        }
                      )}
                      {updatingId === ticket.id && (
                        <RefreshCw className="w-4 h-4 text-indigo-500 animate-spin self-center ml-2" />
                      )}
                    </div>

                    <p className="text-[10px] text-gray-400 font-mono">ID: {ticket.id}</p>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
