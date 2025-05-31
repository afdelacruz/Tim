const db = require('../db');

class UserRepository {
    async createUser(email, pinHash) {
        const query = 'INSERT INTO users (email, pin_hash) VALUES ($1, $2) RETURNING *';
        const values = [email, pinHash];
        try {
            const { rows } = await db.query(query, values);
            return rows[0];
        } catch (err) {
            // Handle potential errors, e.g., duplicate email
            if (err.code === '23505') { // Unique violation
                throw new Error('Email already exists');
            }
            console.error('Error creating user:', err);
            throw new Error('Could not create user');
        }
    }

    async findUserByEmail(email) {
        const query = 'SELECT * FROM users WHERE email = $1';
        const values = [email];
        try {
            const { rows } = await db.query(query, values);
            return rows[0] || null;
        } catch (err) {
            console.error('Error finding user by email:', err);
            throw new Error('Could not find user by email');
        }
    }

    async findUserById(id) {
        const query = 'SELECT * FROM users WHERE id = $1';
        const values = [id];
        try {
            const { rows } = await db.query(query, values);
            return rows[0] || null;
        } catch (err) {
            console.error('Error finding user by id:', err);
            throw new Error('Could not find user by id');
        }
    }

    static async deleteUserByEmail(email) {
        const query = 'DELETE FROM users WHERE email = $1 RETURNING *';
        try {
            const { rows } = await db.pool.query(query, [email]);
            return rows[0]; // Returns the deleted user or undefined
        } catch (err) {
            console.error('Error deleting user by email:', err);
            throw new Error('Could not delete user by email');
        }
    }

    static async deleteAllUsers() {
        if (process.env.NODE_ENV !== 'test') {
            throw new Error('deleteAllUsers can only be run in test environment');
        }
        await db.query('DELETE FROM users');
    }
}

module.exports = UserRepository;
