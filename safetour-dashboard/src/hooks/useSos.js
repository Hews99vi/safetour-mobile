import { useCallback, useEffect, useMemo, useState } from 'react';

import { useAuth } from './useAuth.js';
import { useSocket } from './useSocket.js';
import api from '../services/api.js';

const activeStatuses = new Set(['pending', 'acknowledged']);

function normalizeReport(payload) {
  if (!payload) return null;
  return payload.sos || payload.report || payload;
}

function reportId(report) {
  return report?._id || report?.sosId || report?.id;
}

function sortNewestFirst(items) {
  return [...items].sort((a, b) => {
    const aTime = new Date(a.createdAt || 0).getTime();
    const bTime = new Date(b.createdAt || 0).getTime();
    return bTime - aTime;
  });
}

export function useSos() {
  const { token } = useAuth();
  const { socket } = useSocket(token);
  const [sosList, setSosList] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  const refresh = useCallback(async () => {
    setIsLoading(true);
    setError('');
    try {
      const response = await api.get('/sos/active');
      const nextReports = Array.isArray(response.data) ? response.data : [];
      setSosList(sortNewestFirst(nextReports));
    } catch (err) {
      setError(err.response?.data?.message || 'Unable to load active SOS reports.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  const acknowledge = useCallback(
    async (sosId) => {
      await api.patch(`/sos/${sosId}/status`, { status: 'acknowledged' });
      await refresh();
    },
    [refresh],
  );

  const resolve = useCallback(
    async (sosId) => {
      await api.patch(`/sos/${sosId}/status`, { status: 'resolved' });
      setSosList((current) => current.filter((item) => reportId(item) !== sosId));
    },
    [],
  );

  useEffect(() => {
    queueMicrotask(refresh);
  }, [refresh]);

  useEffect(() => {
    if (!socket) return undefined;

    function handleNew(payload) {
      const report = normalizeReport(payload);
      const id = reportId(report);
      if (!report || !id) return;

      setSosList((current) => {
        if (current.some((item) => reportId(item) === id)) return current;
        return sortNewestFirst([report, ...current]);
      });
    }

    function handleUpdated(payload) {
      const report = normalizeReport(payload);
      const id = reportId(report);
      if (!report || !id) return;

      setSosList((current) => {
        if (!activeStatuses.has(report.status)) {
          return current.filter((item) => reportId(item) !== id);
        }

        const exists = current.some((item) => reportId(item) === id);
        const next = exists
          ? current.map((item) => (reportId(item) === id ? { ...item, ...report } : item))
          : [report, ...current];

        return sortNewestFirst(next);
      });
    }

    socket.on('sos_new', handleNew);
    socket.on('sos_updated', handleUpdated);

    return () => {
      socket.off('sos_new', handleNew);
      socket.off('sos_updated', handleUpdated);
    };
  }, [socket]);

  return useMemo(
    () => ({
      sosList,
      reports: sosList,
      acknowledge,
      resolve,
      isLoading,
      loading: isLoading,
      error,
      refresh,
    }),
    [sosList, acknowledge, resolve, isLoading, error, refresh],
  );
}
