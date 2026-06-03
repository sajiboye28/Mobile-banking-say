import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  CreditCard, Eye, EyeOff, Plus, Zap, ZapOff,
  X, ChevronRight, Loader2, Copy, Shield, Check,
} from 'lucide-react';
import { pb } from '../services/pb';
import { useAuth } from '../context/AuthContext';
import type { VirtualCard } from '../models/types';
import PageHeader from '../components/PageHeader';

function randomCardNumber() {
  return Array.from({ length: 16 }, () => Math.floor(Math.random() * 10)).join('');
}
function randomCvv() {
  return String(Math.floor(100 + Math.random() * 900));
}
function maskCardNumber(num: string) {
  if (num.length < 16) return num;
  return `•••• •••• •••• ${num.slice(-4)}`;
}
function formatCardNumber(num: string) {
  if (num.length < 16) return num;
  return [num.slice(0, 4), num.slice(4, 8), num.slice(8, 12), num.slice(12)].join(' ');
}

const CARD_CONFIGS = [
  { a: '#1a1a2e', b: '#0052ff', glow: 'rgba(0,82,255,0.30)' },
  { a: '#0f2027', b: '#2c5364', glow: 'rgba(44,83,100,0.35)' },
  { a: '#1a0533', b: '#7b2ff7', glow: 'rgba(123,47,247,0.30)' },
  { a: '#0d1b2a', b: '#1b6b43', glow: 'rgba(27,107,67,0.30)' },
];

