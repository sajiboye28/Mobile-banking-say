import { NavLink } from 'react-router-dom';
import { Home, ArrowLeftRight, Send, CreditCard, User } from 'lucide-react';

const leftTabs = [
  { to: '/', icon: Home, label: 'Home', end: true },
  { to: '/transactions', icon: ArrowLeftRight, label: 'History', end: false },
];
const rightTabs = [
  { to: '/cards', icon: CreditCard, label: 'Cards', end: false },
  { to: '/profile', icon: User, label: 'Profile', end: false },
];

function TabItem({
  to,
  icon: Icon,
  label,
  end,
}: {
  to: string;
  icon: React.ElementType;
  label: string;
  end: boolean;
}) {
  return (
    <NavLink
      to={to}
      end={end}
      className="flex-1 flex justify-center"
    >
      {({ isActive }) => (
        <div className="flex flex-col items-center gap-1 py-2 px-3">
          <div
            className={`p-2 rounded-[14px] transition-all duration-200 ${
              isActive ? 'bg-primary/15' : ''
            }`}
          >
            <Icon
              size={21}
              strokeWidth={isActive ? 2.5 : 1.8}
              className={`transition-colors duration-200 ${
                isActive ? 'text-primary' : 'text-outline'
              }`}
            />
          </div>
          <span
            className={`text-[9px] font-bold tracking-widest uppercase leading-none transition-colors duration-200 ${
              isActive ? 'text-primary' : 'text-outline/70'
            }`}
          >
            {label}
          </span>
        </div>
      )}
    </NavLink>
  );
}

export default function BottomNav() {
  return (
    <nav className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[430px] z-50">
      <div className="relative px-4 pb-5 pt-6">
        {/* ── Floating Send FAB ──────────────────────────────────────── */}
        <NavLink
          to="/send"
          className="absolute left-1/2 -translate-x-1/2 top-0 z-10 w-[58px] h-[58px] rounded-full bg-primary flex items-center justify-center"
          style={{
            border: '4px solid #131313',
            boxShadow: '0 6px 28px rgba(79,120,255,0.60), 0 2px 8px rgba(0,0,0,0.4)',
          }}
        >
          {({ isActive }) => (
            <Send
              size={20}
              strokeWidth={2.5}
              className={`text-white transition-transform duration-200 ${
                isActive ? 'scale-90' : 'scale-100'
              }`}
            />
          )}
        </NavLink>

        {/* ── Glass nav bar ─────────────────────────────────────────── */}
        <div
          className="flex items-center h-[60px] rounded-[22px]"
          style={{
            background: 'rgba(32,31,31,0.92)',
            backdropFilter: 'blur(24px)',
            WebkitBackdropFilter: 'blur(24px)',
            border: '1px solid rgba(255,255,255,0.06)',
            boxShadow: '0 -2px 20px rgba(0,0,0,0.5), 0 4px 16px rgba(0,0,0,0.35)',
          }}
        >
          {/* Left 2 items */}
          <div className="flex flex-1">
            {leftTabs.map((t) => (
              <TabItem key={t.to} {...t} />
            ))}
          </div>

          {/* Spacer for the floating FAB */}
          <div className="w-[64px] shrink-0" />

          {/* Right 2 items */}
          <div className="flex flex-1">
            {rightTabs.map((t) => (
              <TabItem key={t.to} {...t} />
            ))}
          </div>
        </div>
      </div>
    </nav>
  );
}
