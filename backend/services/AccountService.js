const AccountRepository = require('../repositories/AccountRepository');
const BalanceSnapshotRepository = require('../repositories/BalanceSnapshotRepository');
const { AppError } = require('../utils/errorHandler');

class AccountService {
    constructor() {
        this.accountRepository = AccountRepository;
        this.balanceSnapshotRepository = BalanceSnapshotRepository;
    }

    /**
     * Get all accounts for a user with their current balances
     * @param {string} userId - The user ID
     * @returns {Array} Array of accounts with balance information
     */
    async getUserAccounts(userId) {
        const accounts = await this.accountRepository.findAccountsByUserId(userId);
        
        if (accounts.length === 0) {
            return [];
        }

        // Get current balance for each account
        const accountsWithBalances = await Promise.all(
            accounts.map(async (account) => {
                const latestSnapshot = await this.balanceSnapshotRepository.getLatestSnapshotForAccount(account.id);
                
                return {
                    id: account.id,
                    accountId: account.account_id,
                    name: account.account_name,
                    nickname: account.nickname,
                    type: account.account_type,
                    subtype: account.account_subtype,
                    institutionName: account.institution_name,
                    mask: account.mask,
                    isActive: account.is_active,
                    isInflow: account.is_inflow || false,
                    isOutflow: account.is_outflow || false,
                    currentBalance: latestSnapshot ? parseFloat(latestSnapshot.balance) : 0,
                    lastUpdated: latestSnapshot ? latestSnapshot.snapshot_date : null,
                    needsReauth: account.needs_reauth || false,
                    createdAt: account.created_at,
                    updatedAt: account.updated_at
                };
            })
        );

        return accountsWithBalances;
    }

    /**
     * Update account settings
     * @param {string} accountId - The account ID
     * @param {string} userId - The user ID (for authorization)
     * @param {Object} updates - The updates to apply
     * @returns {Object} Updated account information
     */
    async updateAccount(accountId, userId, updates) {
        // Verify account belongs to user
        const account = await this.accountRepository.findAccountById(accountId);
        if (!account) {
            throw new AppError('Account not found', 404);
        }

        if (account.user_id !== userId) {
            throw new AppError('Unauthorized to modify this account', 403);
        }

        // Validate and sanitize updates
        const allowedUpdates = ['nickname', 'is_active', 'is_inflow', 'is_outflow'];
        const sanitizedUpdates = {};

        for (const [key, value] of Object.entries(updates)) {
            if (allowedUpdates.includes(key)) {
                if (key === 'nickname') {
                    // Validate nickname length and content
                    if (typeof value !== 'string' || value.length > 50) {
                        throw new AppError('Nickname must be a string with maximum 50 characters', 400);
                    }
                    sanitizedUpdates.nickname = value.trim();
                } else if (key === 'is_active') {
                    // Validate boolean
                    if (typeof value !== 'boolean') {
                        throw new AppError('is_active must be a boolean value', 400);
                    }
                    sanitizedUpdates.is_active = value;
                } else if (key === 'is_inflow' || key === 'is_outflow') {
                    // Validate boolean for category fields
                    if (typeof value !== 'boolean') {
                        throw new AppError(`${key} must be a boolean value`, 400);
                    }
                    sanitizedUpdates[key] = value;
                }
            }
        }

        if (Object.keys(sanitizedUpdates).length === 0) {
            throw new AppError('No valid updates provided', 400);
        }

        // Update the account
        const updatedAccount = await this.accountRepository.updateAccount(accountId, sanitizedUpdates);
        
        // Return the updated account with balance information
        return this.getUserAccountById(accountId, userId);
    }

    /**
     * Get a single account by ID for a user
     * @param {string} accountId - The account ID
     * @param {string} userId - The user ID (for authorization)
     * @returns {Object} Account with balance information
     */
    async getUserAccountById(accountId, userId) {
        const account = await this.accountRepository.findAccountById(accountId);
        
        if (!account) {
            throw new AppError('Account not found', 404);
        }

        if (account.user_id !== userId) {
            throw new AppError('Unauthorized to access this account', 403);
        }

        const latestSnapshot = await this.balanceSnapshotRepository.getLatestSnapshotForAccount(account.id);
        
        return {
            id: account.id,
            accountId: account.account_id,
            name: account.account_name,
            nickname: account.nickname,
            type: account.account_type,
            subtype: account.account_subtype,
            institutionName: account.institution_name,
            mask: account.mask,
            isActive: account.is_active,
            isInflow: account.is_inflow || false,
            isOutflow: account.is_outflow || false,
            currentBalance: latestSnapshot ? parseFloat(latestSnapshot.balance) : 0,
            lastUpdated: latestSnapshot ? latestSnapshot.snapshot_date : null,
            needsReauth: account.needs_reauth || false,
            createdAt: account.created_at,
            updatedAt: account.updated_at
        };
    }

