"use client";

import { useEffect, useState } from "react";
import { ArrowRight, FileText, Loader2, RefreshCw } from "lucide-react";

const getToken = () =>
  typeof window !== "undefined" ? localStorage.getItem("pb_admin_token") ?? "" : "";

interface StatusLog {
  id: string;
  userId: string;
  previousStatus: string;
  newStatus: string;
  changedAt: string | null;
  changedBy: string;
}

export default function StatusLogsPage() {
  const [logs, setLogs] = useState<StatusLog[]>([]);
  const [loading, setLoading] = useState(true);

  const loadLogs = async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/status-logs", {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      if (res.ok) {
        const data = await res.json();
        setLogs(data.logs ?? []);
      }
      // If endpoint doesn't exist (404) — show empty state gracefully
    } catch {
      // Network error — show empty state
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadLogs();
  }, []);

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

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-10 h-10 text-indigo-600 animate-spin" />
      </div>
    );
  }

  return (
    <div className="animate-fade-in">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Status Change Logs</h1>
          <p className="text-sm text-gray-500 mt-0.5">{logs.length} log entries</p>
        </div>
        <button
          onClick={loadLogs}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-white border border-gray-200 text-sm font-semibold text-gray-700 hover:bg-gray-50 transition-colors shadow-sm"
        >
          <RefreshCw className="w-4 h-4" />
          Refresh
        </button>
      </div>

      {logs.length === 0 ? (
        <div className="card text-center py-16">
          <div className="w-20 h-20 mx-auto mb-5 rounded-2xl bg-gradient-to-br from-slate-50 to-gray-100 flex items-center justify-center">
            <FileText className="w-10 h-10 text-gray-300" />
          </div>
          <h2 className="text-xl font-bold text-gray-800">No Status Logs</h2>
          <p className="text-gray-500 mt-2 max-w-sm mx-auto">
            Account status change logs will appear here when admins modify user statuses.
          </p>
        </div>
      ) : (
        <div className="card overflow-hidden p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="table-header">
                  <th>User ID</th>
                  <th className="text-center">Previous Status</th>
                  <th className="text-center w-12"></th>
                  <th className="text-center">New Status</th>
                  <th>Changed By</th>
                  <th>Timestamp</th>
                </tr>
              </thead>
              <tbody>
                {logs.map((log) => (
                  <tr key={log.id} className="table-row">
                    <td className="font-mono text-xs text-gray-400">
                      {log.userId?.substring(0, 16)}...
                    </td>
                    <td className="text-center">{getStatusBadge(log.previousStatus)}</td>
                    <td className="text-center">
                      <div className="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center mx-auto">
                        <ArrowRight className="w-4 h-4 text-indigo-500" />
                      </div>
                    </td>
                    <td className="text-center">{getStatusBadge(log.newStatus)}</td>
                    <td className="text-gray-600 capitalize font-medium">{log.changedBy}</td>
                    <td className="text-xs text-gray-500">
                      {log.changedAt ? new Date(log.changedAt).toLocaleString() : "N/A"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
