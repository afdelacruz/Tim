const AccountRepository = require('../repositories/AccountRepository');
const BalanceSnapshotRepository = require('../repositories/BalanceSnapshotRepository');

class BalanceHistoryService {
    constructor() {
        this.accountRepository = AccountRepository;
        this.balanceSnapshotRepository = BalanceSnapshotRepository;
    }

    /**
     * Get balance history for a user within a date range
     * @param {string} userId - The user ID
     * @param {string} startDate - Start date in YYYY-MM-DD format (optional, defaults to 30 days ago)
     * @param {string} endDate - End date in YYYY-MM-DD format (optional, defaults to today)
     * @returns {Object} Balance history data
     */
    async getBalanceHistoryForUser(userId, startDate = null, endDate = null) {
        // Set default date range if not provided (last 30 days)
        if (!startDate || !endDate) {
            const today = new Date();
            const thirtyDaysAgo = new Date(today);
            thirtyDaysAgo.setDate(today.getDate() - 30);
            
            endDate = endDate || today.toISOString().split('T')[0];
            startDate = startDate || thirtyDaysAgo.toISOString().split('T')[0];
        }

        // Get all accounts for the user
        const accounts = await this.accountRepository.findAccountsByUserId(userId);
        
        if (accounts.length === 0) {
            return {
                dateRange: { startDate, endDate },
                accounts: [],
                totalHistory: []
            };
        }

        // Get account IDs
        const accountIds = accounts.map(account => account.id);

        // Get balance snapshots for all accounts in the date range
        const snapshots = await this.balanceSnapshotRepository.getSnapshotsInDateRange(
            accountIds,
            startDate,
            endDate
        );

        // Group snapshots by account
        const snapshotsByAccount = this._groupSnapshotsByAccount(snapshots);

        // Build account history data
        const accountsWithHistory = accounts.map(account => ({
            id: account.id,
            name: account.account_name,
            type: account.account_type,
            institution: account.institution_name,
            history: (snapshotsByAccount[account.id] || []).map(snapshot => ({
                date: snapshot.snapshot_date,
                balance: parseFloat(snapshot.balance)
            }))
        }));

        // Calculate total balance history
        const totalHistory = this._calculateTotalHistory(snapshots);

        return {
            dateRange: { startDate, endDate },
            accounts: accountsWithHistory,
            totalHistory
        };
    }

    /**
     * Group snapshots by account ID
     * @param {Array} snapshots - Array of balance snapshots
     * @returns {Object} Snapshots grouped by account ID
     */
    _groupSnapshotsByAccount(snapshots) {
        return snapshots.reduce((groups, snapshot) => {
            const accountId = snapshot.account_id;
            if (!groups[accountId]) {
                groups[accountId] = [];
            }
            groups[accountId].push(snapshot);
            return groups;
        }, {});
    }

    /**
     * Calculate total balance history across all accounts
     * @param {Array} snapshots - Array of balance snapshots
     * @returns {Array} Total balance history
     */
    _calculateTotalHistory(snapshots) {
        // Group snapshots by date
        const snapshotsByDate = snapshots.reduce((groups, snapshot) => {
            const date = snapshot.snapshot_date;
            if (!groups[date]) {
                groups[date] = [];
            }
            groups[date].push(snapshot);
            return groups;
        }, {});

        // Calculate total balance for each date
        const totalHistory = Object.keys(snapshotsByDate)
            .sort()
            .map(date => {
                const totalBalance = snapshotsByDate[date].reduce((sum, snapshot) => {
                    return sum + parseFloat(snapshot.balance);
                }, 0);
                
                return {
                    date,
                    totalBalance: parseFloat(totalBalance.toFixed(2))
                };
            });

        return totalHistory;
    }
}

module.exports = BalanceHistoryService; 