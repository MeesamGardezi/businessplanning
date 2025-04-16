const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const authController = require('../controllers/authController');

// Define validation rules
const authRules = {
  register: [
    body('email')
      .isEmail().withMessage('Valid email is required')
      .normalizeEmail(),
    body('password')
      .isLength({ min: 6 }).withMessage('Password must be at least 6 characters long'),
    body('displayName')
      .optional()
      .trim()
      .isLength({ min: 2 }).withMessage('Display name must be at least 2 characters long')
  ],
  updateProfile: [
    body('displayName')
      .optional()
      .trim()
      .isLength({ min: 2 }).withMessage('Display name must be at least 2 characters long'),
    body('photoURL')
      .optional()
      .isURL().withMessage('Photo URL must be a valid URL')
  ]
};

// Public routes
router.post('/register', validate(authRules.register), authController.register);

// Protected routes
router.get('/me', authenticate, authController.getCurrentUser);
router.put('/profile', authenticate, validate(authRules.updateProfile), authController.updateProfile);
router.delete('/account', authenticate, authController.deleteAccount);

module.exports = router;