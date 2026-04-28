import { useEffect, useState } from 'react';
import { io } from 'socket.io-client';

export function useSocket(token) {
  const [socket, setSocket] = useState(null);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    if (!token) return undefined;

    const socket = io(import.meta.env.VITE_WS_BASE_URL || 'http://localhost:5000', {
      auth: { token },
      reconnectionAttempts: 5,
      transports: ['websocket'],
    });

    queueMicrotask(() => setSocket(socket));
    socket.on('connect', () => setConnected(true));
    socket.on('disconnect', () => setConnected(false));
    socket.on('connect_error', () => setConnected(false));

    return () => {
      socket.disconnect();
      queueMicrotask(() => setSocket(null));
      setConnected(false);
    };
  }, [token]);

  return { socket, connected };
}
