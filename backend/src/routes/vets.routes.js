const express = require('express');
const router = express.Router();
const { listAvailableVets, updateAvailability } = require('../controllers/vets.controller');

router.get('/available', listAvailableVets);
router.put('/availability', updateAvailability);

module.exports = router;