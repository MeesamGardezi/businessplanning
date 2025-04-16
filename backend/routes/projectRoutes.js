const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { projectRules } = require('./validationRules');
const projectController = require('../controllers/projectController');

// All routes require authentication
router.use(authenticate);

router.get('/', projectController.getProjects);
router.post('/', validate(projectRules.create), projectController.createProject);
router.get('/:id', projectController.getProject);
router.put('/:id', validate(projectRules.update), projectController.updateProject);
router.delete('/:id', projectController.deleteProject);

module.exports = router;