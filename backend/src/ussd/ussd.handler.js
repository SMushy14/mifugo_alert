const { db } = require("../config/firebase");
const vetsService = require("../services/vets.service");

const SPECIES = ["Cattle", "Goat", "Poultry", "Sheep", "Pig"];
const SYMPTOMS = ["Fever", "Not eating", "Coughing", "Diarrhea", "Swelling", "Wounds"];

const REGIONS = [
  "Arusha", "Dar es Salaam", "Dodoma", "Mwanza", "Kilimanjaro",
  "Mbeya", "Morogoro", "Tanga", "Tabora", "Kagera",
];

const T = {
  en: {
    langPrompt: "CON Welcome to MifugoAlert\n1. English\n2. Kiswahili",
    menu: (name) =>
      `CON MifugoAlert${name ? " - " + name : ""}\n` +
      "1. Report a sick animal\n" +
      "2. Find an available vet\n" +
      "3. Check case status\n" +
      "4. My livestock\n" +
      "5. Health tips\n" +
      "6. Register / update profile",
    chooseSpecies: "CON Select animal type:\n",
    chooseSymptom: "CON Select main symptom:\n",
    howMany: "CON How many animals are affected?\n(Enter a number)",
    confirm: (s, sy, c) =>
      `CON Confirm report:\n${s} - ${sy} - ${c} animal(s)\n1. Submit\n2. Cancel`,
    invalid: "END Invalid choice. Please dial again.",
    cancelled: "END Report cancelled.",
    submitted: (code, vet) =>
      `END Report submitted. Case ${code}.\n` +
      (vet.id
        ? `${vet.name} assigned.\nCall: ${vet.phone}`
        : "A vet will be assigned shortly."),
    noVets: "END No vets are available right now. Please try again later.",
    pickVet: "CON Select a vet to call:\n",
    vetCard: (v) =>
      `END ${v.fullName}\nPhone: ${v.phone}\nArea: ${v.area}\nDial the number to call.`,
    noCases: "END You have no reported cases yet.",
    caseList: "CON Your recent cases:\n",
    caseDetail: (c) =>
      `END Case ${c.caseCode}\n${c.species} - ${c.symptom}\n` +
      `Status: ${statusLabel(c.status, "en")}\n` +
      (c.assignedVetName ? `Vet: ${c.assignedVetName}` : "Awaiting a vet."),
    livestock: (n) =>
      n === 0
        ? "END You have no animals registered. Use the app to add livestock."
        : `END You have ${n} animal(s) registered.`,
    tips:
      "END Health tips:\n- Vaccinate poultry against Newcastle\n" +
      "- Deworm goats every 3 months\n- Isolate sick animals early\n" +
      "- Report sudden deaths immediately.",
    notRegistered:
      "CON You're not registered. Let's set you up.\nEnter your full name:",
    chooseRegion: "CON Select your region:\n",
    registered: (name) => `END Welcome ${name}! You're registered. Dial again to report.`,
    enterNumber: "CON Invalid. Enter a valid number:",
  },
  sw: {
    langPrompt: "CON Karibu MifugoAlert\n1. English\n2. Kiswahili",
    menu: (name) =>
      `CON MifugoAlert${name ? " - " + name : ""}\n` +
      "1. Ripoti mnyama mgonjwa\n" +
      "2. Tafuta daktari\n" +
      "3. Angalia hali ya kesi\n" +
      "4. Mifugo yangu\n" +
      "5. Vidokezo vya afya\n" +
      "6. Jisajili / sasisha wasifu",
    chooseSpecies: "CON Chagua aina ya mnyama:\n",
    chooseSymptom: "CON Chagua dalili kuu:\n",
    howMany: "CON Wanyama wangapi wameathirika?\n(Andika namba)",
    confirm: (s, sy, c) =>
      `CON Thibitisha ripoti:\n${s} - ${sy} - ${c} mnyama\n1. Tuma\n2. Ghairi`,
    invalid: "END Chaguo si sahihi. Piga tena.",
    cancelled: "END Ripoti imeghairiwa.",
    submitted: (code, vet) =>
      `END Ripoti imetumwa. Kesi ${code}.\n` +
      (vet.id
        ? `${vet.name} amepangwa.\nPiga: ${vet.phone}`
        : "Daktari atapangwa hivi karibuni."),
    noVets: "END Hakuna madaktari kwa sasa. Jaribu tena baadaye.",
    pickVet: "CON Chagua daktari wa kupiga simu:\n",
    vetCard: (v) =>
      `END ${v.fullName}\nSimu: ${v.phone}\nEneo: ${v.area}\nPiga namba hii kumpigia.`,
    noCases: "END Huna kesi zilizoripotiwa bado.",
    caseList: "CON Kesi zako za hivi karibuni:\n",
    caseDetail: (c) =>
      `END Kesi ${c.caseCode}\n${c.species} - ${c.symptom}\n` +
      `Hali: ${statusLabel(c.status, "sw")}\n` +
      (c.assignedVetName ? `Daktari: ${c.assignedVetName}` : "Inasubiri daktari."),
    livestock: (n) =>
      n === 0
        ? "END Huna wanyama waliosajiliwa. Tumia app kuongeza mifugo."
        : `END Una wanyama ${n} waliosajiliwa.`,
    tips:
      "END Vidokezo vya afya:\n- Chanja kuku dhidi ya Mdondo\n" +
      "- Tibu minyoo ya mbuzi kila miezi 3\n- Tenga wanyama wagonjwa mapema\n" +
      "- Ripoti vifo vya ghafla haraka.",
    notRegistered:
      "CON Hujasajiliwa. Tukusajili.\nAndika jina lako kamili:",
    chooseRegion: "CON Chagua mkoa wako:\n",
    registered: (name) => `END Karibu ${name}! Umesajiliwa. Piga tena kuripoti.`,
    enterNumber: "CON Si sahihi. Andika namba sahihi:",
  },
};

