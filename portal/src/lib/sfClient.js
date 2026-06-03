const axios = require('axios');
const { getSalesforceAccessToken } = require('../auth/sfJwt');

let cachedToken = null;

async function request(method, urlMapping, data = null) {
    if (!cachedToken) {
        cachedToken = await getSalesforceAccessToken();
    }
    
    try {
        return await axios({
            method,
            url: `${process.env.SF_LOGIN_URL}${urlMapping}`,
            headers: {
                'Authorization': `Bearer ${cachedToken}`,
                'Content-Type': 'application/json'
            },
            data
        });
    } catch (err) {
        if (err.response && err.response.status === 401) {
            console.log('Cached token expired. Re-authenticating with Salesforce JWT...');
            cachedToken = await getSalesforceAccessToken();
            return await axios({
                method,
                url: `${process.env.SF_LOGIN_URL}${urlMapping}`,
                headers: {
                    'Authorization': `Bearer ${cachedToken}`,
                    'Content-Type': 'application/json'
                },
                data
            });
        }
        throw err;
    }
}

module.exports = { request };