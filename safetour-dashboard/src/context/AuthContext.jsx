/* eslint-disable react-refresh/only-export-components */
import { createContext, useCallback, useContext, useMemo, useState } from 'react';
import { Navigate, useLocation } from 'react-router-dom';

import api from '../services/api.js';

const AuthContext = createContext(null);
const tokenKey = 'safetour_dashboard_token';
const userKey = 'safetour_dashboard_user';

function readStoredUser() {
  try {
    const raw = localStorage.getItem(userKey);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem(tokenKey));
  const [user, setUser] = useState(readStoredUser);

  const login = useCallback(async (email, password) => {
    const response = await api.post('/auth/login', { email, password });
    const nextToken = response.data?.token;
    const nextUser = response.data?.user;

    if (!nextToken || !nextUser) {
      throw new Error('Invalid login response.');
    }

    if (nextUser.role !== 'admin') {
      throw new Error('Authority access requires an admin account.');
    }

    localStorage.setItem(tokenKey, nextToken);
    localStorage.setItem(userKey, JSON.stringify(nextUser));
    setToken(nextToken);
    setUser(nextUser);
    return nextUser;
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem(tokenKey);
    localStorage.removeItem(userKey);
    setToken(null);
    setUser(null);
  }, []);

  const value = useMemo(
    () => ({ user, token, login, logout }),
    [user, token, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used inside AuthProvider.');
  }
  return context;
}

export function ProtectedRoute({ children }) {
  const { token } = useAuth();
  const location = useLocation();
  if (!token) return <Navigate to="/login" replace state={{ from: location }} />;
  return children;
}
