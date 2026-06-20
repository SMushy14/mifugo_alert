const { initializeApp, getApps, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

function getCredential() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const parsed = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

    if (parsed.private_key) {
      parsed.private_key = parsed.private_key.replace(/\\n/g, "\n");
    }

    return cert(parsed);
  }

  const serviceAccount = require("./serviceAccountKey.json");
  return cert(serviceAccount);
}

if (getApps().length === 0) {
  initializeApp({
    credential: getCredential(),
  });
}

const db = getFirestore();

module.exports = { db };