// ── Card Visual ───────────────────────────────────────────────────────────────
function CardVisual({
  card, revealCvv, onToggleReveal, idx,
}: {
  card: VirtualCard; revealCvv: boolean; onToggleReveal: () => void; idx: number;
}) {
  const cfg = CARD_CONFIGS[idx % CARD_CONFIGS.length];
  const expiry = `${String(card.expiryMonth).padStart(2, '0')}/${String(card.expiryYear).slice(-2)}`;

  return (
    <div
      className="relative w-full aspect-[1.586] rounded-3xl p-5 overflow-hidden select-none"
      style={{
        background: `linear-gradient(135deg, ${cfg.a} 0%, ${cfg.b} 100%)`,
        boxShadow: `0 24px 60px ${cfg.glow}, 0 6px 20px rgba(0,0,0,0.45)`,
      }}
    >
      {/* Ambient circles */}
      <div className="absolute -top-10 -right-10 w-44 h-44 rounded-full bg-white/5 pointer-events-none" />
      <div className="absolute -bottom-12 -left-12 w-52 h-52 rounded-full bg-white/4 pointer-events-none" />

      {/* Frozen overlay */}
      {card.isFrozen && (
        <div
          className="absolute inset-0 rounded-3xl z-10 flex flex-col items-center justify-center gap-2"
          style={{ background: 'rgba(0,0,0,0.65)', backdropFilter: 'blur(6px)' }}
        >
          <div className="w-14 h-14 rounded-2xl bg-white/10 flex items-center justify-center mb-1">
            <ZapOff size={26} className="text-white/80" />
          </div>
          <p className="text-white/90 text-xs font-black uppercase tracking-[4px]">Card Frozen</p>
        </div>
      )}

      {/* Top row */}
      <div className="flex items-start justify-between mb-4">
        {/* Contactless symbol */}
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" className="opacity-60 mt-0.5">
          <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z" fill="none" stroke="white" strokeWidth="1.5"/>
          <path d="M8.5 8.5C9.9 7.1 11.8 6.5 13.7 6.8" stroke="white" strokeWidth="1.8" strokeLinecap="round"/>
          <path d="M6.5 6.5C8.8 4.2 12.1 3.3 15.2 4.2" stroke="white" strokeWidth="1.8" strokeLinecap="round"/>
          <circle cx="12" cy="13" r="1.5" fill="white"/>
        </svg>

        {/* Status + VISA */}
        <div className="flex flex-col items-end gap-1.5">
          <span className="text-white font-black text-[17px] italic tracking-tight">VISA</span>
          <span
            className={`text-[9px] font-bold uppercase tracking-widest px-2 py-0.5 rounded-full border ${
              card.isFrozen
                ? 'bg-red-500/20 text-red-300 border-red-500/30'
                : 'bg-green-500/20 text-green-300 border-green-500/30'
            }`}
          >
            {card.isFrozen ? '● Frozen' : '● Active'}
          </span>
        </div>
      </div>

      {/* Chip icon */}
      <div className="mb-3">
        <div className="w-9 h-7 rounded-[6px] border border-white/25 bg-gradient-to-br from-white/20 to-white/5 flex items-center justify-center">
          <div className="w-5 h-3.5 rounded-[3px] border border-white/30 bg-gradient-to-br from-yellow-300/30 to-yellow-500/20" />
        </div>
      </div>

      {/* Card number */}
      <p className="text-white font-mono text-[16px] tracking-[3px] mb-4 font-medium">
        {maskCardNumber(card.cardNumber)}
      </p>

      {/* Bottom row */}
      <div className="flex items-end gap-4">
        <div className="flex-1 min-w-0">
          <p className="text-white/45 text-[9px] uppercase tracking-[1.5px] mb-0.5">Card Holder</p>
          <p className="text-white text-[13px] font-semibold truncate">{card.cardholderName}</p>
        </div>
        <div>
          <p className="text-white/45 text-[9px] uppercase tracking-[1.5px] mb-0.5">Expires</p>
          <p className="text-white text-[13px] font-semibold">{expiry}</p>
        </div>
        <div className="text-right">
          <p className="text-white/45 text-[9px] uppercase tracking-[1.5px] mb-0.5">CVV</p>
          <button
            onClick={onToggleReveal}
            className="flex items-center gap-1 text-white text-[13px] font-semibold"
          >
            {revealCvv ? card.cvv : '•••'}
            {revealCvv
              ? <EyeOff size={11} className="text-white/50" />
              : <Eye size={11} className="text-white/50" />}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Card Details Sheet ────────────────────────────────────────────────────────
function CardDetailsSheet({
  card, onClose, onToggleFreeze, toggling,
}: {
  card: VirtualCard; onClose: () => void; onToggleFreeze: () => void; toggling: boolean;
}) {
  const [copied, setCopied] = useState(false);
  const expiry = `${String(card.expiryMonth).padStart(2, '0')}/${String(card.expiryYear).slice(-2)}`;

  const handleCopy = () => {
    navigator.clipboard.writeText(formatCardNumber(card.cardNumber)).catch(() => {});
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const rows = [
    { label: 'Card Number', value: formatCardNumber(card.cardNumber), mono: true },
    { label: 'Expiry Date', value: expiry, mono: true },
    { label: 'CVV', value: card.cvv, mono: true },
    { label: 'Card Holder', value: card.cardholderName, mono: false },
    { label: 'Daily Limit', value: card.dailyLimit > 0 ? `$${card.dailyLimit.toFixed(2)}` : 'No limit', mono: false },
    { label: 'Monthly Limit', value: card.monthlyLimit > 0 ? `$${card.monthlyLimit.toFixed(2)}` : 'No limit', mono: false },
  ];

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/70"
        style={{ backdropFilter: 'blur(4px)' }}
        onClick={onClose}
      />

      {/* Sheet */}
      <div className="relative bg-surface-container rounded-t-[28px] pb-10 overflow-hidden">
        {/* Drag handle */}
        <div className="flex justify-center pt-3 pb-4">
          <div className="w-10 h-1 bg-surface-bright rounded-full" />
        </div>

        {/* Header */}
        <div className="flex items-center justify-between px-6 mb-5">
          <div>
            <p className="text-on-surface font-bold text-lg">Card Details</p>
            <p className="text-outline text-xs mt-0.5">Keep these details private</p>
          </div>
          <button
            onClick={onClose}
            className="w-9 h-9 rounded-full bg-surface-bright flex items-center justify-center text-outline hover:text-on-surface transition-colors"
          >
            <X size={18} />
          </button>
        </div>

        {/* Copy number button */}
        <div className="px-6 mb-4">
          <button
            onClick={handleCopy}
            className="w-full flex items-center justify-between px-4 py-3.5 rounded-2xl bg-surface-bright border border-surface-bright/80 hover:bg-surface-bright/80 transition-colors group"
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-primary/10 flex items-center justify-center">
                {copied
                  ? <Check size={15} className="text-green-400" />
                  : <Copy size={15} className="text-primary" />}
              </div>
              <div className="text-left">
                <p className="text-on-surface text-sm font-semibold">{formatCardNumber(card.cardNumber)}</p>
                <p className="text-outline text-[11px]">{copied ? 'Copied!' : 'Tap to copy card number'}</p>
              </div>
            </div>
            {!copied && <ChevronRight size={15} className="text-outline group-hover:text-on-surface transition-colors" />}
          </button>
        </div>

        {/* Detail rows */}
        <div className="mx-6 bg-surface rounded-2xl overflow-hidden mb-5">
          {rows.slice(1).map(({ label, value, mono }, i, arr) => (
            <div
              key={label}
              className={`flex items-center justify-between px-4 py-3.5 ${
                i < arr.length - 1 ? 'border-b border-surface-bright/40' : ''
              }`}
            >
              <span className="text-outline text-sm">{label}</span>
              <span className={`text-on-surface text-sm font-semibold ${mono ? 'font-mono' : ''}`}>{value}</span>
            </div>
          ))}
        </div>

        {/* Freeze / Unfreeze button */}
        <div className="px-6">
          <button
            onClick={onToggleFreeze}
            disabled={toggling}
            className={`w-full rounded-2xl py-4 font-bold text-sm flex items-center justify-center gap-2 transition-all active:scale-[0.98] disabled:opacity-60 ${
              card.isFrozen
                ? 'bg-primary text-white shadow-lg shadow-primary/25'
                : 'bg-red-500/10 text-red-400 border border-red-500/25 hover:bg-red-500/15'
            }`}
          >
            {toggling ? (
              <Loader2 size={16} className="animate-spin" />
            ) : card.isFrozen ? (
              <><Zap size={16} /> Unfreeze Card</>
            ) : (
              <><ZapOff size={16} /> Freeze Card</>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Main Screen ───────────────────────────────────────────────────────────────
export default function CardsScreen() {
  const { user } = useAuth();
  const navigate = useNavigate();

  const [cards, setCards] = useState<VirtualCard[]>([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [createError, setCreateError] = useState('');
  const [revealMap, setRevealMap] = useState<Record<string, boolean>>({});
  const [selectedCard, setSelectedCard] = useState<VirtualCard | null>(null);
  const [toggling, setToggling] = useState(false);

  const load = useCallback(async () => {
    if (!user) return;
    setLoading(true);
    try {
      const records = await pb.collection('virtual_cards').getFullList({
        filter: `userId="${user.id}"`,
        sort: '-created',
      });
      setCards(records as unknown as VirtualCard[]);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [user]);

  useEffect(() => { load(); }, [load]);

  const handleRequestCard = async () => {
    if (!user) return;
    setCreating(true);
    setCreateError('');
    try {
      const now = new Date();
      const record = await pb.collection('virtual_cards').create({
        userId: user.id,
        cardNumber: randomCardNumber(),
        cvv: randomCvv(),
        expiryMonth: now.getMonth() + 1,
        expiryYear: now.getFullYear() + 4,
        cardholderName: user.fullName,
        isFrozen: false,
        dailyLimit: 0,
        monthlyLimit: 0,
      });
      setCards((prev) => [record as unknown as VirtualCard, ...prev]);
    } catch (e: unknown) {
      setCreateError(e instanceof Error ? e.message : 'Failed to create card.');
    } finally {
      setCreating(false);
    }
  };

  const handleToggleFreeze = async () => {
    if (!selectedCard) return;
    setToggling(true);
    try {
      const updated = await pb.collection('virtual_cards').update(selectedCard.id, {
        isFrozen: !selectedCard.isFrozen,
      });
      setCards((prev) =>
        prev.map((c) => (c.id === selectedCard.id ? (updated as unknown as VirtualCard) : c))
      );
      setSelectedCard(updated as unknown as VirtualCard);
    } catch (e) {
      console.error(e);
    } finally {
      setToggling(false);
    }
  };

  return (
    <div className="flex flex-col min-h-screen bg-surface">
      <PageHeader title="My Cards" onBack={() => navigate(-1)} />

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-4 pb-36 pt-3">
        {loading ? (
          <div className="space-y-4">
            {[0, 1].map((i) => (
              <div key={i} className="space-y-3 animate-pulse">
                <div className="w-full aspect-[1.586] rounded-3xl bg-surface-container" />
                <div className="h-12 rounded-2xl bg-surface-container" />
              </div>
            ))}
          </div>
        ) : cards.length === 0 ? (
          /* ── Empty state ── */
          <div className="flex flex-col items-center justify-center py-16 px-4">
            <div className="w-24 h-24 rounded-3xl bg-surface-container flex items-center justify-center mb-5">
              <CreditCard size={40} className="text-outline" strokeWidth={1.5} />
            </div>
            <p className="text-on-surface font-bold text-xl text-center">No virtual cards yet</p>
            <p className="text-outline text-sm text-center mt-2 max-w-[240px] leading-relaxed">
              Create a virtual card to make secure online purchases without exposing your real details.
            </p>

            {/* Security badges */}
            <div className="flex items-center gap-3 mt-6 flex-wrap justify-center">
              {['Instant issuance', 'Freeze anytime', 'Spending limits'].map((feat) => (
                <span key={feat} className="flex items-center gap-1.5 text-[11px] text-outline bg-surface-container px-3 py-1.5 rounded-full border border-surface-bright/50">
                  <Shield size={11} className="text-primary" />
                  {feat}
                </span>
              ))}
            </div>
          </div>
        ) : (
          /* ── Card list ── */
          <div className="space-y-5">
            {cards.map((card, idx) => (
              <div key={card.id} className="space-y-2.5">
                <CardVisual
                  card={card}
                  revealCvv={!!revealMap[card.id]}
                  onToggleReveal={() => setRevealMap((p) => ({ ...p, [card.id]: !p[card.id] }))}
                  idx={idx}
                />

                {/* Action row */}
                <div className="flex gap-2">
                  {/* View details */}
                  <button
                    onClick={() => setSelectedCard(card)}
                    className="flex-1 bg-surface-container border border-surface-bright/50 rounded-2xl px-4 py-3 flex items-center justify-between hover:bg-surface-bright/30 transition-colors"
                  >
                    <span className="text-on-surface text-sm font-semibold">View details</span>
                    <ChevronRight size={15} className="text-outline" />
                  </button>

                  {/* Freeze quick toggle */}
                  <button
                    onClick={async () => {
                      try {
                        const updated = await pb.collection('virtual_cards').update(card.id, {
                          isFrozen: !card.isFrozen,
                        });
                        setCards((prev) =>
                          prev.map((c) => (c.id === card.id ? (updated as unknown as VirtualCard) : c))
                        );
                      } catch { /* ignore */ }
                    }}
                    className={`w-12 h-12 rounded-2xl flex items-center justify-center transition-colors ${
                      card.isFrozen
                        ? 'bg-primary/15 text-primary border border-primary/25'
                        : 'bg-surface-container border border-surface-bright/50 text-outline hover:bg-surface-bright/30'
                    }`}
                  >
                    {card.isFrozen
                      ? <Zap size={17} />
                      : <ZapOff size={17} />}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        {createError && (
          <p className="text-red-400 text-sm text-center mt-3 bg-red-400/8 px-4 py-2.5 rounded-2xl border border-red-400/20">
            {createError}
          </p>
        )}
      </div>

      {/* ── Request card button — floats above BottomNav ── */}
      <div className="fixed bottom-[90px] left-1/2 -translate-x-1/2 w-full max-w-[430px] px-4 z-30">
        <button
          onClick={handleRequestCard}
          disabled={creating}
          className="w-full py-4 rounded-2xl font-bold text-sm text-white flex items-center justify-center gap-2 transition-all active:scale-[0.98] disabled:opacity-60"
          style={{
            background: 'linear-gradient(135deg, #2563eb, #0052ff)',
            boxShadow: '0 8px 32px rgba(0,82,255,0.40), 0 2px 8px rgba(0,0,0,0.25)',
          }}
        >
          {creating ? (
            <Loader2 size={18} className="animate-spin" />
          ) : (
            <>
              <Plus size={18} strokeWidth={2.5} />
              {cards.length === 0 ? 'Create Virtual Card' : 'Request Another Card'}
            </>
          )}
        </button>
      </div>

      {/* Bottom sheet */}
      {selectedCard && (
        <CardDetailsSheet
          card={selectedCard}
          onClose={() => setSelectedCard(null)}
          onToggleFreeze={handleToggleFreeze}
          toggling={toggling}
        />
      )}
    </div>
  );
}
