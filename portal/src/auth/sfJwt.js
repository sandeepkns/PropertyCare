const jwt = require('jsonwebtoken');
const axios = require('axios');

async function getSalesforceAccessToken() {
    const claim = {
        iss: process.env.SF_CLIENT_ID,
        sub: process.env.SF_USERNAME,
        aud: process.env.SF_LOGIN_URL,
        exp: Math.floor(Date.now() / 1000) + 180
    };
    
    const privateKey = process.env.SF_PRIVATE_KEY.replace(/\\n/g, '\n');
    const assertionToken = jwt.sign(claim, privateKey, { algorithm: 'RS256' });
    
    const params = new URLSearchParams();
    params.append('grant_type', 'urn:ietf:params:oauth:grant-type:jwt-bearer');
    params.append('assertion', assertionToken);

    const res = await axios.post(`${process.env.SF_LOGIN_URL}/services/oauth2/token`, params.toString(), {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    
    return res.data.access_token;
}

module.exports = { getSalesforceAccessToken };