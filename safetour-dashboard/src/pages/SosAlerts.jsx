import { useMemo, useState } from 'react';

import SosCard from '../components/SosCard.jsx';
import StatCard from '../components/StatCard.jsx';
import { useSos } from '../hooks/useSos.js';

const filters = [
  { label: 'All', value: 'all' },
  { label: 'Pending', value: 'pending' },
  { label: 'Acknowledged', value: 'acknowledged' },
];

function sortNewestFirst(items) {
  return [...items].sort((a, b) => {
    const aTime = new Date(a.createdAt || 0).getTime();
    const bTime = new Date(b.createdAt || 0).getTime();
    return bTime - aTime;
  });
}

export default function SosAlerts() {
  const { sosList, isLoading, error, refresh, acknowledge, resolve } = useSos();
  const [filter, setFilter] = useState('all');

  const pending = sosList.filter((sos) => sos.status === 'pending');
  const acknowledged = sosList.filter((sos) => sos.status === 'acknowledged');
  const visibleList = useMemo(() => {
    const filtered =
      filter === 'all' ? sosList : sosList.filter((sos) => sos.status === filter);
    return sortNewestFirst(filtered);
  }, [filter, sosList]);

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-sm font-semibold uppercase tracking-wide text-danger">SOS Response</p>
          <h2 className="text-3xl font-black text-white">Active emergency reports</h2>
        </div>
        <button
          onClick={refresh}
          className="rounded-xl border border-slate-700 px-4 py-2 font-semibold text-slate-200 hover:border-cyan hover:text-cyan"
        >
          Refresh
        </button>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <StatCard label="Total active" value={sosList.length} tone="red" />
        <StatCard label="Pending" value={pending.length} tone="orange" />
        <StatCard label="Acknowledged" value={acknowledged.length} tone="cyan" />
      </div>

      <div className="flex flex-wrap gap-2 rounded-2xl border border-slate-800 bg-slate-900/80 p-2">
        {filters.map((item) => (
          <button
            key={item.value}
            onClick={() => setFilter(item.value)}
            className={`rounded-xl px-4 py-2 text-sm font-bold transition ${
              filter === item.value
                ? 'bg-cyan text-slate-950'
                : 'text-slate-300 hover:bg-slate-800 hover:text-white'
            }`}
          >
            {item.label}
          </button>
        ))}
      </div>

      {isLoading ? <p className="text-slate-400">Loading SOS reports...</p> : null}
      {error ? (
        <p className="rounded-xl border border-danger/40 bg-danger/10 p-4 text-red-200">
          {error}
        </p>
      ) : null}

      <div className="grid gap-4 xl:grid-cols-2">
        {visibleList.map((sos) => (
          <SosCard
            key={sos._id}
            sos={sos}
            onAcknowledge={acknowledge}
            onResolve={resolve}
          />
        ))}
      </div>

      {!isLoading && visibleList.length === 0 ? (
        <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-10 text-center text-slate-400">
          <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-lime/10 text-lime">
            <svg
              viewBox="0 0 24 24"
              className="h-8 w-8"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.8"
              aria-hidden="true"
            >
              <path d="M12 3 5 6v5c0 4.5 3 8.5 7 10 4-1.5 7-5.5 7-10V6l-7-3Z" />
              <path d="m9 12 2 2 4-5" />
            </svg>
          </div>
          <p className="mt-4 text-lg font-bold text-white">No active SOS alerts</p>
          <p className="mt-1 text-sm text-slate-400">
            New tourist emergency reports will appear here in real time.
          </p>
        </div>
      ) : null}
    </div>
  );
}
