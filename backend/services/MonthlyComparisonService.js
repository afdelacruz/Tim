const AccountRepository = require('../repositories/AccountRepository');
const BalanceSnapshotRepository = require('../repositories/BalanceSnapshotRepository');

class MonthlyComparisonService {
    constructor() {
        this.accountRepository = AccountRepository;
        this.balanceSnapshotRepository = BalanceSnapshotRepository;
    }

    /**
     * Get monthly balance comparison for a user
     * @param {string} userId - The user ID
     * @param {Date} referenceDate - The reference date (defaults to current date)
     * @returns {Object} Monthly comparison data
     */
    async getMonthlyComparison(userId, referenceDate = new Date()) {
        // Calculate current and previous month
        const currentMonth = {
            year: referenceDate.getFullYear(),
            month: referenceDate.getMonth() + 1 // JavaScript months are 0-indexed
        };
        
        const previousMonth = this._getPreviousMonth(currentMonth);

        // Get all accounts for the user
        const accounts = await this.accountRepository.findAccountsByUserId(userId);
        
        if (accounts.length === 0) {
            return this._createEmptyComparison(currentMonth, previousMonth);
        }

        // Get balance data for both months
        const currentMonthData = await this._getMonthBalanceData(accounts, currentMonth);
        const previousMonthData = await this._getMonthBalanceData(accounts, previousMonth);

        // Calculate comparison metrics
        const comparison = this._calculateComparison(currentMonthData, previousMonthData);

        return {
            currentMonth: {
                year: currentMonth.year,
                month: currentMonth.month,
                monthName: this._getMonthName(currentMonth.month),
                totalBalance: currentMonthData.totalBalance,
                accounts: currentMonthData.accounts
            },
            previousMonth: {
                year: previousMonth.year,
                month: previousMonth.month,
                monthName: this._getMonthName(previousMonth.month),
                totalBalance: previousMonthData.totalBalance,
                accounts: previousMonthData.accounts
            },
            comparison
        };
    }

    /**
     * Get balance data for a specific month
     * @param {Array} accounts - Array of user accounts
     * @param {Object} monthInfo - Object with year and month
     * @returns {Object} Month balance data
     */
    async _getMonthBalanceData(accounts, monthInfo) {
        const accountBalances = [];
        let totalBalance = 0;

        for (const account of accounts) {
            const snapshot = await this.balanceSnapshotRepository.getFirstSnapshotForAccountInMonth(
                account.id,
                monthInfo.year,
                monthInfo.month
            );

            const balance = snapshot ? parseFloat(snapshot.balance) : 0;
            totalBalance += balance;

            accountBalances.push({
                id: account.id,
                name: account.account_name,
                balance: parseFloat(balance.toFixed(2))
            });
        }

        return {
            totalBalance: parseFloat(totalBalance.toFixed(2)),
            accounts: accountBalances
        };
    }

    /**
     * Calculate comparison metrics between two months
     * @param {Object} currentData - Current month data
     * @param {Object} previousData - Previous month data
     * @returns {Object} Comparison metrics
     */
    _calculateComparison(currentData, previousData) {
        const totalChange = currentData.totalBalance - previousData.totalBalance;
        const percentageChange = previousData.totalBalance === 0 
            ? (currentData.totalBalance > 0 ? 100 : 0)
            : (totalChange / previousData.totalBalance) * 100;

        const trend = totalChange > 0 ? 'increase' : 
                     totalChange < 0 ? 'decrease' : 'no_change';

        // Calculate account-level changes
        const accountChanges = currentData.accounts.map(currentAccount => {
            const previousAccount = previousData.accounts.find(acc => acc.id === currentAccount.id);
            const previousBalance = previousAccount ? previousAccount.balance : 0;
            const change = currentAccount.balance - previousBalance;
            const accountPercentageChange = previousBalance === 0 
                ? (currentAccount.balance > 0 ? 100 : 0)
                : (change / previousBalance) * 100;

            return {
                id: currentAccount.id,
                name: currentAccount.name,
                change: parseFloat(change.toFixed(2)),
                percentageChange: parseFloat(accountPercentageChange.toFixed(2))
            };
        });

        return {
            totalChange: parseFloat(totalChange.toFixed(2)),
            percentageChange: parseFloat(percentageChange.toFixed(2)),
            trend,
            accountChanges
        };
    }

    /**
     * Get the previous month from a given month
     * @param {Object} currentMonth - Object with year and month
     * @returns {Object} Previous month object
     */
    _getPreviousMonth(currentMonth) {
        if (currentMonth.month === 1) {
            return {
                year: currentMonth.year - 1,
                month: 12
            };
        }
        return {
            year: currentMonth.year,
            month: currentMonth.month - 1
        };
    }

    /**
     * Get month name from month number
     * @param {number} monthNumber - Month number (1-12)
     * @returns {string} Month name
     */
    _getMonthName(monthNumber) {
        const months = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return months[monthNumber - 1];
    }

    /**
     * Create empty comparison structure
     * @param {Object} currentMonth - Current month info
     * @param {Object} previousMonth - Previous month info
     * @returns {Object} Empty comparison structure
     */
    _createEmptyComparison(currentMonth, previousMonth) {
        return {
            currentMonth: {
                year: currentMonth.year,
                month: currentMonth.month,
                monthName: this._getMonthName(currentMonth.month),
                totalBalance: 0,
                accounts: []
            },
            previousMonth: {
                year: previousMonth.year,
                month: previousMonth.month,
                monthName: this._getMonthName(previousMonth.month),
                totalBalance: 0,
                accounts: []
            },
            comparison: {
                totalChange: 0,
                percentageChange: 0,
                trend: 'no_change',
                accountChanges: []
            }
        };
    }
}

module.exports = MonthlyComparisonService; 