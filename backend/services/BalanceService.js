const AccountRepository = require('../repositories/AccountRepository');
const BalanceSnapshotRepository = require('../repositories/BalanceSnapshotRepository');

class BalanceService {
    async getCurrentBalancesForUser(userId) {
        try {
            // Get all accounts for the user
            const accounts = await AccountRepository.findAccountsByUserId(userId);
            
            if (accounts.length === 0) {
                return {
                    accounts: [],
                    totalBalance: 0
                };
            }

            // Get latest balance snapshot for each account
            const accountsWithBalances = [];
            let totalBalance = 0;

            for (const account of accounts) {
                const latestSnapshot = await BalanceSnapshotRepository.getLatestSnapshotForAccount(account.id);
                
                const currentBalance = latestSnapshot ? latestSnapshot.balance : 0;
                const lastUpdated = latestSnapshot ? latestSnapshot.snapshot_date : null;
                
                accountsWithBalances.push({
                    id: account.id,
                    name: account.account_name,
                    type: account.account_type,
                    institution: account.institution_name,
                    currentBalance: currentBalance,
                    lastUpdated: lastUpdated,
                    needsReauthentication: account.needs_reauthentication
                });

                totalBalance += currentBalance;
            }

            return {
                accounts: accountsWithBalances,
                totalBalance: totalBalance
            };
        } catch (error) {
            console.error('Error getting current balances for user:', error.message);
            throw error;
        }
    }
}

module.exports = BalanceService; 