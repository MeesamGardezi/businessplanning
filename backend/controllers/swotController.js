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
    const { type, search, page = 1, limit = 50 } = req.query;

    // Verify project exists and belongs to user
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    let query = projectRef.collection('swot_items');
    
    // Apply type filter if provided
    if (type && ['strength', 'weakness', 'opportunity', 'threat'].includes(type)) {
      query = query.where('type', '==', type);
    }

    // Apply sorting
    query = query.orderBy('createdAt', 'desc');

    // Get total count for pagination
    const countSnapshot = await query.get();
    const totalItems = countSnapshot.size;
    const totalPages = Math.ceil(totalItems / limit);

    // Apply pagination
    const pageSize = parseInt(limit);
    const pageNumber = parseInt(page);
    const offset = (pageNumber - 1) * pageSize;
    
    // Get paginated results
    const snapshot = await query.limit(pageSize).offset(offset).get();

    // Process results
    const items = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      items.push({
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate() : null,
        updatedAt: data.updatedAt ? data.updatedAt.toDate() : null
      });
    });

    // If search is provided, filter in memory (Firestore doesn't support text search)
    let filteredItems = items;
    if (search) {
      const searchLower = search.toLowerCase();
      filteredItems = items.filter(item => 
        item.text.toLowerCase().includes(searchLower)
      );
    }

    res.status(200).json(success({
      items: filteredItems,
      pagination: {
        total: search ? filteredItems.length : totalItems,
        page: pageNumber,
        limit: pageSize,
        totalPages: search ? Math.ceil(filteredItems.length / pageSize) : totalPages
      }
    }));
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

    const data = doc.data();

    res.status(200).json(success({
      id: doc.id,
      ...data,
      createdAt: data.createdAt ? data.createdAt.toDate() : null,
      updatedAt: data.updatedAt ? data.updatedAt.toDate() : null
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

/**
 * Batch create multiple SWOT items
 * @route POST /api/projects/:projectId/swot/batch
 */
exports.batchCreateItems = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId } = req.params;
    const { items } = req.body;

    if (!Array.isArray(items) || items.length === 0) {
      return next(error('Items array is required and must not be empty', 400));
    }

    // Verify project exists
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    // Validate items
    const validTypes = ['strength', 'weakness', 'opportunity', 'threat'];
    const invalidItems = items.filter(item => !validTypes.includes(item.type));
    if (invalidItems.length > 0) {
      return next(error(`Invalid SWOT type. Must be one of: ${validTypes.join(', ')}`, 400));
    }

    // Create batch
    const batch = db.batch();
    const swotRef = projectRef.collection('swot_items');
    const createdItems = [];

    for (const item of items) {
      const newDocRef = swotRef.doc();
      const timestamp = new Date();
      
      const newItem = {
        text: item.text,
        type: item.type,
        createdAt: timestamp,
        updatedAt: null
      };

      batch.set(newDocRef, newItem);
      createdItems.push({ id: newDocRef.id, ...newItem });
    }

    await batch.commit();

    res.status(201).json(success(createdItems, 'SWOT items created successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Batch update multiple SWOT items
 * @route PUT /api/projects/:projectId/swot/batch
 */
exports.batchUpdateItems = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId } = req.params;
    const { items } = req.body;

    if (!Array.isArray(items) || items.length === 0) {
      return next(error('Items array is required and must not be empty', 400));
    }

    // Verify project exists
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    // Validate items
    const validTypes = ['strength', 'weakness', 'opportunity', 'threat'];
    const invalidItems = items.filter(item => 
      item.type && !validTypes.includes(item.type)
    );
    
    if (invalidItems.length > 0) {
      return next(error(`Invalid SWOT type. Must be one of: ${validTypes.join(', ')}`, 400));
    }

    // Create batch
    const batch = db.batch();
    const swotRef = projectRef.collection('swot_items');
    const updatedItems = [];
    const timestamp = new Date();

    for (const item of items) {
      if (!item.id) {
        return next(error('Each item must have an id', 400));
      }

      const itemRef = swotRef.doc(item.id);
      const doc = await itemRef.get();

      if (!doc.exists) {
        return next(error(`SWOT item with id ${item.id} not found`, 404));
      }

      const updates = {};
      if (item.text !== undefined) updates.text = item.text;
      if (item.type !== undefined) updates.type = item.type;
      updates.updatedAt = timestamp;

      batch.update(itemRef, updates);
      updatedItems.push({ id: item.id, ...updates });
    }

    await batch.commit();

    res.status(200).json(success(updatedItems, 'SWOT items updated successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Batch delete multiple SWOT items
 * @route DELETE /api/projects/:projectId/swot/batch
 */
exports.batchDeleteItems = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId } = req.params;
    const { ids } = req.body;

    if (!Array.isArray(ids) || ids.length === 0) {
      return next(error('IDs array is required and must not be empty', 400));
    }

    // Verify project exists
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    // Create batch
    const batch = db.batch();
    const swotRef = projectRef.collection('swot_items');

    for (const id of ids) {
      const itemRef = swotRef.doc(id);
      const doc = await itemRef.get();

      if (!doc.exists) {
        return next(error(`SWOT item with id ${id} not found`, 404));
      }

      batch.delete(itemRef);
    }

    await batch.commit();

    res.status(200).json(success({}, 'SWOT items deleted successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Get SWOT statistics
 * @route GET /api/projects/:projectId/swot/stats
 */
exports.getSwotStats = async (req, res, next) => {
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
    const snapshot = await swotRef.get();

    // Initialize stats
    const stats = {
      total: snapshot.size,
      byType: {
        strength: 0,
        weakness: 0,
        opportunity: 0,
        threat: 0
      },
      internal: 0, // strengths + weaknesses
      external: 0, // opportunities + threats
      positive: 0, // strengths + opportunities
      negative: 0, // weaknesses + threats
      mostRecent: null
    };

    // Calculate statistics
    let mostRecentDate = null;
    
    snapshot.forEach(doc => {
      const data = doc.data();
      const type = data.type;
      
      // Count by type
      stats.byType[type]++;
      
      // Count internal/external and positive/negative
      if (type === 'strength' || type === 'weakness') {
        stats.internal++;
      } else {
        stats.external++;
      }
      
      if (type === 'strength' || type === 'opportunity') {
        stats.positive++;
      } else {
        stats.negative++;
      }
      
      // Track most recent
      if (data.createdAt && (!mostRecentDate || data.createdAt.toDate() > mostRecentDate)) {
        mostRecentDate = data.createdAt.toDate();
        stats.mostRecent = {
          id: doc.id,
          text: data.text,
          type: data.type,
          createdAt: mostRecentDate
        };
      }
    });

    // Calculate percentages
    if (stats.total > 0) {
      stats.percentages = {
        strength: Math.round((stats.byType.strength / stats.total) * 100),
        weakness: Math.round((stats.byType.weakness / stats.total) * 100),
        opportunity: Math.round((stats.byType.opportunity / stats.total) * 100),
        threat: Math.round((stats.byType.threat / stats.total) * 100),
        internal: Math.round((stats.internal / stats.total) * 100),
        external: Math.round((stats.external / stats.total) * 100),
        positive: Math.round((stats.positive / stats.total) * 100),
        negative: Math.round((stats.negative / stats.total) * 100)
      };
    }

    res.status(200).json(success(stats));
  } catch (err) {
    next(error(err.message, 500));
  }
};