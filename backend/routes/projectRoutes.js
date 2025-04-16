const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { projectRules, paginationRules, searchRules } = require('./validationRules');
const projectController = require('../controllers/projectController');

// All routes require authentication
router.use(authenticate);

// Get all projects (with pagination and search)
router.get('/', 
  validate([...paginationRules, ...searchRules]), 
  projectController.getProjects
);

// Create a new project
router.post('/', 
  validate(projectRules.create), 
  projectController.createProject
);

// Get a specific project
router.get('/:id', 
  projectController.getProject
);

// Update a project
router.put('/:id', 
  validate(projectRules.update), 
  projectController.updateProject
);

// Delete a project
router.delete('/:id', 
  projectController.deleteProject
);

// Export a project with all its data
router.get('/:id/export', 
  validate(projectRules.export), 
  projectController.exportProject
);

// Import a project
router.post('/import', 
  validate(projectRules.import), 
  projectController.importProject
);

// Get project statistics
router.get('/:id/stats', 
  projectController.getProjectStats
);

module.exports = router;