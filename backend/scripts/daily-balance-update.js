#!/usr/bin/env node

/**
 * Daily Balance Update Script with Scheduling
 * 
 * This script can be run manually or scheduled to run automatically.
 * It fetches fresh balance data and provides detailed logging.
 * 
 * Usage:
 *   node scripts/daily-balance-update.js           # Run once
 *   node scripts/daily-balance-update.js --watch   # Run every hour
 */

// Load environment variables
require('dotenv').config();

const BalanceUpdateService = require('../services/BalanceUpdateService');
const AccountRepository = require('../repositories/AccountRepository');

class DailyBalanceUpdater {
    constructor() {
        this.balanceUpdateService = new BalanceUpdateService();
        this.isWatching = process.argv.includes('--watch');
    }

    async run() {
        console.log('🚀 Tim Balance Updater Started');
        console.log('📅 Timestamp:', new Date().toISOString());
        console.log('🌍 Environment:', process.env.PLAID_ENV || 'not set');
        console.log('⏰ Mode:', this.isWatching ? 'Continuous (every hour)' : 'Single run');
        console.log('');

        if (this.isWatching) {
            console.log('🔄 Starting continuous mode...');
            this.startWatching();
        } else {
            await this.performUpdate();
        }
    }

    startWatching() {
        // Run immediately
        this.performUpdate();
        
        // Then run every hour
        setInterval(() => {
            console.log('\n⏰ Hourly update triggered...');
            this.performUpdate();
        }, 60 * 60 * 1000); // 1 hour in milliseconds

        console.log('✅ Continuous mode active. Updates will run every hour.');
        console.log('💡 Press Ctrl+C to stop');
    }

    async performUpdate() {
        try {
            console.log('📊 Checking connected accounts...');
            
            // Get account summary first
            const accounts = await AccountRepository.findAllActiveAccounts();
            console.log(`🏦 Found ${accounts.length} active accounts`);
            
            if (accounts.length === 0) {
                console.log('⚠️  No accounts connected. Connect some sandbox accounts first!');
                console.log('💡 Run your iOS app and use "Connect Bank Account"');
                return;
            }

            // Group by institution for better logging
            const institutionGroups = {};
            accounts.forEach(account => {
                const inst = account.institution_name || 'Unknown Bank';
                if (!institutionGroups[inst]) institutionGroups[inst] = [];
                institutionGroups[inst].push(account);
            });

            console.log('🏛️  Connected Institutions:');
            Object.entries(institutionGroups).forEach(([inst, accts]) => {
                console.log(`   • ${inst}: ${accts.length} accounts`);
            });

            console.log('');
            console.log('🔄 Fetching fresh balances from Plaid...');
            
            const startTime = Date.now();
            await this.balanceUpdateService.fetchAndStoreBalancesForAllUsers();
            const duration = Date.now() - startTime;

            console.log('');
            console.log('✅ Balance update completed successfully!');
            console.log(`⚡ Duration: ${duration}ms`);
            console.log('📊 New balance snapshots saved to database');
            console.log('🎯 Widget data updated - check your app!');
            
            if (!this.isWatching) {
                console.log('');
                console.log('💡 Next steps:');
                console.log('   1. Open your iOS app');
                console.log('   2. Check the widget on dashboard');
                console.log('   3. Configure account categories (inflow/outflow)');
                console.log('   4. Run this script daily to see progression');
            }
            
        } catch (error) {
            console.error('');
            console.error('❌ Balance update failed:');
            console.error('Error:', error.message);
            
            if (error.message.includes('PLAID')) {
                console.error('');
                console.error('🔧 Plaid-related error. Check:');
                console.error('   • PLAID_CLIENT_ID is set');
                console.error('   • PLAID_SECRET is set');
                console.error('   • PLAID_ENV is "sandbox"');
                console.error('   • Accounts may need re-authentication');
            }
            
            if (!this.isWatching) {
                process.exit(1);
            }
        }
    }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('\n👋 Shutting down balance updater...');
    process.exit(0);
});

// Run the updater
const updater = new DailyBalanceUpdater();
updater.run(); 