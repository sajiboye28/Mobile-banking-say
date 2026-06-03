import { useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Eye, EyeOff, Building2, AlertCircle, CheckCircle2 } from 'lucide-react';
import { pb } from '../services/pb';
import { useAuth } from '../context/AuthContext';

function generateAccountNumber(): string {
  const digits = Array.from({ length: 10 }, () => Math.floor(Math.random() * 10));
  return digits.join('');
}

export default function RegisterScreen() {
  const { signIn } = useAuth();
  const navigate = useNavigate();

  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');

    if (!fullName.trim()) { setError('Please enter your full name.'); return; }
    if (!email.trim()) { setError('Please enter your email.'); return; }
    if (password.length < 8) { setError('Password must be at least 8 characters.'); return; }
    if (password !== confirmPassword) { setError('Passwords do not match.'); return; }

    setLoading(true);
    try {
      await pb.collection('users').create({
        email: email.trim(),
        password,
        passwordConfirm: confirmPassword,
        fullName: fullName.trim(),
        balance: 0,
        accountStatus: 'pending',
        canTransact: false,
        kycStatus: 'not_submitted',
        accountNumber: generateAccountNumber(),
        accountType: 'checking',
        two_fa_enabled: false,
        login_alerts_enabled: true,
      });

      // Auto-login
      await signIn(email.trim(), password);
      navigate('/pending', { replace: true });
    } catch (err: any) {
      const data = err?.response?.data;
      if (data?.email?.message) {
        setError('This email is already registered.');
      } else {
        setError(err?.response?.message || err?.message || 'Registration failed. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  const passwordStrength = (): { label: string; color: string; width: string } => {
    if (password.length === 0) return { label: '', color: '', width: '0%' };
    if (password.length < 6) return { label: 'Weak', color: 'bg-error', width: '25%' };
    if (password.length < 10) return { label: 'Fair', color: 'bg-tertiary', width: '55%' };
    return { label: 'Strong', color: 'bg-green-500', width: '100%' };
  };

  const strength = passwordStrength();

  return (
    <div className="flex flex-col min-h-screen bg-surface px-6 pb-10">
      {/* Header */}
      <div className="flex flex-col items-center gap-3 mt-12 mb-8">
        {/* logo1.png = white version, readable on dark bg-surface */}
        <img src="/logo1.png" alt="STCU" className="h-14 w-auto object-contain" />
        <p className="text-[#a0a8c0] text-xs font-medium mt-0.5 tracking-wide">
          Digital Banking
        </p>
      </div>

      {/* Form card */}
      <div className="bg-surface-container rounded-3xl p-6 flex flex-col gap-5">
        <div>
          <h2 className="text-on-surface text-xl font-semibold">Create account</h2>
          <p className="text-outline text-sm mt-1">Start banking with STCU today</p>
        </div>

        {/* Error banner */}
        {error && (
          <div className="flex items-start gap-2.5 bg-[#ffb4ab1a] border border-[#ffb4ab33] rounded-xl px-3.5 py-3">
            <AlertCircle size={16} className="text-error shrink-0 mt-0.5" />
            <p className="text-error text-sm leading-snug">{error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          {/* Full Name */}
          <div className="flex flex-col gap-1.5">
            <label className="text-on-surface text-sm font-medium">Full Name</label>
            <input
              type="text"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              placeholder="Jane Doe"
              autoComplete="name"
              className="w-full bg-surface border border-outline/40 text-on-surface placeholder-outline rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/40 transition-colors"
            />
          </div>

          {/* Email */}
          <div className="flex flex-col gap-1.5">
            <label className="text-on-surface text-sm font-medium">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
              autoComplete="email"
              className="w-full bg-surface border border-outline/40 text-on-surface placeholder-outline rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/40 transition-colors"
            />
          </div>

          {/* Password */}
          <div className="flex flex-col gap-1.5">
            <label className="text-on-surface text-sm font-medium">Password</label>
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Min. 8 characters"
                autoComplete="new-password"
                className="w-full bg-surface border border-outline/40 text-on-surface placeholder-outline rounded-xl px-4 py-3 pr-12 text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/40 transition-colors"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-outline hover:text-on-surface transition-colors"
                tabIndex={-1}
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
            {/* Password strength bar */}
            {password.length > 0 && (
              <div className="flex items-center gap-2 mt-0.5">
                <div className="flex-1 h-1 bg-surface-bright rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all duration-300 ${strength.color}`}
                    style={{ width: strength.width }}
                  />
                </div>
                <span className="text-outline text-xs">{strength.label}</span>
              </div>
            )}
          </div>

          {/* Confirm Password */}
          <div className="flex flex-col gap-1.5">
            <label className="text-on-surface text-sm font-medium">Confirm Password</label>
            <div className="relative">
              <input
                type={showConfirm ? 'text' : 'password'}
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="Re-enter password"
                autoComplete="new-password"
                className="w-full bg-surface border border-outline/40 text-on-surface placeholder-outline rounded-xl px-4 py-3 pr-12 text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/40 transition-colors"
              />
              <button
                type="button"
                onClick={() => setShowConfirm(!showConfirm)}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-outline hover:text-on-surface transition-colors"
                tabIndex={-1}
              >
                {showConfirm ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
              {confirmPassword.length > 0 && password === confirmPassword && (
                <CheckCircle2 size={16} className="absolute right-10 top-1/2 -translate-y-1/2 text-green-500" />
              )}
            </div>
          </div>

          {/* Terms note */}
          <p className="text-outline text-xs leading-relaxed">
            By creating an account you agree to our{' '}
            <span className="text-secondary">Terms of Service</span> and{' '}
            <span className="text-secondary">Privacy Policy</span>.
          </p>

          {/* Submit */}
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-primary hover:bg-primary/90 disabled:opacity-60 text-white font-semibold rounded-full py-3.5 text-sm transition-colors flex items-center justify-center gap-2 mt-1"
          >
            {loading ? (
              <>
                <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                Creating account…
              </>
            ) : (
              'Create Account'
            )}
          </button>
        </form>
      </div>

      {/* Login link */}
      <p className="text-center text-outline text-sm mt-6">
        Already have an account?{' '}
        <Link to="/login" className="text-primary font-medium hover:underline">
          Sign in
        </Link>
      </p>
    </div>
  );
}
