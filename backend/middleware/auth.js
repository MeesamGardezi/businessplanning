const { verifyToken } = require('../utils/jwt');
const { error } = require('../utils/responseFormatter');
const { admin, db } = require('../config/firebase');

/**
 * Middleware to verify JWT authentication token
 */
exports.authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false, 
        message: 'Access denied. No token provided.' 
      });
    }
    
    const token = authHeader.split(' ')[1];
    
    // Verify the JWT token using our custom verification
    const decoded = verifyToken(token);
    if (!decoded) {
      return res.status(403).json({ 
        success: false, 
        message: 'Invalid or expired token.' 
      });
    }

    // Skip Firebase authentication check
    // Just verify user exists in Firestore
    try {
      const userDoc = await db.collection('users').doc(decoded.uid).get();
      
      if (!userDoc.exists) {
        return res.status(403).json({ 
          success: false, 
          message: 'User not found in database.' 
        });
      }
      
      // Add the user to the request object
      req.user = {
        uid: decoded.uid,
        email: decoded.email,
        role: decoded.role || 'user'
      };
      
      next();
    } catch (dbError) {
      console.error('Database lookup error:', dbError);
      return res.status(500).json({ 
        success: false, 
        message: 'Error verifying user in database.' 
      });
    }
  } catch (error) {
    console.error('Authentication error:', error);
    
    return res.status(403).json({ 
      success: false, 
      message: 'Authentication failed.' 
    });
  }
};

/**
 * Middleware to verify admin role
 * Must be used after the authenticate middleware
 */
exports.authorizeAdmin = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    return next();
  }
  
  return res.status(403).json({
    success: false,
    message: 'Access denied. Admin privileges required.'
  });
};