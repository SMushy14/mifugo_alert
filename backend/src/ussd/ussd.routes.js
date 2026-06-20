const express = require('express');
const router = express.Router();
const { handleUssd } = require('./ussd.handler');

router.post('/', handleUssd);

module.exports = router;