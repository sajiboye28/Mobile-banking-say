import { useNavigate } from 'react-router-dom';
import { useRef, useState, useCallback } from 'react';
import {
  User, ChevronRight, Settings, Shield, CreditCard,
  PiggyBank, Landmark, LogOut, Copy, Check,
  Pencil, Save, X, Camera, Loader2,
} from 'lucide-react';
import { pb, PB_URL } from '../services/pb';
import { useAuth } from '../context/AuthContext';
import PageHeader from '../components/PageHeader';

function formatBalance(n: number) {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(n);
}

const ACCOUNT_STATUS_BADGE: Record<string, string> = {
  active: 'bg-green-400/10 text-green-400',
  pending: 'bg-yellow-400/10 text-yellow-400',
  suspended: 'bg-red-400/10 text-red-400',
  frozen: 'bg-blue-400/10 text-blue-400',
  closed: 'bg-[#8d90a2]/10 text-[#8d90a2]',
};

const KYC_BADGE: Record<string, string> = {
  approved: 'bg-green-400/10 text-green-400',
  pending: 'bg-yellow-400/10 text-yellow-400',
  rejected: 'bg-red-400/10 text-red-400',
  not_submitted: 'bg-[#8d90a2]/10 text-[#8d90a2]',
  unverified: 'bg-[#8d90a2]/10 text-[#8d90a2]',
};

interface EditableField {
  field: string;
  label: string;
  value: string;
  type?: string;
}

function InfoRow({
  label,
  value,
  field,
  onSave,
}: {
  label: string;
  value: string;
  field: string;
  onSave: (field: string, value: string) => Promise<void>;
}) {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(value);
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    await onSave(field, draft);
    setSaving(false);
    setEditing(false);
  };

  const handleCancel = () => {
    setDraft(value);
    setEditing(false);
  };

  return (
    <div className="flex items-center gap-3 px-4 py-3 border-b border-[#3a3939] last:border-0">
      <div className="flex-1 min-w-0">
        <p className="text-[#8d90a2] text-xs">{label}</p>
        {editing ? (
          <input
            autoFocus
            type="text"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleSave();
              if (e.key === 'Escape') handleCancel();
            }}
            className="bg-[#2a2a2a] border border-[#0052ff] rounded-lg px-2 py-1 text-white text-sm outline-none w-full mt-1"
          />
        ) : (
          <p className="text-white text-sm font-medium mt-0.5 truncate">{value || '—'}</p>
        )}
      </div>
      {editing ? (
        <div className="flex items-center gap-2 shrink-0">
          <button
            onClick={handleSave}
            disabled={saving}
            className="text-[#0052ff] hover:text-white transition-colors"
          >
            {saving ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
          </button>
          <button onClick={handleCancel} className="text-[#8d90a2] hover:text-white transition-colors">
            <X size={14} />
          </button>
        </div>
      ) : (
        <button
          onClick={() => { setDraft(value); setEditing(true); }}
          className="text-[#8d90a2] hover:text-white transition-colors shrink-0"
        >
          <Pencil size={14} />
        </button>
      )}
    </div>
  );
}