    /**
     * Update account categories (inflow/outflow settings)
     * @param {string} accountId - The account ID
     * @param {string} userId - The user ID (for authorization)
     * @param {Object} categoryUpdates - The category updates { is_inflow, is_outflow }
     * @returns {Object} Updated account information
     */
    async updateAccountCategories(accountId, userId, categoryUpdates) {
        // Verify account belongs to user
        const account = await this.accountRepository.findAccountById(accountId);
        if (!account) {
            throw new AppError('Account not found', 404);
        }

        if (account.user_id !== userId) {
            throw new AppError('Unauthorized to modify this account', 403);
        }

        // Validate category updates
        const { is_inflow, is_outflow } = categoryUpdates;
        
        if (typeof is_inflow !== 'boolean' || typeof is_outflow !== 'boolean') {
            throw new AppError('Both is_inflow and is_outflow must be boolean values', 400);
        }

        // Update the account categories
        const updates = {
            is_inflow,
            is_outflow,
            updated_at: new Date()
        };

        await this.accountRepository.updateAccount(accountId, updates);
        
        // Return success response
        return {
            success: true,
            message: 'Account categories updated successfully',
            accountId: accountId,
            categories: {
                is_inflow,
                is_outflow
            }
        };
    }

    /**
     * Deactivate an account (soft delete)
     * @param {string} accountId - The account ID
     * @param {string} userId - The user ID (for authorization)
     * @returns {Object} Success message
     */
    async deactivateAccount(accountId, userId) {
        // Verify account belongs to user
        const account = await this.accountRepository.findAccountById(accountId);
        if (!account) {
            throw new AppError('Account not found', 404);
        }

        if (account.user_id !== userId) {
            throw new AppError('Unauthorized to modify this account', 403);
        }

        if (!account.is_active) {
            throw new AppError('Account is already deactivated', 400);
        }

        // Deactivate the account
        await this.accountRepository.updateAccount(accountId, { 
            is_active: false,
            updated_at: new Date()
        });

        return {
            success: true,
            message: 'Account deactivated successfully',
            accountId: accountId
        };
    }

    /**
     * Get account statistics for a user
     * @param {string} userId - The user ID
     * @returns {Object} Account statistics
     */
    async getAccountStatistics(userId) {
        const accounts = await this.getUserAccounts(userId);
        
        const stats = {
            totalAccounts: accounts.length,
            activeAccounts: accounts.filter(acc => acc.isActive).length,
            inactiveAccounts: accounts.filter(acc => !acc.isActive).length,
            accountsNeedingReauth: accounts.filter(acc => acc.needsReauth).length,
            totalBalance: accounts.reduce((sum, acc) => sum + acc.currentBalance, 0),
            accountsByType: {},
            accountsByInstitution: {}
        };

        // Group by account type
        accounts.forEach(account => {
            const type = account.type || 'unknown';
            if (!stats.accountsByType[type]) {
                stats.accountsByType[type] = {
                    count: 0,
                    totalBalance: 0
                };
            }
            stats.accountsByType[type].count++;
            stats.accountsByType[type].totalBalance += account.currentBalance;
        });

        // Group by institution
        accounts.forEach(account => {
            const institution = account.institutionName || 'unknown';
            if (!stats.accountsByInstitution[institution]) {
                stats.accountsByInstitution[institution] = {
                    count: 0,
                    totalBalance: 0
                };
            }
            stats.accountsByInstitution[institution].count++;
            stats.accountsByInstitution[institution].totalBalance += account.currentBalance;
        });

        // Round total balance
        stats.totalBalance = parseFloat(stats.totalBalance.toFixed(2));

        return stats;
    }
}

module.exports = AccountService; 