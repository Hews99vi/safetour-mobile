const mongoose = require('mongoose');

const MAX_RETRIES = 5;
const RETRY_DELAY_MS = 5000;

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function connectDb(attempt = 1) {
  const mongoUri = process.env.MONGO_URI;

  if (!mongoUri) {
    throw new Error('MONGO_URI is required');
  }

  try {
    await mongoose.connect(mongoUri);
    console.log('MongoDB connected');
  } catch (error) {
    console.error(`MongoDB connection failed, attempt ${attempt}:`, error.message);

    if (attempt >= MAX_RETRIES) {
      throw error;
    }

    await wait(RETRY_DELAY_MS);
    return connectDb(attempt + 1);
  }
}

module.exports = connectDb;
