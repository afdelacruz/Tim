class TransactionService {
  constructor(plaidClient) {
    this.plaidClient = plaidClient;
  }

  /**
   * Fetch transactions from the beginning of the current month to today
   * This implements the backfill logic for mid-month account connections
   */
  async fetchMonthlyTransactions(accessToken) {
    const monthStart = this.getMonthStartDate();
    const today = new Date();
    
    const startDate = this.formatDateForPlaid(monthStart);
    const endDate = this.formatDateForPlaid(today);

    try {
      // Handle pagination for large transaction sets
      let allTransactions = [];
      let offset = 0;
      const count = 500; // Plaid's max per request
      let hasMore = true;

      while (hasMore) {
        const response = await this.plaidClient.transactionsGet({
          access_token: accessToken,
          start_date: startDate,
          end_date: endDate,
          options: {
            offset: offset,
            count: count
          }
        });

        allTransactions = allTransactions.concat(response.transactions);
        
        // Check if we have more transactions to fetch
        hasMore = allTransactions.length < response.total_transactions;
        offset = allTransactions.length;
      }

      return allTransactions;
    } catch (error) {
      // Re-throw Plaid errors with their original error codes
      throw error;
    }
  }

  /**
   * Get the first day of the current month at 00:00:00
   * This is always used as the baseline, regardless of when user connected accounts
   */
  getMonthStartDate() {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);
  }

  /**
   * Format a Date object as YYYY-MM-DD string for Plaid API
   */
  formatDateForPlaid(date) {
    return date.toISOString().split('T')[0];
  }
}

module.exports = TransactionService; 