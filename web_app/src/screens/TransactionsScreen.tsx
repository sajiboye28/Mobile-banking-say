import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ArrowDownLeft, ArrowUpRight, Search, RefreshCw, Inbox,
  Receipt, PiggyBank, Landmark, ShoppingBag, Utensils,
} from 'lucide-react';
import { format, isToday, isYesterday, parseISO } from 'date-fns';
import { pb } from '../services/pb';
import { useAuth } from '../context/AuthContext';
import type { TransactionModel } from '../models/types';
import PageHeader from '../components/PageHeader';

type FilterTab = 'All' | 'Credit' | 'Debit';

function getCategoryStyle(tx: TransactionModel) {
  const d = (tx.description ?? '').toLowerCase();
  if (tx.status === 'Failed') return { Icon: ArrowUpRight, color: 'text-red-400/50', bg: 'bg-red-400/8' };
  if (tx.type === 'Credit') return { Icon: ArrowDownLeft, color: 'text-green-400', bg: 'bg-green-400/12' };
  if (d.includes('bill') || d.includes('util') || d.includes('electric') || d.includes('water'))
    return { Icon: Receipt, color: 'text-orange-400', bg: 'bg-orange-400/12' };
  if (d.includes('food') || d.includes('restaurant') || d.includes('coffee') || d.includes('eat'))
    return { Icon: Utensils, color: 'text-red-400', bg: 'bg-red-400/12' };
  if (d.includes('shop') || d.includes('store') || d.includes('amazon') || d.includes('purchase'))
    return { Icon: ShoppingBag, color: 'text-purple-400', bg: 'bg-purple-400/12' };
  if (d.includes('saving') || d.includes('invest'))
    return { Icon: PiggyBank, color: 'text-emerald-400', bg: 'bg-emerald-400/12' };
  if (d.includes('loan') || d.includes('mortgage'))
    return { Icon: Landmark, color: 'text-yellow-400', bg: 'bg-yellow-400/12' };
  return { Icon: ArrowUpRight, color: 'text-on-surface', bg: 'bg-surface-bright' };
}

function statusBadge(status: string) {
  if (status === 'Success') return 'text-green-400 bg-green-400/10';
  if (status === 'Failed') return 'text-red-400 bg-red-400/10';
  return 'text-yellow-400 bg-yellow-400/10';
}

function groupByDate(txns: TransactionModel[]): { label: string; items: TransactionModel[] }[] {
  const map: Record<string, TransactionModel[]> = {};
  for (const t of txns) {
    let label = 'Unknown';
    try {
      const d = parseISO(t.created);
      if (isToday(d)) label = 'Today';
      else if (isYesterday(d)) label = 'Yesterday';
      else label = format(d, 'MMMM d, yyyy');
    } catch { /* skip */ }
    if (!map[label]) map[label] = [];
    map[label].push(t);
  }
  return Object.entries(map).map(([label, items]) => ({ label, items }));
}

