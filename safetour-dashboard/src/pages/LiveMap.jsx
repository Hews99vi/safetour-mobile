import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';

import MapView from '../components/MapView.jsx';
import api from '../services/api.js';
import { useSos } from '../hooks/useSos.js';

const SRI_LANKA_CENTER = { lat: 7.8731, lng: 80.7718 };
const SAFE_ZONE_RADIUS_METERS = 50000;
const ALERT_RADIUS_METERS = 500000;

function timeAgo(dateStr) {
  const diffMs = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diffMs / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  return `${Math.floor(hrs / 24)}d ago`;
}

const STATUS_DOT = {
  pending: 'bg-danger animate-pulse',
  acknowledged: 'bg-yellow-400',
};

const EMERGENCY_COLORS = {
  medical: 'bg-red-500/20 text-red-300',
  theft: 'bg-orange-500/20 text-orange-300',
  harassment: 'bg-purple-500/20 text-purple-300',
  accident: 'bg-yellow-500/20 text-yellow-300',
  fire: 'bg-orange-600/20 text-orange-400',
  other: 'bg-slate-500/20 text-slate-300',
};

function Legend() {
  return (
    <div className="border-t border-slate-800 px-4 py-3 text-xs">
      <p className="mb-2 font-bold uppercase tracking-wide text-slate-400">Legend</p>
      <div className="space-y-1.5">
        <div className="flex items-center gap-2">
          <span className="inline-block h-3 w-3 rounded-full bg-danger" style={{ animation: 'pulse 1.5s ease-in-out infinite' }} />
          <span className="text-slate-300">SOS Emergency</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="inline-block h-3 w-3 rounded-full bg-blue-500" />
          <span className="text-slate-300">Police Station</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="inline-block h-3 w-3 rounded-full bg-red-500" />
          <span className="text-slate-300">Hospital</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="inline-block h-3 w-3 rounded-full bg-purple-500" />
          <span className="text-slate-300">Embassy</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="inline-block h-3 w-3 rounded-full bg-green-500" />
          <span className="text-slate-300">Safe Zone</span>
        </div>
        <div className="flex items-center gap-2">
          <span
            className="inline-block"
            style={{
              width: 0,
              height: 0,
              borderLeft: '6px solid transparent',
              borderRight: '6px solid transparent',
              borderBottom: '11px solid #f97316',
            }}
          />
          <span className="text-slate-300">Active Alert</span>
        </div>
      </div>
    </div>
  );
}

function parseAlertsPayload(payload) {
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload?.alerts)) return payload.alerts;
  return [];
}

