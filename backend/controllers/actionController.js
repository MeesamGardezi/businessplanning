const { db } = require('../config/firebase');
const { success, error } = require('../utils/responseFormatter');

/**
 * Get all action items for a project
 * @route GET /api/projects/:projectId/actions
 */
exports.getActionItems = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId } = req.params;

    // Verify project exists and belongs to user
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    const actionsRef = projectRef.collection('action_items');
    const snapshot = await actionsRef.orderBy('id').get();

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
 * Create a new action item
 * @route POST /api/projects/:projectId/actions
 */
exports.createActionItem = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId } = req.params;
    const { task, responsible, completionDate, update, status } = req.body;

    // Validate status if provided
    if (status) {
      const validStatuses = ['incomplete', 'inProgress', 'complete'];
      if (!validStatuses.includes(status)) {
        return next(error(`Invalid status. Must be one of: ${validStatuses.join(', ')}`, 400));
      }
    }

    // Verify project exists
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    // Get next available ID
    const actionsRef = projectRef.collection('action_items');
    const snapshot = await actionsRef.orderBy('id', 'desc').limit(1).get();
    
    let nextId = '1';
    if (!snapshot.empty) {
      const lastDoc = snapshot.docs[0];
      const lastId = parseInt(lastDoc.data().id);
      nextId = (lastId + 1).toString();
    }

    const newItem = {
      id: nextId,
      task: task || '',
      responsible: responsible || '',
      completionDate: completionDate ? new Date(completionDate) : null,
      update: update || '',
      status: status || 'incomplete',
      createdAt: new Date(),
      updatedAt: null
    };

    await actionsRef.doc(nextId).set(newItem);

    res.status(201).json(success({
      ...newItem
    }, 'Action item created successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Get a specific action item
 * @route GET /api/projects/:projectId/actions/:itemId
 */
exports.getActionItem = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId, itemId } = req.params;

    const itemRef = db.collection('users').doc(uid)
      .collection('projects').doc(projectId)
      .collection('action_items').doc(itemId);
    
    const doc = await itemRef.get();

    if (!doc.exists) {
      return next(error('Action item not found', 404));
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
 * Update an action item
 * @route PUT /api/projects/:projectId/actions/:itemId
 */
exports.updateActionItem = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId, itemId } = req.params;
    const { task, responsible, completionDate, update, status } = req.body;

    // Validate status if provided
    if (status) {
      const validStatuses = ['incomplete', 'inProgress', 'complete'];
      if (!validStatuses.includes(status)) {
        return next(error(`Invalid status. Must be one of: ${validStatuses.join(', ')}`, 400));
      }
    }

    const itemRef = db.collection('users').doc(uid)
      .collection('projects').doc(projectId)
      .collection('action_items').doc(itemId);
    
    const doc = await itemRef.get();

    if (!doc.exists) {
      return next(error('Action item not found', 404));
    }

    const updates = {};
    if (task !== undefined) updates.task = task;
    if (responsible !== undefined) updates.responsible = responsible;
    if (completionDate !== undefined) updates.completionDate = completionDate ? new Date(completionDate) : null;
    if (update !== undefined) updates.update = update;
    if (status !== undefined) updates.status = status;
    updates.updatedAt = new Date();

    await itemRef.update(updates);

    res.status(200).json(success({}, 'Action item updated successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Delete an action item
 * @route DELETE /api/projects/:projectId/actions/:itemId
 */
exports.deleteActionItem = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId, itemId } = req.params;

    const itemRef = db.collection('users').doc(uid)
      .collection('projects').doc(projectId)
      .collection('action_items').doc(itemId);
    
    const doc = await itemRef.get();

    if (!doc.exists) {
      return next(error('Action item not found', 404));
    }

    await itemRef.delete();

    res.status(200).json(success({}, 'Action item deleted successfully'));
  } catch (err) {
    next(error(err.message, 500));
  }
};

/**
 * Update action item status
 * @route PUT /api/projects/:projectId/actions/:itemId/status
 */
exports.updateStatus = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId, itemId } = req.params;
    const { status } = req.body;

    const validStatuses = ['incomplete', 'inProgress', 'complete'];
    if (!validStatuses.includes(status)) {
      return next(error(`Invalid status. Must be one of: ${validStatuses.join(', ')}`, 400));
    }

    const itemRef = db.collection('users').doc(uid)
      .collection('projects').doc(projectId)
      .collection('action_items').doc(itemId);
    
    const doc = await itemRef.get();

    if (!doc.exists) {
      return next(error('Action item not found', 404));
    }

    await itemRef.update({
      status,
      updatedAt: new Date()
    });

    res.status(200).json(success({}, 'Status updated successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Batch create multiple action items
 * @route POST /api/projects/:projectId/actions/batch
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

    // Get next available ID
    const actionsRef = projectRef.collection('action_items');
    const snapshot = await actionsRef.orderBy('id', 'desc').limit(1).get();
    
    let nextId = 1;
    if (!snapshot.empty) {
      const lastDoc = snapshot.docs[0];
      const lastId = parseInt(lastDoc.data().id);
      nextId = lastId + 1;
    }

    // Create batch
    const batch = db.batch();
    const createdItems = [];

    items.forEach((item, index) => {
      const id = (nextId + index).toString();
      const itemRef = actionsRef.doc(id);
      
      // Validate status if provided
      let status = item.status || 'incomplete';
      const validStatuses = ['incomplete', 'inProgress', 'complete'];
      if (!validStatuses.includes(status)) {
        status = 'incomplete';
      }

      const newItem = {
        id,
        task: item.task || '',
        responsible: item.responsible || '',
        completionDate: item.completionDate ? new Date(item.completionDate) : null,
        update: item.update || '',
        status,
        createdAt: new Date(),
        updatedAt: null
      };

      batch.set(itemRef, newItem);
      createdItems.push({ id, ...newItem });
    });

    await batch.commit();

    res.status(201).json(success(createdItems, 'Action items created successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};