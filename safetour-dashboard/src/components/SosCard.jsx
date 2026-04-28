import { useState } from 'react';

function coordinatesOf(sos) {
  const coordinates = sos.location?.coordinates;
  if (!Array.isArray(coordinates) || coordinates.length < 2) return null;
  return {
    lat: Number(coordinates[1]),
    lng: Number(coordinates[0]),
  };
}

function mapsUrl(point) {
  return `https://www.google.com/maps/search/?api=1&query=${point.lat},${point.lng}`;
}

function timeAgo(value) {
  const created = new Date(value || Date.now()).getTime();
  const diffMs = Math.max(Date.now() - created, 0);
  const minutes = Math.floor(diffMs / 60000);
  if (minutes < 1) return 'Just now';
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} hr ago`;
  return `${Math.floor(hours / 24)} d ago`;
}

function statusDot(status) {
  if (status === 'acknowledged') return 'bg-yellow-400 shadow-yellow-400/60';
  return 'bg-danger shadow-danger/60';
}

export default function SosCard({ sos, onAcknowledge, onResolve }) {
  const [isResolving, setIsResolving] = useState(false);
  const tourist = sos.userId || {};
  const point = coordinatesOf(sos);

  function handleResolve() {
    setIsResolving(true);
    window.setTimeout(() => {
      onResolve(sos._id);
    }, 260);
  }

  return (
    <article
      className={`rounded-2xl border border-danger/30 bg-slate-900/85 p-5 shadow-xl transition-all duration-300 ${
        isResolving ? '-translate-y-2 opacity-0' : 'translate-y-0 opacity-100'
      }`}
    >
      <div className="flex flex-col gap-4">
        <div className="flex items-start justify-between gap-4">
          <div className="flex items-center gap-3">
            <span
              className={`mt-1 h-3.5 w-3.5 rounded-full shadow-lg ${statusDot(sos.status)}`}
              aria-label={sos.status}
            />
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <span className="rounded-full bg-danger/15 px-2.5 py-1 text-xs font-bold uppercase text-danger">
                  {sos.emergencyType || 'SOS'}
                </span>
                <span className="rounded-full bg-slate-950 px-2.5 py-1 text-xs font-bold uppercase text-slate-300">
                  {sos.status}
                </span>
              </div>
              <p className="mt-2 text-lg font-bold text-white">
                {tourist.displayName || 'Unknown tourist'}
              </p>
              <p className="text-sm text-slate-400">{tourist.email || 'No email available'}</p>
            </div>
          </div>
          <span className="shrink-0 text-sm font-semibold text-slate-400">
            {timeAgo(sos.createdAt)}
          </span>
        </div>

        {sos.description ? (
          <p className="rounded-xl bg-slate-950/70 p-3 text-sm text-slate-200">
            {sos.description}
          </p>
        ) : null}

        <div className="flex flex-col gap-3 border-t border-slate-800 pt-4 sm:flex-row sm:items-center sm:justify-between">
          {point ? (
            <a
              href={mapsUrl(point)}
              target="_blank"
              rel="noreferrer"
              className="text-sm font-semibold text-cyan hover:text-sky-300"
            >
              {point.lat.toFixed(5)}, {point.lng.toFixed(5)}
            </a>
          ) : (
            <span className="text-sm text-slate-500">Unknown location</span>
          )}

          <div className="flex gap-2">
            <button
              onClick={() => onAcknowledge(sos._id)}
              disabled={sos.status === 'acknowledged' || isResolving}
              className="rounded-lg bg-cyan px-3 py-2 text-sm font-bold text-slate-950 disabled:cursor-not-allowed disabled:opacity-50"
            >
              Acknowledge
            </button>
            <button
              onClick={handleResolve}
              disabled={isResolving}
              className="rounded-lg bg-lime px-3 py-2 text-sm font-bold text-slate-950 disabled:cursor-wait disabled:opacity-60"
            >
              Resolve
            </button>
          </div>
        </div>
      </div>
    </article>
  );
}
