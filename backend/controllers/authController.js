const { auth, db } = require('../config/firebase');
const { success, error } = require('../utils/responseFormatter');
const { generateAccessToken, generateRefreshToken, verifyToken } = require('../utils/jwt');
const crypto = require('crypto');

/**
 * Register a new user
 * @route POST /api/auth/register
 */
exports.register = async (req, res, next) => {
  try {
    const { email, password, displayName } = req.body;

    // Create user in Firebase Auth
    const userRecord = await auth.createUser({
      email,
      password,
      displayName,
    });

    // Create user document in Firestore
    await db.collection('users').doc(userRecord.uid).set({
      email,
      displayName,
      createdAt: new Date(),
      status: 'active',
      role: 'user'
    });

    // Generate tokens
    const tokens = {
      accessToken: generateAccessToken({ uid: userRecord.uid, email, role: 'user' }),
      refreshToken: generateRefreshToken({ uid: userRecord.uid })
    };

    res.status(201).json(success({ 
      uid: userRecord.uid,
      ...tokens 
    }, 'User registered successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Login a user
 * @route POST /api/auth/login
 */
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Verify with Firebase Auth
    let userRecord;
    try {
      // Find user by email
      const userResults = await auth.getUserByEmail(email);
      userRecord = userResults;
    } catch (firebaseError) {
      return next(error('Invalid email or password', 401));
    }

    // Get user from Firestore
    const userDoc = await db.collection('users').doc(userRecord.uid).get();
    if (!userDoc.exists) {
      return next(error('User account not found', 404));
    }

    const userData = userDoc.data();

    // Generate tokens
    const tokens = {
      accessToken: generateAccessToken({ 
        uid: userRecord.uid, 
        email: userRecord.email, 
        role: userData.role || 'user' 
      }),
      refreshToken: generateRefreshToken({ uid: userRecord.uid })
    };

    // Store refresh token hash in database for validation later
    const refreshTokenHash = crypto
      .createHash('sha256')
      .update(tokens.refreshToken)
      .digest('hex');

    await db.collection('users').doc(userRecord.uid).collection('tokens').add({
      tokenHash: refreshTokenHash,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
    });

    res.status(200).json(success({
      user: {
        uid: userRecord.uid,
        email: userRecord.email,
        displayName: userData.displayName,
        photoURL: userData.photoURL,
        role: userData.role || 'user'
      },
      ...tokens
    }, 'Login successful'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Logout a user
 * @route POST /api/auth/logout
 */
exports.logout = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    const { uid } = req.user;

    if (refreshToken) {
      // Invalidate the refresh token
      const refreshTokenHash = crypto
        .createHash('sha256')
        .update(refreshToken)
        .digest('hex');

      const tokensRef = db.collection('users').doc(uid).collection('tokens');
      const tokenSnapshot = await tokensRef
        .where('tokenHash', '==', refreshTokenHash)
        .get();

      if (!tokenSnapshot.empty) {
        const batch = db.batch();
        tokenSnapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
        await batch.commit();
      }
    }

    res.status(200).json(success({}, 'Logout successful'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Refresh authentication token
 * @route POST /api/auth/refresh-token
 */
exports.refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return next(error('Refresh token is required', 400));
    }

    // Verify the refresh token
    const decoded = verifyToken(refreshToken);
    if (!decoded || decoded.tokenType !== 'refresh') {
      return next(error('Invalid refresh token', 401));
    }

    // Verify token exists in database (not revoked)
    const refreshTokenHash = crypto
      .createHash('sha256')
      .update(refreshToken)
      .digest('hex');

    const tokensRef = db.collection('users').doc(decoded.uid).collection('tokens');
    const tokenSnapshot = await tokensRef
      .where('tokenHash', '==', refreshTokenHash)
      .get();

    if (tokenSnapshot.empty) {
      return next(error('Refresh token has been revoked', 401));
    }

    // Get user data
    const userDoc = await db.collection('users').doc(decoded.uid).get();
    if (!userDoc.exists) {
      return next(error('User not found', 404));
    }

    const userData = userDoc.data();
    
    // Generate new tokens
    const newAccessToken = generateAccessToken({ 
      uid: decoded.uid, 
      email: userData.email, 
      role: userData.role || 'user' 
    });
    
    const newRefreshToken = generateRefreshToken({ uid: decoded.uid });

    // Update refresh token in database
    const newRefreshTokenHash = crypto
      .createHash('sha256')
      .update(newRefreshToken)
      .digest('hex');

    // Delete old token and add new one
    const batch = db.batch();
    tokenSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    batch.set(tokensRef.doc(), {
      tokenHash: newRefreshTokenHash,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
    });
    
    await batch.commit();

    res.status(200).json(success({
      accessToken: newAccessToken,
      refreshToken: newRefreshToken
    }, 'Token refreshed successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Check if email exists
 * @route POST /api/auth/check-email
 */
exports.checkEmail = async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email) {
      return next(error('Email is required', 400));
    }

    let exists = false;
    try {
      await auth.getUserByEmail(email);
      exists = true;
    } catch (firebaseError) {
      if (firebaseError.code !== 'auth/user-not-found') {
        return next(error(firebaseError.message, 500));
      }
      // User not found, exists = false
    }

    res.status(200).json(success({ exists }));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Reset password - initiate process
 * @route POST /api/auth/reset-password
 */
exports.resetPassword = async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email) {
      return next(error('Email is required', 400));
    }

    // Generate reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenHash = crypto
      .createHash('sha256')
      .update(resetToken)
      .digest('hex');

    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour from now

    try {
      // Find user
      const userRecord = await auth.getUserByEmail(email);
      
      // Store reset token in Firestore
      await db.collection('users').doc(userRecord.uid).update({
        passwordReset: {
          token: resetTokenHash,
          expiresAt
        }
      });

      // In a real application, send an email with reset link
      // For testing, we'll return the token
      res.status(200).json(success({
        message: 'Password reset instructions sent',
        resetToken // This would normally not be returned in production
      }));
    } catch (firebaseError) {
      // Don't reveal whether the email exists
      res.status(200).json(success({
        message: 'If an account with that email exists, password reset instructions have been sent'
      }));
    }
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Reset password - complete process
 * @route POST /api/auth/reset-password/confirm
 */
exports.resetPasswordConfirm = async (req, res, next) => {
  try {
    const { email, token, password } = req.body;

    if (!email || !token || !password) {
      return next(error('Email, token and password are required', 400));
    }

    const tokenHash = crypto
      .createHash('sha256')
      .update(token)
      .digest('hex');

    try {
      // Find user
      const userRecord = await auth.getUserByEmail(email);
      const userDoc = await db.collection('users').doc(userRecord.uid).get();
      
      if (!userDoc.exists) {
        return next(error('Invalid or expired reset token', 400));
      }

      const userData = userDoc.data();
      const resetData = userData.passwordReset;

      if (!resetData || 
          resetData.token !== tokenHash || 
          new Date(resetData.expiresAt.toDate()) < new Date()) {
        return next(error('Invalid or expired reset token', 400));
      }

      // Update password in Firebase Auth
      await auth.updateUser(userRecord.uid, {
        password
      });

      // Clear reset token
      await db.collection('users').doc(userRecord.uid).update({
        passwordReset: null,
        updatedAt: new Date()
      });

      res.status(200).json(success({}, 'Password reset successfully'));
    } catch (firebaseError) {
      return next(error('Invalid or expired reset token', 400));
    }
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Set or update user password
 * @route POST /api/auth/set-password
 */
exports.setPassword = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return next(error('Email and password are required', 400));
    }

    // Find user in Firebase Auth
    try {
      const userRecord = await auth.getUserByEmail(email);
      
      // Update password in Firebase Auth
      await auth.updateUser(userRecord.uid, {
        password
      });

      // Update any necessary fields in Firestore
      await db.collection('users').doc(userRecord.uid).update({
        updatedAt: new Date()
      });

      res.status(200).json(success({}, 'Password updated successfully'));
    } catch (firebaseError) {
      return next(error('User not found', 404));
    }
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Get current user profile
 * @route GET /api/auth/me
 */
exports.getCurrentUser = async (req, res, next) => {
  try {
    // User info is available from the auth middleware
    const { uid } = req.user;

    // Fetch user document from Firestore
    const userDoc = await db.collection('users').doc(uid).get();
    
    if (!userDoc.exists) {
      return next(error('User not found', 404));
    }

    const userData = userDoc.data();
    
    // Remove sensitive information
    const { passwordReset, ...user } = userData;

    res.status(200).json(success(user));
  } catch (err) {
    next(error(err.message, 500));
  }
};

/**
 * Update user profile
 * @route PUT /api/auth/profile
 */
exports.updateProfile = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { displayName, photoURL } = req.body;

    // Update in Firebase Auth
    await auth.updateUser(uid, {
      displayName,
      photoURL
    });

    // Update in Firestore
    await db.collection('users').doc(uid).update({
      displayName,
      photoURL,
      updatedAt: new Date()
    });

    res.status(200).json(success({}, 'Profile updated successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Delete user account
 * @route DELETE /api/auth/account
 */
exports.deleteAccount = async (req, res, next) => {
  try {
    const { uid } = req.user;

    // Delete from Firebase Auth
    await auth.deleteUser(uid);
    
    // Delete from Firestore
    await db.collection('users').doc(uid).delete();

    res.status(200).json(success({}, 'Account deleted successfully'));
  } catch (err) {
    next(error(err.message, 500));
  }
};

/**
 * Verify email - initiate process
 * @route POST /api/auth/verify-email
 */
exports.verifyEmail = async (req, res, next) => {
  try {
    const { uid } = req.user;

    // Generate verification token
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const verificationTokenHash = crypto
      .createHash('sha256')
      .update(verificationToken)
      .digest('hex');

    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    // Store verification token in Firestore
    await db.collection('users').doc(uid).update({
      emailVerification: {
        token: verificationTokenHash,
        expiresAt
      }
    });

    // In a real application, send an email with verification link
    // For testing, we'll return the token
    res.status(200).json(success({
      message: 'Verification email sent',
      verificationToken // This would normally not be returned in production
    }));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Verify email - complete process
 * @route POST /api/auth/verify-email/confirm
 */
exports.verifyEmailConfirm = async (req, res, next) => {
  try {
    const { email, token } = req.body;

    if (!email || !token) {
      return next(error('Email and token are required', 400));
    }

    const tokenHash = crypto
      .createHash('sha256')
      .update(token)
      .digest('hex');

    try {
      // Find user
      const userRecord = await auth.getUserByEmail(email);
      const userDoc = await db.collection('users').doc(userRecord.uid).get();
      
      if (!userDoc.exists) {
        return next(error('Invalid or expired verification token', 400));
      }

      const userData = userDoc.data();
      const verificationData = userData.emailVerification;

      if (!verificationData || 
          verificationData.token !== tokenHash || 
          new Date(verificationData.expiresAt.toDate()) < new Date()) {
        return next(error('Invalid or expired verification token', 400));
      }

      // Update in Firebase Auth
      await auth.updateUser(userRecord.uid, {
        emailVerified: true
      });

      // Clear verification token
      await db.collection('users').doc(userRecord.uid).update({
        emailVerification: null,
        emailVerified: true,
        updatedAt: new Date()
      });

      res.status(200).json(success({}, 'Email verified successfully'));
    } catch (firebaseError) {
      return next(error('Invalid or expired verification token', 400));
    }
  } catch (err) {
    next(error(err.message, 400));
  }
};