export default function LiveMap() {
  const navigate = useNavigate();
  const { reports, isLoading: sosLoading, refresh: refreshSos } = useSos();
  const [safeZones, setSafeZones] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [selectedSosId, setSelectedSosId] = useState(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [lastUpdated, setLastUpdated] = useState(null);

  const loadSafeZones = useCallback(async () => {
    try {
      const response = await api.get('/locations/safe-zones', {
        params: {
          lat: SRI_LANKA_CENTER.lat,
          lng: SRI_LANKA_CENTER.lng,
          radius: SAFE_ZONE_RADIUS_METERS,
        },
      });
      setSafeZones(Array.isArray(response.data) ? response.data : []);
    } catch (err) {
      setError(err.response?.data?.message || 'Unable to load safe zones.');
    }
  }, []);

  const loadAlerts = useCallback(async () => {
    try {
      const response = await api.get('/alerts/recent', {
        params: {
          lat: SRI_LANKA_CENTER.lat,
          lng: SRI_LANKA_CENTER.lng,
          radius: ALERT_RADIUS_METERS,
          limit: 50,
        },
      });
      setAlerts(parseAlertsPayload(response.data));
    } catch {
      // alerts are non-critical; silently ignore
    }
  }, []);

  useEffect(() => {
    async function loadInitialMapData() {
      await Promise.all([loadSafeZones(), loadAlerts()]);
      setLastUpdated(new Date());
    }
    loadInitialMapData();
  }, [loadSafeZones, loadAlerts]);

  async function handleRefresh() {
    setIsRefreshing(true);
    setError('');
    await Promise.all([loadSafeZones(), loadAlerts(), refreshSos()]);
    setLastUpdated(new Date());
    setIsRefreshing(false);
  }

  function handleSosClick(id) {
    setSelectedSosId((prev) => (prev === id ? null : id));
  }

  const sortedReports = [...reports].sort((a, b) => {
    const aTime = new Date(a.createdAt || 0).getTime();
    const bTime = new Date(b.createdAt || 0).getTime();
    return bTime - aTime;
  });

  return (
    <div className="-mx-4 -mt-6 sm:-mx-6 lg:-mx-8" style={{ height: 'calc(100vh - 4rem)' }}>
      <div className="flex h-full">
        {/* Map area */}
        <div className="relative flex-1 overflow-hidden">
          {sosLoading && !reports.length && (
            <div className="absolute inset-0 z-[1001] flex items-center justify-center bg-midnight/70">
              <span className="text-sm text-slate-400">Loading map data…</span>
            </div>
          )}
          <MapView
            sosReports={sortedReports}
            safeZones={safeZones}
            alerts={alerts}
            selectedSosId={selectedSosId}
            onRespond={() => navigate('/sos')}
          />
        </div>

        {/* SOS side panel */}
        <aside className="flex w-[300px] flex-shrink-0 flex-col border-l border-slate-800 bg-panel">
          {/* Panel header */}
          <div className="flex items-center justify-between border-b border-slate-800 px-4 py-3">
            <div>
              <p className="text-xs font-bold uppercase tracking-wide text-cyan">Active SOS</p>
              <p className="text-lg font-black text-white">{sortedReports.length} Report{sortedReports.length !== 1 ? 's' : ''}</p>
            </div>
            <button
              onClick={handleRefresh}
              disabled={isRefreshing}
              className="rounded-lg border border-slate-700 px-3 py-1.5 text-xs font-semibold text-slate-300 transition hover:border-cyan hover:text-cyan disabled:opacity-50"
            >
              {isRefreshing ? '…' : '↻ Refresh'}
            </button>
          </div>

          {lastUpdated && (
            <p className="border-b border-slate-800 px-4 py-1.5 text-xs text-slate-500">
              Updated {lastUpdated.toLocaleTimeString()}
            </p>
          )}

          {error && (
            <p className="mx-3 mt-3 rounded-lg border border-danger/30 bg-danger/10 p-2 text-xs text-red-300">
              {error}
            </p>
          )}

          {/* SOS list */}
          <div className="flex-1 overflow-y-auto">
            {sortedReports.length === 0 ? (
              <div className="flex h-full flex-col items-center justify-center gap-2 text-slate-600">
                <span className="text-3xl">🛡</span>
                <p className="text-sm">No active SOS reports</p>
              </div>
            ) : (
              <ul className="divide-y divide-slate-800">
                {sortedReports.map((report) => {
                  const isSelected = selectedSosId === report._id;
                  const coords = report.location?.coordinates;
                  const lat = coords ? coords[1].toFixed(4) : '—';
                  const lng = coords ? coords[0].toFixed(4) : '—';
                  return (
                    <li
                      key={report._id}
                      onClick={() => handleSosClick(report._id)}
                      className={`cursor-pointer px-4 py-3 transition-colors ${
                        isSelected
                          ? 'border-l-2 border-cyan bg-cyan/5'
                          : 'border-l-2 border-transparent hover:bg-slate-800/50'
                      }`}
                    >
                      <div className="flex items-start justify-between gap-2">
                        <span
                          className={`rounded px-2 py-0.5 text-xs font-bold capitalize ${
                            EMERGENCY_COLORS[report.emergencyType] || EMERGENCY_COLORS.other
                          }`}
                        >
                          {report.emergencyType}
                        </span>
                        <span
                          className={`mt-0.5 inline-block h-2.5 w-2.5 flex-shrink-0 rounded-full ${
                            STATUS_DOT[report.status] || 'bg-slate-500'
                          }`}
                        />
                      </div>
                      <p className="mt-1 truncate text-sm font-medium text-slate-200">
                        {report.userId?.displayName || report.userId?.email || 'Tourist'}
                      </p>
                      <p className="text-xs text-slate-500">
                        {lat}, {lng}
                      </p>
                      <p className="mt-0.5 text-xs text-slate-600">{timeAgo(report.createdAt)}</p>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>
          <Legend />
        </aside>
      </div>
    </div>
  );
}
