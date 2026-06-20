const express = require('express');
const cors = require('cors');
const vetsRoutes = require('./routes/vets.routes');
const ussdRoutes = require('./ussd/ussd.routes');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

app.get('/health', (req, res) => {
    res.status(200).send('Health check passed.');
});
app.get("/", (req, res) => res.send("MifugoAlert backend is running"));

app.use('/api/vets', vetsRoutes);
app.use('/ussd', ussdRoutes);
app.use('/api/cases', require('./routes/cases.routes'));

module.exports = app;