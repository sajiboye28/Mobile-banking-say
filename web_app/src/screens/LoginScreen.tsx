import { useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Eye, EyeOff, Building2, AlertCircle } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export default function LoginScreen() {
  const { signIn } = useAuth();
  const navigate = useNavigate();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    if (!email.trim() || !password) {
      setError('Please enter your email and password.');
      return;
    }
    setLoading(true);
    try {
      await signIn(email.trim(), password);
      navigate('/', { replace: true });
    } catch (err: any) {
      const msg = err?.response?.message || err?.message || 'Invalid email or password.';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col min-h-screen bg-surface px-6">
      {/* Top logo area — use logo1.png (white version) on dark background */}
      <div className="flex flex-col items-center gap-3 mt-16 mb-10">
        <img src="/logo1.png" alt="STCU" className="h-16 w-auto object-contain" />
        <p className="text-[#a0a8c0] text-sm font-medium mt-0.5 tracking-wide">
          Digital Banking
        </p>
      </div>

      {/* Form card */}
      <div className="bg-surface-container rounded-3xl p-6 flex flex-col gap-5">
        <div>
          <h2 className="text-on-surface text-xl font-semibold">Welcome back</h2>
          <p className="text-outline text-sm mt-1">Sign in to your account</p>
        </div>

        {/* Error banner */}
        {error && (
          <div className="flex items-start gap-2.5 bg-[#ffb4ab1a] border border-[#ffb4ab33] rounded-xl px-3.5 py-3">
            <AlertCircle size={16} className="text-error shrink-0 mt-0.5" />
            <p className="text-error text-sm leading-snug">{error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
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
                placeholder="••••••••"
                autoComplete="current-password"
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
          </div>

          {/* Submit */}
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-primary hover:bg-primary/90 disabled:opacity-60 text-white font-semibold rounded-full py-3.5 text-sm transition-colors flex items-center justify-center gap-2 mt-1"
          >
            {loading ? (
              <>
                <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                Signing in…
              </>
            ) : (
              'Sign In'
            )}
          </button>
        </form>
      </div>

      {/* Register link */}
      <p className="text-center text-outline text-sm mt-6">
        Don't have an account?{' '}
        <Link to="/register" className="text-primary font-medium hover:underline">
          Register
        </Link>
      </p>
    </div>
  );
}
