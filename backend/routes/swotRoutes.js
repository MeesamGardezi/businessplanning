const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { swotRules } = require('./validationRules');
const swotController = require('../controllers/swotController');

// All routes require authentication
router.use(authenticate);

router.get('/:projectId/swot', swotController.getSwotItems);
router.post('/:projectId/swot', validate(swotRules.create), swotController.createSwotItem);
router.get('/:projectId/swot/:itemId', swotController.getSwotItem);
router.put('/:projectId/swot/:itemId', validate(swotRules.update), swotController.updateSwotItem);
router.delete('/:projectId/swot/:itemId', swotController.deleteSwotItem);
router.put('/:projectId/swot/:itemId/move', validate(swotRules.move), swotController.moveSwotItem);

module.exports = router;