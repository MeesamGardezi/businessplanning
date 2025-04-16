const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { allowedOrigins } = require('./config/config');
const errorHandler = require('./middleware/errorHandler');

// Import routes
const authRoutes = require('./routes/authRoutes');
const projectRoutes = require('./routes/projectRoutes');
const swotRoutes = require('./routes/swotRoutes');
const pestRoutes = require('./routes/pestRoutes');
const actionRoutes = require('./routes/actionRoutes');

// Initialize express app
const app = express();

// Configure CORS
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, curl requests)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) === -1) {
      const msg = 'The CORS policy for this site does not allow access from the specified origin.';
      return callback(new Error(msg), false);
    }
    return callback(null, true);
  },
  credentials: true
};

// Middleware
app.use(helmet()); // Security headers
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev')); // Request logging

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/projects', swotRoutes);
app.use('/api/projects', pestRoutes);
app.use('/api/projects', actionRoutes);

// Health check route
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', message: 'Server is running' });
});

// API documentation route
app.get('/api/docs', (req, res) => {
  res.status(200).json({
    message: 'API Documentation',
    version: '1.0',
    endpoints: {
      auth: [
        { method: 'POST', path: '/api/auth/register', description: 'Register a new user' },
        { method: 'POST', path: '/api/auth/login', description: 'Login a user' },
        { method: 'POST', path: '/api/auth/logout', description: 'Logout a user' },
        { method: 'POST', path: '/api/auth/refresh-token', description: 'Refresh authentication token' },
        { method: 'GET', path: '/api/auth/me', description: 'Get current user profile' },
        { method: 'PUT', path: '/api/auth/profile', description: 'Update user profile' },
        { method: 'DELETE', path: '/api/auth/account', description: 'Delete user account' },
        { method: 'POST', path: '/api/auth/check-email', description: 'Check if email exists' },
        { method: 'POST', path: '/api/auth/set-password', description: 'Set or update user password' },
        { method: 'POST', path: '/api/auth/reset-password', description: 'Reset password - initiate process' },
        { method: 'POST', path: '/api/auth/reset-password/confirm', description: 'Reset password - complete process' },
        { method: 'POST', path: '/api/auth/verify-email', description: 'Verify email - initiate process' },
        { method: 'POST', path: '/api/auth/verify-email/confirm', description: 'Verify email - complete process' }
      ],
      projects: [
        { method: 'GET', path: '/api/projects', description: 'Get all projects' },
        { method: 'POST', path: '/api/projects', description: 'Create a new project' },
        { method: 'GET', path: '/api/projects/:id', description: 'Get a specific project' },
        { method: 'PUT', path: '/api/projects/:id', description: 'Update a project' },
        { method: 'DELETE', path: '/api/projects/:id', description: 'Delete a project' },
        { method: 'GET', path: '/api/projects/:id/export', description: 'Export a project with all its data' },
        { method: 'POST', path: '/api/projects/import', description: 'Import a project' },
        { method: 'GET', path: '/api/projects/:id/stats', description: 'Get project statistics' }
      ],
      swot: [
        { method: 'GET', path: '/api/projects/:projectId/swot', description: 'Get all SWOT items for a project' },
        { method: 'POST', path: '/api/projects/:projectId/swot', description: 'Create a new SWOT item' },
        { method: 'GET', path: '/api/projects/:projectId/swot/:itemId', description: 'Get a specific SWOT item' },
        { method: 'PUT', path: '/api/projects/:projectId/swot/:itemId', description: 'Update a SWOT item' },
        { method: 'DELETE', path: '/api/projects/:projectId/swot/:itemId', description: 'Delete a SWOT item' },
        { method: 'PUT', path: '/api/projects/:projectId/swot/:itemId/move', description: 'Move a SWOT item to a different type' },
        { method: 'POST', path: '/api/projects/:projectId/swot/batch', description: 'Batch create multiple SWOT items' },
        { method: 'PUT', path: '/api/projects/:projectId/swot/batch', description: 'Batch update multiple SWOT items' },
        { method: 'DELETE', path: '/api/projects/:projectId/swot/batch', description: 'Batch delete multiple SWOT items' },
        { method: 'GET', path: '/api/projects/:projectId/swot/stats', description: 'Get SWOT statistics' }
      ],
      pest: [
        { method: 'GET', path: '/api/projects/:projectId/pest', description: 'Get all PEST factors for a project' },
        { method: 'POST', path: '/api/projects/:projectId/pest', description: 'Create a new PEST factor' },
        { method: 'GET', path: '/api/projects/:projectId/pest/:factorId', description: 'Get a specific PEST factor' },
        { method: 'PUT', path: '/api/projects/:projectId/pest/:factorId', description: 'Update a PEST factor' },
        { method: 'DELETE', path: '/api/projects/:projectId/pest/:factorId', description: 'Delete a PEST factor' },
        { method: 'PUT', path: '/api/projects/:projectId/pest/:factorId/impact', description: 'Update impact rating for a PEST factor' },
        { method: 'PUT', path: '/api/projects/:projectId/pest/:factorId/timeframe', description: 'Update timeframe for a PEST factor' },
        { method: 'POST', path: '/api/projects/:projectId/pest/batch', description: 'Batch create multiple PEST factors' },
        { method: 'PUT', path: '/api/projects/:projectId/pest/batch', description: 'Batch update PEST factors' },
        { method: 'DELETE', path: '/api/projects/:projectId/pest/batch', description: 'Batch delete PEST factors' },
        { method: 'GET', path: '/api/projects/:projectId/pest/stats', description: 'Get PEST statistics' }
      ],
      actions: [
        { method: 'GET', path: '/api/projects/:projectId/actions', description: 'Get all action items for a project' },
        { method: 'POST', path: '/api/projects/:projectId/actions', description: 'Create a new action item' },
        { method: 'GET', path: '/api/projects/:projectId/actions/:itemId', description: 'Get a specific action item' },
        { method: 'PUT', path: '/api/projects/:projectId/actions/:itemId', description: 'Update an action item' },
        { method: 'DELETE', path: '/api/projects/:projectId/actions/:itemId', description: 'Delete an action item' },
        { method: 'PUT', path: '/api/projects/:projectId/actions/:itemId/status', description: 'Update action item status' },
        { method: 'POST', path: '/api/projects/:projectId/actions/batch', description: 'Batch create multiple action items' },
        { method: 'PUT', path: '/api/projects/:projectId/actions/batch', description: 'Batch update action items' },
        { method: 'DELETE', path: '/api/projects/:projectId/actions/batch', description: 'Batch delete action items' },
        { method: 'GET', path: '/api/projects/:projectId/actions/stats', description: 'Get action item statistics' }
      ]
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Endpoint not found' });
});

// Error handling middleware
app.use(errorHandler);

module.exports = app;