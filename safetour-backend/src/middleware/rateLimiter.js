const rateLimit = require('express-rate-limit');

const apiRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'TooManyRequests',
    message: 'Too many requests. Please try again later.',
    statusCode: 429
  }
});

module.exports = apiRateLimiter;
