const { body, param, query } = require('express-validator');

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
  ],
  export: [
    param('id').notEmpty().withMessage('Project ID is required')
  ],
  import: [
    body('project')
      .notEmpty().withMessage('Project data is required')
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
  ],
  batchCreate: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    body('items')
      .isArray().withMessage('Items must be an array')
      .notEmpty().withMessage('Items array cannot be empty'),
    body('items.*.text')
      .trim()
      .notEmpty().withMessage('Text is required')
      .isLength({ max: 200 }).withMessage('Text must not exceed 200 characters'),
    body('items.*.type')
      .notEmpty().withMessage('Type is required')
      .isIn(['strength', 'weakness', 'opportunity', 'threat'])
      .withMessage('Type must be one of: strength, weakness, opportunity, threat')
  ],
  batchUpdate: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    body('items')
      .isArray().withMessage('Items must be an array')
      .notEmpty().withMessage('Items array cannot be empty'),
    body('items.*.id')
      .notEmpty().withMessage('Item ID is required'),
    body('items.*.type')
      .optional()
      .isIn(['strength', 'weakness', 'opportunity', 'threat'])
      .withMessage('Type must be one of: strength, weakness, opportunity, threat')
  ],
  batchDelete: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    body('ids')
      .isArray().withMessage('IDs must be an array')
      .notEmpty().withMessage('IDs array cannot be empty')
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
  ],
  batchCreate: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    body('factors')
      .isArray().withMessage('Factors must be an array')
      .notEmpty().withMessage('Factors array cannot be empty'),
    body('factors.*.text')
      .trim()
      .notEmpty().withMessage('Text is required')
      .isLength({ max: 200 }).withMessage('Text must not exceed 200 characters'),
    body('factors.*.type')
      .notEmpty().withMessage('Type is required')
      .isIn(['political', 'economic', 'social', 'technological'])
      .withMessage('Type must be one of: political, economic, social, technological'),
    body('factors.*.impact')
      .notEmpty().withMessage('Impact is required')
      .isInt({ min: 1, max: 5 }).withMessage('Impact must be between 1 and 5')
  ],
  batchUpdate: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    body('factors')
      .isArray().withMessage('Factors must be an array')
      .notEmpty().withMessage('Factors array cannot be empty'),
    body('factors.*.id')
      .notEmpty().withMessage('Factor ID is required')
  ],
  batchDelete: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    body('ids')
      .isArray().withMessage('IDs must be an array')
      .notEmpty().withMessage('IDs array cannot be empty')
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
  ],
  batchCreate: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    body('items')
      .isArray().withMessage('Items must be an array')
      .notEmpty().withMessage('Items array cannot be empty')
  ],
  batchUpdate: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    body('items')
      .isArray().withMessage('Items must be an array')
      .notEmpty().withMessage('Items array cannot be empty'),
    body('items.*.id')
      .notEmpty().withMessage('Item ID is required')
  ],
  batchDelete: [
    param('projectId').notEmpty().withMessage('Project ID is required'),
    body('ids')
      .isArray().withMessage('IDs must be an array')
      .notEmpty().withMessage('IDs array cannot be empty')
  ]
};

/**
 * Common pagination and filtering validation rules
 */
exports.paginationRules = [
  query('page')
    .optional()
    .isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
];

exports.searchRules = [
  query('search')
    .optional()
    .isString().withMessage('Search must be a string')
    .isLength({ min: 1, max: 50 }).withMessage('Search must be between 1 and 50 characters')
];

exports.dateFilterRules = [
  query('startDate')
    .optional()
    .isISO8601().withMessage('Start date must be a valid date'),
  query('endDate')
    .optional()
    .isISO8601().withMessage('End date must be a valid date')
];