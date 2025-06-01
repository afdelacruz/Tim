const { PlaidApi, Configuration, PlaidEnvironments, Products, CountryCodes } = require('plaid');
const { AppError } = require('../utils/errorHandler');
const AccountRepository = require('../repositories/AccountRepository');

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
                country_codes: ['US'], // Use string instead of enum
                language: 'en'
            };

            const response = await this.client.linkTokenCreate(request);
            return response.data.link_token;
        } catch (error) {
            throw new AppError(error.message, 500, 'INTERNAL_SERVER_ERROR');
        }
    }

    async exchangePublicToken(userId, publicToken) {
        try {
            // Exchange public token for access token and item ID
            const exchangeResponse = await this.client.itemPublicTokenExchange({
                public_token: publicToken
            });

            const { access_token: accessToken, item_id: itemId } = exchangeResponse.data;

            // Fetch account information
            const accountsResponse = await this.client.accountsGet({
                access_token: accessToken
            });

            const { accounts, item } = accountsResponse.data;
            const institutionId = item.institution_id;

            // Save each account to the database
            for (const account of accounts) {
                await AccountRepository.saveAccount(
                    userId,
                    itemId,
                    accessToken,
                    account.account_id,
                    account.name,
                    account.type,
                    institutionId
                );
            }

            return {
                accessToken,
                itemId,
                accounts
            };
        } catch (error) {
            throw new AppError(error.message, 500, 'INTERNAL_SERVER_ERROR');
        }
    }
}

module.exports = PlaidService; 