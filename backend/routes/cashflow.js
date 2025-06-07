const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../utils/authMiddleware');
const AccountRepository = require('../repositories/AccountRepository');
const TransactionService = require('../services/TransactionService');
const CashFlowCalculationService = require('../services/CashFlowCalculationService');
const { Configuration, PlaidApi, PlaidEnvironments } = require('plaid');

// Initialize Plaid client
const plaidConfig = new Configuration({
  basePath: PlaidEnvironments[process.env.PLAID_ENV || 'sandbox'],
  baseOptions: {
    headers: {
      'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID,
      'PLAID-SECRET': process.env.PLAID_SECRET,
    },
  },
});
const plaidClient = new PlaidApi(plaidConfig);

// Initialize services
const transactionService = new TransactionService(plaidClient);
const cashFlowService = new CashFlowCalculationService();

/**
 * GET /api/cashflow/monthly
 * Get monthly cash flow totals for the authenticated user
 */
router.get('/monthly', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Removed temporary test data - now using real Plaid transaction data
    
    // Get user's accounts
    const accounts = await AccountRepository.findAccountsByUserId(userId);
    
    // If no accounts, return zero totals
    if (!accounts || accounts.length === 0) {
      return res.json({
        success: true,
        data: {
          monthlyInflow: 0,
          monthlyOutflow: 0,
          periodStart: getMonthStartDate().toISOString().split('T')[0],
          periodEnd: new Date().toISOString().split('T')[0],
          lastUpdated: new Date().toISOString()
        }
      });
    }

    // Filter out accounts that need reauthentication
    const activeAccounts = accounts.filter(account => !account.needs_reauthentication);
    
    if (activeAccounts.length === 0) {
      return res.json({
        success: true,
        data: {
          monthlyInflow: 0,
          monthlyOutflow: 0,
          periodStart: getMonthStartDate().toISOString().split('T')[0],
          periodEnd: new Date().toISOString().split('T')[0],
          lastUpdated: new Date().toISOString()
        }
      });
    }

    // Fetch transactions for all active accounts
    let allTransactions = [];
    
    for (const account of activeAccounts) {
      try {
        const transactions = await transactionService.fetchMonthlyTransactions(account.plaid_access_token);
        allTransactions = allTransactions.concat(transactions);
      } catch (error) {
        // Log detailed error information for debugging
        console.error(`Error fetching transactions for account ${account.id}:`, {
          message: error.message,
          error_code: error.error_code,
          error_type: error.error_type,
          status: error.status,
          response: error.response?.data
        });
        
        // If it's a Plaid authentication error, we could mark the account for reauthentication
        if (error.error_code === 'ITEM_LOGIN_REQUIRED') {
          // For now, just log it. In production, we'd update the account's needs_reauthentication flag
          console.warn(`Account ${account.id} needs reauthentication`);
        }
      }
    }

    // Create account categories mapping for calculation
    // Map by plaid_account_id since that's what transactions use
    const accountCategories = {};
    activeAccounts.forEach(account => {
      accountCategories[account.plaid_account_id] = {
        id: account.id,
        is_inflow: account.is_inflow,
        is_outflow: account.is_outflow,
        account_name: account.account_name
      };
    });

    // Calculate cash flow totals
    const cashFlowTotals = cashFlowService.calculateMonthlyCashFlow(allTransactions, accountCategories);

    // Return results
    res.json({
      success: true,
      data: {
        monthlyInflow: cashFlowTotals.totalInflow,
        monthlyOutflow: cashFlowTotals.totalOutflow,
        periodStart: getMonthStartDate().toISOString().split('T')[0],
        periodEnd: new Date().toISOString().split('T')[0],
        lastUpdated: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('Error in monthly cash flow endpoint:', error);
    
    // Determine error type and respond appropriately
    if (error.error_code && error.error_code.startsWith('PLAID_')) {
      return res.status(500).json({
        success: false,
        error: {
          code: 'PLAID_ERROR',
          message: `Plaid API error: ${error.error_code} - ${error.message}`
        }
      });
    }
    
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'An error occurred while calculating monthly cash flow'
      }
    });
  }
});

/**
 * Helper function to get the first day of the current month
 */
function getMonthStartDate() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);
}

module.exports = router; 