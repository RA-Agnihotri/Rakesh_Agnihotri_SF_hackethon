import { RefreshCw } from 'lucide-react';
import { useState } from 'react';

interface Props { onRefresh: () => void; label?: string; }

export default function RefreshButton({ onRefresh, label = 'Refresh' }: Props) {
  const [spinning, setSpinning] = useState(false);
  const handleClick = () => { setSpinning(true); onRefresh(); setTimeout(() => setSpinning(false), 1000); };

  return (
    <button onClick={handleClick}
      className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-gray-500 dark:text-slate-400 bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-lg hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
      title="Refresh data from Snowflake">
      <RefreshCw className={`w-3.5 h-3.5 ${spinning ? 'animate-spin' : ''}`} /> {label}
    </button>
  );
}
