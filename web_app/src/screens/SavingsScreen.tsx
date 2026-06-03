import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Plus, Target, X, Loader2, PiggyBank, ChevronRight, CalendarDays,
} from 'lucide-react';
import { pb } from '../services/pb';
import { useAuth } from '../context/AuthContext';
import type { SavingsGoal } from '../models/types';
import PageHeader from '../components/PageHeader';

const GOAL_ICONS = ['🏠', '🚗', '✈️', '🎓', '💍', '📱', '💻', '🏋️', '🌴', '💰'];
const GOAL_COLORS = [
  '#0052ff', '#7b2ff7', '#00b894', '#e17055', '#fdcb6e',
  '#6c5ce7', '#00cec9', '#fd79a8', '#2d3436', '#d63031',
];

function ProgressBar({ progress, color }: { progress: number; color: string }) {
  const pct = Math.min(100, Math.round(progress * 100));
  return (
    <div className="w-full h-2 bg-[#3a3939] rounded-full overflow-hidden">
      <div
        className="h-full rounded-full transition-all duration-500"
        style={{ width: `${pct}%`, backgroundColor: color }}
      />
    </div>
  );
}

// ── Add Goal Modal ───────────────────────────────────────────────────────────
function AddGoalModal({
  userId,
  onClose,
  onCreated,
}: {
  userId: string;
  onClose: () => void;
  onCreated: (goal: SavingsGoal) => void;
}) {
  const [name, setName] = useState('');
  const [target, setTarget] = useState('');
  const [deadline, setDeadline] = useState('');
  const [icon, setIcon] = useState(GOAL_ICONS[0]);
  const [color, setColor] = useState(GOAL_COLORS[0]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const handleCreate = async () => {
    if (!name.trim() || !target) return;
    setSaving(true);
    setError('');
    try {
      const record = await pb.collection('savings_goals').create({
        userId,
        name: name.trim(),
        targetAmount: parseFloat(target),
        currentAmount: 0,
        icon,
        color,
        deadline: deadline || null,
        isCompleted: false,
      });
      onCreated(record as unknown as SavingsGoal);
      onClose();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to create goal.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end">
      <div className="absolute inset-0 bg-black/60" onClick={onClose} />
      <div className="relative bg-[#201f1f] rounded-t-3xl p-6 pb-10 space-y-5 max-h-[90vh] overflow-y-auto">
        <div className="w-10 h-1 bg-[#3a3939] rounded-full mx-auto mb-2" />
        <div className="flex items-center justify-between">
          <p className="text-white font-bold text-lg">New Savings Goal</p>
          <button onClick={onClose}><X size={20} className="text-[#8d90a2]" /></button>
        </div>

        {/* Name */}
        <div className="flex flex-col gap-2">
          <label className="text-sm font-semibold text-[#8d90a2] uppercase tracking-wider">Goal Name</label>
          <input
            type="text"
            placeholder="e.g. New Laptop"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white placeholder-[#8d90a2] outline-none"
          />
        </div>

        {/* Target amount */}
        <div className="flex flex-col gap-2">
          <label className="text-sm font-semibold text-[#8d90a2] uppercase tracking-wider">Target Amount (USD)</label>
          <input
            type="number"
            inputMode="decimal"
            placeholder="0.00"
            value={target}
            min="1"
            onChange={(e) => setTarget(e.target.value)}
            className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white placeholder-[#8d90a2] outline-none"
          />
        </div>

        {/* Deadline */}
        <div className="flex flex-col gap-2">
          <label className="text-sm font-semibold text-[#8d90a2] uppercase tracking-wider">Deadline (optional)</label>
          <input
            type="date"
            value={deadline}
            onChange={(e) => setDeadline(e.target.value)}
            className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white outline-none [color-scheme:dark]"
          />
        </div>

        {/* Icon picker */}
        <div className="flex flex-col gap-2">
          <label className="text-sm font-semibold text-[#8d90a2] uppercase tracking-wider">Icon</label>
          <div className="flex flex-wrap gap-2">
            {GOAL_ICONS.map((ic) => (
              <button
                key={ic}
                onClick={() => setIcon(ic)}
                className={`w-10 h-10 rounded-xl text-xl flex items-center justify-center transition-colors ${
                  icon === ic ? 'bg-[#0052ff]/30 ring-2 ring-[#0052ff]' : 'bg-[#2a2a2a]'
                }`}
              >
                {ic}
              </button>
            ))}
          </div>
        </div>

        {/* Color picker */}
        <div className="flex flex-col gap-2">
          <label className="text-sm font-semibold text-[#8d90a2] uppercase tracking-wider">Color</label>
          <div className="flex gap-2 flex-wrap">
            {GOAL_COLORS.map((c) => (
              <button
                key={c}
                onClick={() => setColor(c)}
                className={`w-8 h-8 rounded-full transition-all ${
                  color === c ? 'ring-2 ring-white ring-offset-2 ring-offset-[#201f1f]' : ''
                }`}
                style={{ backgroundColor: c }}
              />
            ))}
          </div>
        </div>

        {error && <p className="text-red-400 text-sm">{error}</p>}

        <button
          onClick={handleCreate}
          disabled={saving || !name.trim() || !target}
          className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2 disabled:opacity-50"
        >
          {saving ? <Loader2 size={16} className="animate-spin" /> : <Plus size={16} />}
          Create Goal
        </button>
      </div>
    </div>
  );
}

// ── Add Money Modal ──────────────────────────────────────────────────────────
function AddMoneyModal({
  goal,
  userBalance,
  onClose,
  onUpdated,
}: {
  goal: SavingsGoal;
  userBalance: number;
  onClose: () => void;
  onUpdated: (updated: SavingsGoal) => void;
}) {
  const [amount, setAmount] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const remaining = goal.targetAmount - goal.currentAmount;

  const handleAdd = async () => {
    const n = parseFloat(amount);
    if (isNaN(n) || n <= 0) return;
    if (n > userBalance) { setError('Insufficient balance.'); return; }
    setSaving(true);
    setError('');
    try {
      const updated = await pb.collection('savings_goals').update(goal.id, {
        currentAmount: Math.min(goal.currentAmount + n, goal.targetAmount),
        isCompleted: goal.currentAmount + n >= goal.targetAmount,
      });
      onUpdated(updated as unknown as SavingsGoal);
      onClose();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to add funds.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end">
      <div className="absolute inset-0 bg-black/60" onClick={onClose} />
      <div className="relative bg-[#201f1f] rounded-t-3xl p-6 pb-10 space-y-5">
        <div className="w-10 h-1 bg-[#3a3939] rounded-full mx-auto mb-2" />
        <div className="flex items-center justify-between">
          <p className="text-white font-bold text-lg">Add to "{goal.name}"</p>
          <button onClick={onClose}><X size={20} className="text-[#8d90a2]" /></button>
        </div>

        <div className="bg-[#131313] rounded-xl p-3 flex justify-between text-sm">
          <span className="text-[#8d90a2]">Remaining</span>
          <span className="text-white font-semibold">${remaining.toFixed(2)}</span>
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-sm font-semibold text-[#8d90a2] uppercase tracking-wider">Amount (USD)</label>
          <input
            type="number"
            inputMode="decimal"
            placeholder="0.00"
            value={amount}
            max={Math.min(remaining, userBalance)}
            min="0.01"
            onChange={(e) => { setAmount(e.target.value); setError(''); }}
            className="bg-[#2a2a2a] border border-[#8d90a2] rounded-xl px-4 py-3 text-white placeholder-[#8d90a2] outline-none text-xl font-bold"
          />
          {error && <p className="text-red-400 text-sm">{error}</p>}
        </div>

        <button
          onClick={handleAdd}
          disabled={saving || !amount || parseFloat(amount) <= 0}
          className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2 disabled:opacity-50"
        >
          {saving ? <Loader2 size={16} className="animate-spin" /> : null}
          Add Funds
        </button>
      </div>
    </div>
  );
}

// ── Main ─────────────────────────────────────────────────────────────────────
export default function SavingsScreen() {
  const { user } = useAuth();
  const navigate = useNavigate();

  const [goals, setGoals] = useState<SavingsGoal[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [addMoneyGoal, setAddMoneyGoal] = useState<SavingsGoal | null>(null);

  const load = useCallback(async () => {
    if (!user) return;
    setLoading(true);
    try {
      const records = await pb.collection('savings_goals').getFullList({
        filter: `userId="${user.id}"`,
        sort: '-created',
      });
      setGoals(records as unknown as SavingsGoal[]);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [user]);

  useEffect(() => { load(); }, [load]);

  const handleCreated = (g: SavingsGoal) => setGoals((prev) => [g, ...prev]);
  const handleUpdated = (updated: SavingsGoal) =>
    setGoals((prev) => prev.map((g) => (g.id === updated.id ? updated : g)));

  const totalSaved = goals.reduce((s, g) => s + g.currentAmount, 0);
  const totalTarget = goals.reduce((s, g) => s + g.targetAmount, 0);

  return (
    <div className="flex flex-col min-h-screen bg-[#131313]">
      <PageHeader title="Savings Goals" onBack={() => navigate(-1)} />

      <div className="flex-1 overflow-y-auto px-4 pb-32">

        {/* Summary card */}
        {goals.length > 0 && (
          <div className="bg-[#201f1f] rounded-2xl p-4 mb-5">
            <div className="flex justify-between mb-3">
              <div>
                <p className="text-[#8d90a2] text-xs">Total Saved</p>
                <p className="text-white text-2xl font-bold">${totalSaved.toFixed(2)}</p>
              </div>
              <div className="text-right">
                <p className="text-[#8d90a2] text-xs">Total Target</p>
                <p className="text-white text-lg font-semibold">${totalTarget.toFixed(2)}</p>
              </div>
            </div>
            <ProgressBar
              progress={totalTarget > 0 ? totalSaved / totalTarget : 0}
              color="#0052ff"
            />
            <p className="text-[#8d90a2] text-xs mt-2 text-right">
              {totalTarget > 0 ? Math.round((totalSaved / totalTarget) * 100) : 0}% of total goals
            </p>
          </div>
        )}

        {/* Goals list */}
        {loading ? (
          <div className="space-y-3">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="bg-[#201f1f] rounded-2xl h-28 animate-pulse" />
            ))}
          </div>
        ) : goals.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-24 gap-4">
            <div className="w-20 h-20 rounded-full bg-[#201f1f] flex items-center justify-center">
              <PiggyBank size={36} className="text-[#8d90a2]" />
            </div>
            <p className="text-white font-semibold text-lg">No savings goals</p>
            <p className="text-[#8d90a2] text-sm text-center max-w-[240px]">
              Create a goal to start saving for something you care about.
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            <p className="text-sm font-semibold text-[#8d90a2] uppercase tracking-wider mb-3">Your Goals</p>
            {goals.map((goal) => {
              const progress = goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0;
              const pct = Math.min(100, Math.round(progress * 100));
              const remaining = goal.targetAmount - goal.currentAmount;

              return (
                <div key={goal.id} className="bg-[#201f1f] rounded-2xl p-4 space-y-3">
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-center gap-3 min-w-0">
                      <div
                        className="w-11 h-11 rounded-xl flex items-center justify-center text-xl shrink-0"
                        style={{ backgroundColor: goal.color + '22' }}
                      >
                        {goal.icon}
                      </div>
                      <div className="min-w-0">
                        <p className="text-white font-semibold truncate">{goal.name}</p>
                        {goal.deadline && (
                          <div className="flex items-center gap-1 mt-0.5">
                            <CalendarDays size={10} className="text-[#8d90a2]" />
                            <p className="text-[#8d90a2] text-xs">
                              {new Date(goal.deadline).toLocaleDateString()}
                            </p>
                          </div>
                        )}
                      </div>
                    </div>
                    {goal.isCompleted && (
                      <span className="text-green-400 text-xs font-semibold bg-green-400/10 px-2 py-0.5 rounded-full shrink-0">
                        Completed
                      </span>
                    )}
                  </div>

                  <ProgressBar progress={progress} color={goal.color} />

                  <div className="flex justify-between items-end">
                    <div>
                      <p className="text-white font-bold text-lg">${goal.currentAmount.toFixed(2)}</p>
                      <p className="text-[#8d90a2] text-xs">of ${goal.targetAmount.toFixed(2)}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-white font-semibold">{pct}%</p>
                      {remaining > 0 && (
                        <p className="text-[#8d90a2] text-xs">${remaining.toFixed(2)} left</p>
                      )}
                    </div>
                  </div>

                  {!goal.isCompleted && (
                    <button
                      onClick={() => setAddMoneyGoal(goal)}
                      className="w-full bg-[#131313] rounded-xl py-2.5 text-sm font-semibold flex items-center justify-center gap-2"
                      style={{ color: goal.color }}
                    >
                      <Plus size={14} />
                      Add Money
                      <ChevronRight size={14} />
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* FAB */}
      <div className="fixed bottom-8 left-1/2 -translate-x-1/2 w-full max-w-[430px] px-4">
        <button
          onClick={() => setShowAddModal(true)}
          className="bg-[#0052ff] text-white rounded-full py-4 font-semibold w-full flex items-center justify-center gap-2 shadow-lg"
        >
          <Target size={18} />
          Add New Goal
        </button>
      </div>

      {showAddModal && user && (
        <AddGoalModal
          userId={user.id}
          onClose={() => setShowAddModal(false)}
          onCreated={handleCreated}
        />
      )}

      {addMoneyGoal && user && (
        <AddMoneyModal
          goal={addMoneyGoal}
          userBalance={user.balance}
          onClose={() => setAddMoneyGoal(null)}
          onUpdated={handleUpdated}
        />
      )}
    </div>
  );
}
