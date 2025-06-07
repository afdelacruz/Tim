const { Pool } = require('pg');

async function setupRailwayDatabase() {
    // Use the public DATABASE_URL for Railway
    const DATABASE_PUBLIC_URL = 'postgresql://postgres:EElVnDsTzkfcXoEgdMSyKjUMEdUBwGvn@caboose.proxy.rlwy.net:10065/railway';
    
    const pool = new Pool({
        connectionString: DATABASE_PUBLIC_URL,
        ssl: { rejectUnauthorized: false }
    });

    try {
        console.log('Connecting to Railway database...');
        
        // ⚠️  WARNING: This will delete ALL existing data!
        console.log('⚠️  WARNING: About to drop all tables and data!');
        console.log('Press Ctrl+C within 5 seconds to cancel...');
        await new Promise(resolve => setTimeout(resolve, 5000));
        
        console.log('Dropping existing tables...');
        await pool.query('DROP TABLE IF EXISTS balance_snapshots CASCADE');
        await pool.query('DROP TABLE IF EXISTS accounts CASCADE');
        await pool.query('DROP TABLE IF EXISTS users CASCADE');
        
        console.log('Creating users table...');
        await pool.query(`
            CREATE TABLE users (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                email VARCHAR(255) UNIQUE NOT NULL,
                pin_hash VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT NOW()
            )
        `);
        
        console.log('Creating accounts table...');
        await pool.query(`
            CREATE TABLE accounts (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID REFERENCES users(id) ON DELETE CASCADE,
                plaid_item_id VARCHAR(255) NOT NULL,
                plaid_access_token VARCHAR(255) NOT NULL,
                plaid_account_id VARCHAR(255) NOT NULL,
                account_name VARCHAR(255),
                account_type VARCHAR(50),
                institution_name VARCHAR(255),
                is_inflow BOOLEAN DEFAULT false,
                is_outflow BOOLEAN DEFAULT false,
                created_at TIMESTAMP DEFAULT NOW(),
                needs_reauthentication BOOLEAN DEFAULT false
            )
        `);
        
        console.log('Creating balance_snapshots table...');
        await pool.query(`
            CREATE TABLE balance_snapshots (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
                balance DECIMAL(12,2) NOT NULL,
                snapshot_date DATE NOT NULL,
                created_at TIMESTAMP DEFAULT NOW(),
                UNIQUE(account_id, snapshot_date)
            )
        `);
        
        console.log('✅ Railway database setup complete!');
        
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
        console.error('❌ Railway database setup failed:', error.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

setupRailwayDatabase(); 