export default function ProfileScreen() {
  const { user, refreshUser, signOut } = useAuth();
  const navigate = useNavigate();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [copied, setCopied] = useState(false);
  const [uploadingPic, setUploadingPic] = useState(false);
  const [saveError, setSaveError] = useState('');

  const initials = user?.fullName
    ?.split(' ')
    .map((w) => w[0])
    .join('')
    .toUpperCase()
    .slice(0, 2) ?? '?';

  // Build the avatar display URL:
  // Prefer the PocketBase 'avatar' file field, fall back to legacy text profilePicUrl
  const avatarSrc = user?.avatar
    ? `${PB_URL}/api/files/_pb_users_auth_/${user.id}/${user.avatar}`
    : (user?.profilePicUrl || null);

  const accountNumber = user?.accountNumber ?? '—';

  const copyAccountNumber = () => {
    navigator.clipboard.writeText(accountNumber).catch(() => {});
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleSignOut = () => {
    signOut();
    navigate('/login', { replace: true });
  };

  const handleSaveField = useCallback(async (field: string, value: string) => {
    if (!user?.id) return;
    setSaveError('');
    try {
      await pb.collection('users').update(user.id, { [field]: value });
      await refreshUser();
    } catch (e: unknown) {
      setSaveError(e instanceof Error ? e.message : 'Save failed.');
    }
  }, [user?.id, refreshUser]);

  const handleAvatarClick = () => fileInputRef.current?.click();

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !user?.id) return;
    setUploadingPic(true);
    setSaveError('');
    try {
      // Upload to the PocketBase 'avatar' file field using multipart FormData
      const formData = new FormData();
      formData.append('avatar', file);
      await pb.collection('users').update(user.id, formData);
      await refreshUser();
    } catch (err: unknown) {
      setSaveError(err instanceof Error ? err.message : 'Failed to upload photo.');
      console.error('[ProfileScreen] avatar upload error:', err);
    } finally {
      setUploadingPic(false);
    }
    e.target.value = '';
  };

  const personalFields: EditableField[] = [
    { field: 'fullName', label: 'Full Name', value: user?.fullName ?? '' },
    { field: 'phone', label: 'Phone', value: user?.phone ?? '' },
    { field: 'address', label: 'Address', value: user?.address ?? '' },
    { field: 'city', label: 'City', value: user?.city ?? '' },
    { field: 'country', label: 'Country', value: user?.country ?? '' },
  ];

  const menuSections = [
    {
      items: [
        { icon: Settings, label: 'Settings', path: '/settings' },
        { icon: Shield, label: 'KYC Verification', path: '/kyc' },
        { icon: CreditCard, label: 'My Cards', path: '/cards' },
        { icon: PiggyBank, label: 'Savings Goals', path: '/savings' },
        { icon: Landmark, label: 'Loans', path: '/loans' },
      ],
    },
  ];

  return (
    <div className="flex flex-col min-h-screen bg-[#131313] pb-24">
      <PageHeader title="Profile" onBack={() => navigate(-1)} />

      {/* Avatar + hero */}
      <div className="bg-[#201f1f] px-5 pb-6 pt-2">
        <div className="flex items-center gap-4">
          <div className="relative">
            <button
              onClick={handleAvatarClick}
              className="w-20 h-20 rounded-full bg-[#0052ff]/20 border-2 border-[#0052ff]/40 flex items-center justify-center overflow-hidden shrink-0"
            >
              {avatarSrc ? (
                <img src={avatarSrc} alt="" className="w-full h-full object-cover" />
              ) : (
                <span className="text-[#0052ff] text-2xl font-bold">{initials}</span>
              )}
            </button>
            <button
              onClick={handleAvatarClick}
              className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-[#0052ff] flex items-center justify-center shadow"
            >
              {uploadingPic ? (
                <Loader2 size={10} className="animate-spin text-white" />
              ) : (
                <Camera size={10} className="text-white" />
              )}
            </button>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={handleFileChange}
            />
          </div>

          <div className="flex-1 min-w-0">
            <h2 className="text-white text-lg font-bold truncate">{user?.fullName}</h2>
            <p className="text-[#8d90a2] text-sm truncate">{user?.email}</p>
            <div className="flex flex-wrap items-center gap-2 mt-1.5">
              <span className={`text-xs font-semibold px-2 py-0.5 rounded-full capitalize ${ACCOUNT_STATUS_BADGE[user?.accountStatus ?? 'active'] ?? ACCOUNT_STATUS_BADGE.active}`}>
                {user?.accountStatus}
              </span>
              <span className="text-[#8d90a2] text-xs capitalize">{user?.accountType}</span>
            </div>
          </div>
        </div>

        {/* Balance + account number */}
        <div className="mt-4 bg-[#131313] rounded-2xl p-4 flex items-center justify-between">
          <div>
            <p className="text-[#8d90a2] text-xs">Balance</p>
            <p className="text-white text-lg font-bold mt-0.5">{formatBalance(user?.balance ?? 0)}</p>
          </div>
          <div className="text-right">
            <p className="text-[#8d90a2] text-xs">Account Number</p>
            <button onClick={copyAccountNumber} className="flex items-center gap-1.5 mt-0.5">
              <span className="text-white text-sm font-mono">{accountNumber}</span>
              {copied ? <Check size={12} className="text-green-400" /> : <Copy size={12} className="text-[#8d90a2]" />}
            </button>
          </div>
        </div>
      </div>

      <div className="px-4 mt-4 space-y-4">

        {saveError && (
          <p className="text-red-400 text-sm text-center">{saveError}</p>
        )}

        {/* Personal info — editable */}
        <div>
          <p className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider mb-2">Personal Information</p>
          <div className="bg-[#201f1f] rounded-2xl overflow-hidden">
            {personalFields.map(({ field, label, value }) => (
              <InfoRow
                key={field}
                field={field}
                label={label}
                value={value}
                onSave={handleSaveField}
              />
            ))}
          </div>
        </div>

        {/* Account info */}
        <div>
          <p className="text-xs font-semibold text-[#8d90a2] uppercase tracking-wider mb-2">Account</p>
          <div className="bg-[#201f1f] rounded-2xl p-4 space-y-3">
            {[
              { label: 'Account Type', value: user?.accountType ?? '—' },
              {
                label: 'Account Status',
                badge: (
                  <span className={`text-xs font-semibold px-2 py-0.5 rounded-full capitalize ${ACCOUNT_STATUS_BADGE[user?.accountStatus ?? 'active']}`}>
                    {user?.accountStatus ?? '—'}
                  </span>
                ),
              },
              {
                label: 'KYC Status',
                badge: (
                  <span className={`text-xs font-semibold px-2 py-0.5 rounded-full capitalize ${KYC_BADGE[user?.kycStatus ?? 'not_submitted']}`}>
                    {user?.kycStatus?.replace('_', ' ') ?? 'Not submitted'}
                  </span>
                ),
              },
            ].map(({ label, value, badge }) => (
              <div key={label} className="flex justify-between items-center">
                <span className="text-[#8d90a2] text-sm">{label}</span>
                {badge ?? <span className="text-white text-sm font-medium capitalize">{value}</span>}
              </div>
            ))}
          </div>
        </div>

        {/* Nav menu */}
        {menuSections.map((section, si) => (
          <div key={si} className="bg-[#201f1f] rounded-2xl overflow-hidden divide-y divide-[#3a3939]">
            {section.items.map(({ icon: Icon, label, path }) => (
              <button
                key={path}
                onClick={() => navigate(path)}
                className="flex items-center gap-3 px-4 py-4 w-full text-left hover:bg-[#2a2a2a] transition-colors"
              >
                <div className="w-9 h-9 rounded-xl bg-[#131313] flex items-center justify-center shrink-0">
                  <Icon size={18} className="text-white" />
                </div>
                <span className="flex-1 text-white text-sm font-medium">{label}</span>
                <ChevronRight size={16} className="text-[#8d90a2]" />
              </button>
            ))}
          </div>
        ))}

        {/* Sign out */}
        <button
          onClick={handleSignOut}
          className="flex items-center gap-3 px-4 py-4 bg-red-400/10 border border-red-400/20 rounded-2xl w-full text-left"
        >
          <div className="w-9 h-9 rounded-xl bg-red-400/10 flex items-center justify-center shrink-0">
            <LogOut size={18} className="text-red-400" />
          </div>
          <span className="text-red-400 text-sm font-medium">Sign Out</span>
        </button>

        <p className="text-center text-[#8d90a2]/50 text-xs pb-4">STCU Digital Banking v1.0.0</p>
      </div>
    </div>
  );
}
