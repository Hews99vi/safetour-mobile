export default function StatCard({ label, value, tone = 'cyan', hint }) {
  const tones = {
    cyan: 'border-cyan/40 text-cyan',
    lime: 'border-lime/40 text-lime',
    orange: 'border-orange-400/40 text-orange-300',
    red: 'border-danger/40 text-danger',
  };

  return (
    <div className={`rounded-2xl border bg-slate-900/80 p-5 shadow-xl ${tones[tone]}`}>
      <p className="text-sm font-semibold uppercase tracking-wide text-slate-400">{label}</p>
      <p className="mt-3 text-3xl font-black">{value}</p>
      {hint ? <p className="mt-2 text-sm text-slate-400">{hint}</p> : null}
    </div>
  );
}
