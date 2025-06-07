#!/usr/bin/env node

/**
 * Manual Balance Update Script
 * 
 * This script manually triggers the balance update service to fetch
 * fresh balance data from Plaid for all connected accounts.
 * 
 * Usage:
 *   node scripts/update-balances.js
 */

// Load environment variables
require('dotenv').config();

const BalanceUpdateService = require('../services/BalanceUpdateService');

async function runBalanceUpdate() {
    console.log('🚀 Starting manual balance update...');
    console.log('📅 Timestamp:', new Date().toISOString());
    console.log('🌍 Environment:', process.env.PLAID_ENV || 'not set');
    console.log('');

    try {
        const balanceUpdateService = new BalanceUpdateService();
        
        console.log('🔄 Fetching balances from Plaid...');
        await balanceUpdateService.fetchAndStoreBalancesForAllUsers();
        
        console.log('');
        console.log('✅ Balance update completed successfully!');
        console.log('📊 Check your database for new balance snapshots');
        console.log('🎯 Your widget should now show updated data');
        
    } catch (error) {
        console.error('');
        console.error('❌ Balance update failed:');
        console.error('Error:', error.message);
        console.error('Stack:', error.stack);
        process.exit(1);
    }
}

// Run the update
runBalanceUpdate(); 