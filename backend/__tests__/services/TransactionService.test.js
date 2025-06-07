const TransactionService = require('../../services/TransactionService');
const { jest } = require('@jest/globals');

// Mock Plaid client
const mockPlaidClient = {
  transactionsGet: jest.fn()
};

// Mock date for consistent testing
const mockDate = new Date('2025-01-15T10:00:00Z'); // Mid-month signup
const originalDate = Date;

describe('TransactionService', () => {
  let transactionService;

  beforeEach(() => {
    // Reset mocks
    jest.clearAllMocks();
    
    // Mock Date constructor to return consistent date
    global.Date = jest.fn((...args) => {
      if (args.length === 0) {
        return mockDate;
      }
      return new originalDate(...args);
    });
    
    // Copy static methods from original Date
    Object.setPrototypeOf(Date, originalDate);
    Object.getOwnPropertyNames(originalDate).forEach(name => {
      if (name !== 'length' && name !== 'name' && name !== 'prototype') {
        Date[name] = originalDate[name];
      }
    });

    transactionService = new TransactionService(mockPlaidClient);
  });

  afterEach(() => {
    global.Date = originalDate;
  });

  describe('fetchMonthlyTransactions', () => {
    test('should fetch transactions from month start to current date', async () => {
      // Arrange
      const accessToken = 'test-access-token';
      const expectedTransactions = [
        {
          transaction_id: 'txn1',
          account_id: 'acc1',
          amount: 100.50,
          date: '2025-01-03'
        },
        {
          transaction_id: 'txn2',
          account_id: 'acc1',
          amount: -50.25,
          date: '2025-01-10'
        }
      ];

      mockPlaidClient.transactionsGet.mockResolvedValue({
        transactions: expectedTransactions,
        total_transactions: 2
      });

      // Act
      const result = await transactionService.fetchMonthlyTransactions(accessToken);

      // Assert
      expect(mockPlaidClient.transactionsGet).toHaveBeenCalledWith({
        access_token: accessToken,
        start_date: '2025-01-01', // First of current month
        end_date: '2025-01-15'    // Current date
      });
      expect(result).toEqual(expectedTransactions);
    });

    test('should backfill from month start even for mid-month connection', async () => {
      // Arrange
      const accessToken = 'test-access-token';
      
      mockPlaidClient.transactionsGet.mockResolvedValue({
        transactions: [],
        total_transactions: 0
      });

      // Act
      await transactionService.fetchMonthlyTransactions(accessToken);

      // Assert - Should always start from 1st of month, not connection date
      expect(mockPlaidClient.transactionsGet).toHaveBeenCalledWith({
        access_token: accessToken,
        start_date: '2025-01-01', // Always month start
        end_date: '2025-01-15'    // Current date
      });
    });

    test('should handle Plaid API errors appropriately', async () => {
      // Arrange
      const accessToken = 'test-access-token';
      const plaidError = new Error('ITEM_LOGIN_REQUIRED');
      plaidError.error_code = 'ITEM_LOGIN_REQUIRED';
      
      mockPlaidClient.transactionsGet.mockRejectedValue(plaidError);

      // Act & Assert
      await expect(transactionService.fetchMonthlyTransactions(accessToken))
        .rejects.toThrow('ITEM_LOGIN_REQUIRED');
    });

    test('should return empty array when no transactions exist', async () => {
      // Arrange
      const accessToken = 'test-access-token';
      
      mockPlaidClient.transactionsGet.mockResolvedValue({
        transactions: [],
        total_transactions: 0
      });

      // Act
      const result = await transactionService.fetchMonthlyTransactions(accessToken);

      // Assert
      expect(result).toEqual([]);
    });

    test('should handle pagination for large transaction sets', async () => {
      // Arrange
      const accessToken = 'test-access-token';
      const firstBatch = [
        { transaction_id: 'txn1', amount: 100 },
        { transaction_id: 'txn2', amount: -50 }
      ];
      const secondBatch = [
        { transaction_id: 'txn3', amount: 200 }
      ];

      mockPlaidClient.transactionsGet
        .mockResolvedValueOnce({
          transactions: firstBatch,
          total_transactions: 3
        })
        .mockResolvedValueOnce({
          transactions: secondBatch,
          total_transactions: 3
        });

      // Act
      const result = await transactionService.fetchMonthlyTransactions(accessToken);

      // Assert
      expect(mockPlaidClient.transactionsGet).toHaveBeenCalledTimes(2);
      expect(result).toEqual([...firstBatch, ...secondBatch]);
    });
  });

  describe('getMonthStartDate', () => {
    test('should return first day of current month', () => {
      // Act
      const monthStart = transactionService.getMonthStartDate();

      // Assert
      expect(monthStart.getFullYear()).toBe(2025);
      expect(monthStart.getMonth()).toBe(0); // January (0-indexed)
      expect(monthStart.getDate()).toBe(1);
      expect(monthStart.getHours()).toBe(0);
      expect(monthStart.getMinutes()).toBe(0);
      expect(monthStart.getSeconds()).toBe(0);
    });
  });

  describe('formatDateForPlaid', () => {
    test('should format date as YYYY-MM-DD string', () => {
      // Arrange
      const testDate = new Date('2025-01-15T10:30:00Z');

      // Act
      const formatted = transactionService.formatDateForPlaid(testDate);

      // Assert
      expect(formatted).toBe('2025-01-15');
    });
  });
}); 