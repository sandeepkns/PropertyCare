const express = require('express');
const crypto = require('crypto');
const router = express.Router();

router.post('/', express.raw({ type: 'application/json' }), (req, res) => {
    const inboundSignature = req.headers['x-propertycare-signature'];
    if (!inboundSignature) {
        return res.status(401).json({ error: 'Access Denied: Missing cryptographic verification token header.' });
    }

    const hmac = crypto.createHmac('sha256', process.env.PORTAL_HMAC_SECRET);
    const computedSignature = hmac.update(req.body).digest('hex');

    if (inboundSignature !== computedSignature) {
        console.error('Security Breach Warning: Unauthorized signature key mismatch mismatch detected!');
        return res.status(403).json({ error: 'Access Forbidden: Invalid cryptographic verification match.' });
    }

    const payload = JSON.parse(req.body.toString());
    console.log('Successfully captured authenticated Salesforce status update:', payload);
    
    return res.status(200).json({ status: 'Acknowledged', workOrderId: payload.workOrderId });
});

module.exports = router;