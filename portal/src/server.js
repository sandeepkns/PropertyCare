require('dotenv').config();
const express = require('express');
const requestRoutes = require('./routes/requests');
const webhookRoutes = require('./routes/webhook');

const app = express();
const PORT = process.env.PORT || 3000;

// CRITICAL: Webhook route must declare first to capture the raw unparsed request buffer for signature matching
app.use('/sf-webhook/work-order', webhookRoutes);

// Generic middleware parsers for client requests
app.use(express.json());

// Bind the web request entry module path routing frameworks
app.use('/requests', requestRoutes);

app.listen(PORT, () => {
    console.log(`================================================================`);
    console.log(`  PropertyCare External Tenant Portal App running on port ${PORT} `);
    console.log(`================================================================`);
});