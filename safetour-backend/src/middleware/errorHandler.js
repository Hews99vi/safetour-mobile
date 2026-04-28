function errorHandler(err, req, res, next) {
  const statusCode = err.statusCode || err.status || 500;

  res.status(statusCode).json({
    error: err.name || 'InternalServerError',
    message: err.message || 'Something went wrong',
    statusCode
  });
}

module.exports = errorHandler;
