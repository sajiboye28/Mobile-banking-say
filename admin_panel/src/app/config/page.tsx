"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/AuthContext";
import Sidebar from "@/components/Sidebar";

const getToken = () => typeof window !== 'undefined' ? localStorage.getItem('pb_admin_token') ?? '' : '';
import { Toaster } from "react-hot-toast";
import toast from "react-hot-toast";
import {
  Settings,
  AlertTriangle,
  DollarSign,
  ArrowLeftRight,
  Shield,
  Bell,
  Save,
  Loader2,
  RefreshCw,
  Trash2,
  Download,
  RotateCcw,
  X,
  CheckCircle,
  FileText,
} from "lucide-react";

interface SystemConfig {
  // Maintenance
  maintenanceMode: boolean;
  maintenanceMessage: string;
  // Transaction limits
  dailySendLimit: number;
  maxSingleTransaction: number;
  minTransaction: number;
  // Deposit limits
  maxDepositPerDay: number;
  minDeposit: number;
  // KYC settings
  kycRequiredAbove: number;
  autoApproveKyc: boolean;
  // Notification templates
  welcomeMessage: string;
  transactionSuccessMessage: string;
  kycApprovedMessage: string;
}

const DEFAULT_CONFIG: SystemConfig = {
  maintenanceMode: false,
  maintenanceMessage:
    "We are currently performing scheduled maintenance. Please check back soon.",
  dailySendLimit: 10000,
  maxSingleTransaction: 5000,
  minTransaction: 1,
  maxDepositPerDay: 50000,
  minDeposit: 10,
  kycRequiredAbove: 1000,
  autoApproveKyc: false,
  welcomeMessage: "Welcome to STCU! Your account is ready.",
  transactionSuccessMessage: "Your transaction was completed successfully.",
  kycApprovedMessage:
    "Your identity has been verified. You now have full access to all banking features.",
};

interface ConfirmModal {
  title: string;
  message: string;
  confirmLabel: string;
  confirmClass: string;
  onConfirm: () => void;
}

function Toggle({
  enabled,
  onChange,
  disabled = false,
}: {
  enabled: boolean;
  onChange: (val: boolean) => void;
  disabled?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={() => !disabled && onChange(!enabled)}
      disabled={disabled}
      className={`relative inline-flex h-7 w-12 flex-shrink-0 rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed ${
        enabled ? "bg-indigo-600" : "bg-gray-300"
      }`}
    >
      <span
        className={`pointer-events-none inline-block h-6 w-6 transform rounded-full bg-white shadow-md ring-0 transition duration-200 ease-in-out ${
          enabled ? "translate-x-5" : "translate-x-0"
        }`}
      />
    </button>
  );
}

