const { validationResult } = require('express-validator');
const { error } = require('../utils/responseFormatter');

/**
 * Middleware to validate requests using express-validator
 */
exports.validate = (validations) => {
  return async (req, res, next) => {
    // Run all validations
    await Promise.all(validations.map(validation => validation.run(req)));

    // Check for validation errors
    const errors = validationResult(req);
    if (errors.isEmpty()) {
      return next();
    }

    // Format validation errors
    const extractedErrors = [];
    errors.array().forEach(err => {
      extractedErrors.push({ field: err.param, message: err.msg });
    });

    // Return validation error
    return next(error('Validation failed', 400, extractedErrors));
  };
};