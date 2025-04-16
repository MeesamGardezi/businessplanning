const { db } = require('../config/firebase');
const { success, error } = require('../utils/responseFormatter');

/**
 * Get all projects for the current user
 * @route GET /api/projects
 */
exports.getProjects = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { search, page = 1, limit = 20 } = req.query;

    const pageSize = parseInt(limit);
    const pageNumber = parseInt(page);
    const offset = (pageNumber - 1) * pageSize;

    let projectsRef = db.collection('users').doc(uid).collection('projects');
    
    // Apply sorting
    projectsRef = projectsRef.orderBy('createdAt', 'desc');

    // Get total count for pagination
    const countSnapshot = await projectsRef.get();
    const totalItems = countSnapshot.size;
    const totalPages = Math.ceil(totalItems / pageSize);

    // Get paginated results
    const snapshot = await projectsRef.limit(pageSize).offset(offset).get();

    // Process the results
    const projects = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      projects.push({
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate() : null,
        updatedAt: data.updatedAt ? data.updatedAt.toDate() : null
      });
    });

    // If search is provided, filter in memory (Firestore doesn't support text search)
    let filteredProjects = projects;
    if (search) {
      const searchLower = search.toLowerCase();
      filteredProjects = projects.filter(project => 
        project.title.toLowerCase().includes(searchLower) ||
        project.description.toLowerCase().includes(searchLower)
      );
    }

    res.status(200).json(success({
      projects: filteredProjects,
      pagination: {
        total: search ? filteredProjects.length : totalItems,
        page: pageNumber,
        limit: pageSize,
        totalPages: search ? Math.ceil(filteredProjects.length / pageSize) : totalPages
      }
    }));
  } catch (err) {
    next(error(err.message, 500));
  }
};

/**
 * Create a new project
 * @route POST /api/projects
 */
