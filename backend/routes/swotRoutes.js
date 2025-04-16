const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { swotRules } = require('./validationRules');
const swotController = require('../controllers/swotController');

// All routes require authentication
router.use(authenticate);

// Get all SWOT items for a project
router.get('/:projectId/swot', swotController.getSwotItems);

// Create a new SWOT item
router.post('/:projectId/swot', validate(swotRules.create), swotController.createSwotItem);

// Get a specific SWOT item
router.get('/:projectId/swot/:itemId', swotController.getSwotItem);

// Update a SWOT item
router.put('/:projectId/swot/:itemId', validate(swotRules.update), swotController.updateSwotItem);

// Delete a SWOT item
router.delete('/:projectId/swot/:itemId', swotController.deleteSwotItem);

// Move a SWOT item to a different type
router.put('/:projectId/swot/:itemId/move', validate(swotRules.move), swotController.moveSwotItem);

// Batch operations
router.post('/:projectId/swot/batch', swotController.batchCreateItems);
router.put('/:projectId/swot/batch', swotController.batchUpdateItems);
router.delete('/:projectId/swot/batch', swotController.batchDeleteItems);

// Get SWOT statistics
router.get('/:projectId/swot/stats', swotController.getSwotStats);

module.exports = router;