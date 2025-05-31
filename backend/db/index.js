const { Pool } = require('pg');
require('dotenv').config({ path: '../.env' }); // Ensure .env from backend folder is loaded

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    // SSL configuration for production (e.g., on Railway)
    // Heroku and Railway typically require SSL and set DATABASE_URL accordingly.
    // For local development, ssl might not be needed or might need rejectUnauthorized: false
    // depending on your local Postgres setup.
    // Railway provides a DATABASE_URL that usually works out of the box with SSL.
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

pool.on('connect', () => {
    console.log('Database pool connected');
});

pool.on('error', (err) => {
    console.error('Unexpected error on idle client', err);
    process.exit(-1);
});

module.exports = {
    query: (text, params) => pool.query(text, params),
    pool, // Export the pool itself if needed for transactions etc.
}; 