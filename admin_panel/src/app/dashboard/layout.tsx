"use client";

import { useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";
import { useAuth } from "@/lib/AuthContext";
import Sidebar from "@/components/Sidebar";
import { Toaster } from "react-hot-toast";
import { Loader2 } from "lucide-react";

const pageTitles: Record<string, string> = {
  "/dashboard": "Overview",
  "/dashboard/users": "User Oversight",
  "/dashboard/transactions": "All Transactions",
  "/dashboard/approval-queue": "Approval Queue",
  "/dashboard/support-tickets": "Support Tickets",
  "/dashboard/create-transaction": "Create Transaction",
  "/dashboard/create-user": "Create User",
  "/dashboard/status-logs": "Status Logs",
  "/dashboard/system-config": "System Configuration",
};

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const { user, isAdmin, loading } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (!loading && (!user || !isAdmin)) {
      router.push("/login");
    }
  }, [user, isAdmin, loading, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-100">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="w-10 h-10 text-indigo-600 animate-spin" />
          <p className="text-sm text-gray-500 font-medium">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  if (!user || !isAdmin) {
    return null;
  }

  const currentTitle =
    pageTitles[pathname] ||
    (pathname.startsWith("/dashboard/users/") ? "User Details" : "Dashboard");

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
        {/* Top header bar */}
        <header className="h-16 bg-white/80 backdrop-blur-sm border-b border-gray-200/60 flex items-center justify-between px-8 flex-shrink-0">
          <h1 className="text-lg font-bold text-gray-900">{currentTitle}</h1>
          <div className="flex items-center gap-3">
            <span className="text-sm text-gray-500">{user?.email}</span>
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center">
              <span className="text-xs font-bold text-white">
                {user?.email?.charAt(0).toUpperCase() || "A"}
              </span>
            </div>
          </div>
        </header>
        <main className="flex-1 p-8 overflow-auto">{children}</main>
      </div>
    </div>
  );
}
