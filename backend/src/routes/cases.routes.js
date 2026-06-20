const express = require("express");
const router = express.Router();
const { createCase, listCases } = require("../controllers/cases.controller");

router.post("/", createCase);
router.get("/", listCases);

module.exports = router;
