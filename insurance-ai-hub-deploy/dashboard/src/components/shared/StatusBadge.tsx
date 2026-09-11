interface Props {
  status: string;
}

export default function StatusBadge({ status }: Props) {
  const colors: Record<string, string> = {
    Healthy: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
    Warning: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
    Critical: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
    UP: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
    DOWN: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
    STABLE: 'bg-gray-100 text-gray-700 dark:bg-gray-700/50 dark:text-gray-300',
  };
  return (
    <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${colors[status] || 'bg-gray-100 text-gray-600'}`}>
      {status}
    </span>
  );
}
