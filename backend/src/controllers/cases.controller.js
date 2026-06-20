const casesService = require("../services/cases.service");

async function createCase(req, res) {
  try {
    const { farmerId, species, symptom, source } = req.body;
    if (!farmerId || !species || !symptom) {
      return res
        .status(400)
        .json({ error: "farmerId, species and symptom are required" });
    }
    const created = await casesService.createCase({
      farmerId,
      species,
      symptom,
      source,
    });
    res.status(201).json(created);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Could not create case" });
  }
}

async function listCases(req, res) {
  try {
    const cases = await casesService.getCasesByFarmer(req.query.farmerId);
    res.json(cases);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Could not fetch cases" });
  }
}

module.exports = { createCase, listCases };
