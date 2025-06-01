const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

async function setupDatabase() {
    // Use the same DATABASE_URL that your app uses
    const pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
    });

    try {
        console.log('Connecting to database...');
        
        // Read the schema file
        const schemaPath = path.join(__dirname, '..', 'db', 'schema.sql');
        const schema = fs.readFileSync(schemaPath, 'utf8');
        
        console.log('Creating tables...');
        
        // Drop existing tables first (for clean setup)
        await pool.query('DROP TABLE IF EXISTS balance_snapshots CASCADE');
        await pool.query('DROP TABLE IF EXISTS accounts CASCADE');
        await pool.query('DROP TABLE IF EXISTS users CASCADE');
        
        // Create tables
        await pool.query(schema);
        
        console.log('✅ Database setup complete!');
        
        // Verify tables were created
        const result = await pool.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name
        `);
        
        console.log('📋 Created tables:');
        result.rows.forEach(row => {
            console.log(`  - ${row.table_name}`);
        });
        
    } catch (error) {
        console.error('❌ Database setup failed:', error.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

// Load environment variables
require('dotenv').config();

setupDatabase(); 