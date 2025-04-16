const { db } = require('../config/firebase');
const { success, error } = require('../utils/responseFormatter');

/**
 * Get all PEST factors for a project
 * @route GET /api/projects/:projectId/pest
 */
exports.getPestFactors = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId } = req.params;
    const { type, timeframe, search, page = 1, limit = 50 } = req.query;

    // Verify project exists and belongs to user
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    let query = projectRef.collection('pest_factors');
    
    // Apply type filter if provided
    if (type && ['political', 'economic', 'social', 'technological'].includes(type)) {
      query = query.where('type', '==', type);
    }

    // Apply timeframe filter if provided
    if (timeframe && ['short-term', 'medium-term', 'long-term'].includes(timeframe)) {
      query = query.where('timeframe', '==', timeframe);
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
    const factors = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      factors.push({
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate() : null,
        updatedAt: data.updatedAt ? data.updatedAt.toDate() : null
      });
    });

    // If search is provided, filter in memory (Firestore doesn't support text search)
    let filteredFactors = factors;
    if (search) {
      const searchLower = search.toLowerCase();
      filteredFactors = factors.filter(factor => 
        factor.text.toLowerCase().includes(searchLower)
      );
    }

    res.status(200).json(success({
      factors: filteredFactors,
      pagination: {
        total: search ? filteredFactors.length : totalItems,
        page: pageNumber,
        limit: pageSize,
        totalPages: search ? Math.ceil(filteredFactors.length / pageSize) : totalPages
      }
    }));
  } catch (err) {
    next(error(err.message, 500));
  }
};

/**
 * Create a new PEST factor
 * @route POST /api/projects/:projectId/pest
 */
exports.createPestFactor = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId } = req.params;
    const { text, type, impact, timeframe } = req.body;

    // Validate type
    const validTypes = ['political', 'economic', 'social', 'technological'];
    if (!validTypes.includes(type)) {
      return next(error(`Invalid PEST type. Must be one of: ${validTypes.join(', ')}`, 400));
    }

    // Validate impact
    if (impact < 1 || impact > 5) {
      return next(error('Impact must be between 1 and 5', 400));
    }

    // Validate timeframe if provided
    if (timeframe) {
      const validTimeframes = ['short-term', 'medium-term', 'long-term'];
      if (!validTimeframes.includes(timeframe)) {
        return next(error(`Invalid timeframe. Must be one of: ${validTimeframes.join(', ')}`, 400));
      }
    }

    // Verify project exists
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    const newFactor = {
      text,
      type,
      impact,
      timeframe: timeframe || 'medium-term',
      createdAt: new Date(),
      updatedAt: null
    };

    const docRef = await projectRef.collection('pest_factors').add(newFactor);

    res.status(201).json(success({
      id: docRef.id,
      ...newFactor
    }, 'PEST factor created successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Get a specific PEST factor
 * @route GET /api/projects/:projectId/pest/:factorId
 */
exports.getPestFactor = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId, factorId } = req.params;

    const factorRef = db.collection('users').doc(uid)
      .collection('projects').doc(projectId)
      .collection('pest_factors').doc(factorId);
    
    const doc = await factorRef.get();

    if (!doc.exists) {
      return next(error('PEST factor not found', 404));
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
 * Update a PEST factor
 * @route PUT /api/projects/:projectId/pest/:factorId
 */
exports.updatePestFactor = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId, factorId } = req.params;
    const { text, type, impact, timeframe } = req.body;

    // Validate type if provided
    if (type) {
      const validTypes = ['political', 'economic', 'social', 'technological'];
      if (!validTypes.includes(type)) {
        return next(error(`Invalid PEST type. Must be one of: ${validTypes.join(', ')}`, 400));
      }
    }

    // Validate impact if provided
    if (impact !== undefined) {
      if (impact < 1 || impact > 5) {
        return next(error('Impact must be between 1 and 5', 400));
      }
    }

    // Validate timeframe if provided
    if (timeframe) {
      const validTimeframes = ['short-term', 'medium-term', 'long-term'];
      if (!validTimeframes.includes(timeframe)) {
        return next(error(`Invalid timeframe. Must be one of: ${validTimeframes.join(', ')}`, 400));
      }
    }

    const factorRef = db.collection('users').doc(uid)
      .collection('projects').doc(projectId)
      .collection('pest_factors').doc(factorId);
    
    const doc = await factorRef.get();

    if (!doc.exists) {
      return next(error('PEST factor not found', 404));
    }

    const updates = {};
    if (text !== undefined) updates.text = text;
    if (type !== undefined) updates.type = type;
    if (impact !== undefined) updates.impact = impact;
    if (timeframe !== undefined) updates.timeframe = timeframe;
    updates.updatedAt = new Date();

    await factorRef.update(updates);

    res.status(200).json(success({}, 'PEST factor updated successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Delete a PEST factor
 * @route DELETE /api/projects/:projectId/pest/:factorId
 */
exports.deletePestFactor = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId, factorId } = req.params;

    const factorRef = db.collection('users').doc(uid)
      .collection('projects').doc(projectId)
      .collection('pest_factors').doc(factorId);
    
    const doc = await factorRef.get();

    if (!doc.exists) {
      return next(error('PEST factor not found', 404));
    }

    await factorRef.delete();

    res.status(200).json(success({}, 'PEST factor deleted successfully'));
  } catch (err) {
    next(error(err.message, 500));
  }
};

