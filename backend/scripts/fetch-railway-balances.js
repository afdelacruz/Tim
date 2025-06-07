#!/usr/bin/env node

/**
 * Fetch Balances from Railway Database
 * 
 * This script connects directly to Railway database to fetch balances
 * for accounts stored there, bypassing local database issues.
 */

const { Pool } = require('pg');
const { PlaidApi, Configuration, PlaidEnvironments } = require('plaid');

// Railway database connection
const RAILWAY_DB_URL = 'postgresql://postgres:EElVnDsTzkfcXoEgdMSyKjUMEdUBwGvn@caboose.proxy.rlwy.net:10065/railway';

async function fetchRailwayBalances() {
    const pool = new Pool({
        connectionString: RAILWAY_DB_URL,
        ssl: { rejectUnauthorized: false }
    });

    // Plaid client configuration
    const configuration = new Configuration({
        basePath: PlaidEnvironments.sandbox,
        baseOptions: {
            headers: {
                'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID,
                'PLAID-SECRET': process.env.PLAID_SECRET,
            },
        },
    });
    const plaidClient = new PlaidApi(configuration);

    try {
        console.log('🚂 Connecting to Railway database...');
        
        // Get all accounts from Railway
        const accountsResult = await pool.query('SELECT * FROM accounts WHERE needs_reauthentication = false');
        console.log(`🏦 Found ${accountsResult.rows.length} active accounts`);

        if (accountsResult.rows.length === 0) {
            console.log('❌ No active accounts found');
            return;
        }

        // Group accounts by access token
        const accountsByToken = {};
        for (const account of accountsResult.rows) {
            if (!accountsByToken[account.plaid_access_token]) {
                accountsByToken[account.plaid_access_token] = [];
            }
            accountsByToken[account.plaid_access_token].push(account);
        }

        console.log('💰 Fetching balances from Plaid...');

        // Process each access token
        for (const [accessToken, tokenAccounts] of Object.entries(accountsByToken)) {
            try {
                // Fetch balances from Plaid
                const response = await plaidClient.accountsBalanceGet({
                    access_token: accessToken
                });

                const plaidAccounts = response.data.accounts;
                const today = new Date();

                console.log(`📊 Processing ${tokenAccounts.length} accounts...`);

                // Process each account
                for (const account of tokenAccounts) {
                    const plaidAccount = plaidAccounts.find(pa => pa.account_id === account.plaid_account_id);
                    if (plaidAccount && plaidAccount.balances && plaidAccount.balances.current !== null) {
                        // Save balance snapshot
                        await pool.query(
                            'INSERT INTO balance_snapshots (account_id, balance, snapshot_date) VALUES ($1, $2, $3) ON CONFLICT (account_id, snapshot_date) DO UPDATE SET balance = $2',
                            [account.id, plaidAccount.balances.current, today]
                        );
                        
                        console.log(`   ✅ ${account.account_name}: $${plaidAccount.balances.current.toLocaleString()}`);
                    }
                }

            } catch (error) {
                console.error(`❌ Error fetching balances for token: ${error.message}`);
            }
        }

        console.log('\n🎯 Balance fetch complete! Showing updated balances:');
        
        // Show final balances
        const balancesResult = await pool.query(`
            SELECT a.account_name, a.account_type, a.is_inflow, a.is_outflow, bs.balance, bs.snapshot_date 
            FROM accounts a 
            LEFT JOIN balance_snapshots bs ON a.id = bs.account_id 
            ORDER BY a.account_name
        `);

        console.log('\n💰 Current Account Balances:');
        balancesResult.rows.forEach(acc => {
            const balance = acc.balance ? `$${parseFloat(acc.balance).toLocaleString()}` : 'No balance';
            const category = acc.is_inflow ? '📈 Inflow' : acc.is_outflow ? '📉 Outflow' : '⚪ Uncategorized';
            console.log(`   • ${acc.account_name} (${acc.account_type}): ${balance} - ${category}`);
        });

    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await pool.end();
    }
}

// Load environment variables
require('dotenv').config();

// Run the script
fetchRailwayBalances(); 