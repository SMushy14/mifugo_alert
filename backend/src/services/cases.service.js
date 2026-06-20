const db = require("../config/firebase");
const casesRef = db.collection("cases");

function generateCaseCode() {
  return `MA-${Math.floor(1000 + Math.random() * 9000)}`;
}

async function createCase({ farmerId, species, symptom, source }) {
  const newCase = {
    farmerId,
    species,
    symptom,
    source: source || "mobile_app",
    status: "in_progress",
    caseCode: generateCaseCode(),
    createdAt: new Date(),
  };
  const ref = await casesRef.add(newCase);
  return { id: ref.id, ...newCase };
}

async function getCasesByFarmer(farmerId) {
  const snap = await casesRef
    .where("farmerId", "==", farmerId)
    .orderBy("createdAt", "desc")
    .get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

module.exports = { createCase, getCasesByFarmer };
