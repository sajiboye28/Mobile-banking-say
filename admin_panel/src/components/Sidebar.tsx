"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { useAuth } from "@/lib/AuthContext";
import {
  LayoutDashboard,
  Users,
  ArrowLeftRight,
  ClipboardCheck,
  PlusCircle,
  UserPlus,
  FileText,
  Settings,
  LogOut,
  Landmark,
  Shield,
  MessageSquare,
  SlidersHorizontal,
} from "lucide-react";

const navGroups = [
  {
    label: "Main",
    items: [
      { label: "Overview", href: "/dashboard", icon: LayoutDashboard },
      { label: "Users", href: "/users", icon: Users },
      { label: "Transactions", href: "/dashboard/transactions", icon: ArrowLeftRight },
      { label: "Approval Queue", href: "/dashboard/approval-queue", icon: ClipboardCheck },
    ],
  },
  {
    label: "Support & Compliance",
    items: [
      { label: "Support Tickets", href: "/support", icon: MessageSquare },
      { label: "KYC Review", href: "/kyc", icon: Shield },
    ],
  },
  {
    label: "Administration",
    items: [
      { label: "System Config", href: "/config", icon: SlidersHorizontal },
      { label: "Create Transaction", href: "/dashboard/create-transaction", icon: PlusCircle },
      { label: "Create User", href: "/dashboard/create-user", icon: UserPlus },
      { label: "Status Logs", href: "/dashboard/status-logs", icon: FileText },
      { label: "Settings (Legacy)", href: "/dashboard/system-config", icon: Settings },
    ],
  },
];

export default function Sidebar() {
  const pathname = usePathname();
  const { logout, user } = useAuth();
  const [pendingCount, setPendingCount] = useState(0);

  useEffect(() => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('pb_admin_token') ?? '' : '';
    if (!token) return;
    const fetchPending = async () => {
      try {
        const res = await fetch('/api/users?status=pending&limit=1', {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (res.ok) {
          const data = await res.json();
          setPendingCount(data.pagination?.total ?? data.users?.length ?? 0);
        }
      } catch { /* silently ignore */ }
    };
    fetchPending();
    const interval = setInterval(fetchPending, 60000);
    return () => clearInterval(interval);
  }, []);

  return (
    <aside className="w-[272px] bg-slate-950 min-h-screen flex flex-col border-r border-slate-800/50">
      {/* Logo area */}
      <div className="px-6 py-5 border-b border-slate-800/50">
        <div className="flex items-center gap-3">
          {/* Use white/light logo (logo1.png) since sidebar is dark */}
          <img src="/logo1.png" alt="STCU" className="h-10 w-auto object-contain" />
        </div>
        <p className="text-[10px] text-slate-500 font-medium tracking-widest uppercase mt-2">
          Admin Control Panel
        </p>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 space-y-4 overflow-y-auto">
        {navGroups.map((group) => (
          <div key={group.label}>
            <p className="px-3 mb-1.5 text-[10px] font-bold text-slate-600 uppercase tracking-widest">
              {group.label}
            </p>
            <div className="space-y-0.5">
              {group.items.map((item) => {
                const isActive =
                  pathname === item.href ||
                  (item.href !== "/dashboard" && pathname.startsWith(item.href));
                const Icon = item.icon;
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={`relative flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200 group ${
                      isActive
                        ? "bg-indigo-600/20 text-indigo-400"
                        : "text-slate-400 hover:bg-slate-800/60 hover:text-slate-200"
                    }`}
                  >
                    {isActive && (
                      <div className="absolute left-0 top-1/2 -translate-y-1/2 w-[3px] h-6 bg-indigo-500 rounded-r-full" />
                    )}
                    <Icon
                      className={`w-[18px] h-[18px] transition-colors duration-200 ${
                        isActive
                          ? "text-indigo-400"
                          : "text-slate-500 group-hover:text-slate-300"
                      }`}
                    />
                    <span>{item.label}</span>
                    {item.href === "/dashboard/approval-queue" && pendingCount > 0 && (
                      <span className="ml-auto bg-red-500 text-white text-xs font-bold px-1.5 py-0.5 rounded-full min-w-[18px] text-center">
                        {pendingCount > 99 ? '99+' : pendingCount}
                      </span>
                    )}
                    {isActive && (
                      <div className="absolute inset-0 rounded-xl bg-indigo-400/5 pointer-events-none" />
                    )}
                  </Link>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      {/* User section */}
      <div className="px-3 py-4 border-t border-slate-800/50">
        <div className="flex items-center gap-3 px-3 mb-3">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-indigo-600 to-purple-600 flex items-center justify-center ring-2 ring-indigo-500/20">
            <span className="text-sm font-bold text-white">
              {user?.email?.charAt(0).toUpperCase() || "A"}
            </span>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-slate-200 truncate">
              {user?.email || "Admin"}
            </p>
            <div className="flex items-center gap-1 mt-0.5">
              <Shield className="w-3 h-3 text-indigo-400" />
              <span className="text-[11px] text-indigo-400 font-semibold">Administrator</span>
            </div>
          </div>
        </div>
        <button
          onClick={logout}
          className="flex items-center gap-2 w-full px-3 py-2.5 text-sm text-slate-500 hover:text-rose-400 hover:bg-rose-500/10 rounded-xl transition-all duration-200 font-medium"
        >
          <LogOut className="w-[18px] h-[18px]" />
          Sign Out
        </button>
      </div>
    </aside>
  );
}
