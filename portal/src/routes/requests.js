const express = require('express');
const router = express.Router();
const sfClient = require('../lib/sfClient');

router.post('/', async (req, res) => {
    try {
        const sfResponse = await sfClient.request('POST', '/services/apexrest/api/v1/service-requests/', req.body);
        return res.status(sfResponse.status).json(sfResponse.data);
    } catch (err) {
        const status = err.response ? err.response.status : 500;
        return res.status(status).json(err.response ? err.response.data : { error: 'Internal Gateway Connection Failure' });
    }
});

module.exports = router;