exports.createProject = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { title, description } = req.body;

    const newProject = {
      title,
      description,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    const docRef = await db.collection('users').doc(uid).collection('projects').add(newProject);

    res.status(201).json(success({
      id: docRef.id,
      ...newProject,
      createdAt: newProject.createdAt.toISOString(),
      updatedAt: newProject.updatedAt.toISOString()
    }, 'Project created successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Get a specific project
 * @route GET /api/projects/:id
 */
exports.getProject = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { id } = req.params;

    const docRef = db.collection('users').doc(uid).collection('projects').doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return next(error('Project not found', 404));
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
 * Update a project
 * @route PUT /api/projects/:id
 */
exports.updateProject = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { id } = req.params;
    const { title, description } = req.body;

    const docRef = db.collection('users').doc(uid).collection('projects').doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return next(error('Project not found', 404));
    }

    const updates = {
      updatedAt: new Date()
    };

    if (title !== undefined) updates.title = title;
    if (description !== undefined) updates.description = description;

    await docRef.update(updates);

    // Get the updated document
    const updatedDoc = await docRef.get();
    const updatedData = updatedDoc.data();

    res.status(200).json(success({
      id: doc.id,
      ...updatedData,
      createdAt: updatedData.createdAt ? updatedData.createdAt.toDate() : null,
      updatedAt: updatedData.updatedAt ? updatedData.updatedAt.toDate() : null
    }, 'Project updated successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Delete a project
 * @route DELETE /api/projects/:id
 */
exports.deleteProject = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { id } = req.params;

    const docRef = db.collection('users').doc(uid).collection('projects').doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return next(error('Project not found', 404));
    }

    // Get all subcollections
    const collections = ['swot_items', 'pest_factors', 'action_items'];
    const batch = db.batch();
    
    // Delete all items in subcollections
    for (const collection of collections) {
      const itemsSnapshot = await docRef.collection(collection).get();
      itemsSnapshot.forEach(doc => {
        batch.delete(doc.ref);
      });
    }
    
    // Delete the project document itself
    batch.delete(docRef);
    
    // Commit all deletions as a batch
    await batch.commit();

    res.status(200).json(success({}, 'Project deleted successfully'));
  } catch (err) {
    next(error(err.message, 500));
  }
};

/**
 * Export a project with all its data
 * @route GET /api/projects/:id/export
 */
exports.exportProject = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { id } = req.params;

    const projectRef = db.collection('users').doc(uid).collection('projects').doc(id);
    const projectDoc = await projectRef.get();

    if (!projectDoc.exists) {
      return next(error('Project not found', 404));
    }

    // Get project data
    const projectData = projectDoc.data();
    const project = {
      id: projectDoc.id,
      ...projectData,
      createdAt: projectData.createdAt ? projectData.createdAt.toDate() : null,
      updatedAt: projectData.updatedAt ? projectData.updatedAt.toDate() : null
    };

    // Get all SWOT items
    const swotSnapshot = await projectRef.collection('swot_items').get();
    const swotItems = [];
    swotSnapshot.forEach(doc => {
      const data = doc.data();
      swotItems.push({
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate() : null,
        updatedAt: data.updatedAt ? data.updatedAt.toDate() : null
      });
    });

    // Get all PEST factors
    const pestSnapshot = await projectRef.collection('pest_factors').get();
    const pestFactors = [];
    pestSnapshot.forEach(doc => {
      const data = doc.data();
      pestFactors.push({
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate() : null,
        updatedAt: data.updatedAt ? data.updatedAt.toDate() : null
      });
    });

    // Get all action items
    const actionSnapshot = await projectRef.collection('action_items').get();
    const actionItems = [];
    actionSnapshot.forEach(doc => {
      const data = doc.data();
      actionItems.push({
        id: doc.id,
        ...data,
        completionDate: data.completionDate ? data.completionDate.toDate() : null,
        createdAt: data.createdAt ? data.createdAt.toDate() : null,
        updatedAt: data.updatedAt ? data.updatedAt.toDate() : null
      });
    });

    // Combine all data
    const exportData = {
      project,
      swotItems,
      pestFactors,
      actionItems,
      exportedAt: new Date(),
      version: '1.0'
    };

    res.status(200).json(success(exportData, 'Project exported successfully'));
  } catch (err) {
    next(error(err.message, 500));
  }
};

/**
 * Import a project with all its data
 * @route POST /api/projects/import
 */
