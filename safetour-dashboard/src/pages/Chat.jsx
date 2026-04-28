import { useEffect, useMemo, useState } from 'react';

import { useAuth } from '../hooks/useAuth.js';
import { useSocket } from '../hooks/useSocket.js';
import api from '../services/api.js';

export default function Chat() {
  const { token } = useAuth();
  const { socket, connected } = useSocket(token);
  const [roomId, setRoomId] = useState('');
  const [activeRoom, setActiveRoom] = useState('');
  const [messages, setMessages] = useState([]);
  const [content, setContent] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    if (!socket) return undefined;
    function handleMessage(message) {
      setMessages((current) => [...current, message]);
    }
    socket.on('message_received', handleMessage);
    return () => socket.off('message_received', handleMessage);
  }, [socket]);

  async function joinRoom(event) {
    event.preventDefault();
    if (!roomId.trim() || !socket) return;
    setError('');
    const normalized = roomId.trim();
    socket.emit('join_room', { roomId: normalized }, async (ack) => {
      if (!ack?.success) {
        setError(ack?.message || 'Unable to join room.');
        return;
      }
      setActiveRoom(normalized);
      const response = await api.get(`/chat/${normalized}/history`);
      setMessages(Array.isArray(response.data) ? response.data : []);
    });
  }

  function sendMessage(event) {
    event.preventDefault();
    if (!content.trim() || !activeRoom || !socket) return;
    socket.emit('send_message', {
      roomId: activeRoom,
      content: content.trim(),
      messageType: 'text',
    });
    setContent('');
  }

  const statusClass = connected ? 'bg-lime' : 'bg-danger';
  const sortedMessages = useMemo(() => messages, [messages]);

  return (
    <div className="grid gap-6 lg:grid-cols-[320px,1fr]">
      <section className="rounded-2xl border border-slate-800 bg-slate-900/80 p-5">
        <div className="flex items-center gap-2">
          <span className={`h-3 w-3 rounded-full ${statusClass}`} />
          <p className="text-sm font-semibold text-slate-300">
            Socket {connected ? 'connected' : 'disconnected'}
          </p>
        </div>
        <form onSubmit={joinRoom} className="mt-5 space-y-3">
          <label className="block text-sm font-semibold text-slate-300">Tourist room ID</label>
          <input
            value={roomId}
            onChange={(event) => setRoomId(event.target.value)}
            placeholder="tourist_<userId>"
            className="w-full rounded-xl border border-slate-700 bg-slate-950 px-3 py-2 text-white outline-none focus:border-cyan"
          />
          <button className="w-full rounded-xl bg-cyan px-4 py-2 font-bold text-slate-950">
            Join room
          </button>
        </form>
        {error ? <p className="mt-4 rounded-xl bg-danger/10 p-3 text-sm text-red-200">{error}</p> : null}
      </section>
      <section className="flex min-h-[640px] flex-col rounded-2xl border border-slate-800 bg-slate-900/80">
        <div className="border-b border-slate-800 p-4">
          <h2 className="text-xl font-bold text-white">{activeRoom || 'No room selected'}</h2>
        </div>
        <div className="flex-1 space-y-3 overflow-y-auto p-4">
          {sortedMessages.map((message) => (
            <div
              key={message._id || message.messageId || `${message.createdAt}-${message.content}`}
              className={`max-w-xl rounded-2xl p-3 ${
                message.senderRole === 'authority'
                  ? 'ml-auto bg-cyan text-slate-950'
                  : 'bg-slate-950 text-slate-100'
              }`}
            >
              <p className="text-sm font-semibold">{message.senderRole || 'tourist'}</p>
              <p>{message.content}</p>
            </div>
          ))}
        </div>
        <form onSubmit={sendMessage} className="flex gap-3 border-t border-slate-800 p-4">
          <input
            value={content}
            onChange={(event) => setContent(event.target.value)}
            disabled={!activeRoom}
            placeholder={activeRoom ? 'Type a response...' : 'Join a room first'}
            className="flex-1 rounded-xl border border-slate-700 bg-slate-950 px-4 py-3 text-white outline-none focus:border-cyan disabled:opacity-50"
          />
          <button
            disabled={!activeRoom}
            className="rounded-xl bg-cyan px-5 py-3 font-bold text-slate-950 disabled:opacity-50"
          >
            Send
          </button>
        </form>
      </section>
    </div>
  );
}
