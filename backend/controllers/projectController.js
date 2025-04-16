const { db } = require('../config/firebase');
const { success, error } = require('../utils/responseFormatter');

/**
 * Get all projects for the current user
 * @route GET /api/projects
 */
exports.getProjects = async (req, res, next) => {
  try {
    const { uid } = req.user;

    const projectsRef = db.collection('users').doc(uid).collection('projects');
    const snapshot = await projectsRef.orderBy('createdAt', 'desc').get();

    const projects = [];
    snapshot.forEach(doc => {
      projects.push({
        id: doc.id,
        ...doc.data()
      });
    });

    res.status(200).json(success(projects));
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
      ...newProject
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

    res.status(200).json(success({
      id: doc.id,
      ...doc.data()
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

    await docRef.update({
      title,
      description,
      updatedAt: new Date()
    });

    res.status(200).json(success({}, 'Project updated successfully'));
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

    await docRef.delete();

    res.status(200).json(success({}, 'Project deleted successfully'));
  } catch (err) {
    next(error(err.message, 500));
  }
};