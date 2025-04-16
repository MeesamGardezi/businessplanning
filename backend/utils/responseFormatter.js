/**
 * Format successful response
 * @param {Object} data - Data to be returned
 * @param {string} message - Success message
 * @returns {Object} Formatted response object
 */
exports.success = (data, message = 'Operation successful') => {
    return {
      success: true,
      message,
      data
    };
  };
  
  /**
   * Format error response
   * @param {string} message - Error message
   * @param {number} statusCode - HTTP status code
   * @returns {Object} Formatted error object
   */
  exports.error = (message, statusCode = 400) => {
    const err = new Error(message);
    err.statusCode = statusCode;
    return err;
  };