export default function TransactionsScreen() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [transactions, setTransactions] = useState<TransactionModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<FilterTab>('All');

  const load = useCallback(
    async (showRefreshing = false) => {
      if (!user) return;
      if (showRefreshing) setRefreshing(true);
      else setLoading(true);
      try {
        const records = await pb.collection('transactions').getFullList<TransactionModel>({
          filter: `userId="${user.id}"`,
          sort: '-created',
        });
        setTransactions(records as unknown as TransactionModel[]);
      } catch { /* no txns */ } finally {
        setLoading(false);
        setRefreshing(false);
      }
    },
    [user]
  );

  useEffect(() => { load(); }, [load]);

  const filtered = transactions.filter((t) => {
    const matchesFilter =
      filter === 'All' ||
      (filter === 'Credit' && t.type === 'Credit') ||
      (filter === 'Debit' && t.type === 'Debit');
    const matchesSearch =
      !search || (t.description ?? '').toLowerCase().includes(search.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  const groups = groupByDate(filtered);

  return (
    <div className="flex flex-col min-h-screen bg-surface">
      <PageHeader
        title="Transactions"
        onBack={() => navigate(-1)}
        rightAction={
          <button
            onClick={() => load(true)}
            disabled={refreshing}
            className="w-9 h-9 rounded-full bg-surface-container border border-surface-bright/50 flex items-center justify-center hover:bg-surface-bright transition-colors"
          >
            <RefreshCw
              size={15}
              className={`text-outline transition-transform ${refreshing ? 'animate-spin' : ''}`}
            />
          </button>
        }
      />

      <div className="px-4 pt-3 space-y-3 sticky top-[57px] z-10 bg-surface pb-3">
        {/* Search bar */}
        <div className="flex items-center gap-2.5 bg-surface-container border border-surface-bright/60 rounded-2xl px-4 py-3">
          <Search size={15} className="text-outline shrink-0" />
          <input
            type="text"
            placeholder="Search transactions…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="bg-transparent text-on-surface placeholder-outline/60 text-sm outline-none w-full"
          />
        </div>

        {/* Filter tabs */}
        <div className="flex gap-2">
          {(['All', 'Credit', 'Debit'] as FilterTab[]).map((tab) => (
            <button
              key={tab}
              onClick={() => setFilter(tab)}
              className={`flex-1 py-2 rounded-full text-xs font-bold tracking-wide transition-all duration-200 active:scale-95 ${
                filter === tab
                  ? 'bg-primary text-white shadow-lg shadow-primary/25'
                  : 'bg-surface-container text-outline border border-surface-bright/60 hover:bg-surface-bright'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-4 pb-28 pt-1">
        {loading ? (
          <div className="space-y-3 pt-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="bg-surface-container rounded-2xl p-4 flex items-center gap-3 animate-pulse">
                <div className="w-11 h-11 rounded-2xl bg-surface-bright shrink-0" />
                <div className="flex-1 space-y-2">
                  <div className="h-3 bg-surface-bright rounded-full w-1/2" />
                  <div className="h-2.5 bg-surface-bright rounded-full w-1/3" />
                </div>
                <div className="h-3.5 bg-surface-bright rounded-full w-16" />
              </div>
            ))}
          </div>
        ) : groups.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-24 gap-4">
            <div className="w-20 h-20 rounded-3xl bg-surface-container flex items-center justify-center">
              <Inbox size={32} className="text-outline" strokeWidth={1.5} />
            </div>
            <div className="text-center">
              <p className="text-on-surface font-bold text-base">No transactions found</p>
              <p className="text-outline text-sm mt-1 max-w-[220px]">
                {search || filter !== 'All'
                  ? 'Try adjusting your search or filter.'
                  : 'Your transaction history will appear here.'}
              </p>
            </div>
          </div>
        ) : (
          <div className="space-y-5 pt-2">
            {groups.map(({ label, items }) => (
              <div key={label}>
                <p className="text-[10px] font-bold text-outline uppercase tracking-[1.5px] mb-2.5 px-1">
                  {label}
                </p>
                <div className="bg-surface-container rounded-3xl overflow-hidden divide-y divide-surface-bright/40">
                  {items.map((txn) => {
                    const { Icon, color, bg } = getCategoryStyle(txn);
                    const isCredit = txn.type === 'Credit';
                    const isFailed = txn.status === 'Failed';
                    let timeStr = '';
                    try { timeStr = format(parseISO(txn.created), 'h:mm a'); } catch { /* skip */ }

                    return (
                      <div
                        key={txn.id}
                        className="flex items-center gap-3.5 px-4 py-3.5 hover:bg-surface-bright/20 transition-colors cursor-pointer"
                      >
                        <div className={`w-11 h-11 rounded-2xl ${bg} flex items-center justify-center shrink-0`}>
                          <Icon size={18} className={color} strokeWidth={isFailed ? 1.5 : 2} />
                        </div>
                        <div className="flex-1 min-w-0">
                          <p
                            className={`text-sm font-semibold truncate ${
                              isFailed ? 'text-on-surface/40 line-through' : 'text-on-surface'
                            }`}
                          >
                            {txn.description || (isCredit ? 'Money received' : 'Payment sent')}
                          </p>
                          <p className="text-outline text-[11px] mt-0.5">{timeStr}</p>
                        </div>
                        <div className="flex flex-col items-end gap-1 shrink-0">
                          <span
                            className={`text-sm font-bold ${
                              isFailed
                                ? 'text-outline/40'
                                : isCredit
                                  ? 'text-green-400'
                                  : 'text-on-surface'
                            }`}
                          >
                            {isCredit ? '+' : isFailed ? '' : '−'}
                            ${Number(txn.amount).toFixed(2)}
                          </span>
                          {txn.status && txn.status !== 'Success' && (
                            <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded-full ${statusBadge(txn.status)}`}>
                              {txn.status.toUpperCase()}
                            </span>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
