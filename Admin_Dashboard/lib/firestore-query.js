// Usage:
// 1. Download your Firebase service account key JSON from the Firebase Console.
// 2. Place it in the same directory as this script and name it 'serviceAccountKey.json'.
// 3. Run: node lib/firestore-query.js

const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, 'serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function printAncRecords() {
  const snapshot = await db.collection('ancRecords').get();
  if (snapshot.empty) {
    console.log('No documents found in ancRecords.');
    return;
  }
  snapshot.forEach(doc => {
    console.log(`Document ID: ${doc.id}`);
    console.dir(doc.data(), { depth: null });
    console.log('-----------------------------');
  });
  process.exit(0);
}

printAncRecords().catch(err => {
  console.error('Error querying Firestore:', err);
  process.exit(1);
}); 