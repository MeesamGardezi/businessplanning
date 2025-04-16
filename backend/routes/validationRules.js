const { body, param } = require('express-validator');

/**
 * Project validation rules
 */
exports.projectRules = {
  create: [
    body('title')
      .trim()
      .notEmpty().withMessage('Title is required')
      .isLength({ max: 100 }).withMessage('Title must not exceed 100 characters'),
    body('description')
      .trim()
      .notEmpty().withMessage('Description is required')
      .isLength({ max: 500 }).withMessage('Description must not exceed 500 characters')
  ],
  update: [
    param('id').notEmpty().withMessage('Project ID is required'),
    body('title')
      .optional()
      .trim()
      .notEmpty().withMessage('Title cannot be empty')
      .isLength({ max: 100 }).withMessage('Title must not exceed 100 characters'),
    body('description')
      .optional()
      .trim()
      .notEmpty().withMessage('Description cannot be empty')
      .isLength({ max: 500 }).withMessage('Description must not exceed 500 characters')
  ]
};

/**
 * SWOT item validation rules
 */
exports.swotRules = {
  create: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    body('text')
      .trim()
      .notEmpty().withMessage('Text is required')
      .isLength({ max: 200 }).withMessage('Text must not exceed 200 characters'),
    body('type')
      .notEmpty().withMessage('Type is required')
      .isIn(['strength', 'weakness', 'opportunity', 'threat'])
      .withMessage('Type must be one of: strength, weakness, opportunity, threat')
  ],
  update: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    param('itemId').notEmpty().withMessage('Item ID is required'),
    body('text')
      .optional()
      .trim()
      .notEmpty().withMessage('Text cannot be empty')
      .isLength({ max: 200 }).withMessage('Text must not exceed 200 characters'),
    body('type')
      .optional()
      .isIn(['strength', 'weakness', 'opportunity', 'threat'])
      .withMessage('Type must be one of: strength, weakness, opportunity, threat')
  ],
  move: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    param('itemId').notEmpty().withMessage('Item ID is required'),
    body('newType')
      .notEmpty().withMessage('New type is required')
      .isIn(['strength', 'weakness', 'opportunity', 'threat'])
      .withMessage('Type must be one of: strength, weakness, opportunity, threat')
  ]
};

/**
 * PEST factor validation rules
 */
exports.pestRules = {
  create: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    body('text')
      .trim()
      .notEmpty().withMessage('Text is required')
      .isLength({ max: 200 }).withMessage('Text must not exceed 200 characters'),
    body('type')
      .notEmpty().withMessage('Type is required')
      .isIn(['political', 'economic', 'social', 'technological'])
      .withMessage('Type must be one of: political, economic, social, technological'),
    body('impact')
      .notEmpty().withMessage('Impact is required')
      .isInt({ min: 1, max: 5 }).withMessage('Impact must be between 1 and 5'),
    body('timeframe')
      .optional()
      .isIn(['short-term', 'medium-term', 'long-term'])
      .withMessage('Timeframe must be one of: short-term, medium-term, long-term')
  ],
  update: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    param('factorId').notEmpty().withMessage('Factor ID is required'),
    body('text')
      .optional()
      .trim()
      .notEmpty().withMessage('Text cannot be empty')
      .isLength({ max: 200 }).withMessage('Text must not exceed 200 characters'),
    body('type')
      .optional()
      .isIn(['political', 'economic', 'social', 'technological'])
      .withMessage('Type must be one of: political, economic, social, technological'),
    body('impact')
      .optional()
      .isInt({ min: 1, max: 5 }).withMessage('Impact must be between 1 and 5'),
    body('timeframe')
      .optional()
      .isIn(['short-term', 'medium-term', 'long-term'])
      .withMessage('Timeframe must be one of: short-term, medium-term, long-term')
  ],
  updateImpact: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    param('factorId').notEmpty().withMessage('Factor ID is required'),
    body('impact')
      .notEmpty().withMessage('Impact is required')
      .isInt({ min: 1, max: 5 }).withMessage('Impact must be between 1 and 5')
  ],
  updateTimeframe: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    param('factorId').notEmpty().withMessage('Factor ID is required'),
    body('timeframe')
      .notEmpty().withMessage('Timeframe is required')
      .isIn(['short-term', 'medium-term', 'long-term'])
      .withMessage('Timeframe must be one of: short-term, medium-term, long-term')
  ]
};

/**
 * Action item validation rules
 */
exports.actionRules = {
  create: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    body('task')
      .optional()
      .trim()
      .isLength({ max: 200 }).withMessage('Task must not exceed 200 characters'),
    body('responsible')
      .optional()
      .trim()
      .isLength({ max: 100 }).withMessage('Responsible must not exceed 100 characters'),
    body('completionDate')
      .optional()
      .isISO8601().withMessage('Completion date must be a valid date'),
    body('update')
      .optional()
      .trim()
      .isLength({ max: 300 }).withMessage('Update must not exceed 300 characters'),
    body('status')
      .optional()
      .isIn(['incomplete', 'inProgress', 'complete'])
      .withMessage('Status must be one of: incomplete, inProgress, complete')
  ],
  update: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    param('itemId').notEmpty().withMessage('Item ID is required'),
    body('task')
      .optional()
      .trim()
      .isLength({ max: 200 }).withMessage('Task must not exceed 200 characters'),
    body('responsible')
      .optional()
      .trim()
      .isLength({ max: 100 }).withMessage('Responsible must not exceed 100 characters'),
    body('completionDate')
      .optional()
      .isISO8601().withMessage('Completion date must be a valid date'),
    body('update')
      .optional()
      .trim()
      .isLength({ max: 300 }).withMessage('Update must not exceed 300 characters'),
    body('status')
      .optional()
      .isIn(['incomplete', 'inProgress', 'complete'])
      .withMessage('Status must be one of: incomplete, inProgress, complete')
  ],
  updateStatus: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    param('itemId').notEmpty().withMessage('Item ID is required'),
    body('status')
      .notEmpty().withMessage('Status is required')
      .isIn(['incomplete', 'inProgress', 'complete'])
      .withMessage('Status must be one of: incomplete, inProgress, complete')
  ]
};