function statusLabel(status, lang) {
  const map = {
    en: { pending: "Pending", assigned: "Assigned", in_progress: "In progress", resolved: "Resolved", unresolved: "Needs reassignment", escalated: "Escalated" },
    sw: { pending: "Inasubiri", assigned: "Imepangwa", in_progress: "Inaendelea", resolved: "Imetatuliwa", unresolved: "Inahitaji daktari mpya", escalated: "Imepandishwa" },
  };
  return (map[lang] || map.en)[status] || status;
}

async function listVets() {
  const vets = await vetsService.getAvailableVets();
  vets.sort((a, b) => (a.fullName || "").localeCompare(b.fullName || ""));
  return vets;
}

async function findFarmer(phone) {
  const snap = await db.collection("users")
    .where("phone", "==", phone).where("role", "==", "farmer").limit(1).get();
  return snap.empty ? null : { id: snap.docs[0].id, ...snap.docs[0].data() };
}

async function autoAssignVet(area) {
  const vets = await listVets();
  if (vets.length === 0) return { id: null, name: null, phone: null };
  const inArea = vets.find((v) => (v.area || "").toLowerCase() === (area || "").toLowerCase());
  const chosen = inArea || vets[0];
  return { id: chosen.id, name: chosen.fullName, phone: chosen.phone };
}

function nextCaseCode() {
  return "MA-" + Math.floor(1000 + Math.random() * 9000);
}

function numberedList(items, labelFn) {
  return items.map((it, i) => `${i + 1}. ${labelFn(it)}`).join("\n") + "\n";
}

