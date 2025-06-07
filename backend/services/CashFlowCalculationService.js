class CashFlowCalculationService {
  /**
   * Calculate monthly cash flow totals based on transactions and account categories
   * @param {Array} transactions - Array of transaction objects from Plaid
   * @param {Object} accountCategories - Object mapping account_id to account category info
   * @returns {Object} - { totalInflow, totalOutflow }
   */
  calculateMonthlyCashFlow(transactions, accountCategories) {
    let totalInflow = 0;
    let totalOutflow = 0;

    transactions.forEach((transaction, index) => {
      // Skip undefined or invalid transactions
      if (!transaction || !transaction.account_id) {
        console.log(`Skipping invalid transaction at index ${index}`);
        return;
      }
      
      const account = accountCategories[transaction.account_id];
      
      if (!account) {
        // Skip transactions for accounts not in our system
        console.log(`Skipping transaction for unmapped account: ${transaction.account_id}`);
        return;
      }

      const categorization = this.categorizeTransaction(transaction, account);
      
      // Log transaction processing for categorized accounts
      if (account.is_inflow || account.is_outflow) {
        console.log(`Processing transaction for ${account.account_name}:`);
        console.log(`  Amount: ${transaction.amount}`);
        console.log(`  Date: ${transaction.date}`);
        console.log(`  Categorization: inflow=${categorization.isInflow}, outflow=${categorization.isOutflow}, amount=${categorization.amount}`);
      }
      
      if (categorization.isInflow) {
        totalInflow += categorization.amount;
      }
      
      if (categorization.isOutflow) {
        totalOutflow += categorization.amount;
      }
    });

    return {
      totalInflow: Math.round(totalInflow * 100) / 100, // Round to 2 decimal places
      totalOutflow: Math.round(totalOutflow * 100) / 100
    };
  }

  /**
   * Categorize a single transaction based on its amount and account category
   * @param {Object} transaction - Transaction object with amount and account_id
   * @param {Object} account - Account object with is_inflow and is_outflow flags
   * @returns {Object} - { isInflow, isOutflow, amount }
   */
  categorizeTransaction(transaction, account) {
    const amount = Math.abs(transaction.amount);
    
    // PLAID CONVENTION: 
    // - Positive amounts = money going OUT (purchases, payments)
    // - Negative amounts = money coming IN (deposits, refunds)
    
    // For inflow accounts: negative amounts count as inflow (deposits)
    const isInflow = account.is_inflow && transaction.amount < 0;
    
    // For outflow accounts: positive amounts count as outflow (purchases)
    // For inflow accounts: positive amounts also count as outflow (e.g., rent from checking)
    const isOutflow = (account.is_outflow && transaction.amount > 0) || 
                      (account.is_inflow && transaction.amount > 0);

    return {
      isInflow,
      isOutflow,
      amount: (isInflow || isOutflow) ? amount : 0
    };
  }
}

module.exports = CashFlowCalculationService; 