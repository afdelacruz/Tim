const db = require('../db');

// Helper to format JS Date to YYYY-MM-DD string, crucial for DATE columns
const formatDateToYYYYMMDD = (date) => {
    if (!date || !(date instanceof Date)) {
        // Allow string if it's already YYYY-MM-DD for flexibility, though primarily expects Date object
        if (typeof date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(date)) {
            return date;
        }
        throw new Error('Invalid date provided to formatDateToYYYYMMDD');
    }
    return date.toISOString().split('T')[0];
};

class BalanceSnapshotRepository {
    async saveSnapshot(accountId, balance, snapshotDate) {
        const formattedDate = formatDateToYYYYMMDD(snapshotDate);
        const query = 'INSERT INTO balance_snapshots (account_id, balance, snapshot_date) VALUES ($1, $2, $3) RETURNING *';
        const values = [accountId, balance, formattedDate];
        try {
            const { rows } = await db.query(query, values);
            return rows[0];
        } catch (err) {
            if (err.code === '23505') { // Unique constraint (account_id, snapshot_date)
                throw new Error('Snapshot for this account on this date already exists.');
            }
            console.error('Error saving balance snapshot:', err);
            throw new Error('Could not save balance snapshot');
        }
    }

    async getLatestSnapshotForAccount(accountId) {
        const query = 'SELECT * FROM balance_snapshots WHERE account_id = $1 ORDER BY snapshot_date DESC LIMIT 1';
        const values = [accountId];
        try {
            const { rows } = await db.query(query, values);
            return rows[0] || null;
        } catch (err) {
            console.error('Error getting latest snapshot:', err);
            throw new Error('Could not get latest snapshot');
        }
    }

    async getSnapshotForAccountOnDate(accountId, date) {
        const formattedDate = formatDateToYYYYMMDD(date);
        const query = 'SELECT * FROM balance_snapshots WHERE account_id = $1 AND snapshot_date = $2';
        const values = [accountId, formattedDate];
        try {
            const { rows } = await db.query(query, values);
            return rows[0] || null;
        } catch (err) {
            console.error('Error getting snapshot for account on date:', err);
            throw new Error('Could not get snapshot for account on date');
        }
    }

    async getFirstSnapshotForAccountInMonth(accountId, year, month) {
        const formattedMonth = month.toString().padStart(2, '0');
        const startDate = `${year}-${formattedMonth}-01`;
        const query = `
            SELECT * FROM balance_snapshots 
            WHERE account_id = $1 
            AND snapshot_date >= $2
            AND snapshot_date < date_trunc('month', $2::date) + interval '1 month'
            ORDER BY snapshot_date ASC 
            LIMIT 1
        `;
        const values = [accountId, startDate];
        try {
            const { rows } = await db.query(query, values);
            return rows[0] || null;
        } catch (err) {
            console.error('Error getting first snapshot for account in month:', err);
            throw new Error('Could not get first snapshot for account in month');
        }
    }

    // Helper for tests to clean up
    async deleteAllBalanceSnapshots() {
        if (process.env.NODE_ENV !== 'test') {
            throw new Error('deleteAllBalanceSnapshots can only be run in test environment');
        }
        await db.query('DELETE FROM balance_snapshots');
    }
}

module.exports = new BalanceSnapshotRepository();