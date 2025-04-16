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
    const { status, search, page = 1, limit = 50 } = req.query;

    // Verify project exists and belongs to user
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    let query = projectRef.collection('action_items');
    
    // Apply status filter if provided
    if (status && ['incomplete', 'inProgress', 'complete'].includes(status)) {
      query = query.where('status', '==', status);
    }

    // Apply sorting by ID
    query = query.orderBy('id');

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

    const items = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      items.push({
        id: doc.id,
        ...data,
        completionDate: data.completionDate ? data.completionDate.toDate() : null,
        createdAt: data.createdAt ? data.createdAt.toDate() : null,
        updatedAt: data.updatedAt ? data.updatedAt.toDate() : null
      });
    });

    // If search is provided, filter in memory (Firestore doesn't support text search)
    let filteredItems = items;
    if (search) {
      const searchLower = search.toLowerCase();
      filteredItems = items.filter(item => 
        item.task.toLowerCase().includes(searchLower) ||
        item.responsible.toLowerCase().includes(searchLower) ||
        item.update.toLowerCase().includes(searchLower)
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

    // Format dates for response
    const responseItem = {
      ...newItem,
      completionDate: newItem.completionDate ? newItem.completionDate.toISOString() : null,
      createdAt: newItem.createdAt.toISOString(),
      updatedAt: null
    };

    res.status(201).json(success(responseItem, 'Action item created successfully'));
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

    const data = doc.data();

    res.status(200).json(success({
      id: doc.id,
      ...data,
      completionDate: data.completionDate ? data.completionDate.toDate() : null,
      createdAt: data.createdAt ? data.createdAt.toDate() : null,
      updatedAt: data.updatedAt ? data.updatedAt.toDate() : null
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

    // Get the updated document
    const updatedDoc = await itemRef.get();
    const updatedData = updatedDoc.data();

    res.status(200).json(success({
      id: itemId,
      ...updatedData,
      completionDate: updatedData.completionDate ? updatedData.completionDate.toDate() : null,
      createdAt: updatedData.createdAt ? updatedData.createdAt.toDate() : null,
      updatedAt: updatedData.updatedAt ? updatedData.updatedAt.toDate() : null
    }, 'Action item updated successfully'));
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
    const timestamp = new Date();

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
        createdAt: timestamp,
        updatedAt: null
      };

      batch.set(itemRef, newItem);
      
      // Format dates for response
      createdItems.push({
        ...newItem,
        completionDate: newItem.completionDate ? newItem.completionDate.toISOString() : null,
        createdAt: timestamp.toISOString(),
        updatedAt: null
      });
    });

    await batch.commit();

    res.status(201).json(success(createdItems, 'Action items created successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Batch update action items
 * @route PUT /api/projects/:projectId/actions/batch
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

    // Create batch
    const batch = db.batch();
    const actionsRef = projectRef.collection('action_items');
    const updatedItems = [];
    const timestamp = new Date();

    for (const item of items) {
      if (!item.id) {
        return next(error('Each item must have an id', 400));
      }

      const itemRef = actionsRef.doc(item.id);
      const doc = await itemRef.get();

      if (!doc.exists) {
        return next(error(`Action item with id ${item.id} not found`, 404));
      }

      // Validate status if provided
      if (item.status) {
        const validStatuses = ['incomplete', 'inProgress', 'complete'];
        if (!validStatuses.includes(item.status)) {
          return next(error(`Invalid status for item ${item.id}. Must be one of: ${validStatuses.join(', ')}`, 400));
        }
      }

      const updates = {};
      if (item.task !== undefined) updates.task = item.task;
      if (item.responsible !== undefined) updates.responsible = item.responsible;
      if (item.completionDate !== undefined) {
        updates.completionDate = item.completionDate ? new Date(item.completionDate) : null;
      }
      if (item.update !== undefined) updates.update = item.update;
      if (item.status !== undefined) updates.status = item.status;
      updates.updatedAt = timestamp;

      batch.update(itemRef, updates);
      
      // Format dates for response
      updatedItems.push({
        id: item.id,
        ...updates,
        completionDate: updates.completionDate ? updates.completionDate.toISOString() : null,
        updatedAt: timestamp.toISOString()
      });
    }

    await batch.commit();

    res.status(200).json(success(updatedItems, 'Action items updated successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Batch delete action items
 * @route DELETE /api/projects/:projectId/actions/batch
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
    const actionsRef = projectRef.collection('action_items');

    for (const id of ids) {
      const itemRef = actionsRef.doc(id);
      const doc = await itemRef.get();

      if (!doc.exists) {
        return next(error(`Action item with id ${id} not found`, 404));
      }

      batch.delete(itemRef);
    }

    await batch.commit();

    res.status(200).json(success({}, 'Action items deleted successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Get action item statistics
 * @route GET /api/projects/:projectId/actions/stats
 */
exports.getActionStats = async (req, res, next) => {
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
    const snapshot = await actionsRef.get();

    // Initialize stats
    const stats = {
      total: snapshot.size,
      byStatus: {
        incomplete: 0,
        inProgress: 0,
        complete: 0
      },
      overdue: 0,
      dueToday: 0,
      dueSoon: 0, // Due in next 7 days
      byAssignee: {},
      mostRecent: null
    };

    // Calculate statistics
    let mostRecentDate = null;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const nextWeek = new Date(today);
    nextWeek.setDate(nextWeek.getDate() + 7);
    
    snapshot.forEach(doc => {
      const data = doc.data();
      const status = data.status || 'incomplete';
      const responsible = data.responsible || 'Unassigned';
      
      // Count by status
      stats.byStatus[status]++;
      
      // Count by assignee
      if (!stats.byAssignee[responsible]) {
        stats.byAssignee[responsible] = {
          total: 0,
          incomplete: 0,
          inProgress: 0,
          complete: 0
        };
      }
      stats.byAssignee[responsible].total++;
      stats.byAssignee[responsible][status]++;
      
      // Count due dates
      if (data.completionDate && status !== 'complete') {
        const dueDate = data.completionDate.toDate();
        dueDate.setHours(0, 0, 0, 0);
        
        if (dueDate < today) {
          stats.overdue++;
        } else if (dueDate.getTime() === today.getTime()) {
          stats.dueToday++;
        } else if (dueDate < nextWeek) {
          stats.dueSoon++;
        }
      }
      
      // Track most recent
      if (data.createdAt && (!mostRecentDate || data.createdAt.toDate() > mostRecentDate)) {
        mostRecentDate = data.createdAt.toDate();
        stats.mostRecent = {
          id: doc.id,
          task: data.task,
          responsible: data.responsible,
          status: data.status,
          createdAt: mostRecentDate
        };
      }
    });

    // Calculate completion rate
    if (stats.total > 0) {
      stats.completionRate = Math.round((stats.byStatus.complete / stats.total) * 100);
    } else {
      stats.completionRate = 0;
    }

    res.status(200).json(success(stats));
  } catch (err) {
    next(error(err.message, 500));
  }
};