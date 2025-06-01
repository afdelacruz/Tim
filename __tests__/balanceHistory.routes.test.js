const request = require('supertest');
const express = require('express');
const balanceHistoryRoutes = require('../routes/balanceHistory');
const { authenticateToken } = require('../utils/auth');

// Mock the dependencies
jest.mock('../services/BalanceHistoryService');
jest.mock('../utils/auth');

const BalanceHistoryService = require('../services/BalanceHistoryService');

const app = express();
app.use(express.json());
app.use('/api/balance-history', balanceHistoryRoutes);

describe('Balance History Routes', () => {
    let mockBalanceHistoryService;

    beforeEach(() => {
        jest.clearAllMocks();
        
        // Mock the service instance
        mockBalanceHistoryService = {
            getBalanceHistoryForUser: jest.fn()
        };
        BalanceHistoryService.mockImplementation(() => mockBalanceHistoryService);

        // Mock authentication middleware
        authenticateToken.mockImplementation((req, res, next) => {
            req.user = { id: 'test-user-id' };
            next();
        });
    });

    describe('GET /api/balance-history', () => {
        it('testGetBalanceHistory_withValidRequest_returnsHistoryData', async () => {
            // Arrange
            const mockHistoryData = {
                dateRange: {
                    startDate: '2024-01-01',
                    endDate: '2024-01-31'
                },
                accounts: [
                    {
                        id: 'account1',
                        name: 'Checking Account',
                        type: 'depository',
                        institution: 'Test Bank',
                        history: [
                            { date: '2024-01-01', balance: 1000.00 },
                            { date: '2024-01-15', balance: 1200.50 }
                        ]
                    }
                ],
                totalHistory: [
                    { date: '2024-01-01', totalBalance: 1000.00 },
                    { date: '2024-01-15', totalBalance: 1200.50 }
                ]
            };

            mockBalanceHistoryService.getBalanceHistoryForUser.mockResolvedValue(mockHistoryData);

            // Act
            const response = await request(app)
                .get('/api/balance-history')
                .query({
                    startDate: '2024-01-01',
                    endDate: '2024-01-31'
                });

            // Assert
            expect(response.status).toBe(200);
            expect(response.body).toEqual({
                success: true,
                data: mockHistoryData
            });
            expect(mockBalanceHistoryService.getBalanceHistoryForUser).toHaveBeenCalledWith(
                'test-user-id',
                '2024-01-01',
                '2024-01-31'
            );
        });

        it('testGetBalanceHistory_withoutDateParams_usesDefaults', async () => {
            // Arrange
            const mockHistoryData = {
                dateRange: {
                    startDate: '2024-01-01',
                    endDate: '2024-01-31'
                },
                accounts: [],
                totalHistory: []
            };

            mockBalanceHistoryService.getBalanceHistoryForUser.mockResolvedValue(mockHistoryData);

            // Act
            const response = await request(app)
                .get('/api/balance-history');

            // Assert
            expect(response.status).toBe(200);
            expect(response.body).toEqual({
                success: true,
                data: mockHistoryData
            });
            expect(mockBalanceHistoryService.getBalanceHistoryForUser).toHaveBeenCalledWith(
                'test-user-id',
                undefined,
                undefined
            );
        });

        it('testGetBalanceHistory_withInvalidStartDate_returnsBadRequest', async () => {
            // Act
            const response = await request(app)
                .get('/api/balance-history')
                .query({
                    startDate: 'invalid-date',
                    endDate: '2024-01-31'
                });

            // Assert
            expect(response.status).toBe(400);
            expect(response.body).toEqual({
                success: false,
                error: 'Invalid startDate format. Use YYYY-MM-DD.'
            });
            expect(mockBalanceHistoryService.getBalanceHistoryForUser).not.toHaveBeenCalled();
        });

        it('testGetBalanceHistory_withInvalidEndDate_returnsBadRequest', async () => {
            // Act
            const response = await request(app)
                .get('/api/balance-history')
                .query({
                    startDate: '2024-01-01',
                    endDate: 'invalid-date'
                });

            // Assert
            expect(response.status).toBe(400);
            expect(response.body).toEqual({
                success: false,
                error: 'Invalid endDate format. Use YYYY-MM-DD.'
            });
            expect(mockBalanceHistoryService.getBalanceHistoryForUser).not.toHaveBeenCalled();
        });

        it('testGetBalanceHistory_withStartDateAfterEndDate_returnsBadRequest', async () => {
            // Act
            const response = await request(app)
                .get('/api/balance-history')
                .query({
                    startDate: '2024-01-31',
                    endDate: '2024-01-01'
                });

            // Assert
            expect(response.status).toBe(400);
            expect(response.body).toEqual({
                success: false,
                error: 'startDate cannot be after endDate.'
            });
            expect(mockBalanceHistoryService.getBalanceHistoryForUser).not.toHaveBeenCalled();
        });

        it('testGetBalanceHistory_withServiceError_returnsInternalServerError', async () => {
            // Arrange
            mockBalanceHistoryService.getBalanceHistoryForUser.mockRejectedValue(
                new Error('Database connection failed')
            );

            // Act
            const response = await request(app)
                .get('/api/balance-history')
                .query({
                    startDate: '2024-01-01',
                    endDate: '2024-01-31'
                });

            // Assert
            expect(response.status).toBe(500);
            expect(response.body).toEqual({
                success: false,
                error: 'Failed to get balance history'
            });
        });
    });
}); 