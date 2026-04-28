require('dotenv').config();

const http = require('http');
const app = require('./app');
const connectDb = require('./config/db');
const { initializeChatService } = require('./services/chatService');
require('./config/firebase');

const PORT = process.env.PORT || 5000;

async function startServer() {
  await connectDb();

  const httpServer = http.createServer(app);
  initializeChatService(httpServer);

  httpServer.listen(PORT, () => {
    console.log(`SafeTour backend running on port ${PORT}`);
  });
}

startServer().catch((error) => {
  console.error('Failed to start SafeTour backend:', error);
  process.exit(1);
});
