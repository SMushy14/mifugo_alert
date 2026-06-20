const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

const admin = require("firebase-admin");

function getCredential() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const parsed = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    if (parsed.private_key) {
      parsed.private_key = parsed.private_key.replace(/\\n/g, "\n");
    }
    return admin.credential.cert(parsed);
  }
  const serviceAccount = require("./serviceAccountKey.json");
  return admin.credential.cert(serviceAccount);
}

if (!admin.apps.length) {
  admin.initializeApp({ credential: getCredential() });
}

const db = admin.firestore();
module.exports = { admin, db };
