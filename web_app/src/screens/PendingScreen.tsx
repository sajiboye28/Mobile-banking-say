import { useNavigate } from 'react-router-dom';
import { Clock, LogOut, RefreshCw } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export default function PendingScreen() {
  const { signOut, refreshUser } = useAuth();
  const navigate = useNavigate();

  const handleSignOut = () => {
    signOut();
    navigate('/login', { replace: true });
  };

  const handleRefresh = async () => {
    await refreshUser();
  };

  return (
    <div className="flex flex-col items-center justify-between min-h-screen bg-surface px-6 py-12">
      {/* Top: Logo & Status */}
      <div className="flex flex-col items-center gap-3 mt-8">
        {/* logo1.png = white version, readable on dark bg-surface */}
        <img src="/logo1.png" alt="STCU" className="h-16 w-auto object-contain" />
        <p className="text-[#a0a8c0] text-xs font-medium tracking-widest uppercase">
          Digital Banking
        </p>
      </div>

      {/* Center: Message */}
      <div className="flex flex-col items-center gap-6 text-center px-2">
        {/* Status badge */}
        <div className="flex items-center gap-2 bg-[#ffb4a11a] border border-[#ffb4a133] rounded-full px-4 py-2">
          <Clock size={14} className="text-tertiary" />
          <span className="text-tertiary text-xs font-semibold uppercase tracking-wide">Under Review</span>
        </div>

        <div className="flex flex-col gap-3">
          <h1 className="text-on-surface text-2xl font-bold leading-tight">
            Account Pending<br />Approval
          </h1>
          <p className="text-outline text-sm leading-relaxed max-w-xs">
            Your account is being reviewed by our team. You'll be notified once approved. This usually takes 1–2 business days.
          </p>
        </div>

        {/* Steps */}
        <div className="w-full bg-surface-container rounded-2xl p-4 text-left space-y-3">
          {[
            { step: '1', label: 'Account created', done: true },
            { step: '2', label: 'Identity verification', done: false },
            { step: '3', label: 'Account activated', done: false },
          ].map(({ step, label, done }) => (
            <div key={step} className="flex items-center gap-3">
              <div
                className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold shrink-0 ${
                  done
                    ? 'bg-primary text-white'
                    : 'bg-surface-bright text-outline'
                }`}
              >
                {done ? '✓' : step}
              </div>
              <span className={`text-sm ${done ? 'text-on-surface font-medium' : 'text-outline'}`}>
                {label}
              </span>
            </div>
          ))}
        </div>

        {/* Refresh */}
        <button
          onClick={handleRefresh}
          className="flex items-center gap-2 text-primary text-sm font-medium"
        >
          <RefreshCw size={14} />
          Check status
        </button>
      </div>

      {/* Bottom: Sign out */}
      <button
        onClick={handleSignOut}
        className="flex items-center gap-2 text-outline hover:text-error text-sm font-medium transition-colors py-3"
      >
        <LogOut size={16} />
        Sign out
      </button>
    </div>
  );
}
