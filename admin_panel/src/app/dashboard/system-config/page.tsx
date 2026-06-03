"use client";

import { useEffect, useState } from "react";
import toast from "react-hot-toast";
import {
  Settings,
  AlertTriangle,
  UserPlus,
  DollarSign,
  ArrowLeftRight,
  Percent,
  Mail,
  Phone,
  Megaphone,
  Save,
  Loader2,
  Shield,
} from "lucide-react";

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

interface SystemConfig {
  appName: string;
  maintenanceMode: boolean;
  allowNewRegistrations: boolean;
  defaultBalance: number;
  minTransactionAmount: number;
  maxTransactionAmount: number;
  transactionFeePercent: number;
  supportEmail: string;
  supportPhone: string;
  announcement: string;
  announcementActive: boolean;
}

const defaultConfig: SystemConfig = {
  appName: "STCU",
  maintenanceMode: false,
  allowNewRegistrations: true,
  defaultBalance: 0,
  minTransactionAmount: 1,
  maxTransactionAmount: 100000,
  transactionFeePercent: 0,
  supportEmail: "support@realbanking.com",
  supportPhone: "+1 (555) 000-0000",
  announcement: "",
  announcementActive: false,
};

export default function SystemConfigPage() {
  const [config, setConfig] = useState<SystemConfig>(defaultConfig);
  const [loading, setLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    const loadConfig = async () => {
      try {
        const data = await apiCall("/api/config");
        setConfig({ ...defaultConfig, ...data.config });
      } catch (error) {
        console.error("Error loading config:", error);
      } finally {
        setLoading(false);
      }
    };
    loadConfig();
  }, []);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await apiCall("/api/config", {
        method: "POST",
        body: JSON.stringify(config),
      });
      toast.success("System configuration saved successfully.");
    } catch {
      toast.error("Failed to save configuration.");
    } finally {
      setIsSaving(false);
    }
  };

  const updateField = <K extends keyof SystemConfig>(key: K, value: SystemConfig[K]) => {
    setConfig((prev) => ({ ...prev, [key]: value }));
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
          <h1 className="text-2xl font-bold text-gray-900">System Configuration</h1>
          <p className="text-sm text-gray-500 mt-0.5">Manage global application settings</p>
        </div>
        <button
          onClick={handleSave}
          disabled={isSaving}
          className="btn-primary inline-flex items-center gap-2"
        >
          {isSaving ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              Saving...
            </>
          ) : (
            <>
              <Save className="w-4 h-4" />
              Save All Changes
            </>
          )}
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* General Settings */}
        <div className="card">
          <div className="flex items-center gap-2 mb-5">
            <Settings className="w-5 h-5 text-indigo-600" />
            <h2 className="section-title">General Settings</h2>
          </div>
          <div className="space-y-5">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">App Name</label>
              <input
                type="text"
                value={config.appName}
                onChange={(e) => updateField("appName", e.target.value)}
                className="input-field"
              />
            </div>

            {/* Danger Zone - Maintenance Mode */}
            <div className="p-4 bg-gradient-to-br from-rose-50 to-red-50 rounded-xl border-2 border-rose-200/60">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-rose-100 flex items-center justify-center">
                    <AlertTriangle className="w-5 h-5 text-rose-600" />
                  </div>
                  <div>
                    <p className="text-sm font-bold text-rose-700">Maintenance Mode</p>
                    <p className="text-xs text-rose-500">Disables all user-facing features</p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => updateField("maintenanceMode", !config.maintenanceMode)}
                  className={`toggle-switch ${config.maintenanceMode ? "bg-rose-500" : "bg-gray-300"}`}
                >
                  <span
                    className={`toggle-switch-dot ${
                      config.maintenanceMode ? "translate-x-6" : "translate-x-1"
                    }`}
                  />
                </button>
              </div>
              {config.maintenanceMode && (
                <div className="mt-3 px-3 py-2 bg-rose-100 rounded-lg text-xs text-rose-700 font-medium">
                  Warning: The application is currently in maintenance mode. Users cannot access any
                  features.
                </div>
              )}
            </div>

            <div className="flex items-center justify-between p-4 bg-slate-50 rounded-xl border border-gray-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-indigo-50 flex items-center justify-center">
                  <UserPlus className="w-5 h-5 text-indigo-600" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-gray-700">Allow New Registrations</p>
                  <p className="text-xs text-gray-500">Enable or disable new user sign-ups</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => updateField("allowNewRegistrations", !config.allowNewRegistrations)}
                className={`toggle-switch ${
                  config.allowNewRegistrations ? "bg-emerald-500" : "bg-gray-300"
                }`}
              >
                <span
                  className={`toggle-switch-dot ${
                    config.allowNewRegistrations ? "translate-x-6" : "translate-x-1"
                  }`}
                />
              </button>
            </div>
          </div>
        </div>

        {/* Transaction Settings */}
        <div className="card">
          <div className="flex items-center gap-2 mb-5">
            <ArrowLeftRight className="w-5 h-5 text-indigo-600" />
            <h2 className="section-title">Transaction Settings</h2>
          </div>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                <span className="flex items-center gap-1.5">
                  <DollarSign className="w-4 h-4 text-gray-400" />
                  Default New User Balance ($)
                </span>
              </label>
              <input
                type="number"
                step="0.01"
                value={config.defaultBalance}
                onChange={(e) => updateField("defaultBalance", parseFloat(e.target.value) || 0)}
                className="input-field"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                  Min Amount ($)
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={config.minTransactionAmount}
                  onChange={(e) =>
                    updateField("minTransactionAmount", parseFloat(e.target.value) || 0)
                  }
                  className="input-field"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                  Max Amount ($)
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={config.maxTransactionAmount}
                  onChange={(e) =>
                    updateField("maxTransactionAmount", parseFloat(e.target.value) || 0)
                  }
                  className="input-field"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                <span className="flex items-center gap-1.5">
                  <Percent className="w-4 h-4 text-gray-400" />
                  Transaction Fee (%)
                </span>
              </label>
              <input
                type="number"
                step="0.01"
                min="0"
                max="100"
                value={config.transactionFeePercent}
                onChange={(e) =>
                  updateField("transactionFeePercent", parseFloat(e.target.value) || 0)
                }
                className="input-field"
              />
            </div>
          </div>
        </div>

        {/* Support Contact */}
        <div className="card">
          <div className="flex items-center gap-2 mb-5">
            <Shield className="w-5 h-5 text-indigo-600" />
            <h2 className="section-title">Support Contact</h2>
          </div>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                <span className="flex items-center gap-1.5">
                  <Mail className="w-4 h-4 text-gray-400" />
                  Support Email
                </span>
              </label>
              <input
                type="email"
                value={config.supportEmail}
                onChange={(e) => updateField("supportEmail", e.target.value)}
                className="input-field"
              />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                <span className="flex items-center gap-1.5">
                  <Phone className="w-4 h-4 text-gray-400" />
                  Support Phone
                </span>
              </label>
              <input
                type="tel"
                value={config.supportPhone}
                onChange={(e) => updateField("supportPhone", e.target.value)}
                className="input-field"
              />
            </div>
          </div>
        </div>

        {/* Announcement Banner */}
        <div className="card">
          <div className="flex items-center gap-2 mb-5">
            <Megaphone className="w-5 h-5 text-indigo-600" />
            <h2 className="section-title">Announcement Banner</h2>
          </div>
          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 bg-slate-50 rounded-xl border border-gray-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-amber-50 flex items-center justify-center">
                  <Megaphone className="w-5 h-5 text-amber-600" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-gray-700">Show Announcement</p>
                  <p className="text-xs text-gray-500">Display a banner to all app users</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => updateField("announcementActive", !config.announcementActive)}
                className={`toggle-switch ${
                  config.announcementActive ? "bg-emerald-500" : "bg-gray-300"
                }`}
              >
                <span
                  className={`toggle-switch-dot ${
                    config.announcementActive ? "translate-x-6" : "translate-x-1"
                  }`}
                />
              </button>
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                Announcement Text
              </label>
              <textarea
                value={config.announcement}
                onChange={(e) => updateField("announcement", e.target.value)}
                className="input-field resize-none"
                rows={3}
                placeholder="Enter announcement message for all users..."
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