function SectionCard({
  icon: Icon,
  title,
  iconColor = "text-indigo-600",
  iconBg = "bg-indigo-50",
  children,
  className = "",
}: {
  icon: React.ElementType;
  title: string;
  iconColor?: string;
  iconBg?: string;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden ${className}`}
    >
      <div className="flex items-center gap-3 px-6 py-5 border-b border-gray-100">
        <div className={`w-9 h-9 rounded-xl ${iconBg} flex items-center justify-center`}>
          <Icon className={`w-5 h-5 ${iconColor}`} />
        </div>
        <h3 className="text-base font-bold text-gray-900">{title}</h3>
      </div>
      <div className="px-6 py-5">{children}</div>
    </div>
  );
}

function NumberField({
  label,
  value,
  onChange,
  prefix = "$",
  min = 0,
  step = 1,
}: {
  label: string;
  value: number;
  onChange: (val: number) => void;
  prefix?: string;
  min?: number;
  step?: number;
}) {
  return (
    <div>
      <label className="block text-sm font-semibold text-gray-700 mb-1.5">{label}</label>
      <div className="relative">
        {prefix && (
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm font-semibold text-gray-400">
            {prefix}
          </span>
        )}
        <input
          type="number"
          min={min}
          step={step}
          value={value}
          onChange={(e) => onChange(parseFloat(e.target.value) || 0)}
          className={`w-full ${prefix ? "pl-7" : "pl-3"} pr-3 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-900 font-medium focus:outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 transition-all`}
        />
      </div>
    </div>
  );
}

export default function ConfigPage() {
  const { user, isAdmin, loading: authLoading } = useAuth();
  const router = useRouter();

  const [config, setConfig] = useState<SystemConfig>(DEFAULT_CONFIG);
  const [fetching, setFetching] = useState(true);
  const [saving, setSaving] = useState<string | null>(null); // which section is saving
  const [confirmModal, setConfirmModal] = useState<ConfirmModal | null>(null);
  const [showMaintenanceModal, setShowMaintenanceModal] = useState(false);
  const [pendingMaintenance, setPendingMaintenance] = useState(false);

  useEffect(() => {
    if (!authLoading && (!user || !isAdmin)) {
      router.push("/login");
    }
  }, [user, isAdmin, authLoading, router]);

  const fetchConfig = useCallback(async () => {
    if (!user) return;
    setFetching(true);
    try {
      const token = getToken();
      const res = await fetch("/api/config", {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) throw new Error("Failed to fetch config");
      const data = await res.json();
      setConfig((prev) => ({ ...prev, ...data.config }));
    } catch {
      toast.error("Failed to load configuration");
    } finally {
      setFetching(false);
    }
  }, [user]);

  useEffect(() => {
    if (user && isAdmin) {
      fetchConfig();
    }
  }, [user, isAdmin, fetchConfig]);

  const saveFields = async (
    fields: Partial<SystemConfig>,
    sectionKey: string,
    successMsg = "Settings saved"
  ) => {
    setSaving(sectionKey);
    try {
      const token = getToken();
      const res = await fetch("/api/config", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(fields),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Failed to save");
      setConfig((prev) => ({ ...prev, ...fields }));
      toast.success(successMsg);
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Failed to save settings");
    } finally {
      setSaving(null);
    }
  };

  const handleMaintenanceToggle = (value: boolean) => {
    if (value) {
      // Show warning modal before enabling
      setPendingMaintenance(true);
      setShowMaintenanceModal(true);
    } else {
      // Disable directly
      saveFields({ maintenanceMode: false }, "maintenance", "Maintenance mode disabled");
    }
  };

  const confirmMaintenance = async () => {
    setShowMaintenanceModal(false);
    await saveFields({ maintenanceMode: true }, "maintenance", "Maintenance mode enabled");
    setPendingMaintenance(false);
  };

  const update = <K extends keyof SystemConfig>(key: K, value: SystemConfig[K]) => {
    setConfig((prev) => ({ ...prev, [key]: value }));
  };

  if (authLoading || fetching) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-100">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="w-10 h-10 text-indigo-600 animate-spin" />
          <p className="text-sm text-gray-500 font-medium">Loading configuration...</p>
        </div>
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
          <h1 className="text-lg font-bold text-gray-900">System Configuration</h1>
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
          <div className="animate-fade-in max-w-4xl mx-auto">
            {/* Page header */}
            <div className="flex items-center justify-between mb-8">
              <div>
                <h2 className="text-2xl font-bold text-gray-900">System Configuration</h2>
                <p className="text-sm text-gray-500 mt-0.5">
                  Manage global application settings and limits
                </p>
              </div>
              <button
                onClick={fetchConfig}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-white border border-gray-200 text-sm font-semibold text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-all shadow-sm"
              >
                <RefreshCw className="w-4 h-4" />
                Reload
              </button>
            </div>

            <div className="space-y-6">
              {/* Maintenance Mode */}
              <SectionCard
                icon={AlertTriangle}
                title="Maintenance Mode"
                iconColor="text-rose-600"
                iconBg="bg-rose-50"
              >
                <div className="space-y-4">
                  <div
                    className={`flex items-center justify-between p-4 rounded-xl border-2 transition-colors ${
                      config.maintenanceMode
                        ? "bg-rose-50 border-rose-200"
                        : "bg-gray-50 border-gray-200"
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                          config.maintenanceMode ? "bg-rose-100" : "bg-gray-100"
                        }`}
                      >
                        <AlertTriangle
                          className={`w-5 h-5 ${
                            config.maintenanceMode ? "text-rose-600" : "text-gray-500"
                          }`}
                        />
                      </div>
                      <div>
                        <p
                          className={`text-sm font-bold ${
                            config.maintenanceMode ? "text-rose-700" : "text-gray-700"
                          }`}
                        >
                          Maintenance Mode
                        </p>
                        <p
                          className={`text-xs ${
                            config.maintenanceMode ? "text-rose-500" : "text-gray-500"
                          }`}
                        >
                          {config.maintenanceMode
                            ? "App is currently in maintenance — all users see maintenance screen"
                            : "App is live and accessible to all users"}
                        </p>
                      </div>
                    </div>
                    <Toggle
                      enabled={config.maintenanceMode}
                      onChange={handleMaintenanceToggle}
                      disabled={saving === "maintenance"}
                    />
                  </div>

                  {config.maintenanceMode && (
                    <div className="flex items-start gap-3 px-4 py-3 rounded-xl bg-rose-100 border border-rose-200">
                      <AlertTriangle className="w-4 h-4 text-rose-600 flex-shrink-0 mt-0.5" />
                      <p className="text-xs text-rose-700 font-medium">
                        All users are currently blocked from accessing the app.
                        Disable maintenance mode to restore access.
                      </p>
                    </div>
                  )}

                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                      Maintenance Message
                    </label>
                    <textarea
                      value={config.maintenanceMessage}
                      onChange={(e) => update("maintenanceMessage", e.target.value)}
                      rows={3}
                      placeholder="Message shown to users during maintenance..."
                      className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 resize-none transition-all"
                    />
                  </div>

                  <button
                    onClick={() =>
                      saveFields(
                        { maintenanceMessage: config.maintenanceMessage },
                        "maintenanceMsg",
                        "Maintenance message saved"
                      )
                    }
                    disabled={saving === "maintenanceMsg"}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition-colors disabled:opacity-50"
                  >
                    {saving === "maintenanceMsg" ? (
                      <Loader2 className="w-4 h-4 animate-spin" />
                    ) : (
                      <Save className="w-4 h-4" />
                    )}
                    Save Message
                  </button>
                </div>
              </SectionCard>

              {/* Transaction Limits */}
              <SectionCard
                icon={ArrowLeftRight}
                title="Transaction Limits"
                iconColor="text-indigo-600"
                iconBg="bg-indigo-50"
              >
                <div className="space-y-4">
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <NumberField
                      label="Daily Send Limit"
                      value={config.dailySendLimit}
                      onChange={(v) => update("dailySendLimit", v)}
                    />
                    <NumberField
                      label="Max Single Transaction"
                      value={config.maxSingleTransaction}
                      onChange={(v) => update("maxSingleTransaction", v)}
                    />
                    <NumberField
                      label="Min Transaction Amount"
                      value={config.minTransaction}
                      onChange={(v) => update("minTransaction", v)}
                      min={0.01}
                      step={0.01}
                    />
                  </div>
                  <div className="flex justify-end">
                    <button
                      onClick={() =>
                        saveFields(
                          {
                            dailySendLimit: config.dailySendLimit,
                            maxSingleTransaction: config.maxSingleTransaction,
                            minTransaction: config.minTransaction,
                          },
                          "txLimits",
                          "Transaction limits saved"
                        )
                      }
                      disabled={saving === "txLimits"}
                      className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition-colors disabled:opacity-50"
                    >
                      {saving === "txLimits" ? (
                        <Loader2 className="w-4 h-4 animate-spin" />
                      ) : (
                        <Save className="w-4 h-4" />
                      )}
                      Save Limits
                    </button>
                  </div>
                </div>
              </SectionCard>

              {/* Deposit Limits */}
              <SectionCard
                icon={DollarSign}
                title="Deposit Limits"
                iconColor="text-emerald-600"
                iconBg="bg-emerald-50"
              >
                <div className="space-y-4">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <NumberField
                      label="Max Deposit Per Day"
                      value={config.maxDepositPerDay}
                      onChange={(v) => update("maxDepositPerDay", v)}
                    />
                    <NumberField
                      label="Min Deposit Amount"
                      value={config.minDeposit}
                      onChange={(v) => update("minDeposit", v)}
                      min={0.01}
                      step={0.01}
                    />
                  </div>
                  <div className="flex justify-end">
                    <button
                      onClick={() =>
                        saveFields(
                          {
                            maxDepositPerDay: config.maxDepositPerDay,
                            minDeposit: config.minDeposit,
                          },
                          "depositLimits",
                          "Deposit limits saved"
                        )
                      }
                      disabled={saving === "depositLimits"}
                      className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition-colors disabled:opacity-50"
                    >
                      {saving === "depositLimits" ? (
                        <Loader2 className="w-4 h-4 animate-spin" />
                      ) : (
                        <Save className="w-4 h-4" />
                      )}
                      Save Limits
                    </button>
                  </div>
                </div>
              </SectionCard>

              {/* KYC Settings */}
              <SectionCard
                icon={Shield}
                title="KYC Settings"
                iconColor="text-violet-600"
                iconBg="bg-violet-50"
              >
                <div className="space-y-4">
                  <NumberField
                    label="Require KYC for Transactions Over ($)"
                    value={config.kycRequiredAbove}
                    onChange={(v) => update("kycRequiredAbove", v)}
                  />
                  <div className="flex items-center justify-between p-4 bg-gray-50 rounded-xl border border-gray-200">
                    <div>
                      <p className="text-sm font-semibold text-gray-700">Auto-approve KYC</p>
                      <p className="text-xs text-gray-500 mt-0.5">
                        Automatically approve all KYC submissions without manual review
                      </p>
                    </div>
                    <Toggle
                      enabled={config.autoApproveKyc}
                      onChange={(v) => update("autoApproveKyc", v)}
                    />
                  </div>
                  <div className="flex justify-end">
                    <button
                      onClick={() =>
                        saveFields(
                          {
                            kycRequiredAbove: config.kycRequiredAbove,
                            autoApproveKyc: config.autoApproveKyc,
                          },
                          "kycSettings",
                          "KYC settings saved"
                        )
                      }
                      disabled={saving === "kycSettings"}
                      className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition-colors disabled:opacity-50"
                    >
                      {saving === "kycSettings" ? (
                        <Loader2 className="w-4 h-4 animate-spin" />
                      ) : (
                        <Save className="w-4 h-4" />
                      )}
                      Save KYC Settings
                    </button>
                  </div>
                </div>
              </SectionCard>

              {/* Notification Templates */}
              <SectionCard
                icon={Bell}
                title="Notification Templates"
                iconColor="text-amber-600"
                iconBg="bg-amber-50"
              >
                <div className="space-y-5">
                  <div>
                    <label className="flex items-center gap-2 text-sm font-semibold text-gray-700 mb-1.5">
                      <FileText className="w-4 h-4 text-gray-400" />
                      Welcome Message
                    </label>
                    <textarea
                      value={config.welcomeMessage}
                      onChange={(e) => update("welcomeMessage", e.target.value)}
                      rows={3}
                      className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 resize-none transition-all"
                    />
                  </div>
                  <div>
                    <label className="flex items-center gap-2 text-sm font-semibold text-gray-700 mb-1.5">
                      <CheckCircle className="w-4 h-4 text-gray-400" />
                      Transaction Success Message
                    </label>
                    <textarea
                      value={config.transactionSuccessMessage}
                      onChange={(e) => update("transactionSuccessMessage", e.target.value)}
                      rows={3}
                      className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 resize-none transition-all"
                    />
                  </div>
                  <div>
                    <label className="flex items-center gap-2 text-sm font-semibold text-gray-700 mb-1.5">
                      <Shield className="w-4 h-4 text-gray-400" />
                      KYC Approved Message
                    </label>
                    <textarea
                      value={config.kycApprovedMessage}
                      onChange={(e) => update("kycApprovedMessage", e.target.value)}
                      rows={3}
                      className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 resize-none transition-all"
                    />
                  </div>
                  <button
                    onClick={() =>
                      saveFields(
                        {
                          welcomeMessage: config.welcomeMessage,
                          transactionSuccessMessage: config.transactionSuccessMessage,
                          kycApprovedMessage: config.kycApprovedMessage,
                        },
                        "templates",
                        "Notification templates saved"
                      )
                    }
                    disabled={saving === "templates"}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition-colors disabled:opacity-50"
                  >
                    {saving === "templates" ? (
                      <Loader2 className="w-4 h-4 animate-spin" />
                    ) : (
                      <Save className="w-4 h-4" />
                    )}
                    Save Templates
                  </button>
                </div>
              </SectionCard>

              {/* Danger Zone */}
              <div className="bg-white rounded-2xl border-2 border-rose-200 shadow-sm overflow-hidden">
                <div className="flex items-center gap-3 px-6 py-5 border-b border-rose-100 bg-rose-50/50">
                  <div className="w-9 h-9 rounded-xl bg-rose-100 flex items-center justify-center">
                    <AlertTriangle className="w-5 h-5 text-rose-600" />
                  </div>
                  <div>
                    <h3 className="text-base font-bold text-rose-700">Danger Zone</h3>
                    <p className="text-xs text-rose-500">
                      Irreversible or high-impact actions. Proceed with caution.
                    </p>
                  </div>
                </div>
                <div className="px-6 py-5 space-y-3">
                  {/* Clear All Pending KYC */}
                  <div className="flex items-center justify-between p-4 rounded-xl bg-gray-50 border border-gray-200">
                    <div>
                      <p className="text-sm font-semibold text-gray-900">Clear All Pending KYC</p>
                      <p className="text-xs text-gray-500 mt-0.5">
                        Removes all unreviewed KYC submissions from the queue
                      </p>
                    </div>
                    <button
                      onClick={() =>
                        setConfirmModal({
                          title: "Clear All Pending KYC",
                          message:
                            "This will permanently delete all pending KYC submissions. Users will need to resubmit their documents. This action cannot be undone.",
                          confirmLabel: "Clear Pending KYC",
                          confirmClass:
                            "bg-rose-600 hover:bg-rose-700 text-white",
                          onConfirm: async () => {
                            setConfirmModal(null);
                            toast.success(
                              "Pending KYC submissions cleared. (Demo: integrate Firestore batch delete)"
                            );
                          },
                        })
                      }
                      className="flex items-center gap-2 px-4 py-2 rounded-xl bg-rose-50 text-rose-700 border border-rose-200 hover:bg-rose-100 text-sm font-semibold transition-colors"
                    >
                      <Trash2 className="w-4 h-4" />
                      Clear
                    </button>
                  </div>

                  {/* Export All Data */}
                  <div className="flex items-center justify-between p-4 rounded-xl bg-gray-50 border border-gray-200">
                    <div>
                      <p className="text-sm font-semibold text-gray-900">Export All Data</p>
                      <p className="text-xs text-gray-500 mt-0.5">
                        Download a complete export of all system data
                      </p>
                    </div>
                    <button
                      onClick={() => toast("Feature coming soon", { icon: "🚧" })}
                      className="flex items-center gap-2 px-4 py-2 rounded-xl bg-gray-100 text-gray-700 border border-gray-200 hover:bg-gray-200 text-sm font-semibold transition-colors"
                    >
                      <Download className="w-4 h-4" />
                      Export
                    </button>
                  </div>

                  {/* Reset Transaction Limits */}
                  <div className="flex items-center justify-between p-4 rounded-xl bg-gray-50 border border-gray-200">
                    <div>
                      <p className="text-sm font-semibold text-gray-900">
                        Reset Transaction Limits to Default
                      </p>
                      <p className="text-xs text-gray-500 mt-0.5">
                        Resets daily limit to $10,000, max single to $5,000, min to $1
                      </p>
                    </div>
                    <button
                      onClick={() =>
                        setConfirmModal({
                          title: "Reset Transaction Limits",
                          message:
                            "This will reset all transaction limits to their default values: Daily limit $10,000, Max single transaction $5,000, Min transaction $1.",
                          confirmLabel: "Reset to Default",
                          confirmClass:
                            "bg-amber-600 hover:bg-amber-700 text-white",
                          onConfirm: async () => {
                            setConfirmModal(null);
                            await saveFields(
                              {
                                dailySendLimit: 10000,
                                maxSingleTransaction: 5000,
                                minTransaction: 1,
                              },
                              "resetLimits",
                              "Transaction limits reset to default"
                            );
                          },
                        })
                      }
                      className="flex items-center gap-2 px-4 py-2 rounded-xl bg-amber-50 text-amber-700 border border-amber-200 hover:bg-amber-100 text-sm font-semibold transition-colors"
                    >
                      <RotateCcw className="w-4 h-4" />
                      Reset
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </main>
      </div>

      {/* Maintenance Mode Confirmation Modal */}
      {showMaintenanceModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
            <div className="flex items-center justify-between mb-5">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-rose-100 flex items-center justify-center">
                  <AlertTriangle className="w-5 h-5 text-rose-600" />
                </div>
                <h3 className="text-lg font-bold text-gray-900">Enable Maintenance Mode?</h3>
              </div>
              <button
                onClick={() => {
                  setShowMaintenanceModal(false);
                  setPendingMaintenance(false);
                }}
                className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center hover:bg-gray-200 transition-colors"
              >
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>

            <div className="px-4 py-4 rounded-xl bg-rose-50 border border-rose-200 mb-5">
              <div className="flex gap-3">
                <AlertTriangle className="w-5 h-5 text-rose-500 flex-shrink-0 mt-0.5" />
                <p className="text-sm text-rose-700">
                  This will show a maintenance screen to{" "}
                  <span className="font-bold">ALL users</span>. They will be unable to
                  access any banking features until you disable maintenance mode.
                </p>
              </div>
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => {
                  setShowMaintenanceModal(false);
                  setPendingMaintenance(false);
                }}
                className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={confirmMaintenance}
                disabled={saving === "maintenance"}
                className="flex-1 py-2.5 rounded-xl bg-rose-600 text-white text-sm font-semibold hover:bg-rose-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
              >
                {saving === "maintenance" ? (
                  <Loader2 className="w-4 h-4 animate-spin" />
                ) : (
                  <AlertTriangle className="w-4 h-4" />
                )}
                Enable Maintenance Mode
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Generic Confirmation Modal */}
      {confirmModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
            <div className="flex items-center justify-between mb-5">
              <h3 className="text-lg font-bold text-gray-900">{confirmModal.title}</h3>
              <button
                onClick={() => setConfirmModal(null)}
                className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center hover:bg-gray-200 transition-colors"
              >
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>
            <p className="text-sm text-gray-600 mb-6 leading-relaxed">{confirmModal.message}</p>
            <div className="flex gap-3">
              <button
                onClick={() => setConfirmModal(null)}
                className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={confirmModal.onConfirm}
                className={`flex-1 py-2.5 rounded-xl text-sm font-semibold transition-colors ${confirmModal.confirmClass}`}
              >
                {confirmModal.confirmLabel}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
