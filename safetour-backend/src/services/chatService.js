const jwt = require('jsonwebtoken');
const { Server } = require('socket.io');

const ChatMessage = require('../models/ChatMessage');
const User = require('../models/User');
const notificationService = require('./notificationService');

const allowedMessageTypes = ['text', 'location', 'image'];
const roomMembers = new Map();

function initializeChatService(httpServer) {
  const io = new Server(httpServer, {
    cors: { origin: '*' }
  });

  io.use(authenticateSocket);

  io.on('connection', (socket) => {
    console.log(`Socket connected: ${socket.id}`);

    socket.on('join_room', async (payload = {}, callback) => {
      try {
        const roomId = validateRoomAccess(socket, payload.roomId);
        await socket.join(roomId);
        trackJoin(socket, roomId);
        callback?.({ success: true, roomId });
      } catch (error) {
        callback?.({ success: false, message: error.message });
        socket.emit('chat_error', { message: error.message });
      }
    });

    socket.on('send_message', async (payload = {}, callback) => {
      try {
        const roomId = validateRoomAccess(socket, payload.roomId);
        const content = validateContent(payload.content);
        const messageType = validateMessageType(payload.messageType);
        const locationData = validateLocationData(payload.locationData);
        const senderRole = socket.data.user.role === 'admin' ? 'authority' : 'tourist';

        const message = await ChatMessage.create({
          roomId,
          senderId: socket.data.user.userId,
          senderRole,
          content,
          messageType,
          locationData
        });

        const eventPayload = toMessagePayload(message);
        io.to(roomId).emit('message_received', eventPayload);

        if (senderRole === 'tourist' && !roomHasAdmin(roomId)) {
          await notifyAdmins(roomId, content);
        }

        callback?.({ success: true, message: eventPayload });
      } catch (error) {
        callback?.({ success: false, message: error.message });
        socket.emit('chat_error', { message: error.message });
      }
    });

    socket.on('mark_read', async (payload = {}, callback) => {
      try {
        const roomId = validateRoomAccess(socket, payload.roomId);
        await ChatMessage.updateMany(
          {
            roomId,
            senderId: { $ne: socket.data.user.userId }
          },
          { isRead: true }
        );
        callback?.({ success: true });
      } catch (error) {
        callback?.({ success: false, message: error.message });
        socket.emit('chat_error', { message: error.message });
      }
    });

    socket.on('typing', (payload = {}, callback) => {
      try {
        const roomId = validateRoomAccess(socket, payload.roomId);
        socket.to(roomId).emit('typing_indicator', {
          roomId,
          userId: socket.data.user.userId,
          role: socket.data.user.role
        });
        callback?.({ success: true });
      } catch (error) {
        callback?.({ success: false, message: error.message });
        socket.emit('chat_error', { message: error.message });
      }
    });

    socket.on('disconnect', () => {
      trackDisconnect(socket);
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });

  return io;
}

function authenticateSocket(socket, next) {
  const token = socket.handshake.auth?.token;

  if (!token) {
    return next(new Error('Authentication token is required.'));
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.data.user = {
      userId: decoded.userId,
      role: decoded.role
    };
    return next();
  } catch (error) {
    return next(new Error('Invalid or expired authentication token.'));
  }
}

function validateRoomAccess(socket, roomId) {
  if (typeof roomId !== 'string' || roomId.trim().length === 0) {
    throw new Error('roomId is required.');
  }

  const normalizedRoomId = roomId.trim();
  const { userId, role } = socket.data.user;
  const touristRoomId = `tourist_${userId}`;

  if (role !== 'admin' && normalizedRoomId !== touristRoomId) {
    throw new Error('You do not have access to this room.');
  }

  return normalizedRoomId;
}

function validateContent(content) {
  if (typeof content !== 'string' || content.trim().length === 0) {
    throw new Error('content is required.');
  }

  const trimmed = content.trim();
  if (trimmed.length > 2000) {
    throw new Error('content must be 2000 characters or less.');
  }

  return trimmed;
}

function validateMessageType(messageType) {
  if (messageType == null) {
    return 'text';
  }

  if (!allowedMessageTypes.includes(messageType)) {
    throw new Error(`messageType must be one of: ${allowedMessageTypes.join(', ')}.`);
  }

  return messageType;
}

function validateLocationData(locationData) {
  if (locationData == null) {
    return undefined;
  }

  const lat = Number(locationData.lat);
  const lng = Number(locationData.lng);

  if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
    throw new Error('locationData.lat must be a valid latitude.');
  }

  if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
    throw new Error('locationData.lng must be a valid longitude.');
  }

  return { lat, lng };
}

function trackJoin(socket, roomId) {
  socket.data.chatRooms ??= new Set();
  socket.data.chatRooms.add(roomId);

  const members = roomMembers.get(roomId) ?? new Map();
  members.set(socket.id, socket.data.user.role);
  roomMembers.set(roomId, members);
}

function trackDisconnect(socket) {
  const rooms = socket.data.chatRooms;
  if (!rooms) return;

  for (const roomId of rooms) {
    const members = roomMembers.get(roomId);
    if (!members) continue;
    members.delete(socket.id);
    if (members.size === 0) {
      roomMembers.delete(roomId);
    }
  }
}

function roomHasAdmin(roomId) {
  const members = roomMembers.get(roomId);
  if (!members) return false;
  return [...members.values()].includes('admin');
}

function toMessagePayload(message) {
  return {
    messageId: message._id.toString(),
    senderId: message.senderId.toString(),
    senderRole: message.senderRole,
    content: message.content,
    messageType: message.messageType,
    locationData: message.locationData,
    createdAt: message.createdAt
  };
}

async function notifyAdmins(roomId, content) {
  const admins = await User.find({
    role: 'admin',
    fcmToken: { $exists: true, $ne: '' }
  }).select('fcmToken');

  await notificationService.sendToMultiple(
    admins.map((admin) => admin.fcmToken),
    {
      title: 'New message from tourist',
      body: content.length > 80 ? `${content.slice(0, 77)}...` : content,
      data: {
        roomId,
        type: 'chat'
      }
    }
  );
}

module.exports = { initializeChatService };
