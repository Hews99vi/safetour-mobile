import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';

import Navbar from './components/Navbar.jsx';
import { ProtectedRoute } from './context/AuthContext.jsx';
import Chat from './pages/Chat.jsx';
import Dashboard from './pages/Dashboard.jsx';
import LiveMap from './pages/LiveMap.jsx';
import Login from './pages/Login.jsx';
import SosAlerts from './pages/SosAlerts.jsx';

function ProtectedLayout({ children }) {
  return (
    <ProtectedRoute>
      <div className="min-h-screen bg-midnight">
        <Navbar />
        <main className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
          {children}
        </main>
      </div>
    </ProtectedRoute>
  );
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="/login" element={<Login />} />
        <Route
          path="/dashboard"
          element={
            <ProtectedLayout>
              <Dashboard />
            </ProtectedLayout>
          }
        />
        <Route
          path="/sos"
          element={
            <ProtectedLayout>
              <SosAlerts />
            </ProtectedLayout>
          }
        />
        <Route
          path="/map"
          element={
            <ProtectedLayout>
              <LiveMap />
            </ProtectedLayout>
          }
        />
        <Route
          path="/chat"
          element={
            <ProtectedLayout>
              <Chat />
            </ProtectedLayout>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
