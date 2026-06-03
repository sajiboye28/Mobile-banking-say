import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Bell, Shield, Fingerprint, ChevronRight,
  Lock, LogOut, Eye, EyeOff, Loader2, Check,
  Info, FileText, HelpCircle,
} from 'lucide-react';
import { pb } from '../services/pb';
import { useAuth } from '../context/AuthContext';
import PageHeader from '../components/PageHeader';

// ── Toggle ────────────────────────────────────────────────────────────────────
function Toggle({ checked, onChange, disabled }: { checked: boolean; onChange: (v: boolean) => void; disabled?: boolean }) {
  return (
    <button
      role="switch"
      aria-checked={checked}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={`relative w-11 h-6 rounded-full transition-colors shrink-0 ${checked ? 'bg-[#0052ff]' : 'bg-[#3a3939]'} ${disabled ? 'opacity-50 cursor-not-allowed' : ''}`}
    >
      <span className={`absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white shadow transition-transform ${checked ? 'translate-x-5' : 'translate-x-0'}`} />
    </button>
  );
}

// ── Change password modal ─────────────────────────────────────────────────────
function ChangePasswordModal({ userId, onClose }: { userId: string; onClose: () => void }) {
  const [oldPw, setOldPw] = useState('');
  const [newPw, setNewPw] = useState('');
  const [confirmPw, setConfirmPw] = useState('');
  const [showOld, setShowOld] = useState(false);
  const [showNew, setShowNew] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const handleSave = async () => {
    if (!oldPw || !newPw || !confirmPw) { setError('All fields required.'); return; }
    if (newPw.length < 8) { setError('New password must be at least 8 characters.'); return; }
    if (newPw !== confirmPw) { setError('Passwords do not match.'); return; }
    setSaving(true);
    setError('');
    try {
      await pb.collection('users').update(userId, {
        password: newPw,
        passwordConfirm: confirmPw,
        oldPassword: oldPw,
      });
      setSuccess(true);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to update password.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end">
      <div className="absolute inset-0 bg-black/60" onClick={onClose} />
      <div className="relative bg-[#201f1f] rounded-t-3xl p-6 pb-10 space-y-4">
        <div className="w-10 h-1 bg-[#3a3939] rounded-full mx-auto mb-2" />
        <p className="text-white font-bold text-lg">Change Password</p>

        {success ? (
          <div className="flex flex-col items-center gap-4 py-6">
            <div className="w-16 h-16 rounded-full bg-green-400/10 flex items-center justify-center">
              <Check size={32} className="text-green-400" />
            </div>
            <p className="text-white font-semibold">Password updated!</p>
            <button onClick={onClose} className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full">
              Done
            </button>
          </div>
        ) : (
          <>
            {[
              { label: 'Current Password', value: oldPw, setter: setOldPw, show: showOld, toggle: () => setShowOld((v) => !v) },
              { label: 'New Password', value: newPw, setter: setNewPw, show: showNew, toggle: () => setShowNew((v) => !v) },
              { label: 'Confirm New Password', value: confirmPw, setter: setConfirmPw, show: showNew, toggle: () => setShowNew((v) => !v) },
            ].map(({ label, value, setter, show, toggle }) => (
              <div key={label} className="flex flex-col gap-1.5">
                <label className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider">{label}</label>
                <div className="relative">
                  <input
                    type={show ? 'text' : 'password'}
                    value={value}
                    onChange={(e) => setter(e.target.value)}
                    className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white outline-none w-full pr-10"
                  />
                  <button
                    type="button"
                    onClick={toggle}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-[#8d90a2]"
                  >
                    {show ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>
            ))}

            {error && <p className="text-red-400 text-sm">{error}</p>}

            <button
              onClick={handleSave}
              disabled={saving}
              className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2 disabled:opacity-50 mt-2"
            >
              {saving ? <Loader2 size={16} className="animate-spin" /> : <Lock size={16} />}
              Update Password
            </button>
          </>
        )}
      </div>
    </div>
  );
}

// ── Main ─────────────────────────────────────────────────────────────────────
export default function SettingsScreen() {
  const { user, refreshUser, signOut } = useAuth();
  const navigate = useNavigate();
  const [toggling, setToggling] = useState<string | null>(null);
  const [showPasswordModal, setShowPasswordModal] = useState(false);

  // In-memory biometric pref (demo)
  const [biometricEnabled, setBiometricEnabled] = useState(false);
  const [pushEnabled, setPushEnabled] = useState(true);

  const toggleField = useCallback(async (field: string, value: boolean) => {
    if (!user?.id) return;
    setToggling(field);
    try {
      await pb.collection('users').update(user.id, { [field]: value });
      await refreshUser();
    } catch { /* ignore */ } finally {
      setToggling(null);
    }
  }, [user?.id, refreshUser]);

  const handleSignOut = () => {
    pb.authStore.clear();
    navigate('/login', { replace: true });
    signOut();
  };

  return (
    <div className="flex flex-col min-h-screen bg-[#131313] pb-24">
      <PageHeader title="Settings" onBack={() => navigate(-1)} />

      <div className="flex-1 overflow-y-auto px-4 space-y-5">

        {/* Security */}
        <div>
          <p className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider mb-2">Security</p>
          <div className="bg-[#201f1f] rounded-2xl overflow-hidden divide-y divide-[#3a3939]">
            {/* 2FA toggle */}
            <div className="flex items-center gap-3 px-4 py-4">
              <div className="w-9 h-9 rounded-xl bg-[#131313] flex items-center justify-center shrink-0">
                <Shield size={18} className="text-white" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-white text-sm font-medium">Two-Factor Authentication</p>
                <p className="text-[#8d90a2] text-xs mt-0.5">Extra security on every login</p>
              </div>
              <Toggle
                checked={user?.two_fa_enabled ?? false}
                onChange={(v) => toggleField('two_fa_enabled', v)}
                disabled={toggling === 'two_fa_enabled'}
              />
            </div>

            {/* Login alerts toggle */}
            <div className="flex items-center gap-3 px-4 py-4">
              <div className="w-9 h-9 rounded-xl bg-[#131313] flex items-center justify-center shrink-0">
                <Bell size={18} className="text-white" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-white text-sm font-medium">Login Alerts</p>
                <p className="text-[#8d90a2] text-xs mt-0.5">Notify me on new sign-ins</p>
              </div>
              <Toggle
                checked={user?.login_alerts_enabled ?? false}
                onChange={(v) => toggleField('login_alerts_enabled', v)}
                disabled={toggling === 'login_alerts_enabled'}
              />
            </div>

            {/* Biometric */}
            <div className="flex items-center gap-3 px-4 py-4">
              <div className="w-9 h-9 rounded-xl bg-[#131313] flex items-center justify-center shrink-0">
                <Fingerprint size={18} className="text-white" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-white text-sm font-medium">Biometric Login</p>
                <p className="text-[#8d90a2] text-xs mt-0.5">Fingerprint / Face ID</p>
              </div>
              <Toggle checked={biometricEnabled} onChange={setBiometricEnabled} />
            </div>

            {/* Change password */}
            <button
              onClick={() => setShowPasswordModal(true)}
              className="flex items-center gap-3 px-4 py-4 w-full text-left hover:bg-[#2a2a2a] transition-colors"
            >
              <div className="w-9 h-9 rounded-xl bg-[#131313] flex items-center justify-center shrink-0">
                <Lock size={18} className="text-white" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-white text-sm font-medium">Change Password</p>
                <p className="text-[#8d90a2] text-xs mt-0.5">Update your login password</p>
              </div>
              <ChevronRight size={16} className="text-[#8d90a2] shrink-0" />
            </button>
          </div>
        </div>

        {/* Notifications */}
        <div>
          <p className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider mb-2">Notifications</p>
          <div className="bg-[#201f1f] rounded-2xl overflow-hidden divide-y divide-[#3a3939]">
            <div className="flex items-center gap-3 px-4 py-4">
              <div className="w-9 h-9 rounded-xl bg-[#131313] flex items-center justify-center shrink-0">
                <Bell size={18} className="text-white" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-white text-sm font-medium">Push Notifications</p>
                <p className="text-[#8d90a2] text-xs mt-0.5">Receive alerts and updates</p>
              </div>
              <Toggle checked={pushEnabled} onChange={setPushEnabled} />
            </div>
          </div>
        </div>

        {/* About */}
        <div>
          <p className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider mb-2">About</p>
          <div className="bg-[#201f1f] rounded-2xl overflow-hidden divide-y divide-[#3a3939]">
            {[
              { icon: Info, label: 'App Version', value: 'v1.0.0' },
              { icon: FileText, label: 'Terms of Service', value: '' },
              { icon: HelpCircle, label: 'Privacy Policy', value: '' },
            ].map(({ icon: Icon, label, value }) => (
              <div key={label} className="flex items-center gap-3 px-4 py-4">
                <div className="w-9 h-9 rounded-xl bg-[#131313] flex items-center justify-center shrink-0">
                  <Icon size={18} className="text-white" />
                </div>
                <span className="flex-1 text-white text-sm font-medium">{label}</span>
                {value ? (
                  <span className="text-[#8d90a2] text-sm">{value}</span>
                ) : (
                  <ChevronRight size={16} className="text-[#8d90a2]" />
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Sign out */}
        <button
          onClick={handleSignOut}
          className="flex items-center justify-center gap-2 w-full bg-red-400/10 border border-red-400/20 text-red-400 rounded-full py-4 font-semibold"
        >
          <LogOut size={16} />
          Sign Out
        </button>

        <p className="text-center text-[#8d90a2]/50 text-xs pb-4">STCU Digital Banking</p>
      </div>

      {showPasswordModal && user && (
        <ChangePasswordModal userId={user.id} onClose={() => setShowPasswordModal(false)} />
      )}
    </div>
  );
}
