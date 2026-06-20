const db = require("../config/firebase");

const usersRef = db.collection("users");

async function getAvailableVets() {
  const snapshot = await usersRef
    .where("role", "==", "vet")
    .where("isAvailable", "==", true)
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
}

async function setVetAvailability(vetId, isAvailable) {
  await usersRef.doc(vetId).update({
    isAvailable: isAvailable,
  });

  const updatedVet = await usersRef.doc(vetId).get();

  return {
    id: updatedVet.id,
    ...updatedVet.data(),
  };
}

module.exports = {
  getAvailableVets,
  setVetAvailability,
};
