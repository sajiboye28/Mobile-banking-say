"use client";

import { useState } from "react";
import toast from "react-hot-toast";

const getToken = () => typeof window !== 'undefined' ? localStorage.getItem('pb_admin_token') ?? '' : '';

const generateAccountNumber = () => String(Math.floor(1000000000 + Math.random() * 9000000000));
import {
  User,
  Mail,
  Lock,
  DollarSign,
  CheckCircle2,
  Copy,
  Loader2,
  UserPlus,
} from "lucide-react";

export default function CreateUserPage() {
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [initialBalance, setInitialBalance] = useState("0");
  const [accountStatus, setAccountStatus] = useState<"active" | "pending">("active");
  const [accountType, setAccountType] = useState("");
  const [canTransact, setCanTransact] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [createdUid, setCreatedUid] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!fullName.trim() || !email.trim() || !password.trim()) {
      toast.error("All fields are required.");
      return;
    }

    if (password.length < 6) {
      toast.error("Password must be at least 6 characters.");
      return;
    }

    const balance = parseFloat(initialBalance);
    if (isNaN(balance) || balance < 0) {
      toast.error("Balance must be a non-negative number.");
      return;
    }

    setIsSubmitting(true);
    setCreatedUid(null);

    try {
      const _tccChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
      const tccCode = Array.from({ length: 6 }, () => _tccChars[Math.floor(Math.random() * _tccChars.length)]).join("");

      const res = await fetch(`${process.env.NEXT_PUBLIC_POCKETBASE_URL}/api/collections/users/records`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${getToken()}` },
        body: JSON.stringify({
          email: email.trim(),
          password,
          passwordConfirm: password,
          fullName: fullName.trim(),
          accountType,
          balance,
          accountStatus,
          canTransact,
          kycStatus: 'not_submitted',
          tccCode,
          accountNumber: generateAccountNumber(),
        }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.message || err.error || 'Failed to create user');
      }
      const newUser = await res.json();
      setCreatedUid(newUser.id);
      toast.success("User created successfully!");

      // Reset form
      setFullName("");
      setEmail("");
      setPassword("");
      setInitialBalance("0");
      setAccountType("");
    } catch (error: any) {
      toast.error("Failed to create user: " + (error.message || "Unknown error"));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Create New User</h1>
        <p className="text-sm text-gray-500 mt-0.5">Register a new user account in the system</p>
      </div>

      <div className="max-w-2xl">
        {createdUid && (
          <div className="mb-6 p-5 bg-emerald-50 border border-emerald-200 rounded-2xl animate-slide-up">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-xl bg-emerald-100 flex items-center justify-center flex-shrink-0">
                <CheckCircle2 className="w-5 h-5 text-emerald-600" />
              </div>
              <div className="flex-1">
                <p className="text-sm font-bold text-emerald-800">User created successfully!</p>
                <div className="mt-2 flex items-center gap-2">
                  <code className="text-xs bg-emerald-100 text-emerald-700 px-3 py-1.5 rounded-lg font-mono">
                    {createdUid}
                  </code>
                  <button
                    onClick={() => {
                      navigator.clipboard.writeText(createdUid);
                      toast.success("UID copied to clipboard");
                    }}
                    className="w-7 h-7 rounded-lg bg-emerald-100 hover:bg-emerald-200 flex items-center justify-center transition-colors"
                  >
                    <Copy className="w-3.5 h-3.5 text-emerald-600" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        <div className="card">
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Personal Information Section */}
            <div>
              <h3 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4">Personal Information</h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                    <span className="flex items-center gap-1.5">
                      <User className="w-4 h-4 text-gray-400" />
                      Full Name
                    </span>
                  </label>
                  <input
                    type="text"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    className="input-field"
                    placeholder="John Doe"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                    <span className="flex items-center gap-1.5">
                      <Mail className="w-4 h-4 text-gray-400" />
                      Email Address
                    </span>
                  </label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="input-field"
                    placeholder="user@example.com"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                    <span className="flex items-center gap-1.5">
                      <Lock className="w-4 h-4 text-gray-400" />
                      Password
                    </span>
                  </label>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="input-field"
                    placeholder="Minimum 6 characters"
                    required
                    minLength={6}
                  />
                </div>
              </div>
            </div>

            {/* Divider */}
            <div className="border-t border-gray-100" />

            {/* Account Configuration Section */}
            <div>
              <h3 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4">Account Configuration</h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                    <span className="flex items-center gap-1.5">
                      <DollarSign className="w-4 h-4 text-gray-400" />
                      Initial Balance ($)
                    </span>
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    value={initialBalance}
                    onChange={(e) => setInitialBalance(e.target.value)}
                    className="input-field"
                  />
                </div>

                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Account Status</label>
                  <select
                    value={accountStatus}
                    onChange={(e) => setAccountStatus(e.target.value as "active" | "pending")}
                    className="input-field"
                  >
                    <option value="active">Active (Immediate access)</option>
                    <option value="pending">Pending (Requires approval)</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Account Type</label>
                  <select
                    value={accountType}
                    onChange={(e) => setAccountType(e.target.value)}
                    className="input-field"
                  >
                    <option value="">Select account type</option>
                    <option value="savings">Savings Account</option>
                    <option value="checking">Checking Account</option>
                    <option value="premium">Premium Account</option>
                    <option value="business">Business Account</option>
                    <option value="student">Student Account</option>
                    <option value="joint">Joint Account</option>
                  </select>
                </div>

                <div className="flex items-center justify-between p-4 bg-slate-50 rounded-xl border border-gray-100">
                  <div>
                    <p className="text-sm font-semibold text-gray-700">Can Transact</p>
                    <p className="text-xs text-gray-500 mt-0.5">Allow this user to send money</p>
                  </div>
                  <button
                    type="button"
                    onClick={() => setCanTransact(!canTransact)}
                    className={`toggle-switch ${canTransact ? "bg-emerald-500" : "bg-gray-300"}`}
                  >
                    <span
                      className={`toggle-switch-dot ${
                        canTransact ? "translate-x-6" : "translate-x-1"
                      }`}
                    />
                  </button>
                </div>
              </div>
            </div>

            {/* Submit */}
            <button type="submit" disabled={isSubmitting} className="btn-primary w-full py-3.5 text-base inline-flex items-center justify-center gap-2">
              {isSubmitting ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Creating User...
                </>
              ) : (
                <>
                  <UserPlus className="w-5 h-5" />
                  Create User
                </>
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
