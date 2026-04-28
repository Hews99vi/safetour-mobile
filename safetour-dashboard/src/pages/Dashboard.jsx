import AlertBadge from '../components/AlertBadge.jsx';
import StatCard from '../components/StatCard.jsx';
import { useAlerts } from '../hooks/useAlerts.js';
import { useAuth } from '../hooks/useAuth.js';
import { useSocket } from '../hooks/useSocket.js';
import { useSos } from '../hooks/useSos.js';

export default function Dashboard() {
  const { token } = useAuth();
  const { reports } = useSos();
  const { alerts, riskScore, loading } = useAlerts();
  const { connected } = useSocket(token);
  const criticalAlerts = alerts.filter((alert) => alert.severity === 'critical');

  return (
    <div className="space-y-6">
      <div>
        <p className="text-sm font-semibold uppercase tracking-wide text-cyan">Overview</p>
        <h2 className="text-3xl font-black text-white">Live safety operations</h2>
      </div>
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Active SOS" value={reports.length} tone="red" hint="Pending or acknowledged" />
        <StatCard label="Active Alerts" value={alerts.length} tone="orange" hint="Latest backend alerts" />
        <StatCard
          label="Risk Level"
          value={riskScore?.level || 'N/A'}
          tone={(riskScore?.score || 0) > 70 ? 'red' : 'lime'}
          hint={riskScore ? `${riskScore.score}/100` : loading ? 'Loading' : 'Unavailable'}
        />
        <StatCard
          label="Chat Socket"
          value={connected ? 'Online' : 'Offline'}
          tone={connected ? 'lime' : 'red'}
          hint="Authority websocket"
        />
      </div>
      <section className="grid gap-4 lg:grid-cols-2">
        <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-5">
          <h3 className="text-lg font-bold text-white">Recent SOS</h3>
          <div className="mt-4 space-y-3">
            {reports.slice(0, 4).map((report) => (
              <div key={report._id} className="rounded-xl bg-slate-950/70 p-4">
                <p className="font-semibold capitalize text-white">{report.emergencyType}</p>
                <p className="text-sm text-slate-400">
                  {report.userId?.displayName || report.userId?.email || 'Tourist'} - {report.status}
                </p>
              </div>
            ))}
            {reports.length === 0 ? <p className="text-sm text-slate-400">No active SOS reports.</p> : null}
          </div>
        </div>
        <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-5">
          <h3 className="text-lg font-bold text-white">Critical Alerts</h3>
          <div className="mt-4 space-y-3">
            {criticalAlerts.slice(0, 4).map((alert) => (
              <div key={alert._id} className="rounded-xl bg-slate-950/70 p-4">
                <div className="flex items-center justify-between gap-3">
                  <p className="font-semibold text-white">{alert.title}</p>
                  <AlertBadge severity={alert.severity} />
                </div>
                <p className="mt-1 text-sm text-slate-400">{alert.description}</p>
              </div>
            ))}
            {criticalAlerts.length === 0 ? <p className="text-sm text-slate-400">No critical alerts.</p> : null}
          </div>
        </div>
      </section>
    </div>
  );
}
