const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { actionRules } = require('./validationRules');
const actionController = require('../controllers/actionController');

// All routes require authentication
router.use(authenticate);

// Get all action items for a project
router.get('/:projectId/actions', actionController.getActionItems);

// Create a new action item
router.post('/:projectId/actions', validate(actionRules.create), actionController.createActionItem);

// Get a specific action item
router.get('/:projectId/actions/:itemId', actionController.getActionItem);

// Update an action item
router.put('/:projectId/actions/:itemId', validate(actionRules.update), actionController.updateActionItem);

// Delete an action item
router.delete('/:projectId/actions/:itemId', actionController.deleteActionItem);

// Update action item status
router.put('/:projectId/actions/:itemId/status', validate(actionRules.updateStatus), actionController.updateStatus);

// Get action item statistics 
router.get('/:projectId/actions/stats', actionController.getActionStats);

// Batch operations
router.post('/:projectId/actions/batch', validate(actionRules.batchCreate), actionController.batchCreateItems);
router.put('/:projectId/actions/batch', validate(actionRules.batchUpdate), actionController.batchUpdateItems);
router.delete('/:projectId/actions/batch', validate(actionRules.batchDelete), actionController.batchDeleteItems);

module.exports = router;