/**
 * Update impact rating for a PEST factor
 * @route PUT /api/projects/:projectId/pest/:factorId/impact
 */
exports.updateImpact = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId, factorId } = req.params;
    const { impact } = req.body;

    if (impact === undefined || impact < 1 || impact > 5) {
      return next(error('Impact must be between 1 and 5', 400));
    }

    const factorRef = db.collection('users').doc(uid)
      .collection('projects').doc(projectId)
      .collection('pest_factors').doc(factorId);
    
    const doc = await factorRef.get();

    if (!doc.exists) {
      return next(error('PEST factor not found', 404));
    }

    await factorRef.update({
      impact,
      updatedAt: new Date()
    });

    res.status(200).json(success({}, 'Impact updated successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Update timeframe for a PEST factor
 * @route PUT /api/projects/:projectId/pest/:factorId/timeframe
 */
exports.updateTimeframe = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId, factorId } = req.params;
    const { timeframe } = req.body;

    const validTimeframes = ['short-term', 'medium-term', 'long-term'];
    if (!validTimeframes.includes(timeframe)) {
      return next(error(`Invalid timeframe. Must be one of: ${validTimeframes.join(', ')}`, 400));
    }

    const factorRef = db.collection('users').doc(uid)
      .collection('projects').doc(projectId)
      .collection('pest_factors').doc(factorId);
    
    const doc = await factorRef.get();

    if (!doc.exists) {
      return next(error('PEST factor not found', 404));
    }

    await factorRef.update({
      timeframe,
      updatedAt: new Date()
    });

    res.status(200).json(success({}, 'Timeframe updated successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Batch create multiple PEST factors
 * @route POST /api/projects/:projectId/pest/batch
 */
exports.batchCreateFactors = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId } = req.params;
    const { factors } = req.body;

    if (!Array.isArray(factors) || factors.length === 0) {
      return next(error('Factors array is required and must not be empty', 400));
    }

    // Verify project exists
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    // Validate all factors
    const validTypes = ['political', 'economic', 'social', 'technological'];
    const validTimeframes = ['short-term', 'medium-term', 'long-term'];
    
    for (const factor of factors) {
      if (!validTypes.includes(factor.type)) {
        return next(error(`Invalid PEST type. Must be one of: ${validTypes.join(', ')}`, 400));
      }
      
      if (factor.impact === undefined || factor.impact < 1 || factor.impact > 5) {
        return next(error('Impact must be between 1 and 5', 400));
      }
      
      if (factor.timeframe && !validTimeframes.includes(factor.timeframe)) {
        return next(error(`Invalid timeframe. Must be one of: ${validTimeframes.join(', ')}`, 400));
      }
    }

    // Create batch
    const batch = db.batch();
    const pestRef = projectRef.collection('pest_factors');
    const createdFactors = [];
    const timestamp = new Date();

    for (const factor of factors) {
      const newDocRef = pestRef.doc();
      
      const newFactor = {
        text: factor.text,
        type: factor.type,
        impact: factor.impact,
        timeframe: factor.timeframe || 'medium-term',
        createdAt: timestamp,
        updatedAt: null
      };

      batch.set(newDocRef, newFactor);
      createdFactors.push({ id: newDocRef.id, ...newFactor });
    }

    await batch.commit();

    res.status(201).json(success(createdFactors, 'PEST factors created successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Batch update PEST factors
 * @route PUT /api/projects/:projectId/pest/batch
 */
exports.batchUpdateFactors = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId } = req.params;
    const { factors } = req.body;

    if (!Array.isArray(factors) || factors.length === 0) {
      return next(error('Factors array is required and must not be empty', 400));
    }

    // Verify project exists
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    // Validate factors
    const validTypes = ['political', 'economic', 'social', 'technological'];
    const validTimeframes = ['short-term', 'medium-term', 'long-term'];
    
    for (const factor of factors) {
      if (!factor.id) {
        return next(error('Each factor must have an id', 400));
      }
      
      if (factor.type && !validTypes.includes(factor.type)) {
        return next(error(`Invalid PEST type. Must be one of: ${validTypes.join(', ')}`, 400));
      }
      
      if (factor.impact !== undefined && (factor.impact < 1 || factor.impact > 5)) {
        return next(error('Impact must be between 1 and 5', 400));
      }
      
      if (factor.timeframe && !validTimeframes.includes(factor.timeframe)) {
        return next(error(`Invalid timeframe. Must be one of: ${validTimeframes.join(', ')}`, 400));
      }
    }

    // Create batch
    const batch = db.batch();
    const pestRef = projectRef.collection('pest_factors');
    const updatedFactors = [];
    const timestamp = new Date();

    for (const factor of factors) {
      const factorRef = pestRef.doc(factor.id);
      const doc = await factorRef.get();

      if (!doc.exists) {
        return next(error(`PEST factor with id ${factor.id} not found`, 404));
      }

      const updates = {};
      if (factor.text !== undefined) updates.text = factor.text;
      if (factor.type !== undefined) updates.type = factor.type;
      if (factor.impact !== undefined) updates.impact = factor.impact;
      if (factor.timeframe !== undefined) updates.timeframe = factor.timeframe;
      updates.updatedAt = timestamp;

      batch.update(factorRef, updates);
      updatedFactors.push({ id: factor.id, ...updates });
    }

    await batch.commit();

    res.status(200).json(success(updatedFactors, 'PEST factors updated successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Batch delete PEST factors
 * @route DELETE /api/projects/:projectId/pest/batch
 */
exports.batchDeleteFactors = async (req, res, next) => {
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
    const pestRef = projectRef.collection('pest_factors');

    for (const id of ids) {
      const factorRef = pestRef.doc(id);
      const doc = await factorRef.get();

      if (!doc.exists) {
        return next(error(`PEST factor with id ${id} not found`, 404));
      }

      batch.delete(factorRef);
    }

    await batch.commit();

    res.status(200).json(success({}, 'PEST factors deleted successfully'));
  } catch (err) {
    next(error(err.message, 400));
  }
};

/**
 * Get PEST statistics
 * @route GET /api/projects/:projectId/pest/stats
 */
exports.getPestStats = async (req, res, next) => {
  try {
    const { uid } = req.user;
    const { projectId } = req.params;

    // Verify project exists and belongs to user
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    const pestRef = projectRef.collection('pest_factors');
    const snapshot = await pestRef.get();

    // Initialize stats
    const stats = {
      total: snapshot.size,
      byType: {
        political: 0,
        economic: 0,
        social: 0,
        technological: 0
      },
      byTimeframe: {
        'short-term': 0,
        'medium-term': 0,
        'long-term': 0
      },
      averageImpact: {
        overall: 0,
        political: 0,
        economic: 0,
        social: 0,
        technological: 0
      },
      highestImpact: {
        score: 0,
        factors: []
      },
      mostRecent: null
    };

    // For calculating averages
    const impactSums = {
      overall: 0,
      political: 0,
      economic: 0,
      social: 0,
      technological: 0
    };
    
    const impactCounts = {
      political: 0,
      economic: 0,
      social: 0,
      technological: 0
    };

    // Calculate statistics
    let mostRecentDate = null;
    
    snapshot.forEach(doc => {
      const data = doc.data();
      const type = data.type;
      const impact = data.impact || 0;
      const timeframe = data.timeframe || 'medium-term';
      
      // Count by type
      stats.byType[type]++;
      
      // Count by timeframe
      stats.byTimeframe[timeframe]++;
      
      // Track impact values
      impactSums.overall += impact;
      impactSums[type] += impact;
      impactCounts[type]++;
      
      // Track highest impact factors
      if (impact > stats.highestImpact.score) {
        stats.highestImpact.score = impact;
        stats.highestImpact.factors = [{ 
          id: doc.id, 
          text: data.text,
          type: data.type,
          impact: data.impact
        }];
      } else if (impact === stats.highestImpact.score) {
        stats.highestImpact.factors.push({ 
          id: doc.id, 
          text: data.text,
          type: data.type,
          impact: data.impact
        });
      }
      
      // Track most recent
      if (data.createdAt && (!mostRecentDate || data.createdAt.toDate() > mostRecentDate)) {
        mostRecentDate = data.createdAt.toDate();
        stats.mostRecent = {
          id: doc.id,
          text: data.text,
          type: data.type,
          impact: data.impact,
          timeframe: data.timeframe,
          createdAt: mostRecentDate
        };
      }
    });

    // Calculate averages
    if (stats.total > 0) {
      stats.averageImpact.overall = parseFloat((impactSums.overall / stats.total).toFixed(1));
      
      Object.keys(impactCounts).forEach(type => {
        if (impactCounts[type] > 0) {
          stats.averageImpact[type] = parseFloat((impactSums[type] / impactCounts[type]).toFixed(1));
        }
      });
    }

    // Calculate percentages
    if (stats.total > 0) {
      stats.percentages = {
        byType: {
          political: Math.round((stats.byType.political / stats.total) * 100),
          economic: Math.round((stats.byType.economic / stats.total) * 100),
          social: Math.round((stats.byType.social / stats.total) * 100),
          technological: Math.round((stats.byType.technological / stats.total) * 100)
        },
        byTimeframe: {
          'short-term': Math.round((stats.byTimeframe['short-term'] / stats.total) * 100),
          'medium-term': Math.round((stats.byTimeframe['medium-term'] / stats.total) * 100),
          'long-term': Math.round((stats.byTimeframe['long-term'] / stats.total) * 100)
        }
      };
    }

    res.status(200).json(success(stats));
  } catch (err) {
    next(error(err.message, 500));
  }
};