async function handleUssd(req, res) {
  const { text, phoneNumber, serviceCode } = req.body;
  const parts = text === "" ? [] : text.split("*");
  let response = "";

  const lang = parts[0] === "2" ? "sw" : "en";
  const t = T[lang];
  const p = parts.slice(1);

  try {
    if (parts.length === 0) {
      response = T.en.langPrompt;
      return send(res, response);
    }
    if (parts.length === 1) {
      const farmer = await findFarmer(phoneNumber);
      response = t.menu(farmer ? farmer.fullName : "");
      return send(res, response);
    }

    const choice = p[0];

    if (choice === "1") {
      if (p.length === 1) {
        response = t.chooseSpecies + numberedList(SPECIES, (s) => s);
      } else if (p.length === 2) {
        if (!SPECIES[+p[1] - 1]) response = t.invalid;
        else response = t.chooseSymptom + numberedList(SYMPTOMS, (s) => s);
      } else if (p.length === 3) {
        if (!SYMPTOMS[+p[2] - 1]) response = t.invalid;
        else response = t.howMany;
      } else if (p.length === 4) {
        const count = parseInt(p[3], 10);
        if (!count || count < 1) response = t.enterNumber;
        else response = t.confirm(SPECIES[+p[1] - 1], SYMPTOMS[+p[2] - 1], count);
      } else if (p.length === 5) {
        if (p[4] !== "1") { response = t.cancelled; }
        else {
          const species = SPECIES[+p[1] - 1];
          const symptom = SYMPTOMS[+p[2] - 1];
          const count = parseInt(p[3], 10);
          const farmer = await findFarmer(phoneNumber);
          const area = farmer ? farmer.area || "" : "";
          const vet = await autoAssignVet(area);
          const caseCode = nextCaseCode();

          await db.collection("cases").doc(caseCode).set({
            caseCode,
            farmerId: farmer ? farmer.id : null,
            farmerName: farmer ? farmer.fullName || "USSD Farmer" : "USSD Farmer",
            farmerPhone: phoneNumber,
            area, species, symptom, symptoms: [symptom], count,
            details: "Reported via USSD", source: "ussd",
            status: vet.id ? "assigned" : "pending",
            assignedVetId: vet.id, assignedVetName: vet.name,
            priority: "normal", createdAt: new Date(),
          });

          if (farmer) {
            await db.collection("activities").add({
              userId: farmer.id, type: "ussd_submission",
              title: `Reported ${species} case ${caseCode} (${symptom})`,
              source: "USSD", channel: "ussd", createdAt: new Date(),
            });
            await db.collection("notifications").add({
              userId: farmer.id, type: vet.id ? "vet_assigned" : "reminder",
              title: vet.id ? `Vet assigned to case ${caseCode}` : `Case ${caseCode} received`,
              body: vet.id ? `${vet.name} assigned. Call ${vet.phone}.` : "Report received. A vet will be assigned.",
              vetName: vet.name || "", vetPhone: vet.phone || "",
              read: false, createdAt: new Date(),
            });
          }
          if (vet.id) {
            await db.collection("notifications").add({
              userId: vet.id, type: "vet_assigned",
              title: `New case ${caseCode} in ${area || "your area"}`,
              body: `${species} - ${symptom} - ${count} animal(s). Farmer: ${phoneNumber}`,
              read: false, createdAt: new Date(),
            });
          }
          response = t.submitted(caseCode, vet);
        }
      } else response = t.invalid;

    } else if (choice === "2") {
      const vets = await listVets();
      if (p.length === 1) {
        if (vets.length === 0) response = t.noVets;
        else response = t.pickVet + numberedList(vets, (v) => `${v.fullName} (${v.area})`);
      } else if (p.length === 2) {
        const vet = vets[+p[1] - 1];
        if (!vet) response = t.invalid;
        else { response = t.vetCard(vet); await recordVetContact(phoneNumber, vet, serviceCode); }
      } else response = t.invalid;

    } else if (choice === "3") {
      const farmer = await findFarmer(phoneNumber);
      if (!farmer) { response = t.noCases; }
      else {
        const snap = await db.collection("cases")
          .where("farmerId", "==", farmer.id).get();
        const cases = snap.docs.map((d) => d.data())
          .sort((a, b) => toMs(b.createdAt) - toMs(a.createdAt)).slice(0, 5);
        if (cases.length === 0) response = t.noCases;
        else if (p.length === 1) {
          response = t.caseList + numberedList(cases,
            (c) => `${c.caseCode} (${statusLabel(c.status, lang)})`);
        } else if (p.length === 2) {
          const c = cases[+p[1] - 1];
          response = c ? t.caseDetail(c) : t.invalid;
        } else response = t.invalid;
      }

    } else if (choice === "4") {
      const farmer = await findFarmer(phoneNumber);
      let n = 0;
      if (farmer) {
        const snap = await db.collection("animals")
          .where("ownerId", "==", farmer.id).get();
        n = snap.size;
      }
      response = t.livestock(n);

    } else if (choice === "5") {
      response = t.tips;

    } else if (choice === "6") {
      if (p.length === 1) {
        response = t.notRegistered;
      } else if (p.length === 2) {
        response = t.chooseRegion + numberedList(REGIONS, (r) => r);
      } else if (p.length === 3) {
        const name = p[1].trim();
        const region = REGIONS[+p[2] - 1];
        if (!name || !region) { response = t.invalid; }
        else {
          const existing = await findFarmer(phoneNumber);
          if (existing) {
            await db.collection("users").doc(existing.id)
              .update({ fullName: name, area: region });
          } else {
            await db.collection("users").add({
              role: "farmer", fullName: name, phone: phoneNumber,
              area: region, createdAt: new Date(), source: "ussd",
            });
          }
          response = t.registered(name);
        }
      } else response = t.invalid;

    } else {
      response = t.invalid;
    }
  } catch (err) {
    console.error("USSD error:", err);
    response = "END Something went wrong. Please try again later.";
  }

  send(res, response);
}

function send(res, response) {
  res.set("Content-Type", "text/plain");
  res.send(response);
}

function toMs(ts) {
  if (!ts) return 0;
  if (ts.toMillis) return ts.toMillis();
  if (ts._seconds) return ts._seconds * 1000;
  return new Date(ts).getTime();
}

async function recordVetContact(farmerPhone, vet, serviceCode) {
  try {
    const farmer = await findFarmer(farmerPhone);
    if (!farmer) return;
    await db.collection("activities").add({
      userId: farmer.id, type: "ussd_submission",
      title: `Requested contact for ${vet.fullName} via ${serviceCode || "USSD"}`,
      source: "USSD", channel: "ussd", createdAt: new Date(),
    });
  } catch (err) {
    console.error("Failed to record USSD activity:", err);
  }
}

module.exports = { handleUssd };