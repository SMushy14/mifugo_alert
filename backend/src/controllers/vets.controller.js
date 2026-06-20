const vetService = require('../services/vets.service');

async function listAvailableVets(req, res) {
    try {
        const vets = await vetService.getAvailableVets();
        res.status(200).json(vets);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
}

async function updateAvailability(req, res) {
    try {
        const { vetId, isAvailable } = req.body;
        const updatedVet = await vetService.setVetAvailability(vetId, isAvailable);
        res.status(200).json(updatedVet);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
}

module.exports = {
    listAvailableVets,
    updateAvailability
};