const { PlaidApi, Configuration, PlaidEnvironments, Products, CountryCodes } = require('plaid');
const { AppError } = require('../utils/errorHandler');

class PlaidService {
    constructor() {
        const configuration = new Configuration({
            basePath: PlaidEnvironments.sandbox,
            baseOptions: {
                headers: {
                    'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID,
                    'PLAID-SECRET': process.env.PLAID_SECRET,
                },
            },
        });
        
        this.client = new PlaidApi(configuration);
    }

    async createLinkToken(userId) {
        try {
            const request = {
                user: {
                    client_user_id: userId
                },
                client_name: 'Tim',
                products: [Products.Transactions],
                country_codes: [CountryCodes.US],
                language: 'en'
            };

            const response = await this.client.linkTokenCreate(request);
            return response.data.link_token;
        } catch (error) {
            throw new AppError(error.message, 500, 'INTERNAL_SERVER_ERROR');
        }
    }
}

module.exports = PlaidService; 