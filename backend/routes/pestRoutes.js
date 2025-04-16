const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { pestRules } = require('./validationRules');
const pestController = require('../controllers/pestController');

// All routes require authentication
router.use(authenticate);

// Get all PEST factors for a project
router.get('/:projectId/pest', pestController.getPestFactors);

// Create a new PEST factor
router.post('/:projectId/pest', validate(pestRules.create), pestController.createPestFactor);

// Get a specific PEST factor
router.get('/:projectId/pest/:factorId', pestController.getPestFactor);

// Update a PEST factor
router.put('/:projectId/pest/:factorId', validate(pestRules.update), pestController.updatePestFactor);

// Delete a PEST factor
router.delete('/:projectId/pest/:factorId', pestController.deletePestFactor);

// Update impact rating for a PEST factor
router.put('/:projectId/pest/:factorId/impact', validate(pestRules.updateImpact), pestController.updateImpact);

// Update timeframe for a PEST factor
router.put('/:projectId/pest/:factorId/timeframe', validate(pestRules.updateTimeframe), pestController.updateTimeframe);

// Batch operations
router.post('/:projectId/pest/batch', pestController.batchCreateFactors);
router.put('/:projectId/pest/batch', pestController.batchUpdateFactors);
router.delete('/:projectId/pest/batch', pestController.batchDeleteFactors);

// Get PEST statistics
router.get('/:projectId/pest/stats', pestController.getPestStats);

module.exports = router;