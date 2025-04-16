const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { actionRules } = require('./validationRules');
const actionController = require('../controllers/actionController');

// All routes require authentication
router.use(authenticate);

router.get('/:projectId/actions', actionController.getActionItems);
router.post('/:projectId/actions', validate(actionRules.create), actionController.createActionItem);
router.post('/:projectId/actions/batch', actionController.batchCreateItems);
router.get('/:projectId/actions/:itemId', actionController.getActionItem);
router.put('/:projectId/actions/:itemId', validate(actionRules.update), actionController.updateActionItem);
router.delete('/:projectId/actions/:itemId', actionController.deleteActionItem);
router.put('/:projectId/actions/:itemId/status', validate(actionRules.updateStatus), actionController.updateStatus);

module.exports = router;