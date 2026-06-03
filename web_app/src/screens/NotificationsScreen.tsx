import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Bell, BellOff, Check, ArrowDownLeft, ArrowUpRight,
  Info, Megaphone, AlertTriangle,
} from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { pb } from '../services/pb';
import { useAuth } from '../context/AuthContext';
import type { NotificationModel } from '../models/types';
import PageHeader from '../components/PageHeader';

function notifIcon(type: string) {
  switch (type) {
    case 'credit': return { Icon: ArrowDownLeft, color: 'text-green-400', bg: 'bg-green-400/10' };
    case 'debit': return { Icon: ArrowUpRight, color: 'text-red-400', bg: 'bg-red-400/10' };
    case 'kyc':
    case 'account': return { Icon: Info, color: 'text-blue-400', bg: 'bg-blue-400/10' };
    case 'announcement': return { Icon: Megaphone, color: 'text-yellow-400', bg: 'bg-yellow-400/10' };
    case 'alert': return { Icon: AlertTriangle, color: 'text-red-400', bg: 'bg-red-400/10' };
    default: return { Icon: Bell, color: 'text-[#8d90a2]', bg: 'bg-[#8d90a2]/10' };
  }
}

export default function NotificationsScreen() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [notifications, setNotifications] = useState<NotificationModel[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    if (!user) return;
    setLoading(true);
    try {
      const records = await pb.collection('notifications').getFullList({
        filter: `userId="${user.id}"`,
        sort: '-created',
      });
      setNotifications(records as unknown as NotificationModel[]);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [user]);

  useEffect(() => { load(); }, [load]);

  const markRead = async (id: string) => {
    try {
      await pb.collection('notifications').update(id, { isRead: true });
      setNotifications((prev) =>
        prev.map((n) => (n.id === id ? { ...n, isRead: true } : n))
      );
    } catch { /* ignore */ }
  };

  const markAllRead = async () => {
    const unread = notifications.filter((n) => !n.isRead);
    await Promise.allSettled(
      unread.map((n) => pb.collection('notifications').update(n.id, { isRead: true }))
    );
    setNotifications((prev) => prev.map((n) => ({ ...n, isRead: true })));
  };

  const unreadCount = notifications.filter((n) => !n.isRead).length;

  return (
    <div className="flex flex-col min-h-screen bg-[#131313]">
      <PageHeader
        title="Notifications"
        onBack={() => navigate(-1)}
        rightAction={
          unreadCount > 0 ? (
            <button
              onClick={markAllRead}
              className="flex items-center gap-1.5 text-[#0052ff] text-sm font-medium"
            >
              <Check size={14} />
              Mark all read
            </button>
          ) : undefined
        }
      />

      <div className="flex-1 overflow-y-auto px-4 pb-24">
        {loading ? (
          <div className="space-y-2">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="bg-[#201f1f] rounded-2xl h-20 animate-pulse" />
            ))}
          </div>
        ) : notifications.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-24 gap-4">
            <div className="w-20 h-20 rounded-full bg-[#201f1f] flex items-center justify-center">
              <BellOff size={36} className="text-[#8d90a2]" />
            </div>
            <p className="text-white font-semibold text-lg">No notifications</p>
            <p className="text-[#8d90a2] text-sm text-center max-w-[240px]">
              You're all caught up. New notifications will appear here.
            </p>
          </div>
        ) : (
          <div className="space-y-2">
            {notifications.map((notif) => {
              const { Icon, color, bg } = notifIcon(notif.type ?? 'account');
              const body = notif.body ?? notif.message ?? '';
              return (
                <button
                  key={notif.id}
                  onClick={() => { if (!notif.isRead) markRead(notif.id); }}
                  className={`w-full flex items-start gap-3 p-4 rounded-2xl text-left transition-colors ${
                    notif.isRead
                      ? 'bg-[#201f1f]'
                      : 'bg-[#201f1f] border border-[#0052ff]/25'
                  }`}
                >
                  <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${bg}`}>
                    <Icon size={18} className={color} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <p className={`text-sm font-semibold leading-snug ${notif.isRead ? 'text-[#8d90a2]' : 'text-white'}`}>
                        {notif.title}
                      </p>
                      {!notif.isRead && (
                        <span className="w-2 h-2 rounded-full bg-[#0052ff] shrink-0 mt-1" />
                      )}
                    </div>
                    <p className="text-[#8d90a2] text-xs leading-relaxed mt-0.5 line-clamp-2">{body}</p>
                    <p className="text-[#8d90a2]/60 text-xs mt-1.5">
                      {formatDistanceToNow(new Date(notif.created), { addSuffix: true })}
                    </p>
                  </div>
                </button>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
