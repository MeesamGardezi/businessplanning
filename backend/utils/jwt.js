const jwt = require('jsonwebtoken');

// Secret key should be in environment variables
const JWT_SECRET = process.env.JWT_SECRET || 'lmfao';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1d'; // 1 day by default
const JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '7d'; // 7 days by default

/**
 * Generate an access token for a user
 * @param {Object} user - User data to include in token payload
 * @returns {String} JWT access token
 */
exports.generateAccessToken = (user) => {
  const payload = {
    uid: user.uid || user.id,
    email: user.email,
    role: user.role || 'user',
  };
  
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
};

/**
 * Generate a refresh token for a user
 * @param {Object} user - User data to include in token payload
 * @returns {String} JWT refresh token
 */
exports.generateRefreshToken = (user) => {
  const payload = {
    uid: user.uid || user.id,
    tokenType: 'refresh'
  };
  
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_REFRESH_EXPIRES_IN });
};

/**
 * Verify and decode a JWT token
 * @param {String} token - JWT token to verify
 * @returns {Object} Decoded token payload or null if invalid
 */
exports.verifyToken = (token) => {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (err) {
    return null;
  }
};

/**
 * Get token expiration time
 * @param {String} token - JWT token
 * @returns {Date|null} Expiration date or null if token is invalid
 */
exports.getTokenExpiration = (token) => {
  const decoded = this.verifyToken(token);
  if (!decoded || !decoded.exp) return null;
  
  // JWT exp is in seconds, convert to milliseconds
  return new Date(decoded.exp * 1000);
};