exports.importProject = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { project: projectData, preserveIds = false } = req.body;
    
    if (!projectData || !projectData.title || !projectData.description) {
      return next(error('Invalid project data', 400));
    }

    // Create new project
    const newProject = {
      title: projectData.title,
      description: projectData.description,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    const projectRef = await db.collection('users').doc(uid).collection('projects').add(newProject);
    const projectId = projectRef.id;

    // Import SWOT items if available
    if (Array.isArray(projectData.swotItems) && projectData.swotItems.length > 0) {
      const swotRef = projectRef.collection('swot_items');
      const swotBatch = db.batch();
      
      projectData.swotItems.forEach(item => {
        const docId = preserveIds && item.id ? item.id : swotRef.doc().id;
        const docRef = swotRef.doc(docId);
        
        swotBatch.set(docRef, {
          text: item.text,
          type: item.type,
          createdAt: new Date(),
          updatedAt: null
        });
      });
      
      await swotBatch.commit();
    }

    // Import PEST factors if available
    if (Array.isArray(projectData.pestFactors) && projectData.pestFactors.length > 0) {
      const pestRef = projectRef.collection('pest_factors');
      const pestBatch = db.batch();
      
      projectData.pestFactors.forEach(factor => {
        const docId = preserveIds && factor.id ? factor.id : pestRef.doc().id;
        const docRef = pestRef.doc(docId);
        
        pestBatch.set(docRef, {
          text: factor.text,
          type: factor.type,
          impact: factor.impact || 3,
          timeframe: factor.timeframe || 'medium-term',
          createdAt: new Date(),
          updatedAt: null
        });
      });
      
      await pestBatch.commit();
    }

    // Import action items if available
    if (Array.isArray(projectData.actionItems) && projectData.actionItems.length > 0) {
      const actionRef = projectRef.collection('action_items');
      const actionBatch = db.batch();
      
      // First, determine next available ID
      let nextId = 1;
      
      projectData.actionItems.forEach(item => {
        const id = item.id || nextId.toString();
        nextId++;
        
        const docRef = actionRef.doc(id);
        
        actionBatch.set(docRef, {
          id: id,
          task: item.task || '',
          responsible: item.responsible || '',
          completionDate: item.completionDate ? new Date(item.completionDate) : null,
          update: item.update || '',
          status: item.status || 'incomplete',
          createdAt: new Date(),
          updatedAt: null
        });
      });
      
      await actionBatch.commit();
    }

    res.status(201).json(success({
      id: projectId,
      title: projectData.title,
      description: projectData.description,
      createdAt: newProject.createdAt.toISOString(),
      updatedAt: newProject.updatedAt.toISOString()
    }, 'Project imported successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Get project statistics and summary
 * @route GET /api/projects/:id/stats
 */
exports.getProjectStats = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { id } = req.params;

    const projectRef = db.collection('users').doc(uid).collection('projects').doc(id);
    const projectDoc = await projectRef.get();

    if (!projectDoc.exists) {
      return next(error('Project not found', 404));
    }

    // Get project data
    const projectData = projectDoc.data();
    const project = {
      id: projectDoc.id,
      title: projectData.title,
      description: projectData.description,
      createdAt: projectData.createdAt ? projectData.createdAt.toDate() : null,
      updatedAt: projectData.updatedAt ? projectData.updatedAt.toDate() : null
    };

    // Get SWOT stats
    const swotSnapshot = await projectRef.collection('swot_items').get();
    const swotStats = {
      total: swotSnapshot.size,
      byType: {
        strength: 0,
        weakness: 0,
        opportunity: 0,
        threat: 0
      }
    };
    
    swotSnapshot.forEach(doc => {
      const type = doc.data().type;
      if (swotStats.byType[type] !== undefined) {
        swotStats.byType[type]++;
      }
    });

    // Get PEST stats
    const pestSnapshot = await projectRef.collection('pest_factors').get();
    const pestStats = {
      total: pestSnapshot.size,
      byType: {
        political: 0,
        economic: 0,
        social: 0,
        technological: 0
      },
      averageImpact: 0
    };
    
    let totalImpact = 0;
    
    pestSnapshot.forEach(doc => {
      const data = doc.data();
      const type = data.type;
      if (pestStats.byType[type] !== undefined) {
        pestStats.byType[type]++;
      }
      
      totalImpact += data.impact || 0;
    });
    
    if (pestStats.total > 0) {
      pestStats.averageImpact = parseFloat((totalImpact / pestStats.total).toFixed(1));
    }

    // Get action item stats
    const actionSnapshot = await projectRef.collection('action_items').get();
    const actionStats = {
      total: actionSnapshot.size,
      byStatus: {
        incomplete: 0,
        inProgress: 0,
        complete: 0
      }
    };
    
    actionSnapshot.forEach(doc => {
      const status = doc.data().status || 'incomplete';
      if (actionStats.byStatus[status] !== undefined) {
        actionStats.byStatus[status]++;
      }
    });
    
    // Calculate completion percentage
    if (actionStats.total > 0) {
      actionStats.completionRate = Math.round((actionStats.byStatus.complete / actionStats.total) * 100);
    } else {
      actionStats.completionRate = 0;
    }

    // Combine all stats
    const stats = {
      project,
      lastUpdated: project.updatedAt,
      swot: swotStats,
      pest: pestStats,
      actions: actionStats,
      totalItems: swotStats.total + pestStats.total + actionStats.total
    };

    res.status(200).json(success(stats));
  } catch (err) {
    next(error(err.message, 500));
  }
};