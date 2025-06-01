const request = require('supertest');
const express = require('express');
const { authenticateToken } = require('../utils/authMiddleware');

// Mock the PlaidService before requiring the routes
jest.mock('../services/PlaidService');
const PlaidService = require('../services/PlaidService');

// Mock the auth middleware
jest.mock('../utils/authMiddleware');

// Now require the routes after mocking
const plaidRoutes = require('../routes/plaid');

const app = express();
app.use(express.json());
app.use('/api/plaid', plaidRoutes);

describe('Plaid Routes', () => {
    let mockPlaidService;

    beforeEach(() => {
        jest.clearAllMocks();
        
        // Mock PlaidService instance
        mockPlaidService = {
            createLinkToken: jest.fn(),
            exchangePublicToken: jest.fn()
        };
        PlaidService.mockImplementation(() => mockPlaidService);

        // Mock auth middleware to add user to request
        authenticateToken.mockImplementation((req, res, next) => {
            req.user = { id: 'test-user-id', email: 'test@example.com' };
            next();
        });
    });

    describe('POST /api/plaid/link-token', () => {
        it('should generate link token successfully for authenticated user', async () => {
            // Arrange
            const expectedLinkToken = 'link-sandbox-test-token';
            mockPlaidService.createLinkToken.mockResolvedValue(expectedLinkToken);

            // Act
            const response = await request(app)
                .post('/api/plaid/link-token')
                .expect(200);

            // Assert
            expect(response.body).toEqual({
                success: true,
                linkToken: expectedLinkToken
            });
            expect(mockPlaidService.createLinkToken).toHaveBeenCalledWith('test-user-id');
        });

        it('should return error when PlaidService fails', async () => {
            // Arrange
            const { AppError } = require('../utils/errorHandler');
            mockPlaidService.createLinkToken.mockRejectedValue(new AppError('Plaid API error', 500, 'INTERNAL_SERVER_ERROR'));

            // Act
            const response = await request(app)
                .post('/api/plaid/link-token')
                .expect(500);

            // Assert
            expect(response.body).toEqual({
                success: false,
                error: {
                    code: 'INTERNAL_SERVER_ERROR',
                    message: 'Plaid API error'
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
                .post('/api/plaid/link-token')
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

    describe('POST /api/plaid/exchange-token', () => {
        it('should exchange public token successfully for authenticated user', async () => {
            // Arrange
            const publicToken = 'public-sandbox-test-token';
            const expectedResult = {
                accessToken: 'access-sandbox-test-token',
                itemId: 'item-sandbox-test-id',
                accounts: [
                    {
                        account_id: 'account1',
                        name: 'Checking Account',
                        type: 'depository'
                    }
                ]
            };
            mockPlaidService.exchangePublicToken.mockResolvedValue(expectedResult);

            // Act
            const response = await request(app)
                .post('/api/plaid/exchange-token')
                .send({ publicToken })
                .expect(200);

            // Assert
            expect(response.body).toEqual({
                success: true,
                data: expectedResult
            });
            expect(mockPlaidService.exchangePublicToken).toHaveBeenCalledWith('test-user-id', publicToken);
        });

        it('should return error when public token is missing', async () => {
            // Act
            const response = await request(app)
                .post('/api/plaid/exchange-token')
                .send({})
                .expect(400);

            // Assert
            expect(response.body).toEqual({
                success: false,
                error: {
                    code: 'BAD_REQUEST',
                    message: 'Public token is required'
                }
            });
        });

        it('should return error when PlaidService fails', async () => {
            // Arrange
            const { AppError } = require('../utils/errorHandler');
            const publicToken = 'invalid-token';
            mockPlaidService.exchangePublicToken.mockRejectedValue(new AppError('Invalid public token', 400, 'INVALID_PUBLIC_TOKEN'));

            // Act
            const response = await request(app)
                .post('/api/plaid/exchange-token')
                .send({ publicToken })
                .expect(400);

            // Assert
            expect(response.body).toEqual({
                success: false,
                error: {
                    code: 'INVALID_PUBLIC_TOKEN',
                    message: 'Invalid public token'
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
                .post('/api/plaid/exchange-token')
                .send({ publicToken: 'test-token' })
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