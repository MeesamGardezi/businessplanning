/**
 * Global error handling middleware
 */
const errorHandler = (err, req, res, next) => {
    console.error('Error:', err);
    
    // Default error status and message
    const status = err.statusCode || 500;
    const message = err.message || 'Internal Server Error';
    
    // Different error formats based on environment
    if (process.env.NODE_ENV === 'production') {
      return res.status(status).json({
        success: false,
        message
      });
    } else {
      // More detailed error in development
      return res.status(status).json({
        success: false,
        message,
        stack: err.stack,
        error: err
      });
    }
  };
  
  module.exports = errorHandler;