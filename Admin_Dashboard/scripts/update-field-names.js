// Utility script to update field names in Firebase
// Usage: node scripts/update-field-names.js

import { updateFieldName } from '../lib/firebase.js';

// Example usage - update these values as needed
const COLLECTION_NAME = 'ancRecords'; // Your collection name
const OLD_FIELD_NAME = 'oldFieldName'; // The field name you want to change
const NEW_FIELD_NAME = 'newFieldName'; // The new field name

async function runFieldUpdate() {
  console.log('Starting field name update...');
  console.log(`Collection: ${COLLECTION_NAME}`);
  console.log(`Old field: ${OLD_FIELD_NAME}`);
  console.log(`New field: ${NEW_FIELD_NAME}`);
  
  const result = await updateFieldName(COLLECTION_NAME, OLD_FIELD_NAME, NEW_FIELD_NAME);
  
  if (result.success) {
    console.log(`✅ Successfully updated ${result.updatedCount} documents`);
  } else {
    console.error(`❌ Error: ${result.error}`);
  }
}

// Run the update
runFieldUpdate().catch(console.error); 