const { db } = require('../config/firebase');
const { success, error } = require('../utils/responseFormatter');

/**
 * Get all SWOT items for a project
 * @route GET /api/projects/:projectId/swot
 */
exports.getSwotItems = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId } = req.params;

    // Verify project exists and belongs to user
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    const swotRef = projectRef.collection('swot_items');
    const snapshot = await swotRef.orderBy('createdAt', 'desc').get();

    const items = [];
    snapshot.forEach(doc => {
      items.push({
        id: doc.id,
        ...doc.data()
      });
    });

    res.status(200).json(success(items));
  } catch (err) {
    next(error(err.message, 500));
  }
};

/**
 * Create a new SWOT item
 * @route POST /api/projects/:projectId/swot
 */
exports.createSwotItem = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId } = req.params;
    const { text, type } = req.body;

    // Validate type
    const validTypes = ['strength', 'weakness', 'opportunity', 'threat'];
    if (!validTypes.includes(type)) {
      return next(error(`Invalid SWOT type. Must be one of: ${validTypes.join(', ')}`, 400));
    }

    // Verify project exists
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    const newItem = {
      text,
      type,
      createdAt: new Date(),
      updatedAt: null
    };

    const docRef = await projectRef.collection('swot_items').add(newItem);

    res.status(201).json(success({
      id: docRef.id,
      ...newItem
    }, 'SWOT item created successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Get a specific SWOT item
 * @route GET /api/projects/:projectId/swot/:itemId
 */
exports.getSwotItem = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId, itemId } = req.params;

    const itemRef = db.collection('users').doc(uid)
      .collection('projects').doc(projectId)
      .collection('swot_items').doc(itemId);
    
    const doc = await itemRef.get();

    if (!doc.exists) {
      return next(error('SWOT item not found', 404));
    }

    res.status(200).json(success({
      id: doc.id,
      ...doc.data()
    }));
  } catch (err) {
    next(error(err.message, 500));
  }
};

/**
 * Update a SWOT item
 * @route PUT /api/projects/:projectId/swot/:itemId
 */
exports.updateSwotItem = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId, itemId } = req.params;
    const { text, type } = req.body;

    // Validate type if provided
    if (type) {
      const validTypes = ['strength', 'weakness', 'opportunity', 'threat'];
      if (!validTypes.includes(type)) {
        return next(error(`Invalid SWOT type. Must be one of: ${validTypes.join(', ')}`, 400));
      }
    }

    const itemRef = db.collection('users').doc(uid)
      .collection('projects').doc(projectId)
      .collection('swot_items').doc(itemId);
    
    const doc = await itemRef.get();

    if (!doc.exists) {
      return next(error('SWOT item not found', 404));
    }

    const updates = {};
    if (text !== undefined) updates.text = text;
    if (type !== undefined) updates.type = type;
    updates.updatedAt = new Date();

    await itemRef.update(updates);

    res.status(200).json(success({}, 'SWOT item updated successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Delete a SWOT item
 * @route DELETE /api/projects/:projectId/swot/:itemId
 */
exports.deleteSwotItem = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId, itemId } = req.params;

    const itemRef = db.collection('users').doc(uid)
      .collection('projects').doc(projectId)
      .collection('swot_items').doc(itemId);
    
    const doc = await itemRef.get();

    if (!doc.exists) {
      return next(error('SWOT item not found', 404));
    }

    await itemRef.delete();

    res.status(200).json(success({}, 'SWOT item deleted successfully'));
  } catch (err) {
    next(error(err.message, 500));
  }
};

/**
 * Move a SWOT item to a different type
 * @route PUT /api/projects/:projectId/swot/:itemId/move
 */
exports.moveSwotItem = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId, itemId } = req.params;
    const { newType } = req.body;

    // Validate type
    const validTypes = ['strength', 'weakness', 'opportunity', 'threat'];
    if (!validTypes.includes(newType)) {
      return next(error(`Invalid SWOT type. Must be one of: ${validTypes.join(', ')}`, 400));
    }

    const itemRef = db.collection('users').doc(uid)
      .collection('projects').doc(projectId)
      .collection('swot_items').doc(itemId);
    
    const doc = await itemRef.get();

    if (!doc.exists) {
      return next(error('SWOT item not found', 404));
    }

    await itemRef.update({
      type: newType,
      updatedAt: new Date()
    });

    res.status(200).json(success({}, 'SWOT item moved successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};