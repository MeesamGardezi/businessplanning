const { auth, db } = require('../config/firebase');
const { success, error } = require('../utils/responseFormatter');

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
      status: 'active'
    });

    res.status(201).json(success({ uid: userRecord.uid }, 'User registered successfully'));
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
    const { password, ...user } = userData;

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