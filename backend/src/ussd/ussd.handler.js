const { db } = require("../config/firebase");
const vetsService = require("../services/vets.service");

async function listVets() {
  const vets = await vetsService.getAvailableVets();
  vets.sort((a, b) => (a.fullName || "").localeCompare(b.fullName || ""));
  return vets;
}

async function handleUssd(req, res) {
  const { text, phoneNumber, serviceCode } = req.body;
  const parts = text.split("*");
  let response = "";

  if (text === "") {
    response = "CON Welcome to MifugoAlert\n";
    response += "1. Find an available vet";
  } else if (text === "1") {
    const vets = await listVets();
    if (vets.length === 0) {
      response = "END No vets are available right now. Please try again later.";
    } else {
      response = "CON Select a vet to call:\n";
      vets.forEach((vet, i) => {
        response += `${i + 1}. ${vet.fullName} (${vet.area})\n`;
      });
    }
  } else if (parts.length === 2 && parts[0] === "1") {
    const vets = await listVets();
    const vet = vets[parseInt(parts[1], 10) - 1];
    if (!vet) {
      response = "END Invalid selection.";
    } else {
      response = `END ${vet.fullName}\n`;
      response += `Phone: ${vet.phone}\n`;
      response += `Location: ${vet.area}\n`;
      response += "Dial this number to call the vet.";
      await recordVetContact(phoneNumber, vet, serviceCode);
    }
  } else {
    response = "END Invalid choice. Please dial again.";
  }

  res.set("Content-Type", "text/plain");
  res.send(response);
}

async function recordVetContact(farmerPhone, vet, serviceCode) {
  try {
    const snap = await db
      .collection("users")
      .where("phone", "==", farmerPhone)
      .where("role", "==", "farmer")
      .limit(1)
      .get();
    if (snap.empty) return;

    await db.collection("activities").add({
      userId: snap.docs[0].id,
      type: "ussd_submission",
      title: `Requested contact for ${vet.fullName} via ${serviceCode || "USSD"}`,
      source: "USSD",
      channel: "ussd",
      createdAt: new Date(),
    });
  } catch (err) {
    console.error("Failed to record USSD activity:", err);
  }
}

module.exports = { handleUssd };