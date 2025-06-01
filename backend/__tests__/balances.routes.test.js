const request = require('supertest');
const express = require('express');
const { authenticateToken } = require('../utils/authMiddleware');

// Mock the BalanceService before requiring the routes
jest.mock('../services/BalanceService');
const BalanceService = require('../services/BalanceService');

// Mock the auth middleware
jest.mock('../utils/authMiddleware');

// Now require the routes after mocking
const balancesRoutes = require('../routes/balances');

const app = express();
app.use(express.json());
app.use('/api/balances', balancesRoutes);

describe('Balance Routes', () => {
    let mockBalanceService;

    beforeEach(() => {
        jest.clearAllMocks();
        
        // Mock BalanceService instance
        mockBalanceService = {
            getCurrentBalancesForUser: jest.fn()
        };
        BalanceService.mockImplementation(() => mockBalanceService);

        // Mock auth middleware to pass by default
        authenticateToken.mockImplementation((req, res, next) => {
            req.user = { id: 'test-user-id' };
            next();
        });
    });

    describe('GET /api/balances', () => {
        it('should return current balances successfully for authenticated user', async () => {
            // Arrange
            const expectedResult = {
                accounts: [
                    {
                        id: 'account1',
                        name: 'Checking Account',
                        type: 'depository',
                        institution: 'Test Bank',
                        currentBalance: 1500.75,
                        lastUpdated: '2024-01-15',
                        needsReauthentication: false
                    },
                    {
                        id: 'account2',
                        name: 'Savings Account',
                        type: 'depository',
                        institution: 'Test Bank',
                        currentBalance: 5000.00,
                        lastUpdated: '2024-01-15',
                        needsReauthentication: false
                    }
                ],
                totalBalance: 6500.75
            };
            mockBalanceService.getCurrentBalancesForUser.mockResolvedValue(expectedResult);

            // Act
            const response = await request(app)
                .get('/api/balances')
                .expect(200);

            // Assert
            expect(response.body).toEqual({
                success: true,
                data: expectedResult
            });
            expect(mockBalanceService.getCurrentBalancesForUser).toHaveBeenCalledWith('test-user-id');
        });

        it('should return empty result when user has no accounts', async () => {
            // Arrange
            const expectedResult = {
                accounts: [],
                totalBalance: 0
            };
            mockBalanceService.getCurrentBalancesForUser.mockResolvedValue(expectedResult);

            // Act
            const response = await request(app)
                .get('/api/balances')
                .expect(200);

            // Assert
            expect(response.body).toEqual({
                success: true,
                data: expectedResult
            });
        });

        it('should return error when BalanceService fails', async () => {
            // Arrange
            const { AppError } = require('../utils/errorHandler');
            mockBalanceService.getCurrentBalancesForUser.mockRejectedValue(new AppError('Database error', 500, 'INTERNAL_SERVER_ERROR'));

            // Act
            const response = await request(app)
                .get('/api/balances')
                .expect(500);

            // Assert
            expect(response.body).toEqual({
                success: false,
                error: {
                    code: 'INTERNAL_SERVER_ERROR',
                    message: 'Database error'
                }
            });
        });

        it('should require authentication', async () => {
            // Arrange - Mock auth middleware to reject
            authenticateToken.mockImplementation((req, res, next) => {
                res.status(401).json({
                    success: false,
                    error: {
                        code: 'UNAUTHORIZED',
                        message: 'Access token required'
                    }
                });
            });

            // Act
            const response = await request(app)
                .get('/api/balances')
                .expect(401);

            // Assert
            expect(response.body).toEqual({
                success: false,
                error: {
                    code: 'UNAUTHORIZED',
                    message: 'Access token required'
                }
            });
        });
    });
}); 