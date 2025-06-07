const request = require('supertest');
const app = require('../../server');
const jwt = require('jsonwebtoken');

// Mock the services
jest.mock('../../services/TransactionService');
jest.mock('../../services/CashFlowCalculationService');
jest.mock('../../repositories/AccountRepository');
jest.mock('../../repositories/UserRepository');

const TransactionService = require('../../services/TransactionService');
const CashFlowCalculationService = require('../../services/CashFlowCalculationService');
const AccountRepository = require('../../repositories/AccountRepository');
const UserRepository = require('../../repositories/UserRepository');

describe('Cash Flow API Routes', () => {
  let authToken;
  let mockUserId;

  beforeEach(() => {
    jest.clearAllMocks();
    
    // Create a valid JWT token for testing
    mockUserId = 'test-user-id-123';
    authToken = jwt.sign(
      { 
        sub: mockUserId, 
        email: 'test@example.com',
        type: 'ACCESS' // Required by auth middleware
      },
      process.env.JWT_ACCESS_SECRET || 'your-default-access-secret',
      { expiresIn: '1h' }
    );

    // Mock user repository to return a valid user
    UserRepository.prototype.findUserById.mockResolvedValue({
      id: mockUserId,
      email: 'test@example.com',
      pin_hash: 'hashed-pin'
    });
  });

  describe('GET /api/cashflow/monthly', () => {
    test('should return monthly cash flow totals for authenticated user', async () => {
      // Arrange
      const mockAccounts = [
        {
          id: 'acc1',
          plaid_access_token: 'access-token-1',
          is_inflow: true,
          is_outflow: false,
          account_name: 'Checking'
        },
        {
          id: 'acc2',
          plaid_access_token: 'access-token-2',
          is_inflow: false,
          is_outflow: true,
          account_name: 'Credit Card'
        }
      ];

      const mockTransactionsAcc1 = [
        {
          transaction_id: 'txn1',
          account_id: 'acc1',
          amount: 3000.00,
          date: '2025-01-03'
        }
      ];

      const mockTransactionsAcc2 = [
        {
          transaction_id: 'txn2',
          account_id: 'acc2',
          amount: -500.00,
          date: '2025-01-05'
        }
      ];

      const mockCashFlow = {
        totalInflow: 3000.00,
        totalOutflow: 500.00
      };

      // Mock repository and services
      AccountRepository.findAccountsByUserId.mockResolvedValue(mockAccounts);
      TransactionService.prototype.fetchMonthlyTransactions
        .mockResolvedValueOnce(mockTransactionsAcc1)
        .mockResolvedValueOnce(mockTransactionsAcc2);
      CashFlowCalculationService.prototype.calculateMonthlyCashFlow.mockReturnValue(mockCashFlow);

      // Act
      const response = await request(app)
        .get('/api/cashflow/monthly')
        .set('Authorization', `Bearer ${authToken}`);

      // Assert
      expect(response.status).toBe(200);
      expect(response.body).toEqual({
        success: true,
        data: {
          monthlyInflow: 3000.00,
          monthlyOutflow: 500.00,
          periodStart: expect.stringMatching(/^\d{4}-\d{2}-01$/), // YYYY-MM-01 format
          periodEnd: expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/), // YYYY-MM-DD format
          lastUpdated: expect.stringMatching(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
        }
      });

      expect(AccountRepository.findAccountsByUserId).toHaveBeenCalledWith(mockUserId);
      expect(TransactionService.prototype.fetchMonthlyTransactions).toHaveBeenCalledTimes(2);
      expect(CashFlowCalculationService.prototype.calculateMonthlyCashFlow).toHaveBeenCalledWith(
        [...mockTransactionsAcc1, ...mockTransactionsAcc2],
        expect.any(Object)
      );
    });

    test('should return 401 for unauthenticated requests', async () => {
      // Act
      const response = await request(app)
        .get('/api/cashflow/monthly');

      // Assert
      expect(response.status).toBe(401);
      expect(response.body).toEqual({
        success: false,
        error: {
          code: 'MISSING_TOKEN',
          message: expect.any(String)
        }
      });
    });

    test('should return 401 for invalid JWT token', async () => {
      // Act
      const response = await request(app)
        .get('/api/cashflow/monthly')
        .set('Authorization', 'Bearer invalid-token');

      // Assert
      expect(response.status).toBe(401);
      expect(response.body).toEqual({
        success: false,
        error: {
          code: 'INVALID_TOKEN',
          message: expect.any(String)
        }
      });
    });

    test('should return zero totals when user has no accounts', async () => {
      // Arrange
      AccountRepository.findAccountsByUserId.mockResolvedValue([]);

      // Act
      const response = await request(app)
        .get('/api/cashflow/monthly')
        .set('Authorization', `Bearer ${authToken}`);

      // Assert
      expect(response.status).toBe(200);
      expect(response.body.data.monthlyInflow).toBe(0);
      expect(response.body.data.monthlyOutflow).toBe(0);
      expect(TransactionService.prototype.fetchMonthlyTransactions).not.toHaveBeenCalled();
    });

    test('should handle Plaid API errors gracefully', async () => {
      // Arrange
      const mockAccounts = [
        {
          id: 'acc1',
          plaid_access_token: 'access-token-1',
          is_inflow: true,
          is_outflow: false
        }
      ];

      const plaidError = new Error('ITEM_LOGIN_REQUIRED');
      plaidError.error_code = 'ITEM_LOGIN_REQUIRED';

      AccountRepository.findAccountsByUserId.mockResolvedValue(mockAccounts);
      TransactionService.prototype.fetchMonthlyTransactions.mockRejectedValue(plaidError);
      CashFlowCalculationService.prototype.calculateMonthlyCashFlow.mockReturnValue({
        totalInflow: 0,
        totalOutflow: 0
      });

      // Act
      const response = await request(app)
        .get('/api/cashflow/monthly')
        .set('Authorization', `Bearer ${authToken}`);

      // Assert - Should continue processing and return zero totals when all accounts fail
      expect(response.status).toBe(200);
      expect(response.body.data.monthlyInflow).toBe(0);
      expect(response.body.data.monthlyOutflow).toBe(0);
    });

    test('should handle database errors gracefully', async () => {
      // Arrange
      AccountRepository.findAccountsByUserId.mockRejectedValue(new Error('Database connection failed'));

      // Act
      const response = await request(app)
        .get('/api/cashflow/monthly')
        .set('Authorization', `Bearer ${authToken}`);

      // Assert
      expect(response.status).toBe(500);
      expect(response.body).toEqual({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: expect.any(String)
        }
      });
    });

    test('should aggregate transactions from multiple accounts correctly', async () => {
      // Arrange
      const mockAccounts = [
        {
          id: 'acc1',
          plaid_access_token: 'token1',
          is_inflow: true,
          is_outflow: false
        },
        {
          id: 'acc2',
          plaid_access_token: 'token2',
          is_inflow: false,
          is_outflow: true
        }
      ];

      const mockTransactionsAcc1 = [
        { transaction_id: 'txn1', account_id: 'acc1', amount: 2000.00 }
      ];
      const mockTransactionsAcc2 = [
        { transaction_id: 'txn2', account_id: 'acc2', amount: -300.00 }
      ];

      AccountRepository.findAccountsByUserId.mockResolvedValue(mockAccounts);
      TransactionService.prototype.fetchMonthlyTransactions
        .mockResolvedValueOnce(mockTransactionsAcc1)
        .mockResolvedValueOnce(mockTransactionsAcc2);
      
      CashFlowCalculationService.prototype.calculateMonthlyCashFlow.mockReturnValue({
        totalInflow: 2000.00,
        totalOutflow: 300.00
      });

      // Act
      const response = await request(app)
        .get('/api/cashflow/monthly')
        .set('Authorization', `Bearer ${authToken}`);

      // Assert
      expect(response.status).toBe(200);
      expect(TransactionService.prototype.fetchMonthlyTransactions).toHaveBeenCalledTimes(2);
      expect(CashFlowCalculationService.prototype.calculateMonthlyCashFlow).toHaveBeenCalledWith(
        [...mockTransactionsAcc1, ...mockTransactionsAcc2],
        expect.any(Object)
      );
    });

    test('should skip accounts that need reauthentication', async () => {
      // Arrange
      const mockAccounts = [
        {
          id: 'acc1',
          plaid_access_token: 'token1',
          is_inflow: true,
          is_outflow: false,
          needs_reauthentication: false
        },
        {
          id: 'acc2',
          plaid_access_token: 'token2',
          is_inflow: false,
          is_outflow: true,
          needs_reauthentication: true // Should be skipped
        }
      ];

      const mockTransactions = [
        { transaction_id: 'txn1', account_id: 'acc1', amount: 1000.00 }
      ];

      AccountRepository.findAccountsByUserId.mockResolvedValue(mockAccounts);
      TransactionService.prototype.fetchMonthlyTransactions.mockResolvedValue(mockTransactions);
      CashFlowCalculationService.prototype.calculateMonthlyCashFlow.mockReturnValue({
        totalInflow: 1000.00,
        totalOutflow: 0
      });

      // Act
      const response = await request(app)
        .get('/api/cashflow/monthly')
        .set('Authorization', `Bearer ${authToken}`);

      // Assert
      expect(response.status).toBe(200);
      expect(TransactionService.prototype.fetchMonthlyTransactions).toHaveBeenCalledTimes(1);
      expect(TransactionService.prototype.fetchMonthlyTransactions).toHaveBeenCalledWith('token1');
    });
  });
}); 