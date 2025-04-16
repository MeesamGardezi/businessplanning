require('dotenv').config();
const app = require('./app');
const { port, nodeEnv } = require('./config/config');
const { admin } = require('./config/firebase');

// Start the server
const server = app.listen(port, () => {
  console.log(`Server running in ${nodeEnv} mode on port ${port}`);
  
  try {
    const projectId = admin.app().options.projectId || 
                     (admin.app().options.credential && admin.app().options.credential.projectId);
    console.log(`Firebase Admin SDK initialized for project: ${projectId}`);
  } catch (err) {
    console.error('Error getting Firebase project ID:', err.message);
  }
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error('UNHANDLED REJECTION! Shutting down...');
  console.error(err.name, err.message);
  server.close(() => {
    process.exit(1);
  });
});

// Handle SIGTERM signal
process.on('SIGTERM', () => {
  console.log('SIGTERM RECEIVED. Shutting down gracefully');
  server.close(() => {
    console.log('Process terminated!');
  });
});