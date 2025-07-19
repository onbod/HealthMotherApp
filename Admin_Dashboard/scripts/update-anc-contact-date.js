// Script to update dateOfANCContact to dateOfAncContact in ancRecords collection
// Usage: node scripts/update-anc-contact-date.js

const { initializeApp } = require("firebase/app");
const { getFirestore, collection, getDocs, doc, updateDoc, deleteField } = require("firebase/firestore");

const firebaseConfig = {
  apiKey: "AIzaSyBGiim3UDIQp7ACL_DFG82k1CnSNZuvoDg",
  authDomain: "medilink-8b42a.firebaseapp.com",
  projectId: "medilink-8b42a",
  storageBucket: "medilink-8b42a.firebasestorage.app",
  messagingSenderId: "696567663861",
  appId: "1:696567663861:web:5d0716e6cd33ce8ead89bc",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Function to update field names in a collection
async function updateFieldName(collectionName, oldFieldName, newFieldName) {
  try {
    console.log(`Starting field name update: ${oldFieldName} -> ${newFieldName}`);
    
    // Get all documents in the collection
    const querySnapshot = await getDocs(collection(db, collectionName));
    let updatedCount = 0;
    
    for (const document of querySnapshot.docs) {
      const docData = document.data();
      
      // Handle nested field updates (e.g., "visit1.dateOfANCContact")
      if (oldFieldName.includes('.')) {
        const [parentField, childField] = oldFieldName.split('.');
        const [newParentField, newChildField] = newFieldName.split('.');
        
        if (docData[parentField] && docData[parentField][childField] !== undefined) {
          const docRef = doc(db, collectionName, document.id);
          
          // Create update object for nested field
          const updateData = {
            [`${newParentField}.${newChildField}`]: docData[parentField][childField]
          };
          
          // Update the document with new nested field
          await updateDoc(docRef, updateData);
          
          // Remove the old nested field
          const deleteData = {};
          deleteData[`${parentField}.${childField}`] = deleteField();
          await updateDoc(docRef, deleteData);
          
          updatedCount++;
          console.log(`Updated nested field in document: ${document.id}`);
        }
      } else {
        // Handle top-level field updates
        if (docData.hasOwnProperty(oldFieldName)) {
          const docRef = doc(db, collectionName, document.id);
          
          // Create update object with new field name
          const updateData = {
            [newFieldName]: docData[oldFieldName]
          };
          
          // Update the document with new field
          await updateDoc(docRef, updateData);
          
          // Remove the old field
          await updateDoc(docRef, {
            [oldFieldName]: deleteField()
          });
          
          updatedCount++;
          console.log(`Updated document: ${document.id}`);
        }
      }
    }
    
    console.log(`Field name update completed. Updated ${updatedCount} documents.`);
    return { success: true, updatedCount };
    
  } catch (error) {
    console.error('Error updating field names:', error);
    return { success: false, error: error.message };
  }
}

async function updateAncContactDate() {
  console.log('Starting ANC contact date field update...');
  
  // Update visit1.dateOfANCContact -> visit1.dateOfAncContact
  console.log('\n1. Updating visit1.dateOfANCContact...');
  const visit1Result = await updateFieldName('ancRecords', 'visit1.dateOfANCContact', 'visit1.dateOfAncContact');
  
  if (visit1Result.success) {
    console.log(`✅ Successfully updated visit1 in ${visit1Result.updatedCount} documents`);
  } else {
    console.error(`❌ Error updating visit1: ${visit1Result.error}`);
  }
  
  // Update visit2.dateOfANCContact -> visit2.dateOfAncContact
  console.log('\n2. Updating visit2.dateOfANCContact...');
  const visit2Result = await updateFieldName('ancRecords', 'visit2.dateOfANCContact', 'visit2.dateOfAncContact');
  
  if (visit2Result.success) {
    console.log(`✅ Successfully updated visit2 in ${visit2Result.updatedCount} documents`);
  } else {
    console.error(`❌ Error updating visit2: ${visit2Result.error}`);
  }
  
  console.log('\n🎉 Field name update completed!');
}

// Run the update
updateAncContactDate().catch(console.error); 