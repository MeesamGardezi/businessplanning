const dotenv = require('dotenv');
dotenv.config();

module.exports = {
  port: process.env.PORT || 33354,
  nodeEnv: process.env.NODE_ENV || 'development',
  allowedOrigins: process.env.ALLOWED_ORIGINS 
    ? process.env.ALLOWED_ORIGINS.split(',') 
    : ['http://localhost:33354', 'http://localhost:33354'],
  firebaseConfig: {
    databaseURL: process.env.FIREBASE_DATABASE_URL,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET
  }
};