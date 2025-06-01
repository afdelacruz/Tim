const db = require('../db');

class AccountRepository {
    async saveAccount(userId, plaidItemId, plaidAccessToken, plaidAccountId, accountName, accountType, institutionName) {
        const query = `
            INSERT INTO accounts 
                (user_id, plaid_item_id, plaid_access_token, plaid_account_id, account_name, account_type, institution_name)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
        `;
        const values = [userId, plaidItemId, plaidAccessToken, plaidAccountId, accountName, accountType, institutionName];
        try {
            const { rows } = await db.query(query, values);
            return rows[0];
        } catch (err) {
            console.error('Error saving account:', err);
            throw new Error('Could not save account');
        }
    }

    async findAccountsByUserId(userId) {
        const query = 'SELECT * FROM accounts WHERE user_id = $1';
        const values = [userId];
        try {
            const { rows } = await db.query(query, values);
            return rows;
        } catch (err) {
            console.error('Error finding accounts by user ID:', err);
            throw new Error('Could not find accounts by user ID');
        }
    }

    async findAllActiveAccounts() {
        const query = 'SELECT * FROM accounts WHERE needs_reauthentication = false';
        try {
            const { rows } = await db.query(query);
            return rows;
        } catch (err) {
            console.error('Error finding all active accounts:', err);
            throw new Error('Could not find all active accounts');
        }
    }

    async findAccountById(accountId) { // Helper that might be useful
        const query = 'SELECT * FROM accounts WHERE id = $1';
        const values = [accountId];
        try {
            const { rows } = await db.query(query, values);
            return rows[0] || null;
        } catch (err) {
            console.error('Error finding account by ID:', err);
            throw new Error('Could not find account by ID');
        }
    }

    async updateAccount(accountId, updates) {
        const allowedFields = ['nickname', 'is_active', 'is_inflow', 'is_outflow', 'updated_at'];
        const updateFields = [];
        const values = [];
        let paramIndex = 1;

        for (const [key, value] of Object.entries(updates)) {
            if (allowedFields.includes(key)) {
                updateFields.push(`${key} = $${paramIndex}`);
                values.push(value);
                paramIndex++;
            }
        }

        if (updateFields.length === 0) {
            throw new Error('No valid fields to update');
        }

        // Add updated_at if not already included
        if (!updates.updated_at) {
            updateFields.push(`updated_at = $${paramIndex}`);
            values.push(new Date());
            paramIndex++;
        }

        values.push(accountId); // Add accountId as the last parameter
        const query = `UPDATE accounts SET ${updateFields.join(', ')} WHERE id = $${paramIndex} RETURNING *`;

        try {
            const { rows } = await db.query(query, values);
            return rows[0] || null;
        } catch (err) {
            console.error('Error updating account:', err);
            throw new Error('Could not update account');
        }
    }

    async updateAccountCategories(accountId, isInflow, isOutflow) {
        const query = 'UPDATE accounts SET is_inflow = $1, is_outflow = $2 WHERE id = $3 RETURNING *';
        const values = [isInflow, isOutflow, accountId];
        try {
            const { rows } = await db.query(query, values);
            return rows[0] || null;
        } catch (err) {
            console.error('Error updating account categories:', err);
            throw new Error('Could not update account categories');
        }
    }

    async setNeedsReauthentication(plaidItemId, needsReauthValue) {
        const query = 'UPDATE accounts SET needs_reauthentication = $1 WHERE plaid_item_id = $2 RETURNING *';
        const values = [needsReauthValue, plaidItemId];
        try {
            const { rows } = await db.query(query, values);
            return rows; // Returns an array of updated accounts for that item
        } catch (err) {
            console.error('Error setting needs_reauthentication flag:', err);
            throw new Error('Could not set needs_reauthentication flag');
        }
    }

    // Helper for tests to clean up
    async deleteAllAccounts() {
        if (process.env.NODE_ENV !== 'test') {
            throw new Error('deleteAllAccounts can only be run in test environment');
        }
        await db.query('DELETE FROM accounts');
    }

    async deleteAccountsByUserId(userId) {
        if (process.env.NODE_ENV !== 'test') {
            throw new Error('deleteAccountsByUserId can only be run in test environment');
        }
        const query = 'DELETE FROM accounts WHERE user_id = $1';
        try {
            await db.pool.query(query, [userId]);
        } catch (err) {
            console.error(`Error deleting accounts for user ${userId}:`, err);
            throw new Error('Could not delete accounts for user');
        }
    }

    async deleteAccountById(id) {
        const query = 'DELETE FROM accounts WHERE id = $1 RETURNING *';
        try {
            const { rows } = await db.pool.query(query, [id]);
            return rows[0];
        } catch (err) {
            console.error(`Error deleting account by id ${id}:`, err);
            throw new Error('Could not delete account by id');
        }
    }
}

module.exports = new AccountRepository();
