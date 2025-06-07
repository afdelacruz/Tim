#!/usr/bin/env node

/**
 * Calculate Widget Values Script
 * 
 * This script calculates the correct inflow/outflow values that should
 * be displayed in the widget based on account categorization and balances.
 */

const { Pool } = require('pg');

// Railway database connection
const RAILWAY_DB_URL = 'postgresql://postgres:EElVnDsTzkfcXoEgdMSyKjUMEdUBwGvn@caboose.proxy.rlwy.net:10065/railway';

async function calculateWidgetValues() {
    const pool = new Pool({
        connectionString: RAILWAY_DB_URL,
        ssl: { rejectUnauthorized: false }
    });

    try {
        console.log('🧮 Calculating Widget Values');
        console.log('============================');
        
        // Get user ID for test@example.com
        const userResult = await pool.query('SELECT id FROM users WHERE email = $1', ['test@example.com']);
        if (userResult.rows.length === 0) {
            console.log('❌ User test@example.com not found');
            return;
        }
        
        const userId = userResult.rows[0].id;
        console.log(`👤 User ID: ${userId}`);
        console.log('');

        // Get all accounts with their latest balances and categorization
        const accountsQuery = `
            SELECT 
                a.id,
                a.account_name,
                a.account_type,
                a.is_inflow,
                a.is_outflow,
                bs.balance as current_balance,
                bs.snapshot_date
            FROM accounts a
            LEFT JOIN balance_snapshots bs ON a.id = bs.account_id
            WHERE a.user_id = $1
            AND bs.snapshot_date = (
                SELECT MAX(snapshot_date) 
                FROM balance_snapshots bs2 
                WHERE bs2.account_id = a.id
            )
            ORDER BY a.account_name
        `;

        const accountsResult = await pool.query(accountsQuery, [userId]);
        const accounts = accountsResult.rows;

        console.log(`🏦 Found ${accounts.length} accounts with balance data:`);
        console.log('');

        let totalInflow = 0;
        let totalOutflow = 0;
        let uncategorizedAccounts = [];

        accounts.forEach(account => {
            const balance = parseFloat(account.current_balance) || 0;
            const category = account.is_inflow ? '📈 Inflow' : account.is_outflow ? '📉 Outflow' : '⚪ Uncategorized';
            
            console.log(`• ${account.account_name} (${account.account_type})`);
            console.log(`  Balance: $${balance.toLocaleString()}`);
            console.log(`  Category: ${category}`);
            
            if (account.is_inflow) {
                totalInflow += balance;
                console.log(`  ➕ Added to inflow: +$${balance.toLocaleString()}`);
            } else if (account.is_outflow) {
                totalOutflow += balance;
                console.log(`  ➖ Added to outflow: +$${balance.toLocaleString()}`);
            } else {
                uncategorizedAccounts.push({
                    name: account.account_name,
                    balance: balance,
                    type: account.account_type
                });
                console.log(`  ⚠️  Not included in widget (uncategorized)`);
            }
            console.log('');
        });

        console.log('📊 WIDGET CALCULATION RESULTS:');
        console.log('================================');
        console.log(`💚 Total Inflow:  $${totalInflow.toLocaleString()}`);
        console.log(`❤️  Total Outflow: $${totalOutflow.toLocaleString()}`);
        console.log('');

        console.log('🎯 WIDGET SHOULD DISPLAY:');
        console.log(`+$${Math.round(totalInflow).toLocaleString()}`);
        console.log(`-$${Math.round(totalOutflow).toLocaleString()}`);
        console.log('');

        console.log('📱 CURRENT WIDGET SHOWS:');
        console.log('+$2,340');
        console.log('-$1,890');
        console.log('');

        const inflowMatch = Math.round(totalInflow) === 2340;
        const outflowMatch = Math.round(totalOutflow) === 1890;

        if (inflowMatch && outflowMatch) {
            console.log('✅ Widget values are CORRECT!');
        } else {
            console.log('❌ Widget values are INCORRECT!');
            console.log('');
            console.log('🔧 CORRECTIONS NEEDED:');
            if (!inflowMatch) {
                console.log(`   Inflow: Should be $${Math.round(totalInflow).toLocaleString()} (currently shows $2,340)`);
            }
            if (!outflowMatch) {
                console.log(`   Outflow: Should be $${Math.round(totalOutflow).toLocaleString()} (currently shows $1,890)`);
            }
        }

        if (uncategorizedAccounts.length > 0) {
            console.log('');
            console.log('⚠️  UNCATEGORIZED ACCOUNTS (not included in widget):');
            uncategorizedAccounts.forEach(acc => {
                console.log(`   • ${acc.name} (${acc.type}): $${acc.balance.toLocaleString()}`);
            });
            console.log('');
            console.log('💡 Tip: Categorize these accounts in "Configure Categories" to include them in the widget');
        }

    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await pool.end();
    }
}

// Load environment variables
require('dotenv').config();

// Run the calculation
calculateWidgetValues(); 