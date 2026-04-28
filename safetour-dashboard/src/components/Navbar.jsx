import { NavLink, useNavigate } from 'react-router-dom';

import { useAuth } from '../hooks/useAuth.js';
import { useSos } from '../hooks/useSos.js';

const links = [
  { to: '/dashboard', label: 'Dashboard' },
  { to: '/sos', label: 'SOS' },
  { to: '/map', label: 'Live Map' },
  { to: '/chat', label: 'Chat' },
];

export default function Navbar() {
  const { user, logout } = useAuth();
  const { sosList } = useSos();
  const navigate = useNavigate();
  const pendingCount = sosList.filter((sos) => sos.status === 'pending').length;

  function handleLogout() {
    logout();
    navigate('/login', { replace: true });
  }

  return (
    <header className="border-b border-slate-800 bg-slate-950/95 backdrop-blur">
      <div className="mx-auto flex max-w-7xl flex-col gap-4 px-4 py-4 sm:px-6 lg:flex-row lg:items-center lg:justify-between lg:px-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.35em] text-cyan">
            SafeTour Sri Lanka
          </p>
          <h1 className="text-xl font-bold text-white">Authority Console</h1>
        </div>
        <nav className="flex flex-wrap items-center gap-2">
          {links.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              className={({ isActive }) =>
                `rounded-lg px-3 py-2 text-sm font-semibold transition ${
                  isActive
                    ? 'bg-cyan text-slate-950'
                    : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`
              }
            >
              <span className="inline-flex items-center gap-2">
                {link.label}
                {link.to === '/sos' && pendingCount > 0 ? (
                  <span className="rounded-full bg-danger px-2 py-0.5 text-xs font-black text-white">
                    {pendingCount}
                  </span>
                ) : null}
              </span>
            </NavLink>
          ))}
        </nav>
        <div className="flex items-center gap-3">
          <span className="text-sm text-slate-300">{user?.displayName || user?.email}</span>
          <button
            onClick={handleLogout}
            className="rounded-lg border border-slate-700 px-3 py-2 text-sm font-semibold text-slate-200 hover:border-danger hover:text-danger"
          >
            Logout
          </button>
        </div>
      </div>
    </header>
  );
}
