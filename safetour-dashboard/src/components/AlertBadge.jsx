const severityClasses = {
  low: 'bg-lime/15 text-lime ring-lime/30',
  medium: 'bg-yellow-400/15 text-yellow-300 ring-yellow-400/30',
  high: 'bg-orange-400/15 text-orange-300 ring-orange-400/30',
  critical: 'bg-danger/15 text-danger ring-danger/30',
};

export default function AlertBadge({ severity = 'low' }) {
  return (
    <span
      className={`rounded-full px-2.5 py-1 text-xs font-bold uppercase ring-1 ${
        severityClasses[severity] || severityClasses.low
      }`}
    >
      {severity}
    </span>
  );
}
