import { useCallback, useEffect, useState } from 'react';

import api from '../services/api.js';

const defaultCenter = { lat: 6.9271, lng: 79.8612 };

export function useAlerts() {
  const [alerts, setAlerts] = useState([]);
  const [riskScore, setRiskScore] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const refresh = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [alertsResponse, riskResponse] = await Promise.all([
        api.get('/alerts/recent', {
          params: { lat: defaultCenter.lat, lng: defaultCenter.lng, limit: 20 },
        }),
        api.get('/locations/risk-score', {
          params: { lat: defaultCenter.lat, lng: defaultCenter.lng },
        }),
      ]);
      const alertsData = alertsResponse.data;
      setAlerts(Array.isArray(alertsData) ? alertsData : alertsData?.alerts || []);
      setRiskScore(riskResponse.data || null);
    } catch (err) {
      setError(err.response?.data?.message || 'Unable to load safety alerts.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    queueMicrotask(refresh);
  }, [refresh]);

  return { alerts, riskScore, loading, error, refresh };
}
