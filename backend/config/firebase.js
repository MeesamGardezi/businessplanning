const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Path to your service account file
const serviceAccountPath = path.resolve(__dirname, '../firebase_key.json');

// Check if file exists
if (!fs.existsSync(serviceAccountPath)) {
  console.error('Firebase credentials file not found at:', serviceAccountPath);
  process.exit(1); // Exit the process with an error
}

// Read and parse the service account file
let serviceAccount;
try {
  serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
  
  // Validate necessary fields
  if (!serviceAccount.project_id || !serviceAccount.private_key || !serviceAccount.client_email) {
    throw new Error('Firebase credentials file is missing required fields');
  }
  
  console.log('Successfully loaded Firebase credentials for project:', serviceAccount.project_id);
} catch (error) {
  console.error('Error parsing Firebase credentials:', error);
  process.exit(1); // Exit the process with an error
}

// Initialize Firebase Admin SDK with better error handling
try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: process.env.FIREBASE_DATABASE_URL,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET
  });
  console.log('Firebase Admin SDK initialized successfully for project:', serviceAccount.project_id);
} catch (error) {
  console.error('Error initializing Firebase Admin SDK:', error);
  process.exit(1); // Exit the process with an error
}

const db = admin.firestore();
const auth = admin.auth();
const storage = admin.storage();

module.exports = {
  admin,
  db,
  auth,
  storage
};