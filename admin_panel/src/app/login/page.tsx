"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/AuthContext";
import { Landmark, Mail, Lock, Loader2, ShieldCheck, UserPlus, AlertTriangle, User } from "lucide-react";

const getToken = () => typeof window !== 'undefined' ? localStorage.getItem('pb_admin_token') ?? '' : '';
const apiCall = async (url: string, options: RequestInit = {}) => {
  const res = await fetch(url, {
    ...options,
    headers: { 'Authorization': `Bearer ${getToken()}`, 'Content-Type': 'application/json', ...(options.headers ?? {}) }
  });
  if (!res.ok) throw new Error((await res.json().catch(() => ({}))).error || res.statusText);
  return res.json();
};

export default function LoginPage() {
  const [activeTab, setActiveTab] = useState<"login" | "setup">("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [setupComplete, setSetupComplete] = useState(false);
  const [rulesError, setRulesError] = useState(false);
  const { login } = useAuth();
  const router = useRouter();

  const clearError = () => {
    setError("");
    setRulesError(false);
  };

  const switchTab = (tab: "login" | "setup") => {
    setActiveTab(tab);
    clearError();
    setSetupComplete(false);
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    setIsLoading(true);

    try {
      await login(email, password);
      router.push("/dashboard");
    } catch (err: any) {
      setError(err.message || "Failed to login. Please check your credentials.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleSetup = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();

    if (password !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }

    if (password.length < 8) {
      setError("Password must be at least 8 characters.");
      return;
    }

    if (!fullName.trim()) {
      setError("Full name is required.");
      return;
    }

    setIsLoading(true);

    try {
      await apiCall(`${process.env.NEXT_PUBLIC_POCKETBASE_URL}/api/collections/_superusers/records`, {
        method: 'POST',
        body: JSON.stringify({
          email: email.trim(),
          password,
          passwordConfirm: password,
          name: fullName.trim(),
        }),
      });

      setSetupComplete(true);
      setActiveTab("login");
      setPassword("");
      setConfirmPassword("");
      setFullName("");
    } catch (err: any) {
      setError(err.message || "Setup failed. Please use the PocketBase admin panel to create an admin account.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex">
      {/* Left side - branding */}
      <div className="hidden lg:flex lg:w-1/2 relative bg-gradient-to-br from-slate-950 via-slate-900 to-indigo-950 flex-col items-center justify-center p-12 overflow-hidden">
        <div className="absolute top-20 left-20 w-72 h-72 bg-indigo-500/10 rounded-full blur-3xl" />
        <div className="absolute bottom-32 right-16 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
        <div className="absolute top-1/2 left-1/3 w-48 h-48 bg-purple-500/10 rounded-full blur-2xl" />
        <div className="absolute top-10 right-20 w-20 h-20 border border-indigo-500/20 rounded-2xl rotate-12" />
        <div className="absolute bottom-20 left-32 w-16 h-16 border border-blue-500/20 rounded-full" />
        <div className="absolute top-1/3 right-1/4 w-12 h-12 border border-purple-500/20 rounded-lg rotate-45" />

        <div className="relative z-10 text-center max-w-md">
          {/* Use white logo (logo1.png) on the dark left panel */}
          <img src="/logo1.png" alt="STCU" className="h-16 w-auto object-contain mx-auto mb-8" />
          <h1 className="text-4xl font-bold text-white mb-4">STCU</h1>
          <p className="text-lg text-slate-400 leading-relaxed">
            Enterprise-grade administration dashboard for complete banking system oversight and control.
          </p>
          <div className="mt-10 flex items-center justify-center gap-6 text-slate-500">
            <div className="text-center">
              <p className="text-2xl font-bold text-white">256-bit</p>
              <p className="text-xs mt-1">Encryption</p>
            </div>
            <div className="w-px h-10 bg-slate-800" />
            <div className="text-center">
              <p className="text-2xl font-bold text-white">99.9%</p>
              <p className="text-xs mt-1">Uptime</p>
            </div>
            <div className="w-px h-10 bg-slate-800" />
            <div className="text-center">
              <p className="text-2xl font-bold text-white">SOC 2</p>
              <p className="text-xs mt-1">Compliant</p>
            </div>
          </div>
        </div>
      </div>

      {/* Right side - form */}
      <div className="flex-1 flex items-center justify-center p-8 bg-white overflow-y-auto">
        <div className="w-full max-w-md">
          {/* Mobile logo */}
          <div className="lg:hidden text-center mb-8">
            <img src="/logo.png" alt="STCU" className="h-12 w-auto object-contain mx-auto mb-3" />
            <h1 className="text-2xl font-bold text-gray-900">STCU</h1>
          </div>

          {/* Tabs */}
          <div className="flex mb-6 bg-gray-100 rounded-xl p-1">
            <button
              onClick={() => switchTab("login")}
              className={`flex-1 flex items-center justify-center gap-2 py-2.5 text-sm font-semibold rounded-lg transition-all ${
                activeTab === "login"
                  ? "bg-white text-gray-900 shadow-sm"
                  : "text-gray-500 hover:text-gray-700"
              }`}
            >
              <Lock className="w-4 h-4" />
              Sign In
            </button>
            <button
              onClick={() => switchTab("setup")}
              className={`flex-1 flex items-center justify-center gap-2 py-2.5 text-sm font-semibold rounded-lg transition-all ${
                activeTab === "setup"
                  ? "bg-white text-gray-900 shadow-sm"
                  : "text-gray-500 hover:text-gray-700"
              }`}
            >
              <UserPlus className="w-4 h-4" />
              Setup Admin
            </button>
          </div>

          {/* Setup complete message */}
          {setupComplete && (
            <div className="mb-6 flex items-start gap-3 bg-emerald-50 border border-emerald-200 text-emerald-700 px-4 py-3 rounded-xl text-sm">
              <ShieldCheck className="w-5 h-5 flex-shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold">Admin account created successfully!</p>
                <p className="text-emerald-600 mt-1">You can now sign in with your credentials.</p>
              </div>
            </div>
          )}


          {/* ===== SIGN IN TAB ===== */}
          {activeTab === "login" && (
            <>
              <div className="mb-6">
                <h2 className="text-2xl font-bold text-gray-900">Welcome back</h2>
                <p className="text-gray-500 mt-1">Sign in to your admin account to continue</p>
              </div>

              <form onSubmit={handleLogin} className="space-y-5">
                {error && (
                  <div className="flex items-center gap-3 bg-rose-50 border border-rose-200 text-rose-700 px-4 py-3 rounded-xl text-sm">
                    <div className="w-2 h-2 bg-rose-500 rounded-full flex-shrink-0" />
                    {error}
                  </div>
                )}

                <div>
                  <label htmlFor="login-email" className="block text-sm font-semibold text-gray-700 mb-1.5">
                    Email Address
                  </label>
                  <div className="relative">
                    <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input
                      id="login-email"
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="input-field pl-10"
                      placeholder="admin@realbanking.com"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label htmlFor="login-password" className="block text-sm font-semibold text-gray-700 mb-1.5">
                    Password
                  </label>
                  <div className="relative">
                    <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input
                      id="login-password"
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="input-field pl-10"
                      placeholder="Enter your password"
                      required
                    />
                  </div>
                </div>

                <button type="submit" disabled={isLoading} className="btn-primary w-full py-3 text-base">
                  {isLoading ? (
                    <span className="flex items-center justify-center gap-2">
                      <Loader2 className="w-5 h-5 animate-spin" />
                      Signing in...
                    </span>
                  ) : (
                    "Sign In"
                  )}
                </button>
              </form>

              <p className="mt-5 text-center text-sm text-gray-400">
                No admin account yet?{" "}
                <button onClick={() => switchTab("setup")} className="text-indigo-600 font-semibold hover:underline">
                  Create one
                </button>
              </p>
            </>
          )}

          {/* ===== SETUP ADMIN TAB ===== */}
          {activeTab === "setup" && (
            <>
              <div className="mb-6">
                <h2 className="text-2xl font-bold text-gray-900">Create Admin Account</h2>
                <p className="text-gray-500 mt-1">Set up a new administrator for the dashboard.</p>
              </div>

              <form onSubmit={handleSetup} className="space-y-4">
                {error && (
                  <div className="flex items-center gap-3 bg-rose-50 border border-rose-200 text-rose-700 px-4 py-3 rounded-xl text-sm">
                    <div className="w-2 h-2 bg-rose-500 rounded-full flex-shrink-0" />
                    {error}
                  </div>
                )}

                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Full Name</label>
                  <div className="relative">
                    <User className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input
                      type="text"
                      value={fullName}
                      onChange={(e) => setFullName(e.target.value)}
                      className="input-field pl-10"
                      placeholder="Admin Name"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Email Address</label>
                  <div className="relative">
                    <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="input-field pl-10"
                      placeholder="admin@realbanking.com"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Password</label>
                  <div className="relative">
                    <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="input-field pl-10"
                      placeholder="Minimum 6 characters"
                      required
                      minLength={6}
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Confirm Password</label>
                  <div className="relative">
                    <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input
                      type="password"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      className="input-field pl-10"
                      placeholder="Re-enter your password"
                      required
                      minLength={6}
                    />
                  </div>
                </div>

                <button type="submit" disabled={isLoading} className="btn-primary w-full py-3 text-base mt-2">
                  {isLoading ? (
                    <span className="flex items-center justify-center gap-2">
                      <Loader2 className="w-5 h-5 animate-spin" />
                      Creating Admin...
                    </span>
                  ) : (
                    "Create Admin Account"
                  )}
                </button>
              </form>

              <p className="mt-5 text-center text-sm text-gray-400">
                Already have an account?{" "}
                <button onClick={() => switchTab("login")} className="text-indigo-600 font-semibold hover:underline">
                  Sign in
                </button>
              </p>
            </>
          )}

          <div className="mt-8 flex items-center justify-center gap-2 text-xs text-gray-400">
            <ShieldCheck className="w-3.5 h-3.5" />
            <span>Admin Access Only &mdash; Unauthorized access is prohibited</span>
          </div>
        </div>
      </div>
    </div>
  );
}
