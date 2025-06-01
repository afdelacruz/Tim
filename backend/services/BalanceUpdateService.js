const { PlaidApi, Configuration, PlaidEnvironments } = require('plaid');
const AccountRepository = require('../repositories/AccountRepository');
const BalanceSnapshotRepository = require('../repositories/BalanceSnapshotRepository');

class BalanceUpdateService {
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

    async fetchAndStoreBalancesForAllUsers() {
        try {
            // Get all active accounts (not needing re-authentication)
            const accounts = await AccountRepository.findAllActiveAccounts();
            
            if (accounts.length === 0) {
                return; // Nothing to process
            }

            // Group accounts by access token to minimize API calls
            const accountsByToken = {};
            for (const account of accounts) {
                if (!accountsByToken[account.plaid_access_token]) {
                    accountsByToken[account.plaid_access_token] = [];
                }
                accountsByToken[account.plaid_access_token].push(account);
            }

            // Process each access token
            for (const [accessToken, tokenAccounts] of Object.entries(accountsByToken)) {
                await this.fetchBalancesForToken(accessToken, tokenAccounts);
            }
        } catch (error) {
            console.error('Error in fetchAndStoreBalancesForAllUsers:', error.message);
        }
    }

    async fetchBalancesForToken(accessToken, accounts) {
        try {
            // Fetch balances from Plaid
            const response = await this.client.accountsBalanceGet({
                access_token: accessToken
            });

            const plaidAccounts = response.data.accounts;
            const today = new Date();

            // Process each account
            for (const account of accounts) {
                const plaidAccount = plaidAccounts.find(pa => pa.account_id === account.plaid_account_id);
                if (plaidAccount && plaidAccount.balances && plaidAccount.balances.current !== null) {
                    // Save balance snapshot
                    await BalanceSnapshotRepository.saveSnapshot(
                        account.id,
                        plaidAccount.balances.current,
                        today
                    );
                }
            }

            // Clear re-authentication flag for this item (all accounts with same item_id)
            const itemId = accounts[0].plaid_item_id; // All accounts in this group have same item_id
            await AccountRepository.setNeedsReauthentication(itemId, false);

        } catch (error) {
            // Check if this is a re-authentication error
            if (error.error_code === 'ITEM_LOGIN_REQUIRED') {
                console.error('Plaid item requires re-authentication:', accounts[0].plaid_item_id);
                // Set re-authentication flag for this item
                await AccountRepository.setNeedsReauthentication(accounts[0].plaid_item_id, true);
            } else {
                console.error('Error fetching balances:', error.message);
            }
        }
    }
}

module.exports = BalanceUpdateService; 