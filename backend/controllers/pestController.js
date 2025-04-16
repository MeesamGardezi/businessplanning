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

    // Verify project exists and belongs to user
    const projectRef = db.collection('users').doc(uid).collection('projects').doc(projectId);
    const project = await projectRef.get();
    
    if (!project.exists) {
      return next(error('Project not found', 404));
    }

    const pestRef = projectRef.collection('pest_factors');
    const snapshot = await pestRef.orderBy('createdAt', 'desc').get();

    const factors = [];
    snapshot.forEach(doc => {
      factors.push({
        id: doc.id,
        ...doc.data()
      });
    });

    res.status(200).json(success(factors));
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

    res.status(200).json(success({
      id: doc.id,
      ...doc.data()
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