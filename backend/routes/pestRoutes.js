const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { pestRules } = require('./validationRules');
const pestController = require('../controllers/pestController');

// All routes require authentication
router.use(authenticate);

router.get('/:projectId/pest', pestController.getPestFactors);
router.post('/:projectId/pest', validate(pestRules.create), pestController.createPestFactor);
router.get('/:projectId/pest/:factorId', pestController.getPestFactor);
router.put('/:projectId/pest/:factorId', validate(pestRules.update), pestController.updatePestFactor);
router.delete('/:projectId/pest/:factorId', pestController.deletePestFactor);
router.put('/:projectId/pest/:factorId/impact', validate(pestRules.updateImpact), pestController.updateImpact);
router.put('/:projectId/pest/:factorId/timeframe', validate(pestRules.updateTimeframe), pestController.updateTimeframe);

module.exports = router;