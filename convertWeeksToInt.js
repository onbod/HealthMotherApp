const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

async function convertWeeksFieldToInt(collectionName) {
  const snapshot = await db.collection(collectionName).get();
  const batch = db.batch();
  let count = 0;

  snapshot.forEach(doc => {
    const data = doc.data();
    const weeks = data.weeks;
    if (typeof weeks === "string" && !isNaN(Number(weeks))) {
      const weeksInt = parseInt(weeks, 10);
      batch.update(doc.ref, { weeks: weeksInt });
      count++;
    }
  });

  if (count > 0) {
    await batch.commit();
    console.log(`Updated ${count} documents in ${collectionName}.`);
  } else {
    console.log(`No documents needed updating in ${collectionName}.`);
  }
}

async function main() {
  await convertWeeksFieldToInt("health-tips");
  await convertWeeksFieldToInt("nutrition-tips");
  process.exit(0);
}

main().catch(err => {
  console.error("Error updating weeks fields:", err);
  process.exit(1);
});