import { useNavigate } from 'react-router-dom';
import { ChevronLeft } from 'lucide-react';

interface PageHeaderProps {
  title: string;
  showBack?: boolean;
  onBack?: () => void;
  rightAction?: React.ReactNode;
}

export default function PageHeader({
  title,
  showBack = true,
  onBack,
  rightAction,
}: PageHeaderProps) {
  const navigate = useNavigate();

  const handleBack = () => {
    if (onBack) onBack();
    else navigate(-1);
  };

  return (
    <div
      className="flex items-center justify-between px-4 py-3.5 sticky top-0 z-20"
      style={{
        background: 'rgba(19,19,19,0.90)',
        backdropFilter: 'blur(16px)',
        WebkitBackdropFilter: 'blur(16px)',
        borderBottom: '1px solid rgba(255,255,255,0.05)',
      }}
    >
      <div className="flex items-center gap-3 min-w-0">
        {showBack && (
          <button
            onClick={handleBack}
            className="flex items-center justify-center w-9 h-9 rounded-full bg-surface-container border border-surface-bright/50 hover:bg-surface-bright transition-colors shrink-0 active:scale-95"
            aria-label="Go back"
          >
            <ChevronLeft size={20} className="text-on-surface" />
          </button>
        )}
        <h1 className="text-on-surface font-bold text-lg tracking-tight truncate">
          {title}
        </h1>
      </div>
      {rightAction && <div className="shrink-0 ml-2">{rightAction}</div>}
    </div>
  );
}
