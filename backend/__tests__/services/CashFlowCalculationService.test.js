const CashFlowCalculationService = require('../../services/CashFlowCalculationService');

describe('CashFlowCalculationService', () => {
  let cashFlowService;

  beforeEach(() => {
    cashFlowService = new CashFlowCalculationService();
  });

  describe('calculateMonthlyCashFlow', () => {
    test('should calculate inflow correctly for positive transactions in inflow accounts', () => {
      // Arrange
      const transactions = [
        {
          transaction_id: 'txn1',
          account_id: 'acc1',
          amount: 3000.00, // Salary deposit
          date: '2025-01-03'
        },
        {
          transaction_id: 'txn2',
          account_id: 'acc1',
          amount: 500.00, // Bonus
          date: '2025-01-10'
        }
      ];

      const accountCategories = {
        'acc1': {
          id: 'acc1',
          is_inflow: true,
          is_outflow: false,
          account_name: 'Checking Account'
        }
      };

      // Act
      const result = cashFlowService.calculateMonthlyCashFlow(transactions, accountCategories);

      // Assert
      expect(result.totalInflow).toBe(3500.00);
      expect(result.totalOutflow).toBe(0);
    });

    test('should calculate outflow correctly for negative transactions in outflow accounts', () => {
      // Arrange
      const transactions = [
        {
          transaction_id: 'txn1',
          account_id: 'acc2',
          amount: -150.00, // Credit card spending
          date: '2025-01-05'
        },
        {
          transaction_id: 'txn2',
          account_id: 'acc2',
          amount: -75.50, // More spending
          date: '2025-01-12'
        }
      ];

      const accountCategories = {
        'acc2': {
          id: 'acc2',
          is_inflow: false,
          is_outflow: true,
          account_name: 'Credit Card'
        }
      };

      // Act
      const result = cashFlowService.calculateMonthlyCashFlow(transactions, accountCategories);

      // Assert
      expect(result.totalInflow).toBe(0);
      expect(result.totalOutflow).toBe(225.50); // Absolute values
    });

    test('should handle mixed account types correctly', () => {
      // Arrange
      const transactions = [
        // Inflow account transactions
        {
          transaction_id: 'txn1',
          account_id: 'acc1',
          amount: 3000.00, // Salary
          date: '2025-01-03'
        },
        {
          transaction_id: 'txn2',
          account_id: 'acc1',
          amount: -1200.00, // Rent payment from checking
          date: '2025-01-01'
        },
        // Outflow account transactions
        {
          transaction_id: 'txn3',
          account_id: 'acc2',
          amount: -300.00, // Credit card spending
          date: '2025-01-05'
        }
      ];

      const accountCategories = {
        'acc1': {
          id: 'acc1',
          is_inflow: true,
          is_outflow: false,
          account_name: 'Checking Account'
        },
        'acc2': {
          id: 'acc2',
          is_inflow: false,
          is_outflow: true,
          account_name: 'Credit Card'
        }
      };

      // Act
      const result = cashFlowService.calculateMonthlyCashFlow(transactions, accountCategories);

      // Assert
      expect(result.totalInflow).toBe(3000.00); // Only positive amounts from inflow accounts
      expect(result.totalOutflow).toBe(1500.00); // Absolute values: 1200 (rent) + 300 (credit)
    });

    test('should exclude uncategorized accounts from calculations', () => {
      // Arrange
      const transactions = [
        {
          transaction_id: 'txn1',
          account_id: 'acc1',
          amount: 1000.00,
          date: '2025-01-03'
        },
        {
          transaction_id: 'txn2',
          account_id: 'acc3', // Uncategorized account
          amount: 5000.00,
          date: '2025-01-05'
        }
      ];

      const accountCategories = {
        'acc1': {
          id: 'acc1',
          is_inflow: true,
          is_outflow: false,
          account_name: 'Checking Account'
        },
        'acc3': {
          id: 'acc3',
          is_inflow: false,
          is_outflow: false, // Uncategorized
          account_name: 'Savings Account'
        }
      };

      // Act
      const result = cashFlowService.calculateMonthlyCashFlow(transactions, accountCategories);

      // Assert
      expect(result.totalInflow).toBe(1000.00); // Only categorized inflow
      expect(result.totalOutflow).toBe(0);
    });

    test('should return zero totals when no categorized accounts exist', () => {
      // Arrange
      const transactions = [
        {
          transaction_id: 'txn1',
          account_id: 'acc1',
          amount: 1000.00,
          date: '2025-01-03'
        }
      ];

      const accountCategories = {
        'acc1': {
          id: 'acc1',
          is_inflow: false,
          is_outflow: false, // Uncategorized
          account_name: 'Account'
        }
      };

      // Act
      const result = cashFlowService.calculateMonthlyCashFlow(transactions, accountCategories);

      // Assert
      expect(result.totalInflow).toBe(0);
      expect(result.totalOutflow).toBe(0);
    });

    test('should return zero totals when no transactions exist', () => {
      // Arrange
      const transactions = [];
      const accountCategories = {
        'acc1': {
          id: 'acc1',
          is_inflow: true,
          is_outflow: false,
          account_name: 'Checking Account'
        }
      };

      // Act
      const result = cashFlowService.calculateMonthlyCashFlow(transactions, accountCategories);

      // Assert
      expect(result.totalInflow).toBe(0);
      expect(result.totalOutflow).toBe(0);
    });

    test('should handle accounts that are both inflow and outflow', () => {
      // Arrange
      const transactions = [
        {
          transaction_id: 'txn1',
          account_id: 'acc1',
          amount: 2000.00, // Income
          date: '2025-01-03'
        },
        {
          transaction_id: 'txn2',
          account_id: 'acc1',
          amount: -800.00, // Expense
          date: '2025-01-05'
        }
      ];

      const accountCategories = {
        'acc1': {
          id: 'acc1',
          is_inflow: true,
          is_outflow: true, // Both categories
          account_name: 'Main Checking'
        }
      };

      // Act
      const result = cashFlowService.calculateMonthlyCashFlow(transactions, accountCategories);

      // Assert
      expect(result.totalInflow).toBe(2000.00); // Positive amount
      expect(result.totalOutflow).toBe(800.00); // Absolute value of negative amount
    });

    test('should handle decimal amounts correctly', () => {
      // Arrange
      const transactions = [
        {
          transaction_id: 'txn1',
          account_id: 'acc1',
          amount: 1234.56,
          date: '2025-01-03'
        },
        {
          transaction_id: 'txn2',
          account_id: 'acc2',
          amount: -67.89,
          date: '2025-01-05'
        }
      ];

      const accountCategories = {
        'acc1': {
          id: 'acc1',
          is_inflow: true,
          is_outflow: false,
          account_name: 'Checking'
        },
        'acc2': {
          id: 'acc2',
          is_inflow: false,
          is_outflow: true,
          account_name: 'Credit Card'
        }
      };

      // Act
      const result = cashFlowService.calculateMonthlyCashFlow(transactions, accountCategories);

      // Assert
      expect(result.totalInflow).toBe(1234.56);
      expect(result.totalOutflow).toBe(67.89);
    });
  });

  describe('categorizeTransaction', () => {
    test('should identify positive transaction in inflow account as inflow', () => {
      // Arrange
      const transaction = { amount: 1000.00, account_id: 'acc1' };
      const account = { is_inflow: true, is_outflow: false };

      // Act
      const result = cashFlowService.categorizeTransaction(transaction, account);

      // Assert
      expect(result.isInflow).toBe(true);
      expect(result.isOutflow).toBe(false);
      expect(result.amount).toBe(1000.00);
    });

    test('should identify negative transaction in outflow account as outflow', () => {
      // Arrange
      const transaction = { amount: -500.00, account_id: 'acc2' };
      const account = { is_inflow: false, is_outflow: true };

      // Act
      const result = cashFlowService.categorizeTransaction(transaction, account);

      // Assert
      expect(result.isInflow).toBe(false);
      expect(result.isOutflow).toBe(true);
      expect(result.amount).toBe(500.00); // Absolute value
    });

    test('should ignore transaction from uncategorized account', () => {
      // Arrange
      const transaction = { amount: 1000.00, account_id: 'acc3' };
      const account = { is_inflow: false, is_outflow: false };

      // Act
      const result = cashFlowService.categorizeTransaction(transaction, account);

      // Assert
      expect(result.isInflow).toBe(false);
      expect(result.isOutflow).toBe(false);
      expect(result.amount).toBe(0);
    });
  });
}); 