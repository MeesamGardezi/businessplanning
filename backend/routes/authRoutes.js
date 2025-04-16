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
  login: [
    body('email')
      .isEmail().withMessage('Valid email is required')
      .normalizeEmail(),
    body('password')
      .notEmpty().withMessage('Password is required')
  ],
  checkEmail: [
    body('email')
      .isEmail().withMessage('Valid email is required')
      .normalizeEmail()
  ],
  setPassword: [
    body('email')
      .isEmail().withMessage('Valid email is required')
      .normalizeEmail(),
    body('password')
      .isLength({ min: 6 }).withMessage('Password must be at least 6 characters long')
  ],
  updateProfile: [
    body('displayName')
      .optional()
      .trim()
      .isLength({ min: 2 }).withMessage('Display name must be at least 2 characters long'),
    body('photoURL')
      .optional()
      .isURL().withMessage('Photo URL must be a valid URL')
  ],
  refreshToken: [
    body('refreshToken')
      .notEmpty().withMessage('Refresh token is required')
  ],
  resetPassword: [
    body('email')
      .isEmail().withMessage('Valid email is required')
      .normalizeEmail()
  ],
  resetPasswordConfirm: [
    body('email')
      .isEmail().withMessage('Valid email is required')
      .normalizeEmail(),
    body('token')
      .notEmpty().withMessage('Token is required'),
    body('password')
      .isLength({ min: 6 }).withMessage('Password must be at least 6 characters long')
  ],
  logout: [
    body('refreshToken')
      .optional()
  ],
  verifyEmailConfirm: [
    body('email')
      .isEmail().withMessage('Valid email is required')
      .normalizeEmail(),
    body('token')
      .notEmpty().withMessage('Token is required')
  ]
};

// Public routes
router.post('/register', validate(authRules.register), authController.register);
router.post('/login', validate(authRules.login), authController.login);
router.post('/check-email', validate(authRules.checkEmail), authController.checkEmail);
router.post('/set-password', validate(authRules.setPassword), authController.setPassword);
router.post('/refresh-token', validate(authRules.refreshToken), authController.refreshToken);
router.post('/reset-password', validate(authRules.resetPassword), authController.resetPassword);
router.post('/reset-password/confirm', validate(authRules.resetPasswordConfirm), authController.resetPasswordConfirm);
router.post('/verify-email/confirm', validate(authRules.verifyEmailConfirm), authController.verifyEmailConfirm);

// Protected routes
router.get('/me', authenticate, authController.getCurrentUser);
router.put('/profile', authenticate, validate(authRules.updateProfile), authController.updateProfile);
router.delete('/account', authenticate, authController.deleteAccount);
router.post('/logout', authenticate, validate(authRules.logout), authController.logout);
router.post('/verify-email', authenticate, authController.verifyEmail);